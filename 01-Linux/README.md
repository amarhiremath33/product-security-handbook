# 🐧 Module 01 — Linux

> From your first `ls` to hardening a server — with a Product Security lens on every chapter.

Almost everything a Product Security Engineer touches — servers, containers, Kubernetes nodes, CI runners, cloud VMs, security tools — runs on Linux. This module takes you from zero to confidently investigating and hardening a Linux system.

---

## Learning Path

| # | Chapter | Level | You will be able to… |
|:-:|---|:-:|---|
| 01 | [Linux Introduction](01-Linux-Introduction.md) | 🟢 | Explain kernel vs shell, user vs kernel space, the boot process |
| 02 | [Linux Filesystem](02-Linux-Filesystem.md) | 🟢 | Find configs, logs, binaries; understand inodes and links |
| 03 | [Linux Commands](03-Linux-Commands.md) | 🟢→🟡 | Navigate, manipulate files, use pipes, `grep`, `find`, `awk`, `sed` |
| 04 | [Users, Groups & Permissions](04-Users-Groups-Permissions.md) | 🟡 | Manage users, sudo, permissions, SUID, ACLs, capabilities |
| 05 | [Processes](05-Processes.md) | 🟡 | Inspect, signal and investigate processes via `/proc` |
| 06 | [Linux Networking](06-Linux-Networking.md) | 🟡 | Read IPs, routes, ports, DNS; capture traffic |
| 07 | [systemd & Services](07-Systemd-and-Services.md) | 🟡→🔴 | Write and sandbox your own service |
| 08 | [Package Management](08-Package-Management.md) | 🟡 | Install safely, add signed repos, track vulnerabilities |
| 09 | [Logs](09-Logs.md) | 🟡→🔴 | Investigate logins, sudo use and attacks with logs |
| 10 | [Storage](10-Storage.md) | 🔴 | Partition, mount, LVM, encryption, secure mount options |
| 11 | [Shell Scripting](11-Shell-Scripting.md) | 🔴 | Write safe, robust Bash automation |
| 12 | [Linux Security Hardening](12-Linux-Security-Hardening.md) | 🔴 | Harden SSH, firewall, kernel, services; audit with Lynis |
| 13 | [Linux Interview Questions](13-Linux-Interview-Questions.md) | 🟢→🔴 | Answer basic, scenario and Product Security questions |

🟢 Basic · 🟡 Intermediate · 🔴 Advanced

**Quick reference:** [Linux Cheat Sheet](../cheatsheets/linux-cheatsheet.md)

---

## Before You Start: Set Up a Lab

Read **[labs/README.md](../labs/README.md)** first. In short:

| You use | Do this |
|---|---|
| **Windows** | Install WSL2 Ubuntu (`wsl --install -d Ubuntu`). Add a Multipass VM for chapters 07, 10, 12. |
| **Linux** | Create a Multipass VM (`multipass launch --name lab`). Don't run ⚠️ labs on your own machine. |
| **macOS** | Multipass VM (`brew install --cask multipass`). |

Which environment each chapter needs:

| Chapter | WSL2 | Docker | VM |
|---|:-:|:-:|:-:|
| 01–05, 11 | ✅ | ✅ | ✅ |
| 06 Networking | ✅ | ⚠️ limited | ✅ |
| 07 systemd | ✅ with systemd enabled | ❌ | ✅ |
| 08 Packages | ✅ | ✅ | ✅ |
| 09 Logs | ✅ (use `journalctl`) | ❌ | ✅ |
| 10 Storage | ⚠️ loop devices only | ❌ | ✅ |
| 12 Hardening | ⚠️ partial | ❌ | ✅ |

---

## How Every Chapter Is Structured

1. **Objectives** — what you'll be able to do
2. **Theory** — how it works, with diagrams
3. **Commands** — grouped 🟢 Basic → 🟡 Intermediate → 🔴 Advanced, each with an example
4. **In Production** — how it's used on real systems
5. **Product Security Perspective** — attacks, misconfigurations, what to check
6. **Hands-on Lab** — step-by-step, with expected results
7. **Common Mistakes**
8. **Interview Questions** — with answers
9. **Summary & References**

---

## Progress Tracker

Copy this into your notes and tick items off as you finish each lab.

- [ ] 01 Linux Introduction
- [ ] 02 Linux Filesystem
- [ ] 03 Linux Commands
- [ ] 04 Users, Groups & Permissions
- [ ] 05 Processes
- [ ] 06 Linux Networking
- [ ] 07 systemd & Services
- [ ] 08 Package Management
- [ ] 09 Logs
- [ ] 10 Storage
- [ ] 11 Shell Scripting
- [ ] 12 Linux Security Hardening
- [ ] 13 Linux Interview Questions
- [ ] **Capstone:** run [`linux-security-audit.sh`](../labs/linux/scripts/linux-security-audit.sh) on a fresh VM, harden it with chapter 12, run it again and compare

---

## Module Capstone

On a fresh lab VM:

1. Run the audit script and save the output: `sudo bash linux-security-audit.sh > before.txt`
2. Apply the hardening steps from chapter 12.
3. Deploy the sandboxed service from chapter 07.
4. Run the audit again: `sudo bash linux-security-audit.sh > after.txt`
5. Compare: `diff before.txt after.txt`
6. Write a short report (`capstone-report.md`): what you found, what you fixed, what risk remains.

That report is a great portfolio piece for Product Security interviews.
