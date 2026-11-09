# 🐧 Linux Cheat Sheet — Basic to Advanced

> Quick reference for [Module 01 — Linux](../01-Linux/README.md). Ubuntu/Debian focused; most commands work on any distro.
> `$` = normal user · `#` = needs root (prefix with `sudo`) · `<x>` = your value · Help: `man <cmd>`, `<cmd> --help`, `tldr <cmd>`

---

## 🟢 Navigation & Files

| Command | Does |
|---|---|
| `pwd` | Current directory |
| `ls -la` / `ls -lh` / `ls -ltr` | All files / human sizes / newest last |
| `cd /path` · `cd ..` · `cd ~` · `cd -` | Absolute · up · home · previous |
| `tree -L 2` | Tree view, 2 levels |
| `mkdir -p a/b/c` | Create nested dirs |
| `touch f` | Create empty file / update time |
| `cp -a src/ dst/` | Copy, keep perms/owners/times |
| `mv old new` | Move / rename |
| `rm -i f` · `rm -r dir` | Delete (ask) · delete dir ⚠️ no undo |
| `ln -s target link` | Symbolic link |
| `stat f` · `file f` | Metadata · real file type |

## 🟢 Viewing

| Command | Does |
|---|---|
| `cat f` · `less f` | Print · scroll (`/word`, `n`, `G`, `q`) |
| `head -n 20 f` · `tail -n 50 f` | First / last lines |
| `tail -f /var/log/syslog` | Follow live |
| `wc -l f` | Count lines |
| `diff -u a b` | Differences |

## 🟢 Shell Shortcuts

`Tab` complete · `Ctrl+R` search history · `Ctrl+C` stop · `Ctrl+Z` pause (`fg`/`bg`) · `Ctrl+L` clear · `Ctrl+A`/`E` line start/end · `!!` last command · `sudo !!` · `!$` last argument

---

## 🟡 Redirection & Pipes

| Syntax | Does |
|---|---|
| `cmd > f` / `>> f` | Overwrite / append stdout |
| `cmd 2> f` · `cmd 2>/dev/null` | Errors to file · discard errors |
| `cmd > f 2>&1` | Both to file |
| `a \| b` | Output of a → input of b |
| `cmd \| tee f` | Screen and file |
| `echo x \| sudo tee -a /etc/f` | Append to a root-owned file |

## 🟡 Search

```bash
find / -name "*.conf" 2>/dev/null        # by name
find /var -size +100M                    # by size
find . -mtime -1                         # modified < 24h
find /tmp -mtime +7 -delete              # ⚠️ delete old files
find . -name "*.sh" -exec chmod +x {} +  # act on results
grep -rn "text" /path                    # recursive with line numbers
grep -i / -v / -c / -w / -E "a|b"        # ignore case / invert / count / word / regex
grep -A3 -B3 "panic" app.log             # context lines
```

## 🟡 Text Processing

```bash
cut -d: -f1 /etc/passwd                          # field 1
sort | uniq -c | sort -rn | head                 # top N pattern
awk '{print $1}' f                               # column 1
awk -F: '$3 >= 1000 {print $1}' /etc/passwd      # filter rows
awk '{s+=$1} END {print s}' f                    # sum
sed 's/old/new/g' f                              # replace (print)
sed -i.bak 's/old/new/g' f                       # in place + backup
sed -n '10,20p' f                                # lines 10-20
grep -Ev '^\s*(#|$)' f                           # hide comments/blank lines
xargs -0 / -I{}                                  # output → arguments
```

## 🟡 Archives

```bash
tar -czvf a.tar.gz dir/     # create
tar -tzvf a.tar.gz          # list (always check untrusted archives)
tar -xzvf a.tar.gz -C /tmp  # extract
zip -r a.zip dir/ ; unzip a.zip
```

---

## 🟡 Users, Groups, Permissions

```bash
whoami ; id ; groups ; who ; w ; last
# adduser bob ; passwd bob ; usermod -aG sudo bob     # -a or you REMOVE other groups
# usermod -L bob ; deluser --remove-home bob
# useradd --system --no-create-home -s /usr/sbin/nologin myapp
sudo -l ; # visudo -f /etc/sudoers.d/<file>
```

| Mode | Symbolic | Use |
|---|---|---|
| 755 | `rwxr-xr-x` | Scripts, dirs |
| 644 | `rw-r--r--` | Files |
| 640 | `rw-r-----` | Configs with secrets |
| 600 | `rw-------` | Private keys |
| 700 | `rwx------` | `~/.ssh` |

```bash
chmod 640 f ; chmod u+x f ; chmod -R g+rX dir
# chown user:group f ; chown -R www-data: /var/www
umask                               # 022 → 644/755, 027 → 640/750
chmod 4755 f / 2775 dir / 1777 dir  # SUID / SGID / sticky
setfacl -m u:bob:r f ; getfacl f    # ACLs
getcap -r / 2>/dev/null             # capabilities
# chattr +i f ; lsattr f            # immutable
```

## 🟡 Processes

```bash
ps aux ; ps -ef --forest ; pstree -p ; pgrep -a nginx
ps -eo pid,user,%cpu,%mem,cmd --sort=-%cpu | head
top (P cpu, M mem, k kill) ; htop
kill PID (TERM) → kill -9 PID (KILL, last resort) ; pkill -f pattern
cmd & ; jobs ; fg %1 ; bg ; nohup cmd > out.log 2>&1 &
nice -n 10 cmd ; # renice -n 5 -p PID
ls -l /proc/PID/exe ; tr '\0' ' ' < /proc/PID/cmdline
# lsof -p PID ; # lsof -i :80 ; # lsof +L1 ; strace -p PID
uptime ; free -h ; vmstat 1 5
```

## 🟡 Networking

```bash
ip -br a ; ip r ; ip route get 1.1.1.1 ; ip neigh
ping -c4 host ; tracepath host ; mtr host
dig +short name ; dig @1.1.1.1 name MX ; getent hosts name ; resolvectl status
# ss -tulpn                              # listening ports + process
ss -tn state established
nc -zv host 443                          # port open?
curl -I https://site ; curl -v url ; curl -sS -L url
openssl s_client -connect host:443 -servername host </dev/null | openssl x509 -noout -dates -issuer
# tcpdump -i any -n port 53 ; # tcpdump -i any -w cap.pcap
```

## 🟡 Packages (apt)

```bash
# apt update ; # apt upgrade ; # apt full-upgrade
# apt install pkg ; # apt remove pkg ; # apt purge pkg ; # apt autoremove
apt search x ; apt show x ; apt-cache policy x ; apt list --upgradable
dpkg -l | grep x ; dpkg -L pkg ; dpkg -S /path/file
# apt-mark hold pkg ; apt-mark showhold
# dpkg --verify ; # debsums -s                # changed files
```

| apt (Debian/Ubuntu) | dnf (RHEL/Fedora) |
|---|---|
| `apt install` | `dnf install` |
| `dpkg -S file` | `rpm -qf file` |
| `dpkg -L pkg` | `rpm -ql pkg` |

---

## 🔴 systemd

```bash
systemctl status svc ; # systemctl start|stop|restart|reload svc
# systemctl enable --now svc ; # systemctl disable --now svc ; # systemctl mask svc
systemctl --failed ; systemctl list-units --type=service --state=running
systemctl cat svc ; # systemctl edit svc ; # systemctl daemon-reload
systemctl list-timers ; systemd-analyze blame ; systemd-analyze security svc
```

Minimal unit (`/etc/systemd/system/myapp.service`):

```ini
[Unit]
Description=My App
After=network-online.target
[Service]
User=myapp
ExecStart=/opt/myapp/run
Restart=on-failure
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
[Install]
WantedBy=multi-user.target
```

## 🔴 Logs

```bash
journalctl -u svc -b ; journalctl -f ; journalctl -p err -b
journalctl --since "1 hour ago" ; journalctl -k ; journalctl -t tag
journalctl --disk-usage ; # journalctl --vacuum-time=14d
sudo tail -f /var/log/auth.log           # RHEL: /var/log/secure
last ; sudo lastb ; lastlog
logger -t myscript "message"
# logrotate -d /etc/logrotate.d/x        # dry run
# auditctl -w /etc/passwd -p wa -k identity ; # ausearch -k identity -i
```

Failed SSH logins by IP:

```bash
sudo grep -h "Failed password" /var/log/auth.log* | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn | head
```

## 🔴 Storage

```bash
df -hT ; df -ih ; du -sh dir ; du -xh --max-depth=1 / | sort -h ; ncdu /
lsblk -f ; # blkid ; findmnt ; # fdisk -l
# parted /dev/sdb --script mklabel gpt mkpart primary ext4 0% 100%
# mkfs.ext4 /dev/sdb1 ; # mount /dev/sdb1 /data ; # umount /data
# findmnt --verify ; # mount -a                 # test fstab before reboot!
# pvcreate /dev/sdb ; # vgcreate vg /dev/sdb ; # lvcreate -n lv -L 10G vg
# lvextend -r -L +5G /dev/vg/lv                 # grow volume + filesystem
# cryptsetup luksFormat /dev/sdb1 ; # cryptsetup open /dev/sdb1 secure
swapon --show ; free -h
```

## 🔴 Scheduling

```text
┌ min ┬ hour ┬ day ┬ month ┬ weekday
  0     2      *     *       *      /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1
  */15  *      *     *       *      every 15 minutes
  @reboot                           at boot
```

`crontab -e` · `crontab -l` · `ls /etc/cron.d` · `systemctl list-timers`

## 🔴 Shell Scripting

```bash
#!/usr/bin/env bash
set -euo pipefail
trap 'rm -rf -- "$tmp"' EXIT
tmp=$(mktemp -d)
for f in ./*.log; do echo "$f"; done
while IFS= read -r line; do echo "$line"; done < file
[[ -f "$file" ]] && echo exists
name=${1:?usage: $0 <name>}
```

Always quote `"$var"` · use `--` before user-supplied filenames · never `eval` input · `shellcheck script.sh`

---

## 🔐 Security Hardening

```bash
# Updates
# apt install unattended-upgrades && dpkg-reconfigure -plow unattended-upgrades

# SSH (/etc/ssh/sshd_config.d/10-hardening.conf) → sshd -t → systemctl reload ssh
PermitRootLogin no
PasswordAuthentication no
MaxAuthTries 3
AllowGroups ssh-users
X11Forwarding no

# Firewall
# ufw default deny incoming ; # ufw allow OpenSSH ; # ufw limit OpenSSH ; # ufw enable

# Brute force
# apt install fail2ban ; # fail2ban-client status sshd

# Audit
# apt install lynis && lynis audit system
sudo bash labs/linux/scripts/linux-security-audit.sh
```

### Audit one-liners

```bash
awk -F: '$3==0' /etc/passwd                                  # UID 0 accounts
sudo awk -F: '$2==""' /etc/shadow                             # empty passwords
getent group sudo docker lxd                                  # privileged groups
find / -xdev -perm -4000 -type f 2>/dev/null                  # SUID
find / -xdev -type f -perm -0002 2>/dev/null                  # world-writable files
sudo ss -tulpn                                                # exposed ports
sudo find /etc -type f -mtime -1                              # changed in /etc today
ls -l /proc/*/exe 2>/dev/null | grep -E 'deleted|/tmp|/dev/shm'   # suspicious processes
for u in $(cut -d: -f1 /etc/passwd); do sudo crontab -u "$u" -l 2>/dev/null; done   # all crontabs
sudo find / -name authorized_keys 2>/dev/null                 # SSH keys
```

## 🔴 Troubleshooting in 60 Seconds

```bash
uptime ; dmesg -T | tail ; vmstat 1 5 ; free -h ; df -h
top ; iostat -xz 1 ; ss -s ; systemctl --failed ; journalctl -p err -b
```

## 🔴 Handy One-Liners

```bash
ps aux --sort=-%mem | head -11                                   # top memory
sudo find /var -type f -size +100M -exec ls -lh {} + 2>/dev/null # big files
cp /etc/nginx/nginx.conf{,.bak.$(date +%F)}                      # dated backup
df -h --output=pcent,target | awk 'NR>1 && $1+0>80'              # disks > 80%
python3 -m http.server 8000 --bind 127.0.0.1                     # quick local web server
openssl rand -base64 24                                          # random password
```
