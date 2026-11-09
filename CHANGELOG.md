# Changelog

All notable changes to this handbook are recorded here.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Linux chapters 06–13: Networking, systemd & Services, Package Management, Logs, Storage, Shell Scripting, Security Hardening, Interview Questions.
- `labs/README.md`: how to run labs on Windows (WSL2), Linux and macOS (Multipass, VMs, Docker).
- `labs/linux/scripts/linux-security-audit.sh`: read-only security baseline script used in the labs.
- `cheatsheets/linux-cheatsheet.md`: Linux quick reference, basic to advanced.
- GitHub CLI (`gh`) setup section in `00-Development-Environment/05-GitHub-SSH-Authentication.md`, including secure token storage and revocation.
- Development Environment chapters 01–04 (Git, GitHub account security, VS Code, first repository) and module README.
- `labs/home-lab-kvm.md`: Windows + Linux VMs with KVM/virt-manager; SSH, SFTP, PowerShell 7 remoting, RDP labs.
- `LICENSE` (MIT), `CONTRIBUTING.md`, `SECURITY.md`, `docs/README.md`, `projects/README.md`, `templates/lab-notes-template.md`.
- GitHub Actions checks (ShellCheck, internal Markdown links) and Dependabot for Actions.

### Changed

- Rewrote Linux chapters 01–05 with basic → advanced levels, Product Security sections, and step-by-step labs.
- `01-Linux/README.md`: learning path, lab environment matrix, progress tracker and capstone.
- `README.md`: "Start Here" section, module status, linked chapters.

### Fixed

- `/etc/shadow` permissions on Debian/Ubuntu are `640 root:shadow`, not `400`.
- `cd /root` fails for normal users; the earlier example showed it succeeding.
- `/bin`, `/sbin` and `/lib` are symlinks to `/usr` on modern distributions.
- SIGHUP's default action is to terminate; reloading config on SIGHUP is a convention some daemons follow.
