# 🏠 Home Lab — Windows + Linux VMs with KVM

> Build a small, isolated lab on an Ubuntu laptop: one **Linux** VM and one **Windows** VM, plus your host. Practise SSH, SFTP, PowerShell 7 remoting, RDP, firewalls, packet capture and every Linux lab in this handbook.

---

## Which Hypervisor?

| Option | Host OS | Cost | Performance | Ease | Verdict for an Ubuntu host |
|---|---|---|---|---|---|
| **KVM + QEMU + virt-manager** | Linux | Free | ⭐⭐⭐ Native (kernel built-in) | ⭐⭐ | ✅ **Recommended** |
| VirtualBox 7 | Linux, Windows, macOS | Free | ⭐⭐ | ⭐⭐⭐ | Good alternative, simpler GUI |
| VMware Workstation Pro | Linux, Windows | Free for personal use | ⭐⭐⭐ | ⭐⭐⭐ | Good; closed source, needs kernel modules |
| Hyper-V | Windows only | Included in Pro/Enterprise | ⭐⭐⭐ | ⭐⭐ | Best if your host is Windows |
| Multipass | All | Free | ⭐⭐ | ⭐⭐⭐ | Linux VMs only — no Windows |

**Why KVM on an Ubuntu laptop:** it's part of the Linux kernel (no extra drivers), has the lowest overhead (which matters on modest hardware), supports TPM 2.0 and Secure Boot for Windows 11, and it's what clouds like AWS (Nitro) and GCP are built on — so the skills transfer.

> Don't run VirtualBox VMs and KVM VMs **at the same time** — the two hypervisors can conflict. Pick one.

---

## Will My Laptop Cope?

Check your hardware:

```bash
lscpu | grep -E 'Model name|^CPU\(s\)|Virtualization'   # need VT-x (Intel) or AMD-V
free -h                                                   # RAM
lsblk -d -o NAME,ROTA,SIZE,MODEL                          # ROTA=1 → spinning hard disk, 0 → SSD
```

### Example: HP 15-bs0xx (i3-6006U, 2 cores / 4 threads, 8 GB RAM, 5400 rpm HDD)

| Machine | vCPU | RAM | Disk | Notes |
|---|:-:|:-:|:-:|---|
| Host (Ubuntu + XFCE + browser) | — | ~2.5 GB | — | Close browser tabs while VMs run |
| Linux VM — Ubuntu Server (no GUI) | 2 | 1.5 GB | 20 GB | Light; can run all the time |
| Windows VM — **Windows Server 2025 Core** (eval) | 2 | 2–3 GB | 40 GB | Best fit: no desktop, perfect for PowerShell/SSH labs |
| *or* Windows 11 (eval) | 2 | 4 GB | 64 GB | Works, but slow on an HDD; run the Linux VM **or** Windows 11, not both with a browser open |

**Biggest upgrades for the money:**

1. **SSD** (512 GB SATA SSD) — VMs on a 5400 rpm disk are very slow to boot and update; an SSD makes the whole laptop feel new.
2. **RAM to 16 GB** — check slots and maximum with `sudo dmidecode -t memory | grep -E 'Size|Maximum|Locator'`.

---

## 1. Install KVM and virt-manager

```bash
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients virtinst virt-manager \
                    ovmf swtpm swtpm-tools cpu-checker
kvm-ok                                        # "KVM acceleration can be used"
sudo usermod -aG libvirt,kvm $USER            # manage VMs without sudo
```

**Log out and back in** (group change), then:

```bash
virsh -c qemu:///system list --all            # empty list, no error = working
virsh -c qemu:///system net-list --all        # 'default' network should be active
sudo virsh net-autostart default && sudo virsh net-start default 2>/dev/null
```

Open the GUI: **Applications → System → Virtual Machine Manager** (or run `virt-manager`).

---

## 2. Lab Network

libvirt's **default** network is a private NAT network:

```text
             Internet
                 │
           ┌─────┴─────┐
           │  Your Wi-Fi│
           └─────┬─────┘
                 │
     ┌───────────┴────────────┐
     │  Host (Ubuntu)         │
     │  virbr0 192.168.122.1  │  ← NAT + DHCP + DNS for VMs
     └───┬────────────────┬───┘
         │                │
 ┌───────┴──────┐  ┌──────┴────────┐
 │ ubuntu-lab   │  │ win-lab       │
 │ 192.168.122.x│  │ 192.168.122.y │
 └──────────────┘  └───────────────┘
```

- Host ↔ VMs ↔ each other: ✅
- VMs → Internet: ✅ (through NAT)
- Your home network → VMs: ❌ (they're hidden behind the host — safe for labs)

Find VM IPs:

```bash
virsh -c qemu:///system net-dhcp-leases default
```

For attack/defence labs that must not touch the internet, create an **isolated** network in virt-manager (**Edit → Connection Details → Virtual Networks → +**, mode *Isolated*).

---

## 3. Linux VM — Ubuntu Server

Download the ISO into `~/ISOs`: https://ubuntu.com/download/server

```bash
mkdir -p ~/ISOs
virt-install --connect qemu:///system \
  --name ubuntu-lab --memory 1536 --vcpus 2 \
  --os-variant ubuntu22.04 \
  --disk size=20,format=qcow2 \
  --cdrom ~/ISOs/ubuntu-24.04*-live-server-amd64.iso \
  --network network=default --graphics spice
```

(`--os-variant ubuntu22.04` is fine for 24.04 if your host's OS database doesn't list 24.04 yet: `osinfo-query os | grep -i ubuntu`.)

During installation:

- ✅ **Install OpenSSH server**
- ✅ Import SSH key from GitHub (enter your username) — then you can log in with the same key
- Skip the snaps

After it reboots:

```bash
virsh -c qemu:///system net-dhcp-leases default      # find its IP
ssh <user>@192.168.122.x
```

Snapshot the clean install (works for this BIOS-booted VM):

```bash
virsh -c qemu:///system snapshot-create-as ubuntu-lab clean "Fresh install"
virsh -c qemu:///system snapshot-list ubuntu-lab
virsh -c qemu:///system snapshot-revert ubuntu-lab clean      # roll back
```

---

## 4. Windows VM

### Get an ISO (free evaluation)

From the **Microsoft Evaluation Center** (https://www.microsoft.com/evalcenter):

| Edition | Evaluation | Needs TPM / Secure Boot | Good for |
|---|---|:-:|---|
| **Windows Server 2025** (choose *Server Core* during setup) | 180 days | No | Low RAM; PowerShell, OpenSSH, AD labs |
| Windows 11 Enterprise | 90 days | Yes | Desktop experience, RDP, client-side labs |

### Create it in virt-manager (easiest for Windows)

1. **File → New Virtual Machine → Local install media** → choose the ISO.
2. OS: let it detect (*Microsoft Windows 11* / *Server 2025*).
3. Memory **4096 MB** (Win 11) or **2560 MB** (Server Core); CPUs **2**.
4. Disk **64 GB** (Win 11) or **40 GB** (Server).
5. Name `win-lab`, tick **Customize configuration before install** → Finish.
6. In the customise window:
   - **Overview → Firmware:** `UEFI x86_64 … OVMF_CODE_4M.secboot.fd` (or an entry with `ms` / `secboot`) — needed for Windows 11.
   - **Add Hardware → TPM:** Model **CRB**, Backend **Emulated**, Version **2.0** — needed for Windows 11.
   - **Disk:** bus **SATA** (works without extra drivers).
   - **NIC:** device model **e1000e** (works without extra drivers).
7. **Begin Installation.**

> Faster later: VirtIO disk/network drivers (`virtio-win.iso` from the Fedora project) give better performance, but SATA/e1000e is simplest for a first install.

Windows 11 asks for a Microsoft account during setup; the Enterprise **evaluation** lets you choose *Domain join instead* to create a local account.

### Snapshots for the Windows VM

Internal snapshots aren't supported for UEFI VMs on older libvirt (Ubuntu 22.04). Instead, shut the VM down and copy its disk:

```bash
virsh -c qemu:///system shutdown win-lab
sudo cp --sparse=always /var/lib/libvirt/images/win-lab.qcow2 /var/lib/libvirt/images/win-lab-clean.qcow2
```

---

## 5. PowerShell 7 Everywhere

| Where | Install |
|---|---|
| Ubuntu host / Linux VM | see below |
| Windows VM | `winget install --id Microsoft.PowerShell -e` (Server Core: download the MSI from https://aka.ms/powershell-release?tag=stable) |

Ubuntu 22.04 (change `22.04` to `24.04` inside an Ubuntu 24.04 VM):

```bash
wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb
sudo apt update && sudo apt install -y powershell
pwsh -Command '$PSVersionTable.PSVersion'
```

---

## 6. Lab Exercises

### Lab A — SSH between all machines 🟢

On the **Windows VM** (PowerShell as Administrator):

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
Get-NetFirewallRule -Name *OpenSSH* | Select-Object Name, Enabled
Enable-NetFirewallRule -Name FPS-ICMP4-ERQ-In          # allow ping (blocked by default)
ipconfig
```

From the **host**:

```bash
ping -c2 192.168.122.y
ssh <winuser>@192.168.122.y           # lands in cmd.exe or PowerShell
ssh <user>@192.168.122.x              # Linux VM
ssh-copy-id <user>@192.168.122.x      # key login to Linux
```

Key login to Windows: put your public key in `C:\Users\<user>\.ssh\authorized_keys` (for administrators: `C:\ProgramData\ssh\administrators_authorized_keys`).

Add both to `~/.ssh/config` on the host:

```text
Host linvm
    HostName 192.168.122.x
    User <user>
Host winvm
    HostName 192.168.122.y
    User <winuser>
```

### Lab B — SFTP and a chrooted SFTP-only user 🟡

```bash
sftp linvm                      # ls, cd, put file, get file, bye
scp ./report.txt linvm:/tmp/
rsync -avz ./notes/ linvm:~/notes/
```

On the **Linux VM**, create an upload-only account that can't get a shell:

```bash
sudo groupadd sftponly
sudo useradd -m -g sftponly -s /usr/sbin/nologin uploader && sudo passwd uploader
sudo mkdir -p /srv/sftp/uploader/upload
sudo chown root:root /srv/sftp/uploader && sudo chmod 755 /srv/sftp/uploader   # chroot must be root-owned
sudo chown uploader:sftponly /srv/sftp/uploader/upload

sudo tee /etc/ssh/sshd_config.d/50-sftponly.conf > /dev/null <<'EOF'
Match Group sftponly
    ChrootDirectory /srv/sftp/%u
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
    PasswordAuthentication yes
EOF
sudo sshd -t && sudo systemctl reload ssh
```

From the host: `sftp uploader@linvm` works and only sees `/upload`; `ssh uploader@linvm` is refused.

### Lab C — PowerShell remoting over SSH 🟡

Add a PowerShell subsystem to sshd on each target:

- **Linux VM** — `/etc/ssh/sshd_config.d/60-pwsh.conf`:
  ```text
  Subsystem powershell /usr/bin/pwsh -sshs -nologo
  ```
  `sudo sshd -t && sudo systemctl reload ssh`
- **Windows VM** — add to `C:\ProgramData\ssh\sshd_config` (above any `Match` block):
  ```text
  Subsystem powershell c:/progra~1/powershell/7/pwsh.exe -sshs -nologo
  ```
  `Restart-Service sshd`

From `pwsh` on the host:

```powershell
Enter-PSSession -HostName 192.168.122.y -UserName <winuser>     # interactive, Windows
Invoke-Command -HostName 192.168.122.x -UserName <user> -ScriptBlock { uname -a; Get-Process | Select-Object -First 5 }
$s = New-PSSession -HostName 192.168.122.y -UserName <winuser>
Invoke-Command -Session $s -ScriptBlock { Get-Service sshd; Get-NetFirewallProfile | Select Name, Enabled }
Remove-PSSession $s
```

### Lab D — Networking and packet capture 🟡

```bash
ip -br a ; ip r                                  # host: note virbr0
sudo tcpdump -i virbr0 -n host 192.168.122.y     # watch host ↔ Windows traffic
sudo apt install -y nmap
nmap -sT -p 1-1024 192.168.122.y                 # scan YOUR OWN lab VM only
```

On Windows:

```powershell
Get-NetTCPConnection -State Listen | Sort-Object LocalPort | Select LocalAddress, LocalPort, OwningProcess
Test-NetConnection 192.168.122.x -Port 22
Get-NetFirewallRule -Enabled True -Direction Inbound | Select DisplayName -First 20
```

Compare the Windows firewall with `ufw` on the Linux VM: block SSH from the host on one side, test, then allow it again.

### Lab E — Remote desktop 🟢

Enable RDP on Windows (**Settings → System → Remote Desktop**, or `Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' fDenyTSConnections 0; Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'`), then from the host:

```bash
sudo apt install -y remmina remmina-plugin-rdp
remmina            # new connection → RDP → 192.168.122.y
```

### Lab F — Run the handbook's Linux labs 🔴

Every ⚠️ lab in [01-Linux](../01-Linux/README.md) — systemd, storage (add a second virtual disk in virt-manager), and hardening — runs safely on `ubuntu-lab`. Snapshot first, then:

```bash
scp ~/Claude_CLI/product_security/linux/product-security-handbook/labs/linux/scripts/linux-security-audit.sh linvm:
ssh linvm 'sudo bash linux-security-audit.sh'
```

---

## Everyday VM Commands

```bash
virsh -c qemu:///system list --all
virsh -c qemu:///system start ubuntu-lab
virsh -c qemu:///system shutdown win-lab          # clean shutdown
virsh -c qemu:///system destroy win-lab           # force off (like pulling the plug)
virsh -c qemu:///system autostart --disable win-lab
virsh -c qemu:///system dominfo ubuntu-lab
virsh -c qemu:///system setmem ubuntu-lab 1G --config   # change RAM (applies at next boot)
```

Tip: `export LIBVIRT_DEFAULT_URI=qemu:///system` in `~/.bashrc` lets you drop the `-c` option.

---

## Safety Rules

- Only scan and attack machines **you own** (your lab VMs).
- Keep attack labs on an **isolated** network.
- Use separate, lab-only passwords and SSH keys.
- Evaluation Windows licences expire; rebuild instead of trying to extend them.
