# 07 — systemd & Services

> **Module:** 01 – Linux · **Level:** 🟡 Intermediate → 🔴 Advanced · **Time:** ~3 hours
> **Lab environment:** VM, or WSL2 **with systemd enabled** (not Docker) — see [labs/README.md](../labs/README.md)

---

## Objectives

After this chapter you will be able to:

- Explain what systemd is and what units are.
- Start, stop, enable, inspect and troubleshoot services with `systemctl`.
- Read a service's logs with `journalctl`.
- Write your own service unit and override a packaged one safely.
- Schedule jobs with systemd timers (and know cron).
- Sandbox a service and measure its exposure with `systemd-analyze security`.

---

## What Is systemd?

systemd is the **init system** (PID 1) on almost every modern distribution. It:

- Starts services at boot, in parallel, in the right order
- Restarts services that crash
- Puts every service in its own **cgroup** (resource tracking and limits)
- Collects logs (**journald**)
- Handles timers, mounts, sockets, network (networkd), DNS (resolved), time sync (timesyncd)

A **daemon** is a background program with no terminal (names often end in `d`: `sshd`, `crond`, `systemd-journald`). A **service** is how systemd manages a daemon.

---

## Units

Everything systemd manages is a **unit**, described by a text file.

| Unit type | Extension | Example |
|---|---|---|
| Service | `.service` | `ssh.service`, `nginx.service` |
| Socket | `.socket` | `ssh.socket` (starts sshd on first connection — Ubuntu 24.04 default) |
| Timer | `.timer` | `apt-daily.timer`, `logrotate.timer` |
| Target | `.target` | `multi-user.target` (group of units, like a "runlevel") |
| Mount | `.mount` | `tmp.mount` |
| Path | `.path` | Trigger when a file changes |

### Where unit files live

| Path | Who writes it | Priority |
|---|---|:-:|
| `/etc/systemd/system/` | **You** (admins) | Highest |
| `/run/systemd/system/` | Runtime/generated | Middle |
| `/usr/lib/systemd/system/` (also `/lib/...`) | Packages | Lowest |

> Never edit files in `/usr/lib/systemd/system/` — package updates overwrite them. Use `systemctl edit` (creates an override in `/etc`).

### Targets (boot modes)

| Target | Old runlevel | Meaning |
|---|:-:|---|
| `rescue.target` | 1 | Single-user, minimal |
| `multi-user.target` | 3 | Normal server, no GUI |
| `graphical.target` | 5 | Desktop |

```bash
systemctl get-default
sudo systemctl set-default multi-user.target
```

---

## 🟢 Managing Services with `systemctl`

```bash
systemctl status ssh                  # state, PID, memory, recent logs
sudo systemctl start nginx            # start now
sudo systemctl stop nginx             # stop now
sudo systemctl restart nginx          # stop + start (brief downtime)
sudo systemctl reload nginx           # re-read config without stopping (if supported)
sudo systemctl enable nginx           # start at boot
sudo systemctl enable --now nginx     # enable + start
sudo systemctl disable --now nginx    # stop + don't start at boot
sudo systemctl mask nginx             # make it impossible to start (even manually or as a dependency)
sudo systemctl unmask nginx
```

> `enable` = at **boot**. `start` = **now**. They're independent — a common source of "it worked until reboot".

### Reading `systemctl status`

```text
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: enabled)
                     │                                       │
                     └── unit file location                  └── starts at boot?
     Active: active (running) since Mon 2026-11-09 10:00:00 UTC; 2h ago
   Main PID: 812 (nginx)
      Tasks: 3 (limit: 4558)
     Memory: 4.1M
     CGroup: /system.slice/nginx.service
             ├─812 "nginx: master process /usr/sbin/nginx"
             └─813 "nginx: worker process"

Nov 09 10:00:00 lab systemd[1]: Started nginx.service - A high performance web server...
```

### Listing and querying

```bash
systemctl list-units --type=service                    # loaded services
systemctl list-units --type=service --state=running    # running only
systemctl list-unit-files --type=service --state=enabled   # start at boot
systemctl --failed                                     # failed units — check after every reboot
systemctl is-active nginx                              # active / inactive (scriptable)
systemctl is-enabled nginx                             # enabled / disabled / masked
systemctl list-dependencies nginx                      # what it needs
systemctl list-timers                                  # scheduled timers
```

### Inspecting a unit

```bash
systemctl cat nginx                 # the unit file + any overrides
systemctl show nginx -p User,ExecStart,Restart,MainPID   # resolved properties
systemctl show nginx | less         # every property
```

---

## 🟢 Service Logs with `journalctl`

```bash
journalctl -u nginx                    # all logs for the unit
journalctl -u nginx -e                 # jump to the end
journalctl -u nginx -f                 # follow live
journalctl -u nginx --since "10 min ago"
journalctl -u nginx -b                 # since last boot
journalctl -u nginx -p err             # errors and worse
journalctl -u nginx -n 50 --no-pager   # last 50 lines, plain output
```

More in [chapter 09 — Logs](09-Logs.md).

---

## 🟡 Writing a Service Unit

Anatomy of `/etc/systemd/system/myapp.service`:

```ini
[Unit]
Description=My App API
Documentation=https://example.com/docs
After=network-online.target         # start after the network is up
Wants=network-online.target

[Service]
Type=simple                          # ExecStart is the main process (most common)
User=myapp                           # never run apps as root
Group=myapp
WorkingDirectory=/opt/myapp
EnvironmentFile=/etc/myapp/env       # KEY=value lines; chmod 600
ExecStart=/opt/myapp/bin/server --port 8080
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure                   # restart if it crashes
RestartSec=5

[Install]
WantedBy=multi-user.target           # "enable" links it into normal boot
```

| `Type=` | When to use |
|---|---|
| `simple` | Program stays in the foreground (default, most apps) |
| `exec` | Like simple, but systemd waits until the binary actually starts |
| `forking` | Old-style daemons that fork into the background (need `PIDFile=`) |
| `oneshot` | Runs a task and exits (scripts, setup jobs) |
| `notify` | App tells systemd when it's ready (`sd_notify`) |

| `Restart=` | Restarts when… |
|---|---|
| `no` | Never (default) |
| `on-failure` | Non-zero exit, signal, timeout |
| `always` | Any exit, including clean |

After creating or editing unit files:

```bash
sudo systemctl daemon-reload          # re-read unit files
sudo systemctl enable --now myapp
systemctl status myapp
```

### Overriding a packaged service

```bash
sudo systemctl edit nginx             # opens an editor; saves to /etc/systemd/system/nginx.service.d/override.conf
```

```ini
[Service]
LimitNOFILE=65535
Environment=EXTRA_OPTS=-q
```

To replace a list setting like `ExecStart`, clear it first:

```ini
[Service]
ExecStart=
ExecStart=/usr/sbin/nginx -g 'daemon off;' -c /etc/nginx/custom.conf
```

```bash
sudo systemctl edit --full nginx      # copy the whole unit to /etc for full control
sudo systemctl revert nginx           # undo all local overrides
```

---

## 🟡 Timers (and cron)

### systemd timer

Two files: a `.service` (what to run) and a `.timer` (when).

`/etc/systemd/system/backup.service`:

```ini
[Unit]
Description=Nightly backup

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
```

`/etc/systemd/system/backup.timer`:

```ini
[Unit]
Description=Run backup every night

[Timer]
OnCalendar=*-*-* 02:00:00     # every day at 02:00
Persistent=true               # run on next boot if the machine was off at 02:00
RandomizedDelaySec=10m        # spread load

[Install]
WantedBy=timers.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now backup.timer
systemctl list-timers backup.timer
systemd-analyze calendar "Mon..Fri 09:00"    # test a calendar expression
journalctl -u backup.service                  # output of each run
```

| OnCalendar | Meaning |
|---|---|
| `hourly`, `daily`, `weekly` | Shortcuts |
| `*-*-* 02:00:00` | Every day 02:00 |
| `Mon..Fri 09:00` | Weekdays 09:00 |
| `*:0/15` | Every 15 minutes |

### cron (still everywhere)

```bash
crontab -e                  # your jobs
crontab -l
sudo crontab -u bob -l
ls /etc/cron.d /etc/cron.daily /etc/cron.hourly
cat /etc/crontab
```

```text
┌──── minute (0–59)
│ ┌── hour (0–23)
│ │ ┌ day of month (1–31)
│ │ │ ┌ month (1–12)
│ │ │ │ ┌ day of week (0–7, Sun = 0 or 7)
│ │ │ │ │
0 2 * * *   /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1
*/15 * * * * /usr/local/bin/check.sh
@reboot     /usr/local/bin/on-boot.sh
```

| | cron | systemd timer |
|---|---|---|
| Logs | You must redirect output | Automatic in the journal |
| Missed runs (machine off) | Lost (except anacron) | `Persistent=true` catches up |
| Sandboxing / limits | No | Full service options |
| Simplicity | One line | Two files |

> 🔐 cron and timers are favourite **persistence** spots for attackers. Audit them: `crontab -l` for every user, `/etc/cron*`, `/var/spool/cron/crontabs`, `systemctl list-timers --all`.

---

## 🔴 Sandboxing Services

A service running as a non-root user is good. A service that **also** can't see `/home`, can't write outside one directory, can't load kernel modules and can't gain new privileges is much better. systemd can do all of this with a few lines.

| Directive | Effect |
|---|---|
| `User=` / `DynamicUser=yes` | Run as non-root (DynamicUser creates a throwaway user) |
| `NoNewPrivileges=yes` | SUID binaries and file capabilities can't raise privileges |
| `ProtectSystem=strict` | Whole filesystem read-only, except paths in `ReadWritePaths=` |
| `ReadWritePaths=/var/lib/myapp` | The only writable locations |
| `ProtectHome=yes` | `/home`, `/root`, `/run/user` invisible |
| `PrivateTmp=yes` | Own private `/tmp` |
| `PrivateDevices=yes` | No access to physical devices |
| `ProtectKernelTunables=yes`, `ProtectKernelModules=yes`, `ProtectKernelLogs=yes` | Can't change sysctl, load modules, read kernel log |
| `ProtectControlGroups=yes` | cgroup tree read-only |
| `CapabilityBoundingSet=` | Drop all capabilities (list the ones it needs, e.g. `CAP_NET_BIND_SERVICE`) |
| `RestrictAddressFamilies=AF_INET AF_INET6` | Only IPv4/IPv6 sockets |
| `SystemCallFilter=@system-service` | Allow only syscalls normal services need |
| `IPAddressDeny=any` + `IPAddressAllow=` | Per-service network firewall |
| `MemoryMax=512M`, `CPUQuota=50%`, `TasksMax=100` | Resource limits (stops a fork bomb or leak taking down the host) |

Measure exposure (lower is better):

```bash
systemd-analyze security                 # all services, scored 0 (safe) – 10 (exposed)
systemd-analyze security nginx.service   # detailed checklist for one service
```

---

## In Production

- Every app is a systemd service (or a container whose runtime is a systemd service).
- `Restart=on-failure` + monitoring on `systemctl --failed`.
- Secrets via `EnvironmentFile=` with `600` permissions or `LoadCredential=` — not in the unit file (unit files are world-readable).
- Config in Git; overrides in `/etc/systemd/system/<unit>.d/`.
- After any change: `daemon-reload` → `restart` → `status` → `journalctl -u`.

### Troubleshooting a failed service

```bash
systemctl status myapp                       # what state, last log lines
journalctl -u myapp -b --no-pager | tail -50 # full recent logs
systemctl cat myapp                          # is the unit what you think it is?
sudo -u myapp /opt/myapp/bin/server --port 8080   # run the command by hand as the service user
```

Common causes: wrong path in `ExecStart`, permission denied for the service user, port already in use, missing `daemon-reload`, sandboxing blocks a needed path.

---

## Product Security Perspective

| Risk | Check |
|---|---|
| Services running as root | `ps -eo user,comm \| grep '^root'`, `systemctl show <svc> -p User` |
| Unneeded services enabled | `systemctl list-unit-files --state=enabled` — disable/mask what you don't need |
| Weak sandboxing | `systemd-analyze security` — anything rated `UNSAFE` deserves a look |
| Malicious persistence | New units in `/etc/systemd/system/`, `~/.config/systemd/user/`, new timers |
| Secrets in unit files | `grep -ri -E 'password\|secret\|token' /etc/systemd/system/` |
| Writable unit or ExecStart files | A non-root-writable script run by a root service = privilege escalation |

```bash
# Units changed in the last 7 days
sudo find /etc/systemd/system /usr/lib/systemd/system ~/.config/systemd -name '*.service' -mtime -7 2>/dev/null

# ExecStart binaries/scripts writable by non-root
for u in $(systemctl list-units --type=service --state=running --no-legend | awk '{print $1}'); do
  bin=$(systemctl show "$u" -p ExecStart --value | grep -oP 'path=\K[^ ;]+' | head -1)
  [ -n "$bin" ] && [ -e "$bin" ] && find "$bin" -perm /022 -printf "WRITABLE: %p (%u:%g %m) used by $u\n"
done
```

---

## Hands-on Lab ⚠️ (VM or WSL2 with systemd)

Check you have systemd: `ps -p 1 -o comm=` must print `systemd`.

### Part 1 — Explore 🟢

```bash
systemctl list-units --type=service --state=running
systemctl --failed
systemctl status ssh 2>/dev/null || systemctl status cron
systemctl cat cron
systemctl list-timers
systemd-analyze blame | head
```

### Part 2 — Create a service 🟡

```bash
sudo useradd --system --no-create-home --shell /usr/sbin/nologin labweb
sudo mkdir -p /srv/labweb
echo "<h1>Hello from systemd</h1>" | sudo tee /srv/labweb/index.html
sudo chown -R root:labweb /srv/labweb && sudo chmod -R 750 /srv/labweb

sudo tee /etc/systemd/system/labweb.service > /dev/null <<'EOF'
[Unit]
Description=Lab web server
After=network-online.target
Wants=network-online.target

[Service]
User=labweb
Group=labweb
WorkingDirectory=/srv/labweb
ExecStart=/usr/bin/python3 -m http.server 8080 --bind 127.0.0.1
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now labweb
systemctl status labweb --no-pager
curl -s http://127.0.0.1:8080
```

### Part 3 — Self-healing 🟡

```bash
sudo kill -9 $(systemctl show labweb -p MainPID --value)
sleep 5
systemctl status labweb --no-pager | head -5        # running again, new PID
journalctl -u labweb -n 10 --no-pager               # see the crash and restart
```

### Part 4 — Measure, then sandbox 🔴

```bash
systemd-analyze security labweb.service | tail -1   # note the score (likely high / UNSAFE)
sudo systemctl edit labweb
```

Paste between the comment lines, then save:

```ini
[Service]
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
PrivateDevices=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectKernelLogs=yes
ProtectControlGroups=yes
ProtectClock=yes
ProtectHostname=yes
RestrictAddressFamilies=AF_INET AF_INET6
RestrictNamespaces=yes
RestrictRealtime=yes
RestrictSUIDSGID=yes
LockPersonality=yes
MemoryDenyWriteExecute=yes
CapabilityBoundingSet=
SystemCallArchitectures=native
SystemCallFilter=@system-service
IPAddressDeny=any
IPAddressAllow=localhost
MemoryMax=128M
TasksMax=20
```

```bash
sudo systemctl restart labweb
curl -s http://127.0.0.1:8080                        # still works
systemd-analyze security labweb.service | tail -1    # much lower score
```

Prove the sandbox works — the service can't read home directories or write anywhere:

```bash
sudo systemd-run --wait --pty -p User=labweb -p ProtectHome=yes -p ProtectSystem=strict \
  bash -c 'ls /home; touch /etc/test; touch /srv/labweb/x'
```

`ls /home` shows an empty directory (home folders are hidden), and both `touch` commands fail with "Read-only file system" or "Permission denied".

### Part 5 — A timer 🟡

```bash
sudo tee /etc/systemd/system/lab-heartbeat.service > /dev/null <<'EOF'
[Unit]
Description=Lab heartbeat

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'logger -t heartbeat "labweb is $$(systemctl is-active labweb)"'
EOF
```

systemd doesn't run commands through a shell, so `$(...)` needs `/bin/sh -c`, and `$$` is how you write a literal `$` in a unit file.

```bash
sudo tee /etc/systemd/system/lab-heartbeat.timer > /dev/null <<'EOF'
[Unit]
Description=Run lab heartbeat every minute

[Timer]
OnCalendar=*:*:00
AccuracySec=1s

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now lab-heartbeat.timer
systemctl list-timers lab-heartbeat.timer
sleep 65; journalctl -t heartbeat -n 3 --no-pager
```

### Part 6 — Hunt for persistence 🔴

```bash
systemctl list-timers --all
sudo find /etc/systemd/system -newer /etc/hostname -type f     # units newer than install
for u in $(cut -d: -f1 /etc/passwd); do sudo crontab -u "$u" -l 2>/dev/null | sed "s/^/$u: /"; done
ls -la /etc/cron.d /etc/cron.daily
```

You should see the two lab units you created — exactly what an attacker's would look like.

### Clean up

```bash
sudo systemctl disable --now labweb lab-heartbeat.timer
sudo rm -rf /etc/systemd/system/labweb.service /etc/systemd/system/labweb.service.d \
            /etc/systemd/system/lab-heartbeat.{service,timer} /srv/labweb
sudo systemctl daemon-reload
sudo userdel labweb
```

**Questions**

1. What's the difference between `enable` and `start`?
2. Why did the service come back after `kill -9`?
3. Which sandbox directives changed the security score the most?
4. Why does the heartbeat unit need `/bin/sh -c` and `$$`?

---

## Common Mistakes

- Forgetting `daemon-reload` after editing unit files.
- `enable` without `--now` (or `start` without `enable`) — surprises after reboot.
- Editing files in `/usr/lib/systemd/system/` — lost on package update.
- Running services as root because "it needs port 80" — use `AmbientCapabilities=CAP_NET_BIND_SERVICE` or a reverse proxy.
- Putting secrets directly in unit files (they're world-readable; `systemctl show` reveals them).
- Expecting shell features (`|`, `$(...)`, `>`) in `ExecStart` without `/bin/sh -c`.
- Killing a service's process with `kill` instead of `systemctl stop` — it gets restarted.

---

## Interview Questions

**1. What is systemd?**
The init system and service manager (PID 1) on most modern distros. It starts and supervises services, manages dependencies, logging (journald), timers, mounts and cgroups.

**2. `systemctl enable` vs `start`?**
`start` runs it now; `enable` makes it start at boot. `enable --now` does both.

**3. `restart` vs `reload`?**
`restart` stops and starts the process (brief downtime, new PID). `reload` asks the running process to re-read config (usually SIGHUP), keeping connections.

**4. Where do you put a custom unit file? Why not `/usr/lib/systemd/system`?**
`/etc/systemd/system/`. `/usr/lib` is owned by packages and overwritten on updates; `/etc` has higher priority.

**5. A service fails to start. What do you do?**
`systemctl status`, `journalctl -u <svc> -b`, `systemctl cat` to verify the unit, run `ExecStart` by hand as the service user, check permissions, ports, and whether `daemon-reload` was run.

**6. cron vs systemd timers?**
Timers log to the journal, can catch up missed runs, support dependencies and sandboxing. Cron is simpler and universal.

**7. 🔐 How can systemd improve a service's security?**
Run as a non-root or dynamic user, `NoNewPrivileges`, `ProtectSystem=strict` with minimal `ReadWritePaths`, `ProtectHome`, `PrivateTmp`, drop capabilities, restrict syscalls and address families, limit IPs and resources. Verify with `systemd-analyze security`.

**8. 🔐 Where would an attacker hide persistence in systemd, and how would you find it?**
New `.service` or `.timer` units in `/etc/systemd/system/` or `~/.config/systemd/user/`, overrides in `*.d/` directories, or modified `ExecStart` scripts. Find them with `systemctl list-unit-files`, `list-timers --all`, recent-file searches, and package integrity checks (`dpkg --verify`).

---

## Summary

- systemd (PID 1) manages services, timers, logs and resources through units.
- `systemctl` controls units; `journalctl -u` shows their logs.
- Custom units go in `/etc/systemd/system/`; overrides via `systemctl edit`.
- Timers replace cron with logging and catch-up.
- A few sandbox directives drastically reduce a service's blast radius — measure with `systemd-analyze security`.

**Next:** [08 — Package Management](08-Package-Management.md)

---

## References

- `man systemctl`, `man systemd.service`, `man systemd.unit`, `man systemd.exec`, `man systemd.timer`, `man systemd.time`
- systemd documentation — https://systemd.io/
- systemd sandboxing directives — `man systemd.exec` (sections SANDBOXING, SECURITY)
