# Linux Commands

> **Module:** 01 - Linux
> **Chapter:** 03 - Linux Commands

---

# Learning Objectives

After completing this chapter, you will be able to:

* Navigate the Linux filesystem confidently.
* Display files and directories.
* Create, copy, move, and delete files.
* View file contents.
* Understand absolute and relative paths.
* Use essential Linux commands used in daily administration and Product Security.

---

# Why This Matters

Linux is primarily operated through the command line.

Whether you are:

* Product Security Engineer
* DevSecOps Engineer
* Cloud Engineer
* Linux Administrator
* SRE

you will use Linux commands every day.

---

# Command Categories

This chapter covers:

* Navigation
* File Operations
* Directory Operations
* Viewing Files
* Searching
* Help Commands

---

# 1. pwd (Print Working Directory)

Displays the current directory.

```bash
pwd
```

Example

```text
/home/amar
```

---

# 2. whoami

Displays the currently logged-in user.

```bash
whoami
```

Example

```text
amar
```

---

# 3. hostname

Displays the system hostname.

```bash
hostname
```

Example

```text
ubuntu-dev
```

---

# 4. cd (Change Directory)

Move between directories.

Go to root

```bash
cd /
```

Go to home

```bash
cd ~
```

Go to previous directory

```bash
cd -
```

Go up one level

```bash
cd ..
```

---

# Absolute vs Relative Paths

Absolute path

```text
/etc/ssh/sshd_config
```

Relative path

```text
Documents/project
```

Example

```bash
cd /etc
```

Example

```bash
cd ../home
```

---

# 5. ls

Lists directory contents.

```bash
ls
```

Long listing

```bash
ls -l
```

Hidden files

```bash
ls -a
```

Human-readable sizes

```bash
ls -lh
```

Recursive

```bash
ls -R
```

---

# 6. mkdir

Creates directories.

```bash
mkdir test
```

Nested directories

```bash
mkdir -p project/docs/images
```

---

# 7. touch

Creates an empty file.

```bash
touch notes.txt
```

---

# 8. cp

Copies files.

```bash
cp file1.txt file2.txt
```

Copy directory

```bash
cp -r project backup
```

---

# 9. mv

Moves or renames files.

Rename

```bash
mv old.txt new.txt
```

Move

```bash
mv file.txt /tmp/
```

---

# 10. rm

Delete files.

```bash
rm file.txt
```

Delete directory

```bash
rm -r project
```

Force delete

```bash
rm -rf project
```

⚠ **Use `rm -rf` carefully.**

---

# 11. cat

Displays file contents.

```bash
cat file.txt
```

---

# 12. less

View large files one page at a time.

```bash
less /var/log/syslog
```

Exit

```text
q
```

---

# 13. head

Displays first 10 lines.

```bash
head file.txt
```

First 20 lines

```bash
head -20 file.txt
```

---

# 14. tail

Displays last 10 lines.

```bash
tail file.txt
```

Live log monitoring

```bash
tail -f /var/log/syslog
```

---

# 15. echo

Print text or variables.

```bash
echo Hello
```

Display home directory

```bash
echo $HOME
```

---

# 16. find

Search for files.

```bash
find /home -name "*.txt"
```

Find directories

```bash
find . -type d
```

---

# 17. which

Find executable location.

```bash
which curl
```

Example

```text
/usr/bin/curl
```

---

# 18. man

Displays manual pages.

```bash
man ls
```

Search

```bash
/permission
```

Quit

```text
q
```

---

# 19. clear

Clears the terminal.

```bash
clear
```

Shortcut

```text
Ctrl + L
```

---

# Useful Keyboard Shortcuts

| Shortcut | Purpose                |
| -------- | ---------------------- |
| Ctrl + C | Stop running command   |
| Ctrl + L | Clear screen           |
| Ctrl + R | Search command history |
| Tab      | Auto-complete          |
| ↑        | Previous command       |
| ↓        | Next command           |

---

# Practical Example

Create a project.

```bash
mkdir linux-lab

cd linux-lab

touch notes.txt

ls

pwd

cat notes.txt
```

---

# Real Production Example

Suppose an application is failing.

Typical investigation:

```text
SSH

↓

cd /var/log

↓

ls

↓

tail -f application.log

↓

cat config

↓

find log files
```

Almost every Linux troubleshooting session begins with these commands.

---

# Product Security Perspective

A Product Security Engineer uses these commands to:

* Investigate logs
* Locate configuration files
* Review application files
* Search for indicators of compromise
* Verify installed binaries
* Inspect directories
* Collect forensic evidence

Example

```bash
find / -name "*.pem"
```

Locate certificate files.

Example

```bash
tail -f /var/log/auth.log
```

Monitor authentication logs.

---

# Hands-on Lab

Run the following commands:

```bash
pwd

whoami

hostname

mkdir linux-practice

cd linux-practice

touch demo.txt

ls -lah

echo "Linux Practice" > demo.txt

cat demo.txt

cp demo.txt backup.txt

mv backup.txt renamed.txt

find . -name "*.txt"

which curl

head demo.txt

tail demo.txt
```

---

# Common Mistakes

❌ Running `rm -rf` without checking the path.

❌ Using relative paths from the wrong directory.

❌ Editing system files without backup.

❌ Forgetting to check permissions.

---

# Interview Questions

### What does `pwd` do?

Displays the current working directory.

---

### Difference between `cp` and `mv`?

* `cp` copies files.
* `mv` moves or renames files.

---

### Difference between `cat`, `less`, and `tail`?

* `cat` displays the whole file.
* `less` displays one page at a time.
* `tail` displays the last lines and can monitor live logs.

---

### What does `which` do?

Displays the path of an executable.

---

### Why use `find`?

To search for files or directories based on name, type, permissions, or other criteria.

---

### Why is `tail -f` useful?

It allows real-time monitoring of log files as new entries are written.

---

# Key Takeaways

* Linux command-line skills are essential for system administration and Product Security.
* Learn navigation before advanced commands.
* Always verify your current directory before modifying files.
* Use `find`, `tail`, and `less` frequently during troubleshooting.
* Be cautious with destructive commands like `rm -rf`.

---

# References

* Linux man pages (`man ls`, `man cp`, `man mv`, `man find`)
* https://man7.org/linux/man-pages/
* GNU Core Utilities Documentation