# 01 — Linux Introduction

> **Module:** 01 – Linux · **Level:** 🟢 Basic · **Time:** ~1.5 hours
> **Lab environment:** WSL2, Docker or VM — see [labs/README.md](../labs/README.md)

---

## Objectives

After this chapter you will be able to:

- Explain what Linux is (and what it isn't).
- Describe the Linux architecture: hardware, kernel, system calls, user space.
- Explain the difference between the kernel and the shell.
- Describe the Linux boot process from power-on to login.
- Choose between common distributions and package families.
- Compare Linux with Windows concepts you may already know.
- Explain why Linux is essential for Product Security.

---

## What Is Linux?

Strictly speaking, **Linux is a kernel** — the core program that manages hardware, memory and processes. Linus Torvalds released it in **1991**.

What people usually call "Linux" (Ubuntu, Debian, RHEL…) is a **distribution**: the Linux kernel plus GNU tools, a package manager, an init system (usually systemd) and other software.

```text
 Linux distribution (e.g. Ubuntu)
┌──────────────────────────────────────────────┐
│  Applications   (nginx, python, docker, ...) │
│  System tools   (bash, ls, grep — from GNU)  │
│  Init system    (systemd)                    │
│  Package manager(apt / dnf)                  │
├──────────────────────────────────────────────┤
│  Linux kernel                                │
└──────────────────────────────────────────────┘
```

Linux runs:

- Most web servers and almost all cloud workloads
- Every Docker container and Kubernetes node (Linux containers share the host's Linux kernel)
- Android phones (Linux kernel)
- Routers, TVs, cars, IoT devices
- All of the world's top 500 supercomputers

---

## A Short History

| Year | Event | Why it matters today |
|---|---|---|
| 1969 | **Unix** created at Bell Labs | Introduced the ideas Linux still uses: one file tree, multi-user, small tools combined with pipes |
| 1983 | Richard Stallman starts the **GNU Project** | Gave us `bash`, `grep`, `ls`, `cp`, `gcc` |
| 1991 | Linus Torvalds releases the **Linux kernel** | GNU tools + Linux kernel = a complete free OS |
| 1993 | Debian and Slackware released | First major distributions |
| 2004 | Ubuntu released | Made Linux easy for beginners |
| 2013 | Docker released | Containers made Linux the default runtime for applications |
| 2014 | Kubernetes released | Linux became the platform for cloud-native systems |

---

## Linux Architecture

```text
┌──────────────────────────────────────────────────────────┐
│                       USER SPACE                         │
│                                                          │
│   You ──► Shell (bash) ──► Programs (ls, nginx, python)  │
│                               │                          │
│                     C library (glibc)                    │
├───────────────────────────────┼──────────────────────────┤
│                      SYSTEM CALLS                        │
│        open() read() write() fork() execve() socket()    │
├───────────────────────────────┼──────────────────────────┤
│                      KERNEL SPACE                        │
│                                                          │
│  Process     Memory     Filesystems   Networking  Security│
│  scheduler   manager    (ext4, xfs)   (TCP/IP)   (LSM,   │
│                                                   caps)  │
│                     Device drivers                       │
├──────────────────────────────────────────────────────────┤
│              HARDWARE  (CPU · RAM · Disk · NIC)          │
└──────────────────────────────────────────────────────────┘
```

### User space vs kernel space

| | User space | Kernel space |
|---|---|---|
| Who runs there | Your programs, shells, services | The kernel and drivers |
| Hardware access | **No** — must ask the kernel | Full |
| If it crashes | That program dies | The whole system can crash (kernel panic) |

Programs **cannot** touch hardware directly. They ask the kernel through **system calls** (syscalls). For example, `cat file.txt` asks the kernel to `openat()` the file, `read()` it and `write()` it to your terminal.

You can watch this happen:

```bash
strace -e trace=openat,read,write cat /etc/hostname
```

> **Security angle:** this boundary is why a bug in a normal program is less dangerous than a bug in the kernel. Container escapes and privilege-escalation exploits often target kernel bugs, because the kernel is shared by every process and container on the host.

---

## Kernel vs Shell

| | Kernel | Shell |
|---|---|---|
| What | Core of the OS | A program that reads your commands |
| Examples | Linux 6.8 | `bash`, `zsh`, `sh`, `fish` |
| Runs in | Kernel space | User space |
| You interact with it | Indirectly, through syscalls | Directly, by typing |
| Can you change it? | Requires reboot (or modules) | Just run another shell |

Check yours:

```bash
uname -r          # kernel version, e.g. 6.8.0-45-generic
echo $SHELL       # your login shell, e.g. /bin/bash
echo $0           # the shell you are in right now
cat /etc/shells   # shells installed on the system
```

---

## How Linux Boots

```text
 Power on
    │
    ▼
 UEFI / BIOS ─────────── firmware checks hardware, finds a boot disk
    │                    (Secure Boot verifies the bootloader signature)
    ▼
 Bootloader (GRUB) ───── shows the menu, loads kernel + initramfs
    │
    ▼
 Linux kernel ────────── initialises CPU, memory, drivers
    │
    ▼
 initramfs ───────────── small temporary filesystem; finds and mounts the real root /
    │                    (unlocks encrypted disks here)
    ▼
 systemd (PID 1) ─────── starts all services in parallel
    │
    ▼
 Login prompt / desktop / SSH
```

See it on your system:

```bash
ls /boot                    # kernel (vmlinuz-*) and initramfs (initrd.img-*)
ps -p 1 -o pid,comm         # PID 1 should be systemd
systemd-analyze             # how long boot took
systemd-analyze blame | head   # slowest services
journalctl -b | head        # logs from the current boot
```

> **Security angle:** every stage can be attacked or protected. Secure Boot protects the bootloader and kernel; a GRUB password stops someone with physical access from booting into single-user mode; disk encryption (LUKS) protects data if the disk is stolen.

---

## Distributions

### Two big families

| Family | Distros | Package format | Package tool |
|---|---|---|---|
| **Debian** | Debian, Ubuntu, Kali, Linux Mint | `.deb` | `apt`, `dpkg` |
| **Red Hat** | RHEL, Rocky Linux, AlmaLinux, Fedora, Amazon Linux | `.rpm` | `dnf`, `rpm` |

Others you'll meet: **Alpine** (tiny, popular for containers, uses `apk`), **Arch** (rolling release, `pacman`), **SUSE** (`zypper`).

### Which one where?

| Distro | Typical use |
|---|---|
| Ubuntu LTS | Cloud VMs, developer laptops, this handbook |
| Debian | Stable servers, base for many Docker images |
| RHEL / Rocky / Alma | Enterprise servers, regulated industries |
| Amazon Linux | AWS EC2 |
| Alpine | Minimal container images |
| Kali | Penetration testing (not for servers) |

**LTS** (Long-Term Support) releases get security updates for years. Production systems should run an LTS version and be upgraded before it reaches **end of life (EOL)** — EOL systems get no security patches.

```bash
cat /etc/os-release        # which distro and version
```

---

## Linux for Windows Users

| Windows | Linux |
|---|---|
| `C:\`, `D:\` drives | One tree starting at `/`; disks are mounted into it |
| `C:\Users\amar` | `/home/amar` (also `~`) |
| `C:\Windows\System32` | `/usr/bin`, `/usr/sbin` |
| Registry | Text files in `/etc` |
| Administrator | `root` (UID 0), used via `sudo` |
| Services (`services.msc`) | systemd units (`systemctl`) |
| Task Manager | `top`, `htop`, `ps` |
| Event Viewer | `journalctl`, `/var/log` |
| PowerShell / CMD | bash |
| `.exe` extension means executable | The **execute permission** (`x`) means executable; extensions don't matter |
| Paths use `\` | Paths use `/` |
| Case-insensitive file names | **Case-sensitive**: `File.txt` ≠ `file.txt` |
| `winget` / Microsoft Store | `apt` / `dnf` / `snap` |

---

## Why Linux Matters in Product Security

| Task | Linux skill used |
|---|---|
| Investigate an incident on a server | Logs, processes, network connections |
| Review a Dockerfile | Users, permissions, packages, filesystem |
| Harden a Kubernetes node | systemd, kernel parameters, SSH, firewall |
| Triage a CVE in a base image | Package management, versions |
| Automate a security check in CI | Shell scripting |
| Run security tools | Most tools are Linux-first: `nmap`, `tcpdump`, `trivy`, `falco`, `openssl`, `lynis` |

---

## Hands-on Lab 🟢

**Goal:** identify your system and see the user/kernel boundary.

1. Identify the system:

   ```bash
   cat /etc/os-release
   uname -a
   hostnamectl          # skip on Docker
   ```

2. Who and where are you?

   ```bash
   whoami
   id
   pwd
   echo $SHELL
   ```

3. Find PID 1:

   ```bash
   ps -p 1 -o pid,user,comm
   ```

   On a VM or WSL with systemd you'll see `systemd`. In Docker you'll see `bash` — a container has no init system unless you add one.

4. Watch system calls (install strace first: `sudo apt install -y strace`):

   ```bash
   strace -c ls /           # summary: which syscalls ls made and how often
   strace -e trace=openat cat /etc/hostname
   ```

5. Look at the boot files (VM/WSL):

   ```bash
   ls -lh /boot
   systemd-analyze
   ```

**Questions to answer in your notes**

1. Which distribution and version are you running? Is it LTS?
2. What kernel version is running?
3. What is PID 1, and why is it different in a container?
4. Which file did `cat` open, and which syscall did it use?

---

## Common Mistakes

- Thinking "Linux" and "Ubuntu" mean the same thing (Ubuntu is one distribution).
- Thinking the shell *is* the operating system.
- Running an end-of-life release because "it still works" — it gets no security patches.
- Assuming file extensions decide what is executable.
- Forgetting Linux is case-sensitive.

---

## Interview Questions

**1. What is Linux?**
A free, open-source operating system kernel created by Linus Torvalds in 1991. Combined with GNU tools and other software it forms a distribution such as Ubuntu or RHEL.

**2. What is the difference between the kernel and the shell?**
The kernel manages hardware, memory, processes and security in kernel space. The shell is a user-space program that reads commands and asks the kernel to do work through system calls.

**3. What is a system call?**
The interface a user-space program uses to request a service from the kernel, such as `open`, `read`, `fork`, `execve` or `socket`.

**4. Describe the Linux boot process.**
Firmware (UEFI/BIOS) → bootloader (GRUB) → kernel → initramfs (mounts the real root filesystem) → systemd as PID 1 → services → login.

**5. What is the difference between Debian-based and Red Hat-based distributions?**
Package format and tools: `.deb` with `apt`/`dpkg` versus `.rpm` with `dnf`/`rpm`. They also differ in default paths, release cycles and some config locations.

**6. Why do containers share the host kernel, and why does that matter for security?**
Containers are isolated processes, not VMs; they use the host's kernel via namespaces and cgroups. A kernel vulnerability can therefore let a process escape its container and affect the host and all other containers.

**7. What is LTS and why does it matter?**
Long-Term Support releases receive security updates for many years. Production systems should use LTS releases and be upgraded before end of life.

---

## Summary

- Linux is a kernel; distributions add tools, an init system and a package manager.
- Programs run in user space and use system calls to ask the kernel for anything.
- Boot: firmware → GRUB → kernel → initramfs → systemd.
- Two main families: Debian (`apt`) and Red Hat (`dnf`).
- Linux is the foundation for servers, containers and cloud — and so for Product Security.

**Next:** [02 — Linux Filesystem](02-Linux-Filesystem.md)

---

## References

- The Linux Kernel documentation — https://docs.kernel.org/
- GNU Project — https://www.gnu.org/
- `man 2 syscalls`, `man 7 boot`, `man bootup`
- Ubuntu release cycle — https://ubuntu.com/about/release-cycle
