# 09 — Logs

> **Module:** 01 – Linux · **Level:** 🟡 Intermediate → 🔴 Advanced · **Time:** ~3 hours
> **Lab environment:** VM recommended; WSL2 with systemd works (use `journalctl`) — see [labs/README.md](../labs/README.md)

---

## Objectives

After this chapter you will be able to:

- Explain how logging works on Linux: journald, rsyslog, application logs, kernel log.
- Find the right log for any question.
- Filter logs by service, time, priority, boot and field with `journalctl`.
- Investigate logins, `sudo` use, SSH attacks and service failures.
- Explain log rotation and retention.
- Use `auditd` to record security-relevant events, and know why logs must leave the host.

---

## How Logging Works

```text
  Applications ──► stdout/stderr ─────────┐   (systemd services)
  Applications ──► syslog() / logger ─────┤
  Kernel ────────► /dev/kmsg ─────────────┤
                                          ▼
                              ┌──────────────────────┐
                              │  systemd-journald    │  binary journal
                              │  /var/log/journal/   │  (or /run/log/journal = RAM only)
                              └──────────┬───────────┘
                                         │ forwards
                                         ▼
                              ┌──────────────────────┐
                              │      rsyslog         │  classic text files
                              │  /var/log/syslog     │
                              │  /var/log/auth.log   │──► remote log server / SIEM
                              └──────────────────────┘

  Apps writing their own files ──► /var/log/nginx/access.log, /var/log/mysql/…
  Login records (binary)       ──► /var/log/wtmp, /var/log/btmp, /var/log/lastlog
```

- **journald** captures everything from systemd services and the kernel.
- **rsyslog** (if installed — standard on Ubuntu Server, often missing in WSL and containers) writes classic text files.
- Some applications write their own files.

---

## Where Are the Logs?

### Debian / Ubuntu

| File | Contents |
|---|---|
| `/var/log/syslog` | General system messages |
| `/var/log/auth.log` | **Logins, SSH, sudo, su, PAM, user changes** |
| `/var/log/kern.log` | Kernel messages |
| `/var/log/dpkg.log`, `/var/log/apt/history.log` | Package installs/removals |
| `/var/log/cloud-init.log` | Cloud VM first-boot setup |
| `/var/log/ufw.log` | Firewall blocks (if logging is on) |
| `/var/log/nginx/`, `/var/log/apache2/` | Web server access and error logs |
| `/var/log/unattended-upgrades/` | Automatic updates |
| `/var/log/wtmp` (binary) | Successful logins → `last` |
| `/var/log/btmp` (binary) | Failed logins → `sudo lastb` |
| `/var/log/lastlog` (binary) | Last login per user → `lastlog` |

### RHEL / Rocky / Fedora

| Debian file | RHEL equivalent |
|---|---|
| `/var/log/syslog` | `/var/log/messages` |
| `/var/log/auth.log` | `/var/log/secure` |
| `/var/log/dpkg.log` | `/var/log/dnf.log` |

Many log files need root or membership in the `adm` group: `sudo` or `sudo usermod -aG adm $USER`.

---

## 🟢 Reading Text Logs

```bash
sudo tail -n 50 /var/log/syslog
sudo tail -f /var/log/auth.log              # follow live
sudo less /var/log/syslog                    # G = end, /word = search
sudo grep -i "error" /var/log/syslog | tail
zcat /var/log/syslog.2.gz | grep -i error    # rotated, compressed logs
sudo zgrep -h "Failed password" /var/log/auth.log*   # search current + rotated logs
```

Anatomy of a syslog line:

```text
Nov  9 10:15:32 web01 sshd[2412]: Failed password for root from 203.0.113.50 port 51234 ssh2
│               │     │    │      └── message
│               │     │    └── PID
│               │     └── program
│               └── hostname
└── timestamp (Ubuntu 24.04+ uses ISO format: 2026-11-09T10:15:32.123456+00:00)
```

### Severity levels (syslog priorities)

| No. | Name | `journalctl -p` | Meaning |
|:-:|---|---|---|
| 0 | emerg | `emerg` | System unusable |
| 1 | alert | `alert` | Act immediately |
| 2 | crit | `crit` | Critical |
| 3 | err | `err` | Error |
| 4 | warning | `warning` | Warning |
| 5 | notice | `notice` | Normal but significant |
| 6 | info | `info` | Informational |
| 7 | debug | `debug` | Debug |

---

## 🟢 `journalctl`

```bash
journalctl                          # everything, oldest first (q to quit)
journalctl -e                       # jump to end
journalctl -f                       # follow live
journalctl -n 100 --no-pager        # last 100 lines, plain output
journalctl -r                       # newest first
```

### Filtering 🟡

```bash
journalctl -u ssh                   # one unit (service name may be 'sshd' on other distros)
journalctl -u nginx -u php8.3-fpm   # several units
journalctl -b                       # current boot
journalctl -b -1                    # previous boot (needs persistent journal)
journalctl --list-boots
journalctl -k                       # kernel only (like dmesg)
journalctl -p err                   # priority err and worse
journalctl -p warning -b            # warnings and worse, this boot
journalctl --since "2026-11-09 08:00" --until "2026-11-09 09:00"
journalctl --since "1 hour ago"
journalctl --since today
journalctl -t sudo                  # by syslog identifier (tag)
journalctl _UID=1000                # by user ID
journalctl _PID=2412                # by process
journalctl _COMM=sshd               # by command name
journalctl /usr/sbin/sshd           # by executable
journalctl -g "Failed password"     # grep inside messages (--grep)
```

### Output formats 🔴

```bash
journalctl -u ssh -o short-iso      # ISO timestamps
journalctl -u ssh -o verbose -n 1   # every field of an entry
journalctl -u ssh -o json-pretty -n 1
journalctl -u ssh -o json --since today | jq -r '.MESSAGE'   # machine processing
journalctl -o cat -u ssh            # message only
```

### Storage and retention

```bash
journalctl --disk-usage
sudo journalctl --vacuum-time=14d   # delete entries older than 14 days
sudo journalctl --vacuum-size=500M  # shrink to 500 MB
sudo journalctl --verify            # check journal file integrity
```

Persistent vs volatile: if `/var/log/journal/` exists, the journal survives reboots; otherwise it lives in `/run/log/journal/` (RAM) and is lost. Configure in `/etc/systemd/journald.conf`:

```ini
[Journal]
Storage=persistent
SystemMaxUse=1G
MaxRetentionSec=1month
```

---

## 🟢 Writing to the Log

```bash
logger "Deployment v2.3 started"                    # tag = your username
logger -t deploy -p user.warning "Disk at 85%"      # custom tag and priority
journalctl -t deploy
```

Use this in scripts so their actions are recorded with everything else.

---

## 🟡 Login and Session Records

```bash
last -n 20                 # successful logins (from wtmp)
last -x reboot shutdown    # reboots and shutdowns
sudo lastb -n 20           # failed logins (from btmp)
lastlog                    # last login for every account (accounts that never log in should show "Never")
who / w                    # who is logged in now
journalctl -u systemd-logind --since today
```

---

## 🟡 Log Rotation

Without rotation, logs fill the disk. **logrotate** renames, compresses and deletes old logs.

```bash
cat /etc/logrotate.conf
ls /etc/logrotate.d/
cat /etc/logrotate.d/rsyslog
sudo logrotate -d /etc/logrotate.d/nginx       # dry run (debug)
sudo logrotate -f /etc/logrotate.d/nginx       # force a rotation now
```

Example for your own app (`/etc/logrotate.d/myapp`):

```text
/var/log/myapp/*.log {
    daily
    rotate 14              # keep 14 old files
    compress
    delaycompress          # keep yesterday's uncompressed
    missingok
    notifempty
    create 0640 myapp adm  # new file permissions
    postrotate
        systemctl reload myapp > /dev/null 2>&1 || true
    endscript
}
```

Rotated files look like `syslog`, `syslog.1`, `syslog.2.gz`, …

---

## 🔴 auditd — Recording Security Events

The **Linux audit system** records events at the kernel level: file access, command execution, permission changes, logins. It's what compliance standards (PCI DSS, CIS) expect.

```bash
sudo apt install -y auditd
sudo systemctl enable --now auditd
```

Add rules:

```bash
sudo auditctl -w /etc/passwd -p wa -k identity          # watch writes/attribute changes
sudo auditctl -w /etc/shadow -p wa -k identity
sudo auditctl -w /etc/sudoers -p wa -k sudoers
sudo auditctl -w /etc/ssh/sshd_config -p wa -k sshd
sudo auditctl -a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -F auid!=unset -k root-cmds   # commands run as root by humans
sudo auditctl -l                                         # list active rules
```

`-p` permissions: `r` read, `w` write, `x` execute, `a` attribute change. `auid` = the **original login user**, kept even after `sudo` or `su` — so you know who really did it.

Search and report:

```bash
sudo ausearch -k identity -i            # events with key 'identity', human-readable
sudo ausearch -k root-cmds -i --start today
sudo aureport --summary
sudo aureport -au                       # authentication report
sudo aureport -x --summary              # executables report
```

Rules added with `auditctl` are lost at reboot. Make them permanent in `/etc/audit/rules.d/hardening.rules` and run `sudo augenrules --load`.

---

## In Production

- **Centralise logs.** Ship them off the host (rsyslog/journald forwarding, Fluent Bit, Vector, the Elastic/Datadog/Splunk agents) to a SIEM. If an attacker gets root, local logs can be edited; remote copies can't.
- **Synchronise time.** `timedatectl` — correlated events across hosts need NTP and UTC.
- **Structured logs.** JSON logs from apps are far easier to search than free text.
- **Retention.** Keep enough history to investigate (often 90 days hot, 1 year archived, depending on regulations).
- **Don't log secrets.** Tokens, passwords, full card numbers and session cookies must never be logged.
- **Alert on what matters.** Root logins, new sudoers, auth failures spikes, audit-rule hits, service crashes.

---

## Product Security Perspective — Investigations

### Brute force against SSH

```bash
# Failed logins per source IP
sudo grep -hE "Failed password|Invalid user" /var/log/auth.log* 2>/dev/null \
  | grep -oE 'from [0-9.]+' | awk '{print $2}' | sort | uniq -c | sort -rn | head

# Same with journald
journalctl -u ssh --since today -g "Failed password|Invalid user" -o cat \
  | grep -oE 'from [0-9.]+' | awk '{print $2}' | sort | uniq -c | sort -rn | head

# Usernames attackers tried
sudo grep -h "Invalid user" /var/log/auth.log* | awk '{for(i=1;i<=NF;i++) if($i=="user") print $(i+1)}' | sort | uniq -c | sort -rn | head
```

### Did any of those IPs succeed?

```bash
sudo grep -h "Accepted" /var/log/auth.log*          # successful logins: method, user, IP
```

`Accepted publickey for amar from 198.51.100.7` — check the IP against the brute-force list.

### What did people do with sudo?

```bash
sudo grep -h "sudo:" /var/log/auth.log* | grep COMMAND | tail -20
journalctl _COMM=sudo --since "1 day ago" -o cat | grep COMMAND
```

### Account changes

```bash
sudo grep -hE "useradd|usermod|userdel|groupadd|passwd\[|new user|new group" /var/log/auth.log*
```

### Timeline around an event

```bash
journalctl --since "2026-11-09 10:10" --until "2026-11-09 10:30" -o short-iso
```

### Signs of log tampering

| Sign | Check |
|---|---|
| Gaps in time | Large jumps between consecutive timestamps |
| Truncated/empty files | `ls -la /var/log/auth.log` with size 0 on a busy host |
| `wtmp`/`btmp` wiped | `last` shows nothing since an odd date |
| History cleared | `~/.bash_history` empty or symlinked to `/dev/null` |
| Journal corrupt | `journalctl --verify` |
| Logging stopped | `systemctl status rsyslog systemd-journald auditd` |

Attackers clear local logs — another reason to forward them in real time.

---

## Hands-on Lab 🟢→🔴

### Part 1 — Explore 🟢

```bash
ls -lh /var/log
sudo tail -n 20 /var/log/syslog 2>/dev/null || journalctl -n 20 --no-pager
journalctl --disk-usage
journalctl --list-boots | tail -3
journalctl -p err -b --no-pager | tail
```

### Part 2 — Write and find your own logs 🟢

```bash
logger -t labapp "User login succeeded for alice"
logger -t labapp -p user.err "Database connection failed"
journalctl -t labapp --no-pager
journalctl -t labapp -p err --no-pager
journalctl -t labapp -o json-pretty -n 1
```

### Part 3 — Generate and investigate failed logins 🟡

Install and start an SSH server (VM or WSL):

```bash
sudo apt install -y openssh-server && sudo systemctl enable --now ssh
```

Generate failures (enter wrong passwords when asked; press Enter to give up):

```bash
for u in admin test oracle $USER; do
  ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -o StrictHostKeyChecking=no "$u@localhost" true
done
```

Also fail `sudo` once (`sudo -k; sudo ls` with a wrong password).

Now investigate:

```bash
journalctl -u ssh --since "15 min ago" -g "Failed|Invalid" --no-pager
journalctl -u ssh --since "15 min ago" -o cat | grep -oE 'Invalid user [^ ]+' | sort | uniq -c
sudo lastb | head
journalctl _COMM=sudo --since "15 min ago" --no-pager
sudo grep -h "authentication failure" /var/log/auth.log 2>/dev/null | tail -3
```

### Part 4 — Logrotate 🟡

```bash
sudo mkdir -p /var/log/labapp
for i in $(seq 1 1000); do echo "$(date -Is) line $i"; done | sudo tee /var/log/labapp/app.log > /dev/null
sudo tee /etc/logrotate.d/labapp > /dev/null <<'EOF'
/var/log/labapp/*.log {
    daily
    rotate 3
    compress
    missingok
    notifempty
    create 0640 root adm
}
EOF
sudo logrotate -d /etc/logrotate.d/labapp 2>&1 | tail -5     # dry run
sudo logrotate -f /etc/logrotate.d/labapp
ls -l /var/log/labapp/
```

### Part 5 — auditd 🔴

```bash
sudo apt install -y auditd && sudo systemctl enable --now auditd
sudo auditctl -w /etc/passwd -p wa -k identity
sudo auditctl -w /etc/hosts -p wa -k hosts-change
sudo useradd labaudit
echo "# lab" | sudo tee -a /etc/hosts > /dev/null
sudo ausearch -k identity -i | tail -20
sudo ausearch -k hosts-change -i | grep -E 'type=SYSCALL|auid' | tail -3
```

Note the `auid=` field: your real username, even though the command ran via `sudo`.

Clean up:

```bash
sudo userdel labaudit
sudo sed -i '/^# lab$/d' /etc/hosts
sudo auditctl -D                                   # delete all temporary rules
sudo rm -rf /var/log/labapp /etc/logrotate.d/labapp
```

**Questions**

1. Which IPs/usernames appeared in your failed SSH attempts?
2. Why might `/var/log/auth.log` not exist on WSL or in a container?
3. What does `auid` tell you that `uid` doesn't?
4. Why should logs be shipped to a remote system?

---

## Common Mistakes

- Looking only at `/var/log` on systems without rsyslog — use `journalctl`.
- Volatile journal (RAM only) — logs from before the reboot that caused the incident are gone.
- No log rotation → full disk → outage.
- Logging secrets (tokens, passwords, full request bodies).
- Mixed time zones across servers — always log in UTC.
- Relying on local logs only — the first thing an attacker with root does is clean them.

---

## Interview Questions

**1. Where are authentication logs on Ubuntu and on RHEL?**
`/var/log/auth.log` on Debian/Ubuntu, `/var/log/secure` on RHEL; also in the journal (`journalctl -u ssh`, `_COMM=sudo`).

**2. What's the difference between journald and rsyslog?**
journald is systemd's structured, binary journal collecting from services and the kernel. rsyslog is a traditional syslog daemon that writes text files and forwards logs; on Ubuntu it receives messages from journald.

**3. How do you see logs for a service since the last boot?**
`journalctl -u <service> -b`.

**4. How do you make journald logs survive reboots?**
Create `/var/log/journal` or set `Storage=persistent` in `journald.conf` and restart journald.

**5. What is logrotate?**
A tool that rotates, compresses and deletes old logs according to rules in `/etc/logrotate.conf` and `/etc/logrotate.d/`.

**6. 🔐 How would you investigate a suspected SSH brute-force attack?**
Count failed and invalid-user attempts per IP and username in auth logs/journal, check for any `Accepted` logins from those IPs, review `last`/`lastb`, look at what successful sessions did (sudo logs, bash history, audit logs), and block the sources (fail2ban, firewall). Then confirm password auth is disabled.

**7. 🔐 What is auditd and what would you monitor with it?**
The kernel audit framework's user-space daemon. Monitor changes to identity files (`passwd`, `shadow`, `group`, `sudoers`), SSH config, cron and systemd directories, privileged command execution, and use of `auid` to attribute actions to the original user.

**8. 🔐 How can you tell whether logs were tampered with, and how do you prevent it?**
Look for time gaps, truncated files, wiped `wtmp`, failing `journalctl --verify`, stopped logging services. Prevent it by forwarding logs in real time to a separate, access-controlled system (SIEM), with append-only or WORM storage.

---

## Summary

- journald collects everything; rsyslog writes classic files; apps may have their own.
- `journalctl` filters by unit, time, boot, priority, tag and field.
- `auth.log`/`secure`, `last`, `lastb` and sudo logs answer "who did what".
- Rotate logs, keep them persistent, and ship them off the host.
- `auditd` records security-relevant actions with the real user behind `sudo`.

**Next:** [10 — Storage](10-Storage.md)

---

## References

- `man journalctl`, `man journald.conf`, `man logger`, `man logrotate`, `man auditctl`, `man ausearch`
- Red Hat — System auditing — https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/security_hardening/auditing-the-system_security-hardening
- CIS Benchmarks (logging and auditing sections) — https://www.cisecurity.org/cis-benchmarks
