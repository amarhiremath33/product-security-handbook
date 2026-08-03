# Linux Filesystem

> **Module:** 01 - Linux
> **Chapter:** 02 - Linux Filesystem

---

# Learning Objectives

After completing this chapter, you will be able to:

* Understand the Linux filesystem hierarchy.
* Explain the purpose of important Linux directories.
* Navigate the filesystem confidently.
* Identify where applications, logs, configuration files, and user data are stored.
* Understand how the Linux filesystem is used in real production environments.
* Explain the Product Security importance of the Linux filesystem.

---

# Why This Matters

Whether you're a Linux Administrator, DevOps Engineer, Cloud Engineer, or Product Security Engineer, almost every task starts with understanding the Linux filesystem.

Examples:

* Where are application logs stored?
* Where are configuration files located?
* Where are user accounts stored?
* Where should software be installed?
* Where should investigation begin after a security incident?

Understanding the filesystem answers all of these questions.

---

# What is the Linux Filesystem?

The Linux filesystem is a hierarchical directory structure that stores everything in the operating system.

Unlike Windows, Linux does **not** have multiple drive letters such as `C:` or `D:`.

Everything begins from a single root directory.

```text
/
```

---

# Linux Filesystem Hierarchy

```text
/
├── bin
├── boot
├── dev
├── etc
├── home
├── lib
├── media
├── mnt
├── opt
├── proc
├── root
├── run
├── sbin
├── srv
├── sys
├── tmp
├── usr
└── var
```

Every directory has a specific purpose.

---

# Root Directory (/)

The root directory is the top-level directory of Linux.

Every other directory exists under it.

Example:

```bash
cd /
pwd
```

Output

```text
/
```

---

# /home

Stores home directories for normal users.

Example

```text
/home
├── amar
├── john
└── alice
```

Each user stores:

* Documents
* Downloads
* Projects
* Personal configuration files

Example

```bash
cd /home
ls
```

---

# /root

Home directory of the **root** user.

Do not confuse:

```text
/
```

with

```text
/root
```

Example

```bash
cd /root
pwd
```

Output

```text
/root
```

---

# /etc

One of the most important directories.

Stores system configuration files.

Examples

```text
/etc/passwd
/etc/group
/etc/hosts
/etc/ssh/
/etc/systemd/
```

Example

```bash
ls /etc
```

---

# /var

Stores data that changes frequently.

Examples

```text
/var/log
/var/cache
/var/tmp
/var/spool
```

Most log investigation begins here.

Example

```bash
ls /var/log
```

---

# /usr

Contains user-space programs and shared libraries.

Examples

```text
/usr/bin
/usr/lib
/usr/share
```

Most installed applications are stored here.

Example

```bash
ls /usr/bin
```

---

# /bin

Contains essential user commands.

Examples

```text
ls
cp
mv
cat
mkdir
```

---

# /sbin

Contains essential administrative commands.

Examples

```text
fdisk
reboot
mount
shutdown
```

Typically intended for system administration.

---

# /tmp

Temporary files.

Applications use this directory for temporary storage.

Example

```bash
touch /tmp/test.txt
```

Many systems automatically clean this directory during reboot.

---

# /opt

Optional third-party software.

Example

```text
/opt/google
/opt/microsoft
```

Often used by commercial software.

---

# /boot

Contains bootloader files and the Linux kernel.

Examples

```text
vmlinuz
initrd
grub
```

---

# /dev

Contains device files.

Everything in Linux is treated as a file—even hardware.

Examples

```text
/dev/sda
/dev/null
/dev/tty
```

---

# /proc

A virtual filesystem.

Provides information about running processes and the kernel.

Examples

```text
/proc/cpuinfo
/proc/meminfo
/proc/version
```

Example

```bash
cat /proc/cpuinfo
```

---

# /sys

Virtual filesystem containing hardware and kernel information.

Used by administrators and system tools.

---

# /run

Stores runtime information.

Examples include:

* PID files
* Runtime sockets
* Temporary service data

---

# /mnt

Temporary mount point for manually mounted filesystems.

Example

```bash
sudo mount /dev/sdb1 /mnt
```

---

# /media

Automatically mounted removable devices.

Examples

* USB drives
* DVDs
* External disks

---

# Filesystem Hierarchy Diagram

```text
               /
     ┌─────────┼──────────┐
    etc      home       var
     │         │          │
 Configs    Users      Logs
     │
    usr
     │
 Applications
```

---

# Common Navigation Commands

Current directory

```bash
pwd
```

Move to root

```bash
cd /
```

Move to home

```bash
cd ~
```

List files

```bash
ls
```

Recursive listing

```bash
ls -R
```

Long listing

```bash
ls -l
```

---

# Practical Example

Suppose an application is not starting.

Possible investigation:

```text
Configuration
↓

/etc

↓

Logs

↓

/var/log

↓

Binary

↓

/usr/bin
```

This simple workflow is common in production troubleshooting.

---

# In Real Production

Consider a web server:

```text
Ubuntu Server
        │
        ▼
Nginx
        │
        ├── Config → /etc/nginx
        ├── Binary → /usr/sbin/nginx
        ├── Logs → /var/log/nginx
        └── Website → /var/www
```

Knowing these locations helps you troubleshoot faster.

---

# Product Security Perspective

A Product Security Engineer frequently uses the filesystem to:

* Review application logs in `/var/log`
* Inspect configuration files in `/etc`
* Verify binaries in `/usr/bin`
* Investigate suspicious files in `/tmp`
* Check SSH configuration in `/etc/ssh`
* Review user accounts using `/etc/passwd`
* Collect forensic artifacts after an incident

Filesystem knowledge is essential during vulnerability investigations and incident response.

---

# Hands-on Lab

Run the following commands:

```bash
pwd
```

```bash
cd /
ls
```

```bash
cd /etc
pwd
ls
```

```bash
cd /var/log
ls
```

```bash
cat /proc/version
```

Questions:

1. Which directory stores logs?
2. Which directory stores configuration files?
3. Which directory contains temporary files?
4. Which directory is the root user's home?

---

# Common Mistakes

❌ Confusing `/` with `/root`

❌ Editing configuration files without backup

❌ Storing permanent data inside `/tmp`

❌ Running applications from random directories instead of standard locations

---

# Interview Questions

### 1. What is the Linux filesystem hierarchy?

A hierarchical directory structure beginning at `/`, where every file and directory is organized under the root directory.

---

### 2. What is stored inside `/etc`?

System-wide configuration files.

---

### 3. Where are logs stored?

Usually inside:

```text
/var/log
```

---

### 4. What is the purpose of `/proc`?

A virtual filesystem that exposes information about processes and the running kernel.

---

### 5. Difference between `/home` and `/root`?

* `/home` stores home directories for normal users.
* `/root` is the home directory of the root user.

---

### 6. What is `/tmp` used for?

Temporary files created by users and applications.

---

### 7. Why is `/var` important?

It stores variable data such as logs, caches, mail queues, and spool files that change during system operation.

---

# Key Takeaways

* Linux has a single filesystem hierarchy beginning at `/`.
* Every directory has a specific purpose.
* `/etc` stores configuration.
* `/var` stores logs and variable data.
* `/home` stores user files.
* `/root` is the root user's home directory.
* `/usr` stores applications and libraries.
* `/proc` and `/sys` expose kernel and system information.
* Understanding the filesystem is fundamental for troubleshooting and Product Security.

---

# References

* Linux Filesystem Hierarchy Standard (FHS): https://refspecs.linuxfoundation.org/FHS_3.0/fhs/
* Linux man pages (`man hier`)
* https://www.kernel.org/doc/html/latest/