# Users, Groups & Permissions

> **Module:** 01 - Linux
> **Chapter:** 04 - Users, Groups & Permissions

---

# Learning Objectives

After completing this chapter, you will be able to:

* Understand Linux users and groups.
* Differentiate between root, normal, and system users.
* Understand file ownership.
* Read and modify Linux file permissions.
* Use `chmod`, `chown`, `chgrp`, `umask`, and `id`.
* Understand SUID, SGID, and Sticky Bit.
* Apply the Principle of Least Privilege.
* Explain Linux permissions from a Product Security perspective.

---

# Why This Matters

Linux is a **multi-user operating system**.

Every process runs as a user and every file belongs to a user and a group. Proper permissions help protect systems from unauthorized access and accidental modification.

Weak permissions are a common cause of security incidents.

---

# Linux Users

A **user** represents an identity that can log in to the system or run processes.

## Types of Users

### Root User

* Username: `root`
* User ID (UID): `0`
* Full administrative privileges

Example:

```bash
whoami
```

Output

```text
root
```

---

### Normal Users

Created for people using the system.

Examples:

```text
amar
john
alice
```

Home directories are usually located under:

```text
/home
```

---

### System Users

Used by services and applications.

Examples:

```text
www-data
mysql
postgres
nginx
```

These accounts normally cannot log in interactively.

---

# Understanding User IDs (UID)

Every Linux user has a unique User ID.

Example:

```bash
id
```

Output

```text
uid=1000(amar)
gid=1000(amar)
groups=1000(amar),27(sudo)
```

---

# Groups

A **group** is a collection of users.

Instead of assigning permissions individually, Linux allows permissions to be granted to groups.

Example:

```text
Developers
├── Amar
├── John
└── Alice
```

---

# Primary Group

Every user has one primary group.

Example:

```text
amar
```

Primary Group:

```text
amar
```

---

# Secondary Groups

A user may belong to multiple groups.

Example:

```bash
groups
```

Output

```text
amar sudo docker
```

---

# File Ownership

Every file has:

* Owner
* Group
* Others

Example:

```bash
ls -l
```

Output

```text
-rw-r--r-- 1 amar developers notes.txt
```

Meaning:

* Owner → amar
* Group → developers
* Others → Everyone else

---

# Linux Permission Model

Example:

```text
-rwxr-xr--
```

Breakdown:

```text
- rwx r-x r--
  │   │   │
  │   │   └── Others
  │   └────── Group
  └────────── Owner
```

---

# Permission Types

## Read (r)

Allows reading a file.

Value:

```text
4
```

---

## Write (w)

Allows modifying a file.

Value:

```text
2
```

---

## Execute (x)

Allows executing a file or entering a directory.

Value:

```text
1
```

---

# Numeric Permissions

| Number | Permission |
| -----: | ---------- |
|      7 | rwx        |
|      6 | rw-        |
|      5 | r-x        |
|      4 | r--        |
|      3 | -wx        |
|      2 | -w-        |
|      1 | --x        |
|      0 | ---        |

---

# Common Permission Values

| Permission | Meaning                                        |
| ---------- | ---------------------------------------------- |
| 777        | Everyone has full access (avoid in production) |
| 755        | Owner full, others read & execute              |
| 750        | Owner full, group read & execute               |
| 700        | Owner only                                     |
| 644        | Common for text/config files                   |
| 600        | Private files (SSH keys)                       |

---

# chmod

Changes permissions.

Example:

```bash
chmod 755 script.sh
```

Symbolic mode:

```bash
chmod u+x script.sh
```

Remove write permission:

```bash
chmod g-w file.txt
```

---

# chown

Changes file ownership.

Example:

```bash
sudo chown amar file.txt
```

Owner and group:

```bash
sudo chown amar:developers file.txt
```

---

# chgrp

Changes group ownership.

Example:

```bash
sudo chgrp developers project.txt
```

---

# umask

Defines default permissions for newly created files.

Check current value:

```bash
umask
```

Example output:

```text
0022
```

---

# Special Permissions

## SUID

Runs a program with the owner's privileges.

Example:

```bash
ls -l /usr/bin/passwd
```

Output:

```text
-rwsr-xr-x
```

Notice the `s`.

---

## SGID

Files inherit the directory's group.

Useful for shared project directories.

---

## Sticky Bit

Commonly used on:

```text
/tmp
```

Example:

```text
drwxrwxrwt
```

Only the owner can delete their own files.

---

# Important System Files

## /etc/passwd

Contains user account information.

Example:

```text
amar:x:1000:1000::/home/amar:/bin/bash
```

---

## /etc/shadow

Contains password hashes.

Permissions:

```text
-r-------- root root
```

Only root can access it.

---

# Principle of Least Privilege

Users should have **only the permissions required** to perform their tasks.

Benefits:

* Reduced attack surface
* Better security
* Lower risk of accidental changes

---

# Practical Examples

View current user:

```bash
whoami
```

Display user information:

```bash
id
```

Display group membership:

```bash
groups
```

View file permissions:

```bash
ls -l
```

Change permissions:

```bash
chmod 644 notes.txt
```

Change owner:

```bash
sudo chown amar notes.txt
```

---

# In Real Production

Example:

```text
Application
        │
        ▼
Configuration → /etc
        │
Logs → /var/log
        │
Application User → www-data
```

The application should run as a **non-root** service account with only the permissions it requires.

---

# Product Security Perspective

A Product Security Engineer frequently checks:

* World-writable files
* Incorrect ownership
* SUID binaries
* Sensitive file permissions
* SSH private key permissions
* Least privilege compliance

Example:

```bash
find / -perm -4000 2>/dev/null
```

Find SUID binaries.

Find world-writable files:

```bash
find / -type f -perm -002 2>/dev/null
```

---

# Hands-on Lab

Run:

```bash
whoami

id

groups

touch demo.txt

ls -l demo.txt

chmod 600 demo.txt

ls -l demo.txt

chmod 755 demo.txt

ls -l demo.txt

umask
```

Explore:

```bash
cat /etc/passwd

sudo cat /etc/shadow
```

Observe the difference in access permissions.

---

# Common Mistakes

* Using `777` on production systems.
* Running applications as `root`.
* Storing SSH private keys with open permissions.
* Ignoring group memberships.
* Giving unnecessary write permissions.

---

# Interview Questions

### What is the difference between a user and a group?

A user is an identity. A group is a collection of users used to simplify permission management.

---

### What does `chmod` do?

Changes file or directory permissions.

---

### What does `chown` do?

Changes file ownership.

---

### What is the difference between `644` and `755`?

* **644**: Owner can read/write; group and others can read.
* **755**: Owner has full access; group and others can read and execute.

---

### Why should applications avoid running as root?

Running as root increases the impact of a compromise. Least privilege reduces risk.

---

### What is SUID?

A special permission that allows a program to run with the owner's privileges.

---

### What is the Sticky Bit?

A directory permission that allows only the file owner (or root) to delete files, even if the directory is writable by everyone.

---

### Why is `/etc/shadow` protected?

It contains password hashes and must be accessible only to privileged users.

---

# Key Takeaways

* Linux is a multi-user operating system.
* Every file has an owner, group, and permissions.
* Understand `r`, `w`, and `x` permissions.
* Learn numeric permission values.
* Use `chmod`, `chown`, and `chgrp` confidently.
* Apply the Principle of Least Privilege.
* Avoid running applications as `root`.
* Correct file permissions are fundamental to Linux security.

---

# References

* Linux `man chmod`
* Linux `man chown`
* Linux `man umask`
* Linux Filesystem Hierarchy Standard (FHS)
* https://man7.org/linux/man-pages/