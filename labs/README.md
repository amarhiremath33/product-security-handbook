# 🧪 Labs — How to Run Them on Windows and Linux

Every chapter in this handbook ends with a **Hands-on Lab**. This page explains how to set up a safe lab machine, whether you use **Windows** or **Linux**.

> **Golden rule:** practise on a machine you can throw away. Some labs create users, change firewall rules, format disks, or edit `/etc`. Never run them on a work laptop or a production server.

---

## Which Environment Should I Use?

| Environment | Works on | Best for | systemd | Disk/firewall labs | Effort |
|---|---|---|:---:|:---:|---|
| **WSL2 (Ubuntu)** | Windows 10/11 | Daily commands, scripting, logs | ✅ (enable it) | ⚠️ partial | Very low |
| **Multipass VM** | Windows, Linux, macOS | All labs, quick throwaway VMs | ✅ | ✅ | Low |
| **VirtualBox / Hyper-V / VMware VM** | Windows, Linux, macOS | All labs, GUI if you want one | ✅ | ✅ | Medium |
| **Docker container** | Windows, Linux, macOS | Throwaway command practice | ❌ | ❌ | Low |
| **Your own Linux machine** | Linux | Read-only labs only | ✅ | ❌ don't | None |
| **Cloud VM (AWS/Azure/GCP free tier)** | Any | Real SSH, firewall, internet-facing labs | ✅ | ✅ | Medium + cost risk |

**Recommendation**

- **Windows users:** WSL2 for everyday practice **plus** a Multipass VM for chapters 07, 10 and 12.
- **Linux users:** a Multipass VM for everything. Use your own machine only for read-only commands.

---

## Option 1 — WSL2 on Windows

WSL2 runs a real Linux kernel inside Windows. It's the fastest way to get a Linux terminal.

### Install

Open **PowerShell as Administrator**:

```powershell
wsl --install -d Ubuntu
```

Reboot when asked, then open **Ubuntu** from the Start menu and create a username and password.

Useful WSL commands (run in PowerShell):

```powershell
wsl --list --verbose          # installed distros and their WSL version
wsl --list --online           # distros you can install
wsl -d Ubuntu                 # open a specific distro
wsl --shutdown                # stop all distros (needed after config changes)
wsl --export Ubuntu ubuntu-backup.tar     # back up your distro
wsl --unregister Ubuntu       # DELETE the distro and all its files
```

### Enable systemd (needed for chapters 07, 09, 12)

Inside Ubuntu:

```bash
ps -p 1 -o comm=              # prints "systemd" if it is already enabled
```

If it prints `init` instead:

```bash
sudo tee /etc/wsl.conf > /dev/null <<'EOF'
[boot]
systemd=true
EOF
```

Then in PowerShell run `wsl --shutdown`, reopen Ubuntu, and check again.

### WSL limitations

- No real disks to partition — use the **loop-device** lab in chapter 10 instead.
- Windows Firewall sits in front of WSL, so `ufw` labs are less realistic.
- Windows drives appear under `/mnt/c`, `/mnt/d`. **Keep lab files in your Linux home (`~`)**, not in `/mnt/c` — it's faster and Linux permissions work properly there.

---

## Option 2 — Multipass VM (Windows, Linux, macOS)

[Multipass](https://multipass.run) creates Ubuntu VMs with one command. Each VM is a full Linux system with systemd, real disks and a firewall.

### Install

| OS | Command |
|---|---|
| Linux | `sudo snap install multipass` |
| Windows | Download the installer from https://multipass.run/install (uses Hyper-V or VirtualBox) |
| macOS | `brew install --cask multipass` |

### Use

```bash
multipass launch --name lab --cpus 2 --memory 2G --disk 15G   # create Ubuntu VM
multipass shell lab              # open a shell inside it
multipass list                   # list VMs and their IPs
multipass stop lab               # stop it
multipass snapshot lab           # snapshot (VM must be stopped)
multipass restore lab.snapshot1  # roll back after you break something
multipass delete lab && multipass purge    # destroy it completely
```

> **Tip:** take a snapshot before the hardening labs in chapter 12. If you lock yourself out, restore it.

---

## Option 3 — VirtualBox / Hyper-V / VMware / KVM

Use this if you want a desktop GUI, a **Windows VM**, or a non-Ubuntu distro (Rocky Linux, Debian, Kali).

> **On an Ubuntu host, use KVM + virt-manager.** Step-by-step guide for a Windows + Linux home lab (SSH, SFTP, PowerShell remoting, RDP): **[home-lab-kvm.md](home-lab-kvm.md)**

1. Download an ISO, e.g. **Ubuntu Server LTS** from https://ubuntu.com/download/server
2. Create a VM: 2 CPUs, 2–4 GB RAM, 20 GB disk.
3. Install with default options and enable **OpenSSH server** during setup.
4. Take a snapshot right after installation ("clean install").
5. Optional for chapter 10: add a **second virtual disk** (5 GB) to practise partitioning and LVM.

Connect from your host with SSH so you can copy and paste:

```bash
ssh youruser@<vm-ip>
```

---

## Option 4 — Docker Container (quick throwaway)

Good for practising commands with zero risk. Every time you exit, everything is gone.

```bash
docker run -it --rm --name linux-lab ubuntu:24.04 bash
```

Inside the container, install the tools you need:

```bash
apt update && apt install -y sudo nano less procps iproute2 iputils-ping curl dnsutils
```

**Not suitable for:** systemd (chapter 07), real disks (chapter 10), firewall labs (chapter 12). You are `root` inside the container, so permission labs feel different too.

---

## Lab Conventions Used in This Handbook

| Symbol | Meaning |
|---|---|
| `$ command` | Run as your normal user |
| `# command` / `sudo command` | Needs root |
| `<value>` | Replace with your own value |
| 🟢 Basic · 🟡 Intermediate · 🔴 Advanced | Lab difficulty |
| ⚠️ | The step changes the system — use a lab VM |

Create a working folder for all labs:

```bash
mkdir -p ~/labs && cd ~/labs
```

---

## Before Every Lab

- [ ] I'm on a lab machine, not a work or production system.
- [ ] I took a snapshot (VM) or don't care if it breaks (container).
- [ ] I read the whole lab before running anything.

## After Every Lab

- [ ] Write what you learned in your own words (that's the point of this repo).
- [ ] Note anything that surprised you or failed — failures teach the most.
- [ ] Commit your notes.

---

## Lab Index

| Module | Labs |
|---|---|
| [01 — Linux](../01-Linux/README.md) | 13 chapters, basic → advanced |
| [Home lab (KVM)](home-lab-kvm.md) | Windows + Linux VMs: SSH, SFTP, PowerShell 7 remoting, RDP, packet capture |
| [Linux scripts](linux/scripts/) | Ready-to-run helper scripts used in the labs |
| [Lab notes template](../templates/lab-notes-template.md) | Copy it for every lab you complete |
