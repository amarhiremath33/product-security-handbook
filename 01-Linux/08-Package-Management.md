# 08 — Package Management

> **Module:** 01 – Linux · **Level:** 🟡 Intermediate → 🔴 Advanced · **Time:** ~2 hours
> **Lab environment:** WSL2, Docker or VM — see [labs/README.md](../labs/README.md)

---

## Objectives

After this chapter you will be able to:

- Install, upgrade, remove and query software with `apt` and `dpkg` (and know the `dnf`/`rpm` equivalents).
- Explain repositories, signing keys and why package signatures matter.
- Add a third-party repository **securely** (with a real example: the GitHub CLI).
- Pin, hold and downgrade packages.
- Find out whether a system has pending security updates and verify installed files.
- Explain package management as part of the software supply chain.

---

## Why Package Managers?

A package manager installs software **with its dependencies**, tracks every file it owns, verifies **signatures**, and upgrades or removes it cleanly. Downloading random binaries and `curl | bash` scripts does none of that.

```text
 Repository (HTTPS or HTTP mirror)
 ┌──────────────────────────────────────┐
 │ InRelease  ← signed by the repo's GPG key
 │   └── lists hashes of Packages files
 │ Packages   ← list of packages + SHA256 of each .deb
 │ pool/…/nginx_1.24.0-2_amd64.deb
 └──────────────────────────────────────┘
          │  apt update   (download + verify the signed index)
          ▼
 Local cache /var/lib/apt/lists
          │  apt install nginx   (download .deb, check its hash against the signed index)
          ▼
 dpkg unpacks files, runs install scripts, records them in /var/lib/dpkg
```

The chain of trust: **GPG key → signed index → hash of every package**. Even if a mirror is compromised, tampered packages fail verification.

---

## Debian vs Red Hat Families

| Task | Debian / Ubuntu | RHEL / Rocky / Fedora |
|---|---|---|
| Refresh package lists | `apt update` | `dnf check-update` (automatic) |
| Install | `apt install nginx` | `dnf install nginx` |
| Remove | `apt remove nginx` | `dnf remove nginx` |
| Upgrade everything | `apt upgrade` | `dnf upgrade` |
| Search | `apt search nginx` | `dnf search nginx` |
| Info | `apt show nginx` | `dnf info nginx` |
| Which package owns a file | `dpkg -S /usr/sbin/nginx` | `rpm -qf /usr/sbin/nginx` |
| Files in a package | `dpkg -L nginx` | `rpm -ql nginx` |
| Install a local file | `apt install ./pkg.deb` | `dnf install ./pkg.rpm` |
| Verify installed files | `dpkg --verify` / `debsums` | `rpm -Va` |
| Security updates only | `unattended-upgrades` | `dnf upgrade --security` |
| History | `/var/log/apt/history.log` | `dnf history` |
| Repo config | `/etc/apt/sources.list.d/` | `/etc/yum.repos.d/` |

Alpine (common in containers) uses `apk add`, `apk del`, `apk upgrade`.

---

## 🟢 Everyday `apt`

```bash
sudo apt update                    # refresh package lists — always first
apt list --upgradable              # what can be upgraded
sudo apt upgrade                   # upgrade installed packages (never removes)
sudo apt full-upgrade              # upgrade, adding/removing packages if needed (kernel updates, transitions)
sudo apt install htop tree         # install
sudo apt install -y nginx          # without the confirmation prompt (scripts)
sudo apt install --no-install-recommends curl   # fewer extra packages (smaller attack surface)
sudo apt remove nginx              # remove, keep config files
sudo apt purge nginx               # remove including config
sudo apt autoremove                # remove dependencies nothing needs any more
sudo apt clean                     # empty the download cache (/var/cache/apt/archives)

apt search "json processor"        # search names and descriptions
apt show jq                        # details: version, size, dependencies, homepage
apt list --installed | wc -l       # how many packages are installed
apt-cache policy nginx             # installed vs available version and from which repo
apt-cache depends nginx            # dependencies
apt-cache rdepends --installed libssl3   # what depends on this library (CVE triage!)
```

> `apt` is for humans. In scripts, `apt-get` and `apt-cache` have a stable output format.

### Is a reboot needed?

```bash
ls /var/run/reboot-required 2>/dev/null && cat /var/run/reboot-required.pkgs
sudo needrestart -r l             # which services still use old libraries (sudo apt install needrestart)
```

Updating a library on disk doesn't fix processes already running with the old version in memory — they need a restart.

---

## 🟢 `dpkg` — the Low-Level Tool

```bash
dpkg -l | grep ssh                 # installed packages matching ssh (ii = installed)
dpkg -l openssh-server             # status of one package
dpkg -L openssh-server             # files it installed
dpkg -S /usr/bin/ssh               # which package owns this file
dpkg -s openssh-server             # status and metadata
sudo dpkg -i package.deb           # install a .deb (doesn't fetch dependencies — prefer apt install ./package.deb)
dpkg -c package.deb                # list files inside a .deb before installing
dpkg-deb -I package.deb            # metadata and install scripts in a .deb
```

---

## 🟡 Snap and Flatpak

Self-contained packages with bundled dependencies, auto-updating, sandboxed.

```bash
snap list
snap find vlc
sudo snap install code --classic   # --classic = no sandbox confinement
sudo snap remove --purge firefox
snap refresh --list                # pending updates
snap connections firefox           # what the snap is allowed to access
```

| | apt (.deb) | snap |
|---|---|---|
| Dependencies | Shared system libraries | Bundled inside |
| Updates | When you run `apt upgrade` | Automatic |
| Sandbox | No | Yes (unless `--classic`) |
| Security fixes for libraries | Fixed once for the whole system | Each snap publisher must rebuild |

---

## 🟡 Repositories and Signing Keys

### Where repositories are configured

```bash
ls /etc/apt/sources.list.d/
cat /etc/apt/sources.list.d/ubuntu.sources     # Ubuntu 24.04+ (deb822 format)
cat /etc/apt/sources.list                       # older releases
ls /etc/apt/keyrings/ /usr/share/keyrings/      # repository signing keys
```

Ubuntu components: **main** (supported by Canonical), **universe** (community), **restricted** (proprietary drivers), **multiverse** (non-free). `-security` suites carry security fixes; `-updates` carries other fixes.

### Adding a third-party repository — the secure way

**Real example:** Ubuntu 22.04's own `gh` package is version 2.4.0 (from 2022). It is too old to store its token in the system keyring, so it saves it in plain text. The fix is to install `gh` from GitHub's official repository:

```bash
# 1. Download the vendor's signing key into a dedicated keyring file
sudo mkdir -p -m 755 /etc/apt/keyrings
wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

# 2. Add the repository, trusting that key ONLY for this repository (signed-by=)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# 3. Install
sudo apt update && sudo apt install gh
apt-cache policy gh        # confirm the version comes from cli.github.com
```

Why `signed-by=` matters:

| Old way (deprecated) | New way |
|---|---|
| `apt-key add key.gpg` | Key saved in `/etc/apt/keyrings/vendor.gpg` |
| Key trusted for **every** repository | Key trusted **only** for the repo that names it |
| A compromised vendor key could sign fake Ubuntu packages | Damage limited to that vendor's packages |

> 🔐 Before adding any repository, ask: do I trust this vendor with **root on this machine**? Package install scripts run as root.

### PPAs

```bash
sudo add-apt-repository ppa:<user>/<ppa>    # Ubuntu Personal Package Archive
sudo add-apt-repository --remove ppa:<user>/<ppa>
```

A PPA is maintained by an individual or team, not Canonical. Treat it like any third-party repository.

---

## 🔴 Holding, Pinning and Downgrading

```bash
sudo apt-mark hold nginx           # never upgrade it (e.g. while testing compatibility)
apt-mark showhold
sudo apt-mark unhold nginx

apt list -a nginx                  # all available versions
sudo apt install nginx=1.24.0-2ubuntu7   # install a specific version (downgrade)
```

Pinning with priorities (`/etc/apt/preferences.d/`) — e.g. never install Firefox from apt:

```text
Package: firefox*
Pin: release o=Ubuntu
Pin-Priority: -1
```

Priority `< 0` = never install, `100` = installed but not upgraded automatically, `500` = default, `> 1000` = allow downgrades.

> Holding a package means **you stop getting its security fixes**. Track every hold and remove it as soon as possible.

---

## 🔴 Security Updates

### Automatic security updates

```bash
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades    # enable
cat /etc/apt/apt.conf.d/50unattended-upgrades       # which origins get auto-installed
cat /etc/apt/apt.conf.d/20auto-upgrades
sudo unattended-upgrade --dry-run --debug | tail    # test
less /var/log/unattended-upgrades/unattended-upgrades.log
```

### Which updates are security fixes?

```bash
apt list --upgradable 2>/dev/null | grep -- -security
```

### Is my system affected by a CVE?

The OpenSSL library package is `libssl3` on Ubuntu 22.04 and `libssl3t64` on 24.04. Find the right name with `dpkg -l 'libssl*'`.

```bash
dpkg -l openssl libssl3            # installed version
apt-cache policy libssl3           # available fixed version?
apt changelog libssl3 | grep -m5 CVE   # which CVEs this version fixes
```

Then compare with the distro's advisory: Ubuntu CVE tracker (https://ubuntu.com/security/cves) or `pro fix CVE-XXXX-YYYY` on Ubuntu Pro. Note that distributions **backport** fixes: `openssl 3.0.2-0ubuntu1.18` may contain a fix that upstream only shipped in `3.0.15`. Scanners that compare raw upstream versions produce false positives.

### Verifying installed files

```bash
sudo dpkg --verify                 # files changed since installation (missing output = OK)
sudo apt install debsums
sudo debsums -s                    # only report changed files
sudo debsums -c openssh-server     # check one package
```

`dpkg --verify` output like `??5??????   /usr/bin/ssh` means the file's MD5 no longer matches the package — a binary was replaced. Config files under `/etc` change legitimately; binaries in `/usr` should not.

---

## In Production

- Base images and VMs are built from a pinned, scanned OS version, then patched on a schedule.
- Security updates are applied automatically (`unattended-upgrades`) or within an SLA (e.g. critical CVEs in 7 days).
- Kernel and glibc/openssl updates require reboots or service restarts — `needrestart` and `/var/run/reboot-required` tell you.
- Container images are **rebuilt**, not patched in place: `apt-get update && apt-get upgrade` in the Dockerfile, then redeploy.
- Production servers don't pull from random PPAs or `curl | bash`.

Minimal, secure Dockerfile pattern:

```dockerfile
FROM ubuntu:24.04
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*
```

---

## Product Security Perspective

Package management **is** software supply-chain security.

| Risk | Example | Control |
|---|---|---|
| Unpatched known vulnerabilities | Old `openssl`, `sudo` (Baron Samedit, CVE-2021-3156) | Automatic security updates, image rebuilds, scanners |
| Malicious or compromised repository | Third-party repo key stolen | `signed-by=`, minimal third-party repos, review before adding |
| Unsigned / unverified downloads | `curl https://x.sh \| sudo bash` | Download, inspect, verify checksum/signature first |
| Typosquatting | `pip install reqeusts`, npm lookalikes | Pin dependencies, use lockfiles and private mirrors |
| Install scripts run as root | Malicious `postinst` in a `.deb` | Inspect with `dpkg-deb -I`, `dpkg-deb -e` |
| Unneeded packages | Compilers, `netcat`, `telnet` on prod | Minimal images, `--no-install-recommends`, remove extras |
| End-of-life OS | No more security fixes | Track EOL dates, upgrade proactively |

Useful commands in an assessment:

```bash
cat /etc/os-release                                   # still supported?
apt list --upgradable 2>/dev/null | grep -c security  # missing security updates
grep -rh '^deb\|^URIs' /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null   # repos in use
ls /etc/apt/trusted.gpg 2>/dev/null && echo "WARNING: legacy global keyring in use"
grep -E ' (install|upgrade|remove) ' /var/log/dpkg.log | tail      # recent changes
dpkg -l | grep -E 'telnet|netcat|nmap|gcc|tcpdump'    # tools attackers love to find
```

Scanners you'll meet later: **Trivy** and **Grype** (images, filesystems, SBOMs), **OSV-Scanner**, Ubuntu `pro security-status`.

---

## Hands-on Lab 🟢→🔴

### Part 1 — Basics 🟢

```bash
sudo apt update
apt list --upgradable 2>/dev/null | head
sudo apt install -y jq tree
jq --version
dpkg -L jq
dpkg -S "$(which jq)"
apt show jq 2>/dev/null | grep -E 'Version|Depends|Homepage'
sudo apt remove -y tree && sudo apt autoremove -y
```

### Part 2 — Investigate a package 🟡

```bash
apt-cache policy openssh-server
apt-cache depends openssh-server | head
dpkg -l 'libssl*' | grep ^ii                                     # libssl3 or libssl3t64?
apt-cache rdepends --installed libssl3 2>/dev/null | head -20    # who uses OpenSSL? (use the name you found)
apt changelog openssh-server 2>/dev/null | grep -m5 CVE
```

### Part 3 — Look inside a .deb before installing 🟡

```bash
mkdir -p ~/labs/deb && cd ~/labs/deb
apt download cowsay
dpkg -c cowsay_*.deb | head
dpkg-deb -I cowsay_*.deb
dpkg-deb -e cowsay_*.deb control/ && ls control/   # maintainer scripts (postinst etc.) would be here
```

### Part 4 — Detect a tampered binary 🔴 ⚠️ (VM/container only)

```bash
sudo apt install -y debsums cowsay
sudo debsums -s cowsay; echo "exit: $?"                # clean
sudo cp /usr/games/cowsay /tmp/cowsay.orig
echo "# tampered" | sudo tee -a /usr/games/cowsay > /dev/null
sudo debsums -s cowsay                                 # reports the changed file
sudo dpkg --verify cowsay
sudo cp /tmp/cowsay.orig /usr/games/cowsay            # restore (or: sudo apt install --reinstall cowsay)
sudo debsums -s cowsay; echo "exit: $?"
```

### Part 5 — Add a signed third-party repository 🔴

Follow the GitHub CLI steps in **Adding a third-party repository — the secure way** above, then:

```bash
apt-cache policy gh
cat /etc/apt/sources.list.d/github-cli.list
gpg --show-keys /etc/apt/keyrings/githubcli-archive-keyring.gpg    # fingerprint of the key you now trust
```

### Part 6 — Hold and security updates 🔴

```bash
sudo apt-mark hold jq && apt-mark showhold
sudo apt-mark unhold jq
apt list --upgradable 2>/dev/null | grep -- -security | head
cat /etc/apt/apt.conf.d/20auto-upgrades 2>/dev/null
```

**Questions**

1. What protects you if an apt mirror serves a modified package?
2. Why is `signed-by=` safer than `apt-key add`?
3. How did `debsums` detect the change?
4. Why might a scanner report a CVE that your Ubuntu package has already fixed?

---

## Common Mistakes

- `apt upgrade` without `apt update` first — you upgrade to stale versions.
- `curl | sudo bash` from the internet without reading the script.
- Using deprecated `apt-key add` (global trust).
- Leaving packages on hold forever — they silently miss security fixes.
- Forgetting to restart services after library updates.
- Installing build tools and debugging utilities on production hosts or in final container images.
- Patching running containers instead of rebuilding images.

---

## Interview Questions

**1. `apt update` vs `apt upgrade` vs `apt full-upgrade`?**
`update` refreshes package lists; `upgrade` upgrades installed packages without removing any; `full-upgrade` may install or remove packages to complete upgrades.

**2. `remove` vs `purge`?**
`remove` keeps configuration files; `purge` deletes them too.

**3. How do you find which package installed a file?**
`dpkg -S /path/to/file` (Debian) or `rpm -qf /path/to/file` (RHEL).

**4. How does apt make sure packages aren't tampered with?**
The repository's `InRelease`/`Release` file is GPG-signed; it contains hashes of the package indexes, which contain hashes of each `.deb`. apt verifies the whole chain.

**5. Why is `apt-key` deprecated?**
Keys added with it are trusted for all repositories. The replacement stores each key separately and binds it to one repository with `signed-by=`.

**6. How do you check whether a server is vulnerable to a specific CVE?**
Find the affected package and installed version (`dpkg -l`), check the distribution's security tracker for the fixed version (fixes are often backported), check `apt changelog`, and confirm running services were restarted after the update.

**7. 🔐 What supply-chain risks exist in package management?**
Compromised repositories or signing keys, typosquatted packages, malicious install scripts, unpinned dependencies, unsigned downloads, and outdated packages with known CVEs.

**8. 🔐 How would you detect a replaced system binary?**
`dpkg --verify` or `debsums` (Debian), `rpm -Va` (RHEL), compare hashes against the package, or use file-integrity monitoring (AIDE, auditd).

---

## Summary

- Package managers install, track, verify and update software and its dependencies.
- Trust flows from a GPG key → signed index → hashes of every package.
- Add third-party repos with a dedicated key and `signed-by=`.
- Apply security updates automatically and restart what uses old libraries.
- Verify installed files with `dpkg --verify` / `debsums` during investigations.

**Next:** [09 — Logs](09-Logs.md)

---

## References

- `man apt`, `man apt-get`, `man dpkg`, `man sources.list`, `man apt_preferences`, `man debsums`
- Debian SecureApt — https://wiki.debian.org/SecureApt
- Ubuntu security notices — https://ubuntu.com/security/notices
- GitHub CLI installation (Linux) — https://github.com/cli/cli/blob/trunk/docs/install_linux.md
