# Linux Introduction

> **Module:** 01 - Linux
> **Chapter:** 01 - Linux Introduction

---

# Objective

After completing this chapter, you will be able to:

* Understand what Linux is and why it was created.
* Differentiate Linux from Unix and Windows.
* Explain the Linux architecture.
* Understand the roles of the Kernel and Shell.
* Identify major Linux distributions.
* Understand why Linux dominates servers, cloud platforms, containers, and cybersecurity.
* Explain why Linux knowledge is essential for Product Security Engineers.

---

# What is Linux?

Linux is a free and open-source operating system kernel created by **Linus Torvalds** in 1991.

An operating system manages hardware resources and provides an environment where applications can run.

Linux is used in:

* Servers
* Cloud platforms
* Containers
* Mobile devices (Android uses the Linux kernel)
* Embedded systems
* Supercomputers
* Security appliances

Today, Linux powers a significant portion of the world's servers and cloud infrastructure.

---

# What is an Operating System?

An Operating System (OS) acts as a bridge between hardware and software.

```text
+---------------------------+
| Applications              |
+---------------------------+
| Operating System          |
+---------------------------+
| CPU | Memory | Disk | NIC |
+---------------------------+
```

Without an operating system:

* Programs cannot access hardware directly.
* Memory cannot be managed safely.
* Multiple applications cannot run efficiently.

---

# Brief History

## Unix (1969)

Unix was developed at Bell Labs and introduced many concepts still used today.

Examples:

* Hierarchical filesystem
* Multi-user support
* Multitasking
* Shell

---

## GNU Project (1983)

Richard Stallman started the GNU Project to build a free Unix-like operating system.

Many user-space tools such as `bash`, `grep`, `ls`, and `cp` come from GNU.

---

## Linux Kernel (1991)

Linus Torvalds created the Linux kernel.

The GNU tools and Linux kernel together formed what is commonly known as a Linux operating system.

---

# Linux vs Unix

| Linux                         | Unix                                |
| ----------------------------- | ----------------------------------- |
| Open Source                   | Mostly Proprietary                  |
| Free                          | Usually Licensed                    |
| Community Driven              | Vendor Driven                       |
| Runs on almost every platform | Vendor-specific implementations     |
| Widely used in Cloud          | Common in enterprise legacy systems |

---

# Linux Architecture

```text
+------------------------------------+
| Applications                       |
+------------------------------------+
| Shell (bash, zsh, sh)              |
+------------------------------------+
| Linux Kernel                       |
+------------------------------------+
| Hardware                           |
+------------------------------------+
```

---

# Kernel

The kernel is the core of Linux.

Responsibilities include:

* Process management
* Memory management
* Device drivers
* Filesystem management
* Networking
* Security

Users never interact directly with the kernel.

Instead:

```text
User
   │
Shell
   │
Kernel
   │
Hardware
```

---

# Shell

The shell is the command interpreter.

It receives commands from users and requests services from the kernel.

Popular shells:

* Bash
* Zsh
* Fish
* sh

Example:

```bash
pwd
```

The shell sends the request to the kernel, which returns the current directory.

---

# Linux Filesystem

Unlike Windows, Linux has a **single filesystem hierarchy**.

Everything begins from:

```text
/
```

Example:

```text
/
├── bin
├── boot
├── dev
├── etc
├── home
├── root
├── usr
├── var
```

You will study these directories in detail in the next chapter.

---

# Linux Distributions

A Linux distribution combines:

* Linux Kernel
* GNU utilities
* Package manager
* Desktop environment (optional)
* Additional software

Common distributions:

| Distribution                    | Typical Use               |
| ------------------------------- | ------------------------- |
| Ubuntu                          | Beginners, Servers, Cloud |
| Debian                          | Stable Servers            |
| Red Hat Enterprise Linux (RHEL) | Enterprise                |
| Rocky Linux                     | Enterprise                |
| AlmaLinux                       | Enterprise                |
| Fedora                          | Development               |
| Kali Linux                      | Security Testing          |
| Arch Linux                      | Advanced Users            |

---

# Why Linux Dominates Cloud Computing

Most cloud providers primarily run Linux.

Examples:

* AWS EC2
* Microsoft Azure
* Google Cloud
* Kubernetes clusters
* Docker containers

Reasons:

* Stable
* Secure
* Highly customizable
* Excellent networking
* Automation friendly
* Efficient resource usage

---

# Linux in Product Security

Linux is one of the most important skills for Product Security Engineers.

Typical responsibilities include:

* Reviewing logs
* Investigating incidents
* Running security tools
* Performing vulnerability assessments
* Managing containers
* Working with Kubernetes
* Writing automation scripts
* Testing APIs
* Hardening servers

Most security tools are designed to run on Linux.

Examples:

* Nmap
* OpenSCAP
* Trivy
* Falco
* Wireshark
* tcpdump
* OpenSSL

---

# Real-World Example

Imagine an e-commerce application running in AWS.

```text
Customer
      │
Internet
      │
Load Balancer
      │
Ubuntu Server
      │
Docker
      │
Application
      │
Database
```

A Product Security Engineer may need to:

* Check logs
* Verify running processes
* Inspect network connections
* Review permissions
* Validate TLS certificates
* Investigate suspicious activity

Linux knowledge is essential for each of these tasks.

---

# Hands-on Lab

Open your Linux terminal (WSL or Linux VM).

Run:

```bash
uname -a
```

```bash
cat /etc/os-release
```

```bash
hostname
```

```bash
whoami
```

```bash
pwd
```

Questions:

1. Which Linux distribution are you using?
2. What kernel version is installed?
3. Which user are you logged in as?
4. What is your current working directory?

---

# Common Mistakes

* Thinking Linux is only for hackers.
* Assuming Linux and Ubuntu are the same thing.
* Believing the shell and kernel are the same.
* Ignoring command-line skills in favor of graphical tools.

---

# Interview Questions

### 1. What is Linux?

Linux is an open-source operating system kernel used to build complete operating systems.

---

### 2. Who created Linux?

Linus Torvalds in 1991.

---

### 3. What is the difference between the Kernel and the Shell?

* **Kernel:** Core of the operating system that manages hardware and system resources.
* **Shell:** Command interpreter that allows users to interact with the kernel.

---

### 4. Why is Linux widely used in cloud computing?

Because it is stable, secure, efficient, highly customizable, and well suited for automation and containerized workloads.

---

### 5. Why should a Product Security Engineer learn Linux?

Because most production servers, cloud platforms, containers, and security tools run on Linux.

---

# Summary

In this chapter you learned:

* What Linux is
* The history of Linux
* Linux vs Unix
* Operating system basics
* Linux architecture
* Kernel vs Shell
* Linux distributions
* Why Linux dominates cloud computing
* Why Linux is important for Product Security

The next chapter covers the **Linux Filesystem**, where you'll explore directories such as `/etc`, `/home`, `/var`, `/usr`, `/tmp`, and `/root` in detail.

---

# References

* https://www.kernel.org/
* https://www.gnu.org/
* https://ubuntu.com/
* Linux man pages (`man intro`, `man hier`)