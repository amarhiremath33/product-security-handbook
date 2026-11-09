# 02 — Linux Filesystem

> **Module:** 01 – Linux · **Level:** 🟢 Basic → 🟡 Intermediate · **Time:** ~2 hours
> **Lab environment:** WSL2, Docker or VM — see [labs/README.md](../labs/README.md)

---

## Objectives

After this chapter you will be able to:

- Navigate the Linux directory tree and explain what each top-level directory is for.
- Find where any application keeps its binary, config, data and logs.
- Explain the seven Linux file types.
- Explain inodes, hard links and symbolic links.
- Use `/proc` to look inside running processes.
- Identify security-sensitive files and directories.

---

## One Tree, Starting at `/`

Linux has no drive letters. Everything — disks, USB sticks, network shares, even kernel information — appears somewhere under the **root directory** `/`. Extra disks are **mounted** onto a directory in the tree.

```text
/
├── bin  → usr/bin      User commands (symlink on modern distros)
├── boot                Kernel, initramfs, GRUB
├── dev                 Device files (disks, terminals, /dev/null)
├── etc                 System-wide configuration (text files)
├── home                Users' home directories
│   └── amar
├── lib  → usr/lib      Shared libraries (symlink on modern distros)
├── media               Auto-mounted removable media (USB, DVD)
├── mnt                 Temporary manual mounts
├── opt                 Third-party software installed as one bundle
├── proc                Virtual: processes and kernel info
├── root                Home directory of the root user
├── run                 Runtime data (PID files, sockets) — cleared at boot
├── sbin → usr/sbin     Admin commands (symlink on modern distros)
├── srv                 Data served by this system (web, FTP)
├── sys                 Virtual: devices and kernel settings
├── tmp                 Temporary files — world-writable, often cleared at boot
├── usr                 Installed software (read-only in principle)
│   ├── bin  sbin  lib  share
│   └── local           Software you compiled/installed yourself
└── var                 Variable data that grows
    ├── log             Logs
    ├── lib             Application state (databases, package DB)
    ├── cache           Caches (safe to delete)
    ├── spool           Queues (mail, print, cron)
    └── www             Websites (Debian/Ubuntu convention)
```

This layout follows the **Filesystem Hierarchy Standard (FHS)**. See it on your system with `man hier`.

> **Modern distros ("usrmerge"):** on Ubuntu 20.04+, Debian 12+, Fedora and RHEL 9, `/bin`, `/sbin` and `/lib` are just symlinks to `/usr/bin`, `/usr/sbin` and `/usr/lib`. Check with `ls -l /bin`.

---

## Key Directories in Detail

### `/etc` — configuration

Plain text files that control the system. Back up before editing anything here.

| File / folder | Purpose |
|---|---|
| `/etc/passwd` | User accounts (no passwords despite the name) |
| `/etc/shadow` | Password hashes — root and `shadow` group only |
| `/etc/group` | Groups and their members |
| `/etc/sudoers`, `/etc/sudoers.d/` | Who can use `sudo` |
| `/etc/hosts` | Local hostname → IP overrides |
| `/etc/resolv.conf` | DNS servers |
| `/etc/fstab` | Filesystems mounted at boot |
| `/etc/ssh/sshd_config` | SSH server settings |
| `/etc/systemd/system/` | Your custom/overridden service units |
| `/etc/cron.d/`, `/etc/crontab` | Scheduled jobs |
| `/etc/os-release` | Distribution name and version |

### `/var` — data that changes

| Path | Purpose |
|---|---|
| `/var/log/` | Logs: `syslog`, `auth.log`, `kern.log`, app folders like `nginx/` |
| `/var/lib/` | Persistent app state: `/var/lib/mysql`, `/var/lib/docker`, `/var/lib/dpkg` |
| `/var/cache/` | Caches, e.g. downloaded packages in `/var/cache/apt/archives` |
| `/var/spool/` | Queues: `cron`, mail |
| `/var/tmp/` | Temporary files that **survive** reboot |

A full `/var` is one of the most common production outages — logs or Docker images fill the disk.

### `/usr` — installed software

| Path | Contents |
|---|---|
| `/usr/bin` | Most user commands (`ls`, `python3`, `curl`) |
| `/usr/sbin` | Admin commands (`useradd`, `sshd`, `nginx`) |
| `/usr/lib` | Libraries, and systemd unit files from packages (`/usr/lib/systemd/system`) |
| `/usr/share` | Docs, man pages, icons |
| `/usr/local` | Software **you** installed manually — package manager doesn't touch it |

### `/home` and `/root`

- `/home/<user>` — each normal user's files and personal config ("dotfiles" like `~/.bashrc`, `~/.ssh/`).
- `/root` — root's home. It is **not** the same as `/`. A normal user can't even list it:

  ```bash
  $ ls /root
  ls: cannot open directory '/root': Permission denied
  $ sudo ls -la /root
  ```

### `/tmp`, `/var/tmp`, `/dev/shm`

World-writable areas anyone can create files in. They are protected by the **sticky bit** (`drwxrwxrwt`), so users can't delete each other's files.

| Path | Cleared at reboot? | Notes |
|---|---|---|
| `/tmp` | Usually yes | Often a RAM-backed `tmpfs` |
| `/var/tmp` | No | For temp files that must survive reboot |
| `/dev/shm` | Yes | Shared memory, always in RAM |

### `/proc` and `/sys` — virtual filesystems

These files don't exist on disk. The kernel generates them when you read them.

```bash
cat /proc/cpuinfo        # CPU details
cat /proc/meminfo        # memory details
cat /proc/version        # kernel version
cat /proc/loadavg        # load average
ls /proc/$$              # info about your current shell ($$ = its PID)
cat /sys/class/net/*/address    # MAC addresses of network interfaces
cat /proc/sys/net/ipv4/ip_forward   # kernel setting: is IP forwarding on?
```

Every running process has a folder `/proc/<PID>/`:

| Path | Shows |
|---|---|
| `/proc/<PID>/cmdline` | Full command line |
| `/proc/<PID>/exe` | Symlink to the binary that is running |
| `/proc/<PID>/cwd` | Its current directory |
| `/proc/<PID>/environ` | Environment variables (may contain secrets!) |
| `/proc/<PID>/fd/` | Open files and sockets |
| `/proc/<PID>/status` | State, UID, memory, capabilities |

### `/dev` — devices as files

```bash
ls -l /dev/sda /dev/null /dev/tty 2>/dev/null
```

| Device | Meaning |
|---|---|
| `/dev/sda`, `/dev/nvme0n1` | Disks (`b` = block device) |
| `/dev/sda1` | First partition |
| `/dev/null` | Discards anything written to it |
| `/dev/zero` | Endless zeros |
| `/dev/urandom` | Random bytes |
| `/dev/tty`, `/dev/pts/0` | Terminals (`c` = character device) |

---

## Paths

| Type | Example | Starts from |
|---|---|---|
| Absolute | `/etc/ssh/sshd_config` | `/` — works from anywhere |
| Relative | `notes/todo.txt` | Your current directory |
| Home shortcut | `~/notes`, `~bob` | Your home / bob's home |
| Current dir | `./script.sh` | `.` = here |
| Parent dir | `../logs` | `..` = one level up |

```bash
cd /var/log          # absolute
cd ../lib            # relative → /var/lib
cd ~                 # home
cd -                 # previous directory
realpath ../log      # convert to absolute path
```

---

## File Types

The first character of `ls -l` shows the type:

```text
-rw-r--r-- 1 root root  2.1K  /etc/passwd
drwxr-xr-x 2 root root  4.0K  /etc/ssh
lrwxrwxrwx 1 root root     7  /bin -> usr/bin
```

| Char | Type | Example |
|:-:|---|---|
| `-` | Regular file | `/etc/passwd` |
| `d` | Directory | `/etc` |
| `l` | Symbolic link | `/bin` |
| `b` | Block device | `/dev/sda` |
| `c` | Character device | `/dev/null` |
| `s` | Socket | `/run/systemd/journal/socket` |
| `p` | Named pipe (FIFO) | created with `mkfifo` |

```bash
file /bin/ls /etc/passwd /dev/null    # what kind of content is this?
stat /etc/passwd                       # full metadata
```

---

## Inodes and Links 🟡

### Inodes

Every file has an **inode**: a record that stores its metadata (owner, permissions, size, timestamps, location of data blocks) — **but not its name**. The name lives in the directory, which maps names → inode numbers.

```text
 Directory /home/amar
 ┌──────────────┬────────┐          Inode 524301
 │ name         │ inode  │         ┌──────────────────────┐
 ├──────────────┼────────┤         │ owner: amar          │
 │ notes.txt    │ 524301 │ ──────► │ perms: rw-r--r--     │ ──► data blocks
 │ hardlink.txt │ 524301 │ ──────► │ size: 1024           │
 └──────────────┴────────┘         │ links: 2             │
                                   └──────────────────────┘
```

```bash
ls -i notes.txt          # show the inode number
df -i                    # inode usage per filesystem
```

A disk can be "full" with free space left if it runs out of inodes (millions of tiny files).

### Hard links vs symbolic links

| | Hard link | Symbolic (soft) link |
|---|---|---|
| Create | `ln target link` | `ln -s target link` |
| Points to | The same inode | A path (text) |
| Original deleted? | Still works — data stays until the last link is gone | Breaks ("dangling link") |
| Across filesystems | No | Yes |
| To directories | No | Yes |
| Shown in `ls -l` | Looks like a normal file, link count > 1 | `l` type with `->` |

### Timestamps

| Stamp | Changes when | Show with |
|---|---|---|
| `mtime` | Content modified | `ls -l` |
| `ctime` | Metadata changed (perms, owner) **or** content | `ls -lc` |
| `atime` | File read (often relaxed with `relatime`) | `ls -lu` |

> **Forensics:** attackers can fake `mtime` with `touch -d`, but changing it updates `ctime`, which normal users can't set. A file with an old `mtime` and a very recent `ctime` deserves a closer look.

---

## Mount Points (Preview)

```bash
findmnt               # all mounts as a tree
df -hT                # mounted filesystems, type and usage
lsblk                 # disks and partitions
```

Chapter [10 — Storage](10-Storage.md) covers mounting in depth.

---

## Where Does an Application Keep Things?

Example: **nginx** installed with `apt`

```text
 Binary          /usr/sbin/nginx
 Config          /etc/nginx/nginx.conf, /etc/nginx/sites-enabled/
 Website files   /var/www/html
 Logs            /var/log/nginx/access.log, error.log
 Service unit    /usr/lib/systemd/system/nginx.service
 Runtime PID     /run/nginx.pid
 Runs as user    www-data
```

How to discover this for *any* package:

```bash
which nginx                        # where the binary is
dpkg -S /usr/sbin/nginx            # which package installed it
dpkg -L <package> | head -30       # every file that package installed
systemctl cat nginx                # the service unit
ps -o user,cmd -C nginx            # which user it runs as
```

---

## Product Security Perspective

### Sensitive locations to know by heart

| Path | Why attackers want it | Expected permissions |
|---|---|---|
| `/etc/shadow` | Password hashes for offline cracking | `640 root:shadow` (Debian/Ubuntu) or `000`/`400` root (RHEL) |
| `/etc/sudoers`, `/etc/sudoers.d/` | Add yourself to sudo | `440 root:root` |
| `~/.ssh/authorized_keys` | Add a key = persistent access | `600`, owned by the user |
| `~/.ssh/id_*` | Private keys = log in elsewhere | `600` |
| `/etc/crontab`, `/etc/cron.*`, `/var/spool/cron` | Persistence via scheduled jobs | root-owned, not writable by others |
| `/etc/systemd/system/` | Persistence via a malicious service | root-owned |
| `~/.bashrc`, `~/.profile` | Persistence on every login | user-owned, not writable by others |
| `/tmp`, `/dev/shm` | Drop and run malware (world-writable) | Ideally mounted `noexec` |
| `/proc/<PID>/environ` | Secrets passed as env vars | Readable only by the process owner |
| `.env`, `config.yml`, `*.pem`, `*.key` in app folders | Hard-coded credentials | Not world-readable |

### Quick checks

```bash
# Recently modified files in /etc (last 2 days)
sudo find /etc -type f -mtime -2 -ls 2>/dev/null

# Executables hiding in temp directories
find /tmp /var/tmp /dev/shm -type f -perm -u+x 2>/dev/null

# Hidden files and folders in temp directories
find /tmp /var/tmp /dev/shm -name ".*" 2>/dev/null

# Private keys lying around
sudo find / -xdev \( -name "*.pem" -o -name "id_rsa" -o -name "id_ed25519" -o -name "*.key" \) 2>/dev/null

# Files with no valid owner (left from deleted users or extracted archives)
sudo find / -xdev \( -nouser -o -nogroup \) 2>/dev/null
```

---

## Hands-on Lab 🟢→🟡

**Goal:** explore the tree, understand links and inodes, and find files like an investigator.

### Part 1 — Explore 🟢

```bash
cd / && ls -l
ls -l /bin /sbin /lib            # symlinks to /usr on modern distros?
ls /etc | head -20
ls -l /var/log
ls -ld /tmp                      # note the trailing 't' (sticky bit)
ls /root                         # expect "Permission denied"
sudo ls /root
```

### Part 2 — Map an application 🟢

```bash
sudo apt update && sudo apt install -y nginx
dpkg -S /usr/sbin/nginx          # which package owns the binary?
dpkg -L "$(dpkg -S /usr/sbin/nginx | cut -d: -f1)" | head -20
ls /etc/nginx /var/log/nginx /var/www/html
```

Write down the binary, config, log and web-root paths.

### Part 3 — Inodes and links 🟡

```bash
mkdir -p ~/labs/fs && cd ~/labs/fs
echo "original content" > original.txt
ln original.txt hard.txt
ln -s original.txt soft.txt
ls -li                           # compare inode numbers and link counts
rm original.txt
cat hard.txt                     # still works — why?
cat soft.txt                     # fails — why?
ls -l soft.txt                   # dangling link
```

### Part 4 — /proc 🟡

```bash
sleep 600 &                      # start a background process
PID=$!                           # PID of the last background job
ls -l /proc/$PID/exe /proc/$PID/cwd
tr '\0' ' ' < /proc/$PID/cmdline; echo
grep -E 'State|Uid' /proc/$PID/status
kill $PID
```

### Part 5 — Timestamps (forensics) 🟡

```bash
cd ~/labs/fs
echo "hello" > evidence.txt
stat evidence.txt
touch -d "2020-01-01 10:00" evidence.txt    # fake the modification time
stat evidence.txt                           # mtime changed, ctime = now
```

**Questions**

1. Why did `hard.txt` survive deleting the original but `soft.txt` didn't?
2. What does the `t` in `drwxrwxrwt` on `/tmp` do?
3. Which `stat` field revealed that `evidence.txt` was tampered with?
4. Where are nginx's config and logs?

---

## Common Mistakes

- Confusing `/` (root of the tree) with `/root` (root user's home).
- Storing anything important in `/tmp` — it may be wiped at reboot.
- Editing files in `/usr/lib/systemd/system/` — package updates overwrite them; use `/etc/systemd/system/` or `systemctl edit`.
- Installing manual software into `/usr/bin` instead of `/usr/local/bin` or `/opt`.
- Deleting files from `/var/log` while a program still has them open — space isn't freed (see chapter 10).
- Forgetting Linux paths are case-sensitive.

---

## Interview Questions

**1. What is the FHS?**
The Filesystem Hierarchy Standard: it defines what goes in `/etc`, `/var`, `/usr` and so on, so software and admins know where to find things on any distribution.

**2. What is the difference between `/` and `/root`?**
`/` is the top of the filesystem tree. `/root` is the root user's home directory.

**3. What's stored in `/etc`, `/var` and `/usr`?**
`/etc`: configuration. `/var`: variable data such as logs, caches and databases. `/usr`: installed programs and libraries.

**4. What are `/proc` and `/sys`?**
Virtual filesystems generated by the kernel. `/proc` exposes processes and kernel information; `/sys` exposes devices and kernel settings.

**5. What is an inode?**
A data structure holding a file's metadata and data-block locations, but not its name. Directories map names to inode numbers.

**6. Hard link vs soft link?**
A hard link is another name for the same inode, survives deletion of the original, and can't cross filesystems. A soft link stores a path, can cross filesystems and point to directories, but breaks if the target is removed.

**7. A disk shows free space, but you can't create files. Why?**
It's out of inodes. Check with `df -i`; usually caused by huge numbers of small files (sessions, cache, mail queue).

**8. 🔐 Which files would you check first for signs of persistence after a compromise?**
`~/.ssh/authorized_keys`, cron (`/etc/crontab`, `/etc/cron.*`, `/var/spool/cron`), systemd units in `/etc/systemd/system`, shell startup files (`.bashrc`, `.profile`), `/etc/sudoers.d/`, new SUID binaries, and executables in `/tmp` or `/dev/shm`.

**9. 🔐 Why should `/tmp` be mounted with `noexec`?**
It's world-writable, so attackers commonly download and run payloads there. `noexec` blocks direct execution of binaries from it (it doesn't stop `bash script.sh`, so it's one layer, not a complete fix).

---

## Summary

- Linux has a single tree from `/`; disks are mounted into it.
- `/etc` = config, `/var` = changing data and logs, `/usr` = software, `/home` = users.
- `/proc` and `/sys` are windows into the kernel and running processes.
- Files are inodes; names are directory entries; links are extra names or paths.
- Knowing where sensitive files live is the foundation of hardening and incident response.

**Next:** [03 — Linux Commands](03-Linux-Commands.md)

---

## References

- Filesystem Hierarchy Standard 3.0 — https://refspecs.linuxfoundation.org/FHS_3.0/fhs/
- `man hier`, `man 5 proc`, `man 7 inode`, `man ln`, `man stat`
- The `/proc` filesystem — https://docs.kernel.org/filesystems/proc.html
