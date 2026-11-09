# 04 — Users, Groups & Permissions

> **Module:** 01 – Linux · **Level:** 🟢 Basic → 🔴 Advanced · **Time:** ~3 hours
> **Lab environment:** WSL2 or VM (Docker works, but you're root there) — see [labs/README.md](../labs/README.md)

---

## Objectives

After this chapter you will be able to:

- Explain users, groups, UIDs and GIDs, and read `/etc/passwd`, `/etc/shadow`, `/etc/group`.
- Create, modify, lock and delete users and groups.
- Configure `sudo` safely.
- Read and set permissions in symbolic and numeric form — on files **and** directories.
- Explain `umask`, SUID, SGID, sticky bit, ACLs, capabilities and immutable files.
- Audit a system for dangerous permissions and privilege-escalation paths.

---

## Why This Matters

Linux is a **multi-user** system. Every process runs **as a user**, and every file is **owned by a user and a group**. The kernel checks these on every file access.

Most Linux privilege-escalation attacks come down to a permission mistake: a writable script run by root, a SUID binary, a loose `sudo` rule, a readable private key.

---

## Users

```bash
whoami                 # your username
id                     # uid, gid, groups
id bob                 # another user
who                    # who is logged in
w                      # who is logged in and what they're doing
last | head            # login history
```

### Types of accounts

| Type | UID range (Debian/Ubuntu) | Example | Can log in? |
|---|---|---|---|
| root | `0` | `root` | Yes (but SSH login should be disabled) |
| System / service | `1–999` | `www-data`, `sshd`, `systemd-network` | No — shell is `/usr/sbin/nologin` |
| Normal (human) | `1000+` | `amar` | Yes |
| nobody | `65534` | `nobody` | No — owns nothing, used for least privilege |

The kernel only cares about the **number**. A user named `admin` with UID 0 *is* root.

### `/etc/passwd` — account list (world-readable)

```text
amar:x:1000:1000:Amar,,,:/home/amar:/bin/bash
 │   │  │    │     │         │          │
 │   │  │    │     │         │          └── login shell
 │   │  │    │     │         └── home directory
 │   │  │    │     └── comment (GECOS: full name)
 │   │  │    └── primary GID
 │   │  └── UID
 │   └── 'x' = password is in /etc/shadow
 └── username
```

### `/etc/shadow` — password hashes (protected)

```text
amar:$y$j9T$Yl...$Kd...:20400:0:99999:7:::
 │    │                  │    │   │   │
 │    │                  │    │   │   └── warn days before expiry
 │    │                  │    │   └── max days between changes
 │    │                  │    └── min days between changes
 │    │                  └── last change (days since 1970-01-01)
 │    └── hash: $y$ = yescrypt (Ubuntu 22.04+), $6$ = SHA-512, '!' or '*' = locked/no password
 └── username
```

Permissions: `-rw-r----- root shadow` (640) on Debian/Ubuntu; `----------` (000) on RHEL. Only root (and the `shadow` group) can read it.

### `/etc/group`

```text
sudo:x:27:amar,bob
 │   │ │   └── members (secondary)
 │   │ └── GID
 │   └── group password (unused)
 └── group name
```

---

## Groups

- **Primary group**: assigned to files you create. Usually a private group with your name (`amar:amar`).
- **Secondary groups**: extra memberships that grant access (`sudo`, `docker`, `adm`).

```bash
groups               # your groups
getent group sudo    # members of sudo (works with LDAP too)
```

Important groups on Ubuntu:

| Group | Grants | Risk |
|---|---|---|
| `sudo` (`wheel` on RHEL) | Run any command as root via `sudo` | Equivalent to root |
| `adm` | Read most logs in `/var/log` | Sees sensitive info |
| `docker` | Talk to the Docker daemon | **Equivalent to root** (can mount `/` into a container) |
| `lxd` | Manage LXD containers | Equivalent to root |
| `shadow` | Read `/etc/shadow` | Can crack all passwords |

---

## Managing Users and Groups ⚠️

```bash
# Create
sudo adduser bob                          # interactive, creates home, Debian/Ubuntu
sudo useradd -m -s /bin/bash -c "Bob" bob # low-level, scriptable, any distro
sudo passwd bob                           # set password

# Modify
sudo usermod -aG sudo bob                 # add to group (-a = append — without it, other groups are REMOVED)
sudo gpasswd -d bob sudo                  # remove from a group
sudo usermod -s /usr/sbin/nologin bob     # disable shell login
sudo usermod -L bob                       # lock password  (-U unlocks)
sudo usermod -e 2026-12-31 bob            # account expires on a date
sudo chage -l bob                         # password aging info
sudo chage -M 90 -W 7 bob                 # max 90 days, warn 7 days before

# Groups
sudo groupadd devs
sudo usermod -aG devs bob
newgrp devs                               # use new group without logging out

# Delete
sudo deluser --remove-home bob            # Debian/Ubuntu
sudo userdel -r bob                       # any distro

# Service account for an app (no login, no home)
sudo useradd --system --no-create-home --shell /usr/sbin/nologin myapp
```

Group changes take effect at the **next login** — run `newgrp` or log out and in.

---

## sudo

`sudo` lets permitted users run commands as root (or another user), and **logs** every use.

```bash
sudo -l                    # what am I allowed to run?
sudo -i                    # root login shell (use sparingly)
sudo -u www-data whoami    # run as another user
sudo visudo                # edit /etc/sudoers safely (syntax check before saving)
sudo visudo -f /etc/sudoers.d/deploy    # better: separate drop-in file
```

### sudoers syntax

```text
 user/%group   HOST = (RUN_AS)   [NOPASSWD:] COMMANDS
 amar          ALL  = (ALL:ALL)  ALL                     ← full root
 %sudo         ALL  = (ALL:ALL)  ALL                     ← anyone in sudo group
 deploy        ALL  = (root)     NOPASSWD: /usr/bin/systemctl restart myapp
```

The last line is **least privilege**: `deploy` can restart one service and nothing else.

> 🔐 **Dangerous sudo rules.** Allowing any of these effectively grants full root, because they can spawn a shell or write any file: `vim`, `less`, `find`, `awk`, `python`, `tar`, `cp`, `tee`, `bash`, `env`, wildcards like `/usr/bin/*`, or editable scripts. See [GTFOBins](https://gtfobins.github.io/) for hundreds of examples.
>
> Example: `sudo find . -exec /bin/sh \; -quit` → root shell.

---

## Permissions

### Reading `ls -l`

```text
-rwxr-x---  1  amar  devs  4096  Nov 9 10:00  deploy.sh
│└┬┘└┬┘└┬┘     │     │
│ │  │  │      │     └── group owner
│ │  │  │      └── user owner
│ │  │  └── others:  ---  no access
│ │  └── group:  r-x  read + execute
│ └── user:  rwx  read + write + execute
└── type: - file, d directory, l link
```

### What r, w, x mean — files vs directories

| | On a **file** | On a **directory** |
|---|---|---|
| `r` (4) | Read contents | List names (`ls`) |
| `w` (2) | Modify contents | Create, delete, rename entries inside (**even files you don't own!**) |
| `x` (1) | Run as a program | Enter it (`cd`) and access files inside by name |

Key consequences:

- Deleting a file needs `w` on the **directory**, not on the file.
- A directory with `x` but no `r` lets you open files if you know their names, but not list them.
- To read `/home/amar/notes.txt`, you need `x` on `/`, `/home`, `/home/amar` **and** `r` on the file.

### Numeric (octal) notation

```text
 r=4  w=2  x=1        user  group  others
                       rwx   r-x    ---
                       4+2+1 4+0+1  0+0+0
                        7     5      0    →  chmod 750
```

| Mode | Symbolic | Typical use |
|---|---|---|
| `755` | `rwxr-xr-x` | Programs, scripts, public directories |
| `750` | `rwxr-x---` | Directory shared with a group only |
| `700` | `rwx------` | `~/.ssh`, private directories |
| `644` | `rw-r--r--` | Normal files, public configs |
| `640` | `rw-r-----` | Configs with secrets readable by an app group |
| `600` | `rw-------` | Private keys, `authorized_keys`, secret files |
| `440` | `r--r-----` | `/etc/sudoers` |
| `777` | `rwxrwxrwx` | ❌ Almost never correct |

### chmod, chown, chgrp

```bash
chmod 640 app.conf                 # numeric
chmod u+x script.sh                # symbolic: add execute for user
chmod go-w file                    # remove write from group and others
chmod u=rw,g=r,o= file             # set exactly (= 640)
chmod -R g+rX shared/              # capital X: execute only on directories (and already-executable files)
sudo chown bob file                # change owner
sudo chown bob:devs file           # owner and group
sudo chown -R www-data:www-data /var/www/site
sudo chgrp devs file               # group only
stat -c '%a %U:%G %n' file         # show octal mode and owners
```

> Avoid `chmod -R 755` on a tree of files: it makes every file executable. Use `find` instead:
> ```bash
> find site/ -type d -exec chmod 755 {} +
> find site/ -type f -exec chmod 644 {} +
> ```

### umask — default permissions 🟡

New files start at `666`, new directories at `777`, and the **umask** removes bits.

```text
 umask 022:   files 666 - 022 = 644 (rw-r--r--)    dirs 777 - 022 = 755
 umask 027:   files 666 - 027 = 640 (rw-r-----)    dirs 777 - 027 = 750
 umask 077:   files 600 (rw-------)                 dirs 700
```

```bash
umask              # e.g. 0002 (Ubuntu users) or 0022
umask -S           # symbolic: u=rwx,g=rwx,o=rx
umask 027          # stricter for this shell session
```

Services can set their own: `UMask=0027` in a systemd unit.

---

## Special Permissions 🔴

| Bit | Octal | On a file | On a directory | Shown as |
|---|:-:|---|---|---|
| **SUID** | `4000` | Runs as the **file's owner** (often root) | — (ignored) | `s` in user x: `-rwsr-xr-x` |
| **SGID** | `2000` | Runs with the file's **group** | New files inherit the **directory's group** | `s` in group x: `drwxrwsr-x` |
| **Sticky** | `1000` | — | Only the file's owner (or root) can delete/rename it | `t` in others x: `drwxrwxrwt` |

A capital `S` or `T` means the special bit is set but the underlying `x` is not.

```bash
ls -l /usr/bin/passwd          # -rwsr-xr-x root  → SUID: lets users change their own shadow entry
ls -ld /tmp                    # drwxrwxrwt       → sticky
chmod u+s file  / chmod 4755 file    # set SUID ⚠️
chmod g+s dir   / chmod 2775 dir     # set SGID on a shared folder
chmod +t dir    / chmod 1777 dir     # set sticky
```

> 🔐 **SUID root binaries are prime privilege-escalation targets.** If a SUID-root program can run commands, read arbitrary files, or has a bug, any user can become root. Know your baseline and investigate anything new:
> ```bash
> find / -xdev -perm -4000 -type f 2>/dev/null
> ```

### Shared team folder with SGID

```bash
sudo groupadd devs
sudo mkdir /srv/project
sudo chown root:devs /srv/project
sudo chmod 2770 /srv/project      # rwxrws---: group members can work, files get group 'devs'
```

---

## ACLs — Per-User Exceptions 🔴

Normal permissions allow one owner and one group. **Access Control Lists** add more.

```bash
setfacl -m u:bob:r report.txt        # give bob read access
setfacl -m g:auditors:rx /var/log/app
setfacl -d -m g:devs:rwx /srv/project   # default ACL: inherited by new files
getfacl report.txt                    # show ACLs
setfacl -x u:bob report.txt           # remove bob's entry
setfacl -b report.txt                 # remove all ACLs
```

A `+` at the end of the mode in `ls -l` (`-rw-r-----+`) means ACLs are present. Easy to miss during audits.

---

## Capabilities — Splitting Root 🔴

Instead of all-or-nothing root, Linux divides root's powers into ~40 **capabilities**.

| Capability | Allows |
|---|---|
| `CAP_NET_BIND_SERVICE` | Bind to ports < 1024 |
| `CAP_NET_RAW` | Raw sockets (`ping`, packet sniffing) |
| `CAP_NET_ADMIN` | Change network config, firewall |
| `CAP_SYS_ADMIN` | Huge set (mount, etc.) — "the new root" |
| `CAP_DAC_OVERRIDE` | Ignore file permissions |
| `CAP_SETUID` | Change UID — instant root |

```bash
getcap -r / 2>/dev/null                        # binaries with file capabilities
sudo setcap cap_net_bind_service=+ep ./webapp  # let a non-root app use port 80
grep Cap /proc/$$/status                        # capabilities of your shell (hex)
capsh --decode=000001ffffffffff                 # decode the hex
```

> 🔐 `cap_setuid` or `cap_dac_override` on an interpreter like `python3` = root for everyone. Containers drop most capabilities by default; `--privileged` gives them all back.

---

## Immutable and Append-Only Files 🔴

```bash
sudo chattr +i /etc/resolv.conf     # immutable: even root can't modify or delete it
sudo chattr +a /var/log/app.log     # append-only: can add lines, not change or delete
lsattr /etc/resolv.conf             # show attributes
sudo chattr -i /etc/resolv.conf     # remove
```

Used to protect critical configs and logs. Attackers sometimes use `+i` to stop admins removing their backdoor — check `lsattr` when a file "can't be deleted even as root".

---

## In Production

```text
 nginx (runs as www-data)
   ├── reads    /etc/nginx/*         root:root 644      ← www-data can read, not change config
   ├── serves   /var/www/site        root:www-data 750  ← read-only for the app
   ├── writes   /var/www/site/uploads www-data 750      ← only place it can write
   └── TLS key  /etc/ssl/private/site.key  root:ssl-cert 640
```

Principles:

1. Apps run as a dedicated, non-login, non-root user.
2. The app **cannot write** to its own code or config — so a compromised app can't plant a backdoor that survives restart.
3. Writable directories are explicit and minimal (uploads, cache).
4. Secrets readable only by the user/group that needs them.

---

## Product Security Perspective — Audit Checklist

```bash
# 1. Accounts with UID 0 (should be only root)
awk -F: '$3 == 0 {print $1}' /etc/passwd

# 2. Accounts with empty passwords
sudo awk -F: '$2 == "" {print $1}' /etc/shadow

# 3. Who has sudo, and any NOPASSWD rules
getent group sudo wheel
sudo grep -rE 'NOPASSWD|ALL' /etc/sudoers /etc/sudoers.d/ 2>/dev/null | grep -v '^#'

# 4. Members of root-equivalent groups
getent group docker lxd

# 5. SUID / SGID binaries
find / -xdev \( -perm -4000 -o -perm -2000 \) -type f -exec ls -l {} + 2>/dev/null

# 6. File capabilities
getcap -r / 2>/dev/null

# 7. World-writable files and directories without sticky bit
find / -xdev -type f -perm -0002 2>/dev/null
find / -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null

# 8. Sensitive file permissions
ls -l /etc/passwd /etc/shadow /etc/group /etc/sudoers
ls -la ~/.ssh

# 9. Files with no owner
find / -xdev \( -nouser -o -nogroup \) 2>/dev/null
```

Automated version: [`labs/linux/scripts/linux-security-audit.sh`](../labs/linux/scripts/linux-security-audit.sh).

---

## Hands-on Lab ⚠️ (VM or WSL)

### Part 1 — Users and groups 🟢

```bash
sudo adduser --gecos "" alice          # set a password when asked
sudo adduser --gecos "" bob
sudo groupadd devs
sudo usermod -aG devs alice
id alice; id bob
grep -E '^(alice|bob)' /etc/passwd
sudo grep -E '^(alice|bob)' /etc/shadow   # note the hash type
```

### Part 2 — File vs directory permissions 🟡

```bash
sudo mkdir -p /srv/lab && sudo chown alice:devs /srv/lab && sudo chmod 770 /srv/lab
sudo -u alice touch /srv/lab/alice.txt
sudo -u bob ls /srv/lab                 # Permission denied — bob is not in devs
sudo usermod -aG devs bob
sudo -u bob ls /srv/lab                 # works (sudo -u starts a fresh session)
sudo -u bob rm /srv/lab/alice.txt       # works! w on the DIRECTORY allows deleting
```

Now protect files with the sticky bit:

```bash
sudo -u alice touch /srv/lab/alice2.txt
sudo chmod 1770 /srv/lab
sudo -u bob rm /srv/lab/alice2.txt      # Operation not permitted
```

### Part 3 — SGID shared folder 🟡

```bash
sudo chmod 2770 /srv/lab
sudo -u bob touch /srv/lab/bob.txt
ls -l /srv/lab                          # group is 'devs', not 'bob'
```

### Part 4 — umask 🟡

```bash
cd ~/labs && umask
touch a.txt && mkdir a.dir && ls -ld a.txt a.dir
umask 077
touch b.txt && mkdir b.dir && ls -ld b.txt b.dir
umask 0002     # restore Ubuntu default
```

### Part 5 — Privilege escalation via sudo (understand the risk) 🔴

```bash
echo 'bob ALL=(root) NOPASSWD: /usr/bin/find' | sudo tee /etc/sudoers.d/lab-bob
sudo chmod 440 /etc/sudoers.d/lab-bob
sudo -u bob sudo -l
sudo -u bob sudo find /etc/hostname -exec whoami \;     # prints: root
sudo rm /etc/sudoers.d/lab-bob                          # clean up!
```

Lesson: "only `find`" was actually "everything".

### Part 6 — SUID and capabilities 🔴

```bash
find / -xdev -perm -4000 -type f 2>/dev/null | tee ~/labs/suid-baseline.txt
getcap -r / 2>/dev/null
```

Save the baseline. In chapter 12 you'll compare against it.

### Part 7 — ACLs and immutable files 🔴

```bash
sudo apt install -y acl
echo "secret" > ~/labs/report.txt && chmod 600 ~/labs/report.txt
setfacl -m u:bob:r ~/labs/report.txt
chmod o+x ~ ~/labs     # bob needs x on the path
getfacl ~/labs/report.txt; ls -l ~/labs/report.txt   # note the '+'
sudo -u bob cat ~/labs/report.txt
setfacl -b ~/labs/report.txt; chmod o-x ~ ~/labs

sudo chattr +i ~/labs/report.txt
sudo rm ~/labs/report.txt            # fails, even as root
lsattr ~/labs/report.txt
sudo chattr -i ~/labs/report.txt
```

### Clean up

```bash
sudo deluser --remove-home alice; sudo deluser --remove-home bob
sudo groupdel devs; sudo rm -rf /srv/lab
```

**Questions**

1. Why could bob delete alice's file in Part 2 without owning it?
2. What did the sticky bit change?
3. Why is `NOPASSWD: /usr/bin/find` as dangerous as `NOPASSWD: ALL`?
4. How would you spot an ACL during an audit?

---

## Common Mistakes

- `chmod 777` "to make it work" — fix ownership instead.
- `usermod -G` without `-a` — silently removes the user from all other groups (including `sudo`).
- Editing `/etc/sudoers` directly instead of with `visudo` — a typo can lock everyone out of sudo.
- Adding developers to the `docker` group without realising it equals root.
- Running applications as root "temporarily".
- `chmod -R 755` on files — makes every file executable.
- Forgetting directory permissions: a `600` file in a world-writable directory can still be deleted and replaced.
- SSH keys with loose permissions — `ssh` refuses to use a private key readable by others.

---

## Interview Questions

**1. What's the difference between `/etc/passwd` and `/etc/shadow`?**
`/etc/passwd` holds account info and is world-readable. `/etc/shadow` holds password hashes and aging data and is readable only by root (and the `shadow` group on Debian/Ubuntu).

**2. Explain `chmod 750`.**
Owner rwx (7), group r-x (5), others nothing (0).

**3. What does `x` mean on a directory?**
Permission to enter it and access entries by name. Without it you can't `cd` in or open files inside, even if they're readable.

**4. Can a user delete a file they don't own?**
Yes, if they have `w` and `x` on the directory — unless the directory has the sticky bit.

**5. What are SUID, SGID and the sticky bit?**
SUID: an executable runs as its owner. SGID: runs as its group; on directories, new files inherit the directory's group. Sticky bit: on directories, only a file's owner can delete it (e.g. `/tmp`).

**6. What is umask? What does `027` produce?**
A mask removing permission bits from new files/dirs. `027` → files `640`, directories `750`.

**7. Why is membership in the `docker` group dangerous?**
The Docker daemon runs as root; a member can run `docker run -v /:/host -it ubuntu chroot /host` and get a root shell on the host.

**8. 🔐 How would you look for privilege-escalation paths on a Linux host?**
Check `sudo -l`, SUID/SGID binaries, file capabilities, writable files run by root (cron jobs, systemd units, scripts in PATH), root-equivalent groups, world-writable directories in root's PATH, credentials in readable files, and kernel version for known exploits. Tools like `linpeas` automate this.

**9. 🔐 What are Linux capabilities and why do they matter for containers?**
They split root's privileges into units. Containers run with a reduced set; adding capabilities such as `CAP_SYS_ADMIN` or running `--privileged` greatly increases escape risk.

**10. 🔐 A file can't be deleted even by root. Why?**
It's probably immutable (`chattr +i`) — check with `lsattr`. Other causes: a read-only mount, or the file is on an immutable layer (e.g. container image).

---

## Summary

- Users and groups are numbers (UID/GID); root is UID 0.
- Permissions: `r w x` for user, group and others — different meaning on directories.
- `sudo` should grant the minimum; many "harmless" commands give a root shell.
- SUID, capabilities, ACLs and root-equivalent groups are where privilege escalation hides.
- Least privilege: apps run as non-root and can't write to their own code or config.

**Next:** [05 — Processes](05-Processes.md)

---

## References

- `man 5 passwd`, `man 5 shadow`, `man chmod`, `man sudoers`, `man 7 capabilities`, `man acl`, `man chattr`
- GTFOBins — https://gtfobins.github.io/
- CIS Benchmarks (Ubuntu Linux) — https://www.cisecurity.org/benchmark/ubuntu_linux
