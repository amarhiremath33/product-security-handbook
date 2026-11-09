# 12 — Linux Security Hardening

> **Module:** 01 – Linux · **Level:** 🔴 Advanced · **Time:** ~5 hours
> **Lab environment:** **VM only** (Multipass, VirtualBox or a cloud VM). Take a snapshot first — some steps can lock you out. See [labs/README.md](../labs/README.md)

---

## Objectives

After this chapter you will be able to:

- Explain hardening as attack-surface reduction and defence in depth.
- Measure a baseline with an audit script and Lynis.
- Harden accounts, sudo, SSH, the firewall, services, filesystems and kernel parameters.
- Add brute-force protection, mandatory access control (AppArmor) and auditing.
- Keep a system patched automatically.
- Map your work to the CIS Benchmark and explain trade-offs.

---

## What Is Hardening?

**Hardening** = reducing a system's attack surface and limiting the damage if something is compromised.

```text
                 ┌─────────────────────────────────────────────┐
  Internet  ───► │ Cloud firewall / security group             │ ← only needed ports
                 │  ┌───────────────────────────────────────┐  │
                 │  │ Host firewall (ufw / nftables)        │  │ ← default deny
                 │  │  ┌─────────────────────────────────┐  │  │
                 │  │  │ SSH: keys only, no root, limits │  │  │ ← strong authentication
                 │  │  │  ┌───────────────────────────┐  │  │  │
                 │  │  │  │ Least-privilege users,    │  │  │  │
                 │  │  │  │ sudo rules, sandboxed     │  │  │  │ ← contain the blast radius
                 │  │  │  │ services, AppArmor        │  │  │  │
                 │  │  │  │  ┌─────────────────────┐  │  │  │  │
                 │  │  │  │  │ Patched kernel and  │  │  │  │  │ ← remove known bugs
                 │  │  │  │  │ packages, sysctl    │  │  │  │  │
                 │  │  │  │  └─────────────────────┘  │  │  │  │
                 │  │  │  └───────────────────────────┘  │  │  │
                 │  │  └─────────────────────────────────┘  │  │
                 │  └───────────────────────────────────────┘  │
                 │      Logging + auditing + alerting watch every layer
                 └─────────────────────────────────────────────┘
```

Principles:

1. **Minimise** — fewer packages, services, ports, users and privileges.
2. **Least privilege** — every user and service gets only what it needs.
3. **Defence in depth** — assume one layer will fail.
4. **Secure defaults** — deny by default, allow explicitly.
5. **Verify** — measure before and after; hardening you can't measure is guesswork.
6. **Automate** — hand-hardened servers drift. Codify it (Ansible, cloud-init, golden images).

Standards: **CIS Benchmarks** (most common), **DISA STIGs** (US government), vendor guides (Ubuntu Security Guide `usg`).

---

## Step 0 — Baseline 📏

Before changing anything, measure:

```bash
sudo bash linux-security-audit.sh --no-color > ~/before-audit.txt    # from labs/linux/scripts/
sudo apt install -y lynis
sudo lynis audit system --quick | tee ~/before-lynis.txt
grep -E "Hardening index" /var/log/lynis.log
```

Keep these. You'll compare at the end.

---

## 1. Patching and Updates

The single most effective control.

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y unattended-upgrades needrestart
sudo dpkg-reconfigure -plow unattended-upgrades       # choose Yes
cat /etc/apt/apt.conf.d/20auto-upgrades
```

Optional automatic reboot (for kernel updates) in `/etc/apt/apt.conf.d/50unattended-upgrades`:

```text
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "03:30";
```

Ubuntu Pro (free for personal use, up to 5 machines) adds **Livepatch** (kernel fixes without reboot) and extended security maintenance: `sudo pro attach <token>`.

Remove what you don't need:

```bash
dpkg -l | grep -E 'telnet|rsh|ftp|xinetd|nis|talk'
sudo apt purge -y telnet ftp 2>/dev/null
sudo apt autoremove -y
```

---

## 2. Accounts, Passwords and sudo

```bash
# Only root has UID 0
awk -F: '$3 == 0' /etc/passwd

# No empty passwords
sudo awk -F: '$2 == ""' /etc/shadow

# Lock the root password (use sudo instead); root keeps working via sudo
sudo passwd -l root

# Lock or remove unused accounts
sudo usermod -L -e 1 olduser

# Service accounts must not have shells
awk -F: '$3 < 1000 && $7 !~ /nologin|false/ {print $1, $7}' /etc/passwd
```

### Password policy

```bash
sudo apt install -y libpam-pwquality
sudo nano /etc/security/pwquality.conf
```

```text
minlen = 14
minclass = 3
maxrepeat = 3
dictcheck = 1
```

Password aging for new accounts in `/etc/login.defs` (`PASS_MAX_DAYS`, `PASS_MIN_DAYS`, `PASS_WARN_AGE`). Modern guidance (NIST SP 800-63B) favours **long passwords + MFA + breach checks** over forced periodic changes.

Lock accounts after repeated failures (`pam_faillock`, Ubuntu 22.04+):

```bash
sudo nano /etc/security/faillock.conf      # deny = 5, unlock_time = 900
sudo faillock --user bob                   # show failures
sudo faillock --user bob --reset           # unlock
```

> Enabling faillock also requires adding it to the PAM stack (`/etc/pam.d/common-auth`). A PAM mistake can lock **everyone** out — keep a root shell open while testing and use a VM snapshot.

### sudo

```bash
sudo visudo -f /etc/sudoers.d/hardening
```

```text
Defaults  use_pty                         # sudo commands run in a pseudo-terminal (stops some escapes)
Defaults  logfile="/var/log/sudo.log"     # extra log file
Defaults  timestamp_timeout=5             # re-ask for password after 5 minutes
Defaults  passwd_tries=3
```

- Review `sudo -l -U <user>` for everyone with sudo.
- Remove `NOPASSWD: ALL` for humans.
- Grant specific commands to automation accounts; avoid editors, interpreters, `find`, `tar`, wildcards (see [chapter 04](04-Users-Groups-Permissions.md)).

---

## 3. SSH Hardening

SSH is the front door of almost every server.

### Before you start ⚠️

1. Confirm **key login works** from your machine: `ssh -i ~/.ssh/id_ed25519 user@server`.
2. Keep your current SSH session open while testing changes in a **second** terminal.
3. Have a snapshot or console access.

### Configuration

Ubuntu reads drop-in files from `/etc/ssh/sshd_config.d/` (first value wins, so keep yours early in the alphabet):

```bash
sudo nano /etc/ssh/sshd_config.d/10-hardening.conf
```

```text
# Authentication
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
AuthenticationMethods publickey
MaxAuthTries 3
LoginGraceTime 30

# Who may log in
AllowGroups ssh-users

# Reduce attack surface
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
PermitTunnel no
ClientAliveInterval 300
ClientAliveCountMax 2

# Logging
LogLevel VERBOSE
```

```bash
sudo groupadd -f ssh-users
sudo usermod -aG ssh-users $USER         # ⚠️ don't skip this — or AllowGroups locks you out
sudo sshd -t                             # syntax check — must print nothing
sudo sshd -T | grep -E 'permitrootlogin|passwordauthentication|allowgroups|maxauthtries'   # effective config
sudo systemctl reload ssh
```

Test from a **new** terminal before closing the old one:

```bash
ssh user@server                                                         # works with your key
ssh -o PubkeyAuthentication=no -o PreferredAuthentications=password user@server   # must be refused
```

Optional:

- Restrict by source IP with the firewall (only your office/VPN can reach port 22).
- Modern crypto only: `ssh-audit` (`pip install ssh-audit`) shows weak algorithms.
- MFA with `libpam-google-authenticator`, or SSH certificates for fleets.
- Remove unused host keys (`ssh_host_dsa_key`, `ssh_host_ecdsa_key`) if your policy requires it.
- Changing the port to e.g. 2222 reduces log noise but **is not** security on its own.

Also audit authorised keys:

```bash
sudo find /home /root -name authorized_keys -exec ls -l {} \; -exec cat {} \;
```

---

## 4. Firewall

### UFW (Ubuntu)

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH                            # ⚠️ BEFORE enabling, or you lock yourself out
sudo ufw limit OpenSSH                            # rate-limit: 6 connections / 30 s per IP
sudo ufw allow from 10.0.0.0/8 to any port 9100 proto tcp   # metrics only from internal network
sudo ufw allow 443/tcp
sudo ufw logging on
sudo ufw enable
sudo ufw status numbered verbose
sudo ufw delete 3                                 # delete a rule by number
```

### nftables (what UFW and firewalld build on)

```bash
sudo nft list ruleset
```

Minimal host firewall (`/etc/nftables.conf`):

```text
#!/usr/sbin/nft -f
flush ruleset

table inet filter {
  chain input {
    type filter hook input priority 0; policy drop;
    iif lo accept
    ct state established,related accept
    ct state invalid drop
    ip protocol icmp accept
    ip6 nexthdr ipv6-icmp accept
    tcp dport 22 ct state new limit rate 10/minute accept
    tcp dport { 80, 443 } accept
    log prefix "nft-drop: " limit rate 5/minute
  }
  chain forward { type filter hook forward priority 0; policy drop; }
  chain output  { type filter hook output priority 0; policy accept; }
}
```

```bash
sudo nft -c -f /etc/nftables.conf      # check syntax
sudo systemctl enable --now nftables
```

Don't run UFW and a hand-written nftables config at the same time — pick one.

> **Egress filtering** (restricting outbound traffic) is often forgotten. A server that can only reach its database and update mirrors can't easily download malware or call a C2 server.

> **Docker bypasses UFW.** Ports published with `docker run -p` are opened through Docker's own rules, ignoring `ufw deny`. Bind to `127.0.0.1:8080:80` or use the `DOCKER-USER` chain.

---

## 5. Brute-Force Protection: fail2ban

```bash
sudo apt install -y fail2ban
sudo tee /etc/fail2ban/jail.local > /dev/null <<'EOF'
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
backend  = systemd
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled = true
EOF
sudo systemctl enable --now fail2ban
sudo fail2ban-client status sshd
sudo fail2ban-client set sshd unbanip 203.0.113.50
```

With key-only SSH, brute force can't succeed — fail2ban mainly reduces noise and resource use. It matters more for services that **do** use passwords (web logins, mail).

---

## 6. Services and Attack Surface

```bash
sudo ss -tulpn                                    # what listens, and where?
systemctl list-unit-files --type=service --state=enabled
systemd-analyze security | sort -k2 -n -r | head  # most exposed services
```

For each service ask: **Do we need it? Does it need to listen on the network? Does it run as root?**

```bash
sudo systemctl disable --now cups avahi-daemon 2>/dev/null   # printing / mDNS — rarely needed on servers
sudo systemctl mask ctrl-alt-del.target                       # Ctrl+Alt+Del won't reboot the box
```

Bind internal services to localhost (`bind 127.0.0.1` in redis.conf, `listen_addresses = 'localhost'` in postgresql.conf) and sandbox your own services ([chapter 07](07-Systemd-and-Services.md)).

---

## 7. Filesystem and Permissions

```bash
# /dev/shm with restrictive options
echo 'tmpfs /dev/shm tmpfs defaults,nosuid,nodev,noexec 0 0' | sudo tee -a /etc/fstab
sudo findmnt --verify && sudo mount -o remount /dev/shm

# /tmp as a separate tmpfs (optional — test first: noexec on /tmp can break
# some installers and build tools that run scripts from /tmp)
# echo 'tmpfs /tmp tmpfs defaults,rw,nosuid,nodev,noexec,relatime,size=1G 0 0' | sudo tee -a /etc/fstab

# Sensitive files
sudo chmod 640 /etc/shadow /etc/gshadow && sudo chown root:shadow /etc/shadow /etc/gshadow
sudo chmod 600 /etc/ssh/sshd_config
sudo chmod 700 /root
sudo chmod 600 /boot/grub/grub.cfg

# Home directories not readable by other users
sudo chmod 750 /home/*

# Stricter default umask for new files (login shells)
sudo sed -i 's/^UMASK.*/UMASK\t\t027/' /etc/login.defs

# SUID review against your baseline from chapter 04
find / -xdev -perm -4000 -type f 2>/dev/null | sort > ~/suid-now.txt
diff ~/labs/suid-baseline.txt ~/suid-now.txt
```

Unneeded SUID can be removed (`sudo chmod u-s /usr/bin/<binary>`) — but understand what breaks first; package updates may restore it (use `dpkg-statoverride` to make it stick).

### File integrity monitoring

```bash
sudo apt install -y aide
sudo aideinit                              # builds the baseline database (takes a while)
sudo cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db
sudo aide --check --config /etc/aide/aide.conf    # reports changed files
```

---

## 8. Kernel Hardening with sysctl

```bash
sudo tee /etc/sysctl.d/99-hardening.conf > /dev/null <<'EOF'
# --- Memory / information leaks ---
kernel.randomize_va_space = 2          # full ASLR
kernel.kptr_restrict = 2               # hide kernel pointers
kernel.dmesg_restrict = 1              # only root reads the kernel log
kernel.yama.ptrace_scope = 1           # processes can only ptrace their children
fs.suid_dumpable = 0                   # no core dumps from SUID programs
kernel.unprivileged_bpf_disabled = 1   # no BPF for unprivileged users
net.core.bpf_jit_harden = 2
kernel.sysrq = 0                       # disable magic SysRq key

# --- Filesystem ---
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2

# --- Network (host, not a router) ---
net.ipv4.ip_forward = 0                # ⚠️ set to 1 on Docker/Kubernetes hosts!
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
EOF

sudo sysctl --system            # apply all files in /etc/sysctl.d
sysctl kernel.kptr_restrict net.ipv4.conf.all.rp_filter
```

Disable rarely used kernel modules (uncommon filesystems and network protocols with a history of bugs):

```bash
sudo tee /etc/modprobe.d/hardening.conf > /dev/null <<'EOF'
install cramfs /bin/false
install freevxfs /bin/false
install hfs /bin/false
install hfsplus /bin/false
install udf /bin/false
install dccp /bin/false
install sctp /bin/false
install rds /bin/false
install tipc /bin/false
EOF
```

Also: GRUB password (stop editing boot parameters at the console), Secure Boot enabled, BIOS/UEFI password — relevant for physical machines.

---

## 9. Mandatory Access Control: AppArmor

Normal permissions are **discretionary** (owners decide). **Mandatory Access Control** confines programs by policy even if they run as root. Ubuntu uses **AppArmor**; RHEL uses **SELinux**.

```bash
sudo aa-status                     # profiles loaded, enforce vs complain mode
sudo apt install -y apparmor-utils apparmor-profiles
ls /etc/apparmor.d/
sudo aa-enforce /etc/apparmor.d/usr.sbin.nginx 2>/dev/null   # enforce a profile (if present)
sudo aa-complain /etc/apparmor.d/<profile>                    # log-only mode, for testing
sudo journalctl -k -g apparmor --since today                  # denials
```

| Mode | Effect |
|---|---|
| enforce | Violations blocked and logged |
| complain | Violations only logged — use while writing a profile |
| unconfined | No profile |

`aa-genprof /path/to/binary` helps you build a profile by watching the program run. SELinux equivalents: `getenforce`, `sestatus`, `ausearch -m avc`.

---

## 10. Logging and Auditing

From [chapter 09](09-Logs.md):

```bash
sudo mkdir -p /var/log/journal && sudo systemctl restart systemd-journald    # persistent journal
sudo apt install -y auditd audispd-plugins
sudo tee /etc/audit/rules.d/hardening.rules > /dev/null <<'EOF'
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d/ -p wa -k sudoers
-w /etc/ssh/sshd_config -p wa -k sshd
-w /etc/ssh/sshd_config.d/ -p wa -k sshd
-w /etc/crontab -p wa -k cron
-w /etc/cron.d/ -p wa -k cron
-w /etc/systemd/system/ -p wa -k systemd
-w /var/log/lastlog -p wa -k logins
-a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -F auid!=unset -k root-cmds
-a always,exit -F arch=b64 -S init_module,finit_module,delete_module -k modules
EOF
sudo augenrules --load
sudo auditctl -l
```

Then forward logs off the host (rsyslog remote, or an agent to your SIEM).

---

## 11. Time Synchronisation

Correct time is essential for logs, TLS and Kerberos.

```bash
timedatectl                          # "System clock synchronized: yes"
sudo timedatectl set-timezone UTC
```

---

## Step 12 — Measure Again 📏

```bash
sudo bash linux-security-audit.sh --no-color > ~/after-audit.txt
diff ~/before-audit.txt ~/after-audit.txt
sudo lynis audit system --quick | tee ~/after-lynis.txt
grep -E "Hardening index" /var/log/lynis.log
less /var/log/lynis-report.dat       # suggestions in machine-readable form
```

Record what you changed, the before/after scores, and **why** you accepted any remaining warnings.

---

## In Production

| Do | Why |
|---|---|
| Harden a **golden image** (Packer, cloud-init) and deploy that | Every server starts hardened; no drift |
| Express hardening as code (Ansible roles like `dev-sec.os-hardening`, `dev-sec.ssh-hardening`) | Reviewed, repeatable, testable |
| Scan continuously (Lynis, OpenSCAP with CIS profile, cloud CSPM, Wazuh) | Detect drift and new findings |
| Use bastion hosts / SSM Session Manager / Tailscale instead of public SSH | Port 22 not exposed to the internet at all |
| Document exceptions | Not every CIS control fits every system — record the risk decision |
| Test on staging first | Hardening breaks things (sysctl on K8s nodes, `noexec` on build agents, MAC profiles) |

Ubuntu's built-in compliance tool (Ubuntu Pro): `sudo usg audit cis_level1_server` and `sudo usg fix cis_level1_server`.

---

## Product Security Perspective

As a Product Security Engineer you'll **define** baselines more than apply them by hand:

- Write the hardening standard for your product's hosts and containers (based on CIS, adjusted to your threat model).
- Make it testable: Lynis/OpenSCAP/InSpec checks in CI for images.
- Review exceptions with engineering teams.
- Map controls to threats: *which attack does this setting stop?*

| Threat | Controls |
|---|---|
| Internet brute force / credential stuffing | Key-only SSH, no root login, fail2ban, no public port 22 |
| Exploitation of an exposed service | Patching, firewall, bind to localhost, minimal services |
| Post-exploitation privilege escalation | Least privilege, sudo review, SUID/capability review, kernel patches, sysctl, AppArmor |
| Persistence | auditd on cron/systemd/ssh/sudoers, AIDE, centralised logs |
| Lateral movement | Egress filtering, no shared SSH keys, segmented networks |
| Data theft from disks/backups | Encryption at rest, permissions, secure backups |
| Covering tracks | Remote logging, append-only/immutable logs |

---

## Hands-on Lab ⚠️ (VM with snapshot)

Use a fresh Multipass VM:

```bash
multipass launch --name harden --cpus 2 --memory 2G --disk 10G
multipass stop harden && multipass snapshot harden && multipass start harden
multipass transfer labs/linux/scripts/linux-security-audit.sh harden:     # from the repo root on your host
multipass shell harden
```

### Part 1 — Baseline

```bash
sudo bash linux-security-audit.sh --no-color > before-audit.txt
sudo apt update && sudo apt install -y lynis
sudo lynis audit system --quick > before-lynis.txt
grep "Hardening index" /var/log/lynis.log
```

### Part 2 — Patch and minimise

Apply section 1. Remove one unneeded package. Record what you removed.

### Part 3 — Users and sudo

Create user `ops`, add to `sudo`, set a strong password. Add the sudo `Defaults` from section 2. Verify with `sudo -l -U ops`.

### Part 4 — SSH keys only

Multipass VMs already use key login. Inside the VM:

```bash
sudo groupadd -f ssh-users && sudo usermod -aG ssh-users ubuntu
```

Create `/etc/ssh/sshd_config.d/10-hardening.conf` from section 3, then:

```bash
sudo sshd -t && sudo systemctl reload ssh
sudo sshd -T | grep -E 'permitrootlogin|passwordauthentication|allowgroups'
```

From your host, open a second session (`multipass shell harden`) to confirm you can still get in. Get the VM IP (`multipass list`) and confirm password login is refused:

```bash
ssh -o PubkeyAuthentication=no -o PreferredAuthentications=password ubuntu@<vm-ip>   # Permission denied (publickey)
```

### Part 5 — Firewall + fail2ban

Apply sections 4 (UFW) and 5. Verify:

```bash
sudo ufw status verbose
sudo fail2ban-client status sshd
```

### Part 6 — Kernel and filesystem

Apply section 8 (`99-hardening.conf`) and the `/dev/shm` line from section 7.

```bash
sudo sysctl --system > /dev/null
sudo mount -o remount /dev/shm && findmnt /dev/shm
cp /usr/bin/id /dev/shm/id && /dev/shm/id       # Permission denied
```

### Part 7 — Auditing

Apply section 10. Then trigger and find events:

```bash
sudo useradd tempuser && sudo userdel tempuser
sudo ausearch -k identity -i | tail -10
```

### Part 8 — Measure and report

```bash
sudo bash linux-security-audit.sh --no-color > after-audit.txt
diff before-audit.txt after-audit.txt
sudo lynis audit system --quick > after-lynis.txt
grep "Hardening index" /var/log/lynis.log
```

Write `hardening-report.md` in your notes:

| Control | Before | After | Threat mitigated |
|---|---|---|---|
| SSH password auth | yes | no | Brute force |
| Firewall | inactive | default deny | Exposed services |
| … | | | |
| **Lynis hardening index** | | | |

Remaining warnings and why you accepted them.

### Reset

```bash
exit
multipass restore harden.snapshot1     # or: multipass delete harden && multipass purge
```

**Questions**

1. Which single change reduced the most risk, and why?
2. Which change could have locked you out, and what protected you?
3. Why should `net.ipv4.ip_forward` stay `1` on a Kubernetes node?
4. Which Lynis suggestions did you decide **not** to apply, and why?

---

## Common Mistakes

- Enabling the firewall before allowing SSH.
- `AllowGroups`/`AllowUsers` without adding yourself.
- Disabling password auth before confirming key login works.
- Closing the only SSH session before testing new settings.
- Copy-pasting sysctl hardening onto Docker/Kubernetes hosts (breaks `ip_forward`, bridge settings).
- Hardening by hand once, then never checking for drift.
- Chasing a perfect Lynis score instead of addressing real threats.
- Thinking a non-standard SSH port is a security control.

---

## Interview Questions

**1. What is system hardening?**
Reducing the attack surface and limiting impact of compromise: patching, removing unneeded software and services, least privilege, secure configuration of SSH/firewall/kernel, MAC, logging and auditing.

**2. How would you harden SSH?**
Key-only authentication, no root login, `AllowGroups`, low `MaxAuthTries`, disable forwarding where not needed, modern algorithms, restrict source IPs at the firewall, fail2ban, MFA or SSH certificates for fleets, and log at `VERBOSE`.

**3. What's the difference between DAC and MAC?**
DAC (discretionary): owners set permissions on their files. MAC (mandatory): a system-wide policy (AppArmor, SELinux) confines programs regardless of ownership, even root.

**4. What is the CIS Benchmark?**
A consensus-based configuration standard with Level 1 (practical baseline) and Level 2 (defence-in-depth, may impact functionality) profiles, used for auditing and compliance.

**5. Name five sysctl hardening settings and what they do.**
`randomize_va_space=2` (ASLR), `kptr_restrict` (hide kernel pointers), `dmesg_restrict` (restrict kernel log), `tcp_syncookies=1` (SYN flood protection), `accept_redirects=0` (ignore ICMP redirects), `rp_filter=1` (anti-spoofing), `protected_symlinks/hardlinks` (prevent TOCTOU link attacks in sticky directories).

**6. Why does Docker bypass UFW and how do you handle it?**
Docker inserts its own iptables/nftables rules for published ports before UFW's chains. Publish only on `127.0.0.1`, use the `DOCKER-USER` chain, or rely on a cloud firewall.

**7. 🔐 You inherit 200 unmanaged servers. How do you harden them?**
Inventory and scan (Lynis/OpenSCAP), prioritise internet-exposed and critical systems, patch, remove public SSH (bastion/SSM), codify a baseline in Ansible tested on staging, roll out in waves, centralise logs and set up drift detection, then move to golden images.

**8. 🔐 How do you prove hardening worked?**
Before/after measurements (audit scripts, Lynis/OpenSCAP scores), targeted tests (password SSH refused, `noexec` blocks execution, ports closed from outside with `nmap`), and continuous compliance scanning.

---

## Summary

- Measure → patch → minimise → least privilege → harden SSH/firewall/kernel → confine → audit → measure again.
- Protect yourself from lockouts: snapshots, a second session, `sshd -t`, allow SSH before enabling the firewall.
- Use CIS as a guide and your threat model as the judge.
- Codify and continuously verify; hand-hardening drifts.

**Next:** [13 — Linux Interview Questions](13-Linux-Interview-Questions.md)

---

## References

- CIS Ubuntu Linux Benchmark — https://www.cisecurity.org/benchmark/ubuntu_linux
- Ubuntu Security documentation — https://ubuntu.com/security
- Lynis — https://cisofy.com/lynis/
- `man sshd_config`, `man ufw`, `man nft`, `man sysctl.d`, `man apparmor`, `man audit.rules`
- Kernel self-protection — https://kernsec.org/wiki/index.php/Kernel_Self_Protection_Project/Recommended_Settings
- DevSec Hardening Framework (Ansible) — https://dev-sec.io/
