# 13 — Linux Interview Questions

> **Module:** 01 – Linux · **Level:** 🟢 → 🔴 · **Time:** revise over several sessions
> Every chapter has its own questions; this page collects the most common ones plus **scenario** and **Product Security** questions you'll meet in real interviews.

---

## How to Use This Page

1. Cover the answer, say yours **out loud**, then compare.
2. For every command in an answer, run it in your lab.
3. For scenario questions, practise structuring your answer: **clarify → investigate → act → prevent**.
4. Mark questions you got wrong and revisit them in a week.

Interviewers care less about memorised flags and more about **how you think**: what you check first, why, and what you'd do about it.

---

## 🟢 Basic

<details><summary><b>1. What is Linux? What is a distribution?</b></summary>

Linux is an open-source kernel. A distribution (Ubuntu, RHEL, Debian, Alpine) bundles the kernel with GNU tools, an init system, a package manager and other software.
</details>

<details><summary><b>2. Kernel vs shell?</b></summary>

The kernel manages hardware, memory, processes and security in kernel space. The shell is a user-space program that interprets commands and asks the kernel to do work through system calls.
</details>

<details><summary><b>3. What's in /etc, /var, /usr, /proc, /tmp?</b></summary>

`/etc` configuration · `/var` variable data (logs, caches, databases) · `/usr` installed programs and libraries · `/proc` virtual view of processes and kernel · `/tmp` world-writable temporary files (sticky bit).
</details>

<details><summary><b>4. Absolute vs relative path?</b></summary>

Absolute starts at `/` and works from anywhere; relative starts from the current directory.
</details>

<details><summary><b>5. How do you find a file by name? By content?</b></summary>

By name: `find / -name "file.conf" 2>/dev/null` (or `locate`). By content: `grep -rn "text" /path`.
</details>

<details><summary><b>6. Explain `chmod 755` and `chmod 640`.</b></summary>

755 = `rwxr-xr-x`: owner full, group and others read/execute. 640 = `rw-r-----`: owner read/write, group read, others nothing.
</details>

<details><summary><b>7. `>` vs `>>`? What does `2>&1` do?</b></summary>

`>` overwrites, `>>` appends. `2>&1` sends stderr to the same place as stdout.
</details>

<details><summary><b>8. How do you check disk space, memory and CPU?</b></summary>

`df -h` (filesystems), `du -sh` (directories), `free -h` (memory), `top`/`htop` (CPU and processes), `uptime` (load), `nproc` (cores).
</details>

<details><summary><b>9. How do you see running processes and kill one?</b></summary>

`ps aux`, `pgrep -a name`, `top`. Kill with `kill PID` (SIGTERM), escalate to `kill -9 PID` only if needed.
</details>

<details><summary><b>10. What does `sudo` do?</b></summary>

Runs a command as another user (root by default) if allowed by `/etc/sudoers`, and logs it. It uses the caller's password, not root's.
</details>

<details><summary><b>11. How do you check which ports are open?</b></summary>

`sudo ss -tulpn` — listening TCP/UDP sockets with the owning process.
</details>

<details><summary><b>12. How do you start a service and make it start at boot?</b></summary>

`sudo systemctl enable --now <service>`.
</details>

---

## 🟡 Intermediate

<details><summary><b>13. What is an inode? Hard link vs soft link?</b></summary>

An inode stores a file's metadata and data location (not its name). A hard link is another name for the same inode (same filesystem, survives deletion of the original). A soft link stores a path (can cross filesystems, breaks if the target is removed).
</details>

<details><summary><b>14. What do r, w, x mean on a directory?</b></summary>

`r` list names, `w` create/delete/rename entries, `x` enter and access entries by name. Deleting a file requires `w`+`x` on its directory, not on the file.
</details>

<details><summary><b>15. Explain SUID, SGID and the sticky bit.</b></summary>

SUID: executable runs as the file owner. SGID: runs as the file's group; on directories, new files inherit the group. Sticky: in a directory, only the file owner can delete/rename files (e.g. `/tmp`).
</details>

<details><summary><b>16. What is umask?</b></summary>

A mask that removes bits from default permissions (666 files, 777 dirs). `022` → 644/755; `027` → 640/750.
</details>

<details><summary><b>17. `/etc/passwd` vs `/etc/shadow`?</b></summary>

`passwd` is world-readable account info; `shadow` holds password hashes and aging, readable only by root (and `shadow` group on Debian/Ubuntu).
</details>

<details><summary><b>18. What happens when you run a command?</b></summary>

The shell parses it (expansions, redirections), finds it (alias → function → builtin → `$PATH`), `fork()`s a child, the child `execve()`s the program, the parent `wait()`s and receives the exit code.
</details>

<details><summary><b>19. Zombie vs orphan process?</b></summary>

Zombie: exited, waiting for its parent to collect the exit status; can't be killed — fix the parent. Orphan: still running, parent died; adopted by PID 1.
</details>

<details><summary><b>20. SIGTERM vs SIGKILL vs SIGHUP?</b></summary>

SIGTERM (15): polite stop, can be handled. SIGKILL (9): immediate, can't be caught, no cleanup. SIGHUP (1): terminal hangup; many daemons reload config on it.
</details>

<details><summary><b>21. What is load average?</b></summary>

Average number of runnable + uninterruptible processes over 1, 5, 15 minutes. Compare with CPU count: load 8 on 4 cores means work is waiting.
</details>

<details><summary><b>22. How does DNS resolution work on Linux?</b></summary>

`/etc/nsswitch.conf` defines the order — usually `/etc/hosts`, then DNS via `/etc/resolv.conf` (on Ubuntu, systemd-resolved at `127.0.0.53`). Test with `getent hosts name` (like apps) and `dig` (DNS only).
</details>

<details><summary><b>23. "Connection refused" vs "timed out"?</b></summary>

Refused: host replied with RST — nothing listening or REJECT rule. Timeout: no reply — dropped by firewall, routing problem or host down.
</details>

<details><summary><b>24. `systemctl restart` vs `reload`?</b></summary>

Restart stops and starts (new PID, brief downtime). Reload asks the running process to re-read config.
</details>

<details><summary><b>25. Where are logs? How do you view a service's logs?</b></summary>

`/var/log` (`syslog`, `auth.log` / `messages`, `secure`) and the journal. `journalctl -u <service> -b`, `-f` to follow, `--since`, `-p err`.
</details>

<details><summary><b>26. `apt update` vs `apt upgrade`? How do you find which package owns a file?</b></summary>

`update` refreshes package lists; `upgrade` installs newer versions. `dpkg -S /path` (or `rpm -qf`).
</details>

<details><summary><b>27. What is LVM and why use it?</b></summary>

A volume manager: PVs → VG → LVs. Lets you resize volumes online, span disks and take snapshots. `lvextend -r -L +10G /dev/vg/lv`.
</details>

<details><summary><b>28. What does `set -euo pipefail` do in a script?</b></summary>

Exit on error, error on unset variables, and fail a pipeline if any command in it fails.
</details>

---

## 🔴 Advanced

<details><summary><b>29. Describe the Linux boot process.</b></summary>

UEFI/BIOS (POST, Secure Boot) → bootloader (GRUB) loads kernel + initramfs → kernel initialises hardware → initramfs mounts the real root (unlocks LUKS) → `systemd` (PID 1) → targets and services → login.
</details>

<details><summary><b>30. What are namespaces and cgroups?</b></summary>

Namespaces isolate what a process sees (PID, mount, network, user, UTS, IPC, cgroup). cgroups limit and account resources (CPU, memory, I/O, PIDs). Together (plus capabilities, seccomp, LSMs) they form containers.
</details>

<details><summary><b>31. What are Linux capabilities?</b></summary>

Root's privileges split into units (`CAP_NET_BIND_SERVICE`, `CAP_SYS_ADMIN`…). Lets programs get only the privilege they need; containers drop most by default. `getcap`, `setcap`, `capsh`.
</details>

<details><summary><b>32. Explain what `strace` and `lsof` show and when you'd use them.</b></summary>

`strace` shows system calls (files opened, network connections, errors like `EACCES`) — great for "why does this fail". `lsof` shows open files and sockets per process — find who holds a port, a deleted file or a mount.
</details>

<details><summary><b>33. What is the OOM killer?</b></summary>

When memory is exhausted, the kernel kills a process (highest `oom_score`) with SIGKILL. Evidence: exit code 137, `dmesg`/`journalctl -k` "Out of memory: Killed process". Mitigate with limits (`MemoryMax`), right-sizing, fixing leaks; tune with `oom_score_adj`.
</details>

<details><summary><b>34. DAC vs MAC? AppArmor vs SELinux?</b></summary>

DAC: owner-controlled permissions. MAC: system policy confines programs even if root. AppArmor (Ubuntu/SUSE) uses path-based profiles; SELinux (RHEL) uses labels on every object — more granular, more complex.
</details>

<details><summary><b>35. How do you make a systemd service more secure?</b></summary>

Non-root `User=`/`DynamicUser=`, `NoNewPrivileges`, `ProtectSystem=strict` + `ReadWritePaths`, `ProtectHome`, `PrivateTmp`, `PrivateDevices`, drop capabilities, `SystemCallFilter`, `RestrictAddressFamilies`, `IPAddressDeny/Allow`, resource limits. Measure with `systemd-analyze security`.
</details>

<details><summary><b>36. How does apt verify packages?</b></summary>

The repository's `InRelease` is GPG-signed and lists hashes of package indexes, which list hashes of each `.deb`. Keys should be bound to their repo with `signed-by=` (not the deprecated global `apt-key`).
</details>

<details><summary><b>37. What kernel parameters would you harden?</b></summary>

ASLR (`randomize_va_space=2`), `kptr_restrict`, `dmesg_restrict`, `yama.ptrace_scope`, `fs.protected_*`, `suid_dumpable=0`, `unprivileged_bpf_disabled`, network: no redirects, no source routing, `rp_filter=1`, `tcp_syncookies=1`, `log_martians=1`, `ip_forward=0` unless routing.
</details>

---

## 🧩 Scenario Questions

Structure: **clarify → investigate (commands) → fix → prevent**.

<details><summary><b>S1. A server is "slow". Walk me through it.</b></summary>

1. `uptime` — load vs `nproc`.
2. `top`/`htop` — CPU (`us` vs `sy` vs `wa` vs `st`), top processes.
3. `free -h`, `vmstat 1 5` — memory pressure, swapping (`si`/`so`).
4. `iostat -xz 1` — disk utilisation and latency; `iotop` for the process.
5. `df -h`, `df -i` — full filesystem?
6. `ss -s`, `sar -n DEV 1` — network saturation, connection counts.
7. `dmesg -T | tail`, `journalctl -p err -b` — OOM, disk or hardware errors.
8. Fix the cause (kill/restart runaway process, add capacity, fix query); prevent with monitoring and limits.
</details>

<details><summary><b>S2. The disk is 100% full. What do you do?</b></summary>

`df -h` to find the filesystem → `du -xh --max-depth=1 / | sort -h` to drill down → common culprits: `/var/log`, journal (`journalctl --vacuum-size`), Docker (`docker system df`), core dumps, package cache (`apt clean`). If `du` and `df` disagree: `lsof +L1` for deleted-but-open files → restart that process. Check `df -i` for inode exhaustion. Prevent: logrotate, journald limits, separate `/var`, monitoring alerts at 80%.
</details>

<details><summary><b>S3. A service won't start after a config change.</b></summary>

`systemctl status svc` → `journalctl -u svc -b --no-pager | tail -50` → validate config with the app's own checker (`nginx -t`, `sshd -t`, `apachectl configtest`) → `systemctl cat svc` → run `ExecStart` manually as the service user → check permissions, port conflicts (`ss -tlnp`), SELinux/AppArmor denials (`journalctl -k -g apparmor`, `ausearch -m avc`). Roll back from backup/Git. Prevent: config in Git, validation in CI, `reload` with config test.
</details>

<details><summary><b>S4. You can't SSH into a server anymore.</b></summary>

Check from the client: `ssh -vvv user@host` (DNS? timeout vs refused vs auth failure). Timeout → network/security group/firewall. Refused → sshd down or wrong port. Auth failure → key, `AllowGroups`, permissions on `~/.ssh` (`700`, `authorized_keys` `600`), account locked/expired. Use the console (cloud serial console, SSM) to inspect `journalctl -u ssh`, `sshd -t`, `ufw status`. Prevent: test SSH changes in a second session, snapshots, break-glass access.
</details>

<details><summary><b>S5. An app can't connect to the database.</b></summary>

From the app host: `getent hosts db` → `ip route get <ip>` → `nc -zv <ip> 5432` (refused vs timeout) → on the DB host: `ss -tlnp` (listening on 127.0.0.1 only?), DB access rules (`pg_hba.conf`), host firewall, cloud security groups → credentials and TLS settings from app logs.
</details>

<details><summary><b>S6. You need to give a contractor access to restart one service and read its logs — nothing else.</b></summary>

Create a user with key-only SSH, add a sudoers drop-in via `visudo -f`: `contractor ALL=(root) NOPASSWD: /usr/bin/systemctl restart myapp, /usr/bin/systemctl status myapp` and add them to a group with read access to that app's logs (or `systemd-journal` with care). Set an expiry (`usermod -e`). Avoid giving editors, shells or wildcards. Audit with auditd/sudo logs. Remove access when done.
</details>

---

## 🔐 Product Security Questions

<details><summary><b>P1. You suspect a Linux server is compromised. What do you do?</b></summary>

1. **Don't panic, don't reboot** — volatile evidence (processes, connections, memory) would be lost. Follow the incident process; inform the lead.
2. **Contain** carefully: isolate network (security group/firewall) rather than power off, if policy allows.
3. **Collect volatile evidence**: `ps -ef --forest`, `ss -tnp`, `lsof -i`, `/proc/*/exe` (deleted binaries), `who`, `last`, logged-in sessions, `crontab -l` for all users, `systemctl list-timers --all`, loaded modules (`lsmod`), memory image if tooling exists.
4. **Persistence check**: `authorized_keys`, cron, systemd units, `/etc/sudoers.d`, shell rc files, new users/UID 0, SUID files, `ld.so.preload`.
5. **Logs**: auth logs, journal, audit logs, web logs — ideally the remote copies.
6. **Integrity**: `dpkg --verify`/`debsums`, AIDE.
7. **Scope**: lateral movement — keys and credentials on the host, other hosts it can reach.
8. **Eradicate & recover**: rebuild from a known-good image, rotate every credential the host had, patch the root cause.
9. **Lessons learned**: detection gaps, hardening, write-up.
</details>

<details><summary><b>P2. How would you find privilege-escalation paths on a Linux host?</b></summary>

`sudo -l`; SUID/SGID binaries (`find / -perm -4000`) and capabilities (`getcap -r /`) checked against GTFOBins; writable files executed by root (cron scripts, systemd `ExecStart`, scripts in root's PATH); root-equivalent groups (`docker`, `lxd`, `disk`); world-writable dirs in PATH; readable secrets (`.env`, SSH keys, history); kernel version vs known exploits; NFS `no_root_squash`; weak service configs. Tools: linpeas, lynis.
</details>

<details><summary><b>P3. Review this Dockerfile from a Linux security view: `FROM ubuntu:latest`, `RUN apt-get update && apt-get install -y curl vim netcat`, `COPY . /app`, `CMD python3 /app/app.py`.</b></summary>

- `latest` isn't reproducible — pin a version or digest; consider a minimal/distroless base.
- Unneeded tools (`vim`, `netcat`) increase attack surface and help attackers.
- No `--no-install-recommends`, apt lists not cleaned.
- `COPY .` may include `.git`, `.env`, keys — use `.dockerignore`.
- Runs as **root** — add a non-root `USER`.
- No pinned dependencies, no image scanning, no healthcheck.
- Runtime: drop capabilities, read-only root filesystem, no `--privileged`, resource limits.
</details>

<details><summary><b>P4. Why is the `docker` group dangerous, and what alternatives exist?</b></summary>

Access to the Docker socket = root on the host (`docker run -v /:/host --rm -it alpine chroot /host`). Alternatives: rootless Docker or Podman, sudo rules for specific commands, CI runners with isolated VMs, and never mounting `/var/run/docker.sock` into containers.
</details>

<details><summary><b>P5. How would you detect a reverse shell or crypto-miner?</b></summary>

Reverse shell: outbound established connections owned by `bash`/`sh`/`python`/`nc` (`ss -tnp`), web server processes with shell children (`ps -ef --forest`), audit rules on `execve` by service users. Miner: sustained high CPU from an unknown or oddly named process, binary in `/tmp`/`/dev/shm` or deleted, connections to mining pools (ports like 3333/4444/14444), new cron/systemd persistence. Runtime tools: Falco, auditd, EDR.
</details>

<details><summary><b>P6. What would your Linux hardening baseline for a product's servers include?</b></summary>

Supported LTS OS; automatic security updates; minimal packages; no public SSH (bastion/SSM) and key-only auth; host firewall default-deny + cloud SGs; services as non-root with systemd sandboxing; AppArmor/SELinux enforcing; sysctl hardening; restrictive mount options; persistent journald + auditd with remote forwarding; file integrity monitoring; time sync; CIS Level 1 as reference with documented exceptions; all of it codified (golden image + Ansible) and continuously scanned.
</details>

<details><summary><b>P7. A developer stores an API key in `/etc/myapp/config.yml` with mode 644. What's wrong and how do you fix it?</b></summary>

Any local user or compromised process can read it. Fix: owner `root:myapp`, mode `640`; better, inject via a secret manager (Vault, AWS Secrets Manager) or systemd credentials (`LoadCredential=`); rotate the exposed key; add secret scanning to prevent recurrence.
</details>

<details><summary><b>P8. How do SSH keys get abused in lateral movement, and how do you reduce it?</b></summary>

Attackers harvest private keys and `known_hosts`/history to find targets, or hijack forwarded agents. Reduce: passphrase-protected keys, no agent forwarding (`ProxyJump` instead), per-user keys (no shared keys), short-lived SSH certificates, `AllowGroups`, restricted `authorized_keys` options (`from=`, `command=`), regular key audits.
</details>

---

## 🧪 Hands-on "Interview Tasks"

Common live tasks. Practise each in your lab with a timer (5–10 minutes each).

1. Find the 10 largest files under `/var`.
2. Find all files modified in the last 24 hours under `/etc`.
3. Show the top 5 IPs from an access log.
4. Create a user who can only run `systemctl restart nginx` via sudo.
5. Write a script that alerts when any filesystem is above 80%.
6. Find which process is listening on port 8080 and stop it gracefully.
7. Make a service start at boot and restart automatically on failure.
8. Find all SUID binaries and explain one of them.
9. Show failed SSH login attempts from today, grouped by IP.
10. Add a 1 GB loop disk, format it, and mount it permanently with `noexec`.

Answers are all in chapters 03–12.

---

## Summary

- Know the basics cold; interviewers use them to judge confidence.
- For scenarios, show a structured, evidence-driven approach.
- For Product Security roles, always connect Linux facts to **risk**: who can do what, what's exposed, how you'd detect and prevent abuse.

**Back to:** [Module 01 — Linux](README.md)

---

## References

- All chapters in this module
- GTFOBins — https://gtfobins.github.io/
- Brendan Gregg, *Linux Performance Analysis in 60,000 Milliseconds* — https://netflixtechblog.com/linux-performance-analysis-in-60-000-milliseconds-accc10403c55
- SANS Linux incident response cheat sheets — https://www.sans.org/posters/
