# Processes

> **Module:** 01 - Linux
> **Chapter:** 05 - Processes

---

# Learning Objectives

After completing this chapter, you will be able to:

* Understand what a process is.
* Differentiate between a program and a process.
* Understand Process ID (PID) and Parent Process ID (PPID).
* View and manage running processes.
* Understand process states.
* Work with foreground and background processes.
* Send signals to processes.
* Understand zombie and orphan processes.
* Explain process management from a Product Security perspective.

---

# Why This Matters

Every application running on Linux executes as one or more **processes**.

Examples:

* Nginx
* Docker
* Kubernetes components
* SSH Server
* Database Server
* Security tools

As a Product Security Engineer, you will frequently inspect running processes during troubleshooting, security investigations, and incident response.

---

# What is a Process?

A **program** is a file stored on disk.

A **process** is a running instance of that program.

Example:

```text
/usr/bin/nginx     → Program

Running nginx      → Process
```

One program can create multiple processes.

---

# Program vs Process

| Program                     | Process                   |
| --------------------------- | ------------------------- |
| Static                      | Running                   |
| Stored on disk              | Exists in memory          |
| Passive                     | Active                    |
| Can exist without execution | Exists only while running |

---

# Process Lifecycle

```text
Program
   │
   ▼
Created
   │
   ▼
Running
   │
   ▼
Sleeping / Waiting
   │
   ▼
Stopped
   │
   ▼
Terminated
```

---

# Process ID (PID)

Every running process has a unique **Process ID (PID)**.

Example:

```bash
ps
```

Output:

```text
PID TTY          TIME CMD
2458 pts/0    00:00:00 bash
2510 pts/0    00:00:00 ps
```

---

# Parent Process ID (PPID)

Every process is created by another process.

Example:

```bash
ps -ef
```

Example output:

```text
UID      PID   PPID  CMD
root       1      0  systemd
amar    2458      1  bash
amar    2600   2458  vim
```

Here:

* `bash` created `vim`
* `bash` is the parent process.

---

# Viewing Processes

## ps

Display current shell processes.

```bash
ps
```

---

## ps -ef

Display all running processes.

```bash
ps -ef
```

---

## ps aux

Commonly used to display detailed process information.

```bash
ps aux
```

---

# top

Real-time process monitoring.

```bash
top
```

Shows:

* CPU usage
* Memory usage
* Running processes
* Load average

Exit:

```text
q
```

---

# htop

Improved interactive version of `top`.

```bash
htop
```

Install (Ubuntu):

```bash
sudo apt install htop
```

---

# Process States

| State | Meaning               |
| ----- | --------------------- |
| R     | Running               |
| S     | Sleeping              |
| D     | Uninterruptible Sleep |
| T     | Stopped               |
| Z     | Zombie                |

View process state:

```bash
ps -el
```

---

# Foreground Process

Runs directly in the terminal.

Example:

```bash
sleep 100
```

The terminal waits until the command finishes.

Stop:

```text
Ctrl + C
```

---

# Background Process

Run in background:

```bash
sleep 100 &
```

View jobs:

```bash
jobs
```

Bring back:

```bash
fg
```

Move to background:

```bash
bg
```

---

# Killing Processes

## kill

Terminate by PID.

```bash
kill 2458
```

---

## kill -9

Force terminate.

```bash
kill -9 2458
```

Use only when necessary.

---

## killall

Kill processes by name.

```bash
killall firefox
```

---

## pkill

Kill using pattern matching.

```bash
pkill nginx
```

---

# Signals

Signals notify processes about events.

Common signals:

| Signal  | Number | Purpose              |
| ------- | -----: | -------------------- |
| SIGTERM |     15 | Graceful termination |
| SIGKILL |      9 | Force kill           |
| SIGINT  |      2 | Ctrl + C             |
| SIGHUP  |      1 | Reload configuration |

Example:

```bash
kill -15 PID
```

---

# Zombie Process

A process that has finished execution but still has an entry in the process table because its parent has not collected its exit status.

State:

```text
Z
```

---

# Orphan Process

A child process whose parent has exited.

Linux automatically reassigns orphan processes to:

```text
systemd
```

(or `init` on older systems).

---

# Useful Commands

Display all processes:

```bash
ps -ef
```

Search for a process:

```bash
ps -ef | grep ssh
```

Display process tree:

```bash
pstree
```

Display current jobs:

```bash
jobs
```

---

# Practical Example

Find the SSH server process:

```bash
ps -ef | grep ssh
```

Monitor CPU usage:

```bash
top
```

Kill a test process:

```bash
sleep 300 &
jobs
kill %1
```

---

# In Real Production

Example:

```text
Internet
     │
     ▼
Nginx Process
     │
     ▼
Application Process
     │
     ▼
Database Process
```

Each service runs as one or more Linux processes.

Monitoring these processes helps identify failures and performance issues.

---

# Product Security Perspective

A Product Security Engineer may:

* Detect suspicious processes.
* Identify unauthorized applications.
* Investigate high CPU or memory usage.
* Verify that security agents are running.
* Monitor long-running background processes.
* Terminate malicious processes.

Examples:

Check running SSH processes:

```bash
ps -ef | grep ssh
```

Monitor processes:

```bash
top
```

Find Java processes:

```bash
ps -ef | grep java
```

---

# Hands-on Lab

Run:

```bash
ps

ps -ef

ps aux

top
```

Start a background process:

```bash
sleep 120 &
```

View jobs:

```bash
jobs
```

Bring to foreground:

```bash
fg
```

Run again:

```bash
sleep 120 &
```

Terminate it:

```bash
jobs

kill %1
```

(Optional)

Install `htop`:

```bash
sudo apt update
sudo apt install htop

htop
```

---

# Common Mistakes

* Using `kill -9` before trying `SIGTERM`.
* Running unnecessary background processes.
* Ignoring zombie processes.
* Forgetting to monitor resource usage.
* Killing the wrong PID.

---

# Interview Questions

### What is a process?

A running instance of a program.

---

### Difference between a program and a process?

A program is stored on disk; a process is the running instance in memory.

---

### What is PID?

A unique Process ID assigned to every running process.

---

### What is PPID?

The Parent Process ID that identifies the process which created the current process.

---

### Difference between `ps`, `top`, and `htop`?

* `ps` displays a snapshot of processes.
* `top` provides real-time monitoring.
* `htop` is an interactive process viewer.

---

### What is a zombie process?

A terminated process that still exists in the process table until its parent collects the exit status.

---

### What is an orphan process?

A child process whose parent has exited; Linux reassigns it to `systemd` (or `init` on older systems).

---

### Difference between `kill` and `kill -9`?

* `kill` (SIGTERM) requests graceful termination.
* `kill -9` (SIGKILL) forcefully terminates the process without allowing cleanup.

---

# Key Takeaways

* Every running application is a process.
* Every process has a unique PID.
* Processes can run in the foreground or background.
* Learn `ps`, `top`, `htop`, `kill`, and `jobs`.
* Use `SIGTERM` before `SIGKILL`.
* Understanding processes is essential for Linux administration and Product Security.

---

# References

* Linux `man ps`
* Linux `man top`
* Linux `man kill`
* Linux `man signal`
* https://man7.org/linux/man-pages/