#!/usr/bin/env bash
#
# linux-security-audit.sh — read-only Linux security baseline check
#
# Part of the Product Security Handbook, Module 01 — Linux.
# Prints PASS / WARN / INFO findings for users, SSH, network, filesystem,
# services, logging and kernel settings. It never changes the system.
#
# Usage:
#   sudo bash linux-security-audit.sh            # full audit (recommended)
#   bash linux-security-audit.sh                 # partial audit as a normal user
#   sudo bash linux-security-audit.sh --no-color > report.txt
#
# Tested on Ubuntu 22.04 / 24.04. Most checks also work on Debian and RHEL-family systems.

set -uo pipefail

# ---------- output helpers ----------------------------------------------------

USE_COLOR=1
for arg in "$@"; do
  case "$arg" in
    --no-color) USE_COLOR=0 ;;
    -h|--help)  sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done
[[ -t 1 ]] || USE_COLOR=0

if (( USE_COLOR )); then
  C_RED=$'\e[31m'; C_GRN=$'\e[32m'; C_YEL=$'\e[33m'; C_BLU=$'\e[36m'; C_BLD=$'\e[1m'; C_RST=$'\e[0m'
else
  C_RED=''; C_GRN=''; C_YEL=''; C_BLU=''; C_BLD=''; C_RST=''
fi

WARNINGS=0
PASSES=0

section() { printf '\n%s== %s ==%s\n' "$C_BLD" "$1" "$C_RST"; }
pass()    { printf '  %s[PASS]%s %s\n' "$C_GRN" "$C_RST" "$1"; PASSES=$((PASSES + 1)); }
warn()    { printf '  %s[WARN]%s %s\n' "$C_YEL" "$C_RST" "$1"; WARNINGS=$((WARNINGS + 1)); }
info()    { printf '  %s[INFO]%s %s\n' "$C_BLU" "$C_RST" "$1"; }
skip()    { printf '  %s[SKIP]%s %s\n' "$C_RED" "$C_RST" "$1"; }
detail()  { sed 's/^/         /'; }

have() { command -v "$1" > /dev/null 2>&1; }

IS_ROOT=0
[[ $EUID -eq 0 ]] && IS_ROOT=1

HAS_SYSTEMD=0
[[ "$(ps -p 1 -o comm= 2>/dev/null)" == "systemd" ]] && HAS_SYSTEMD=1

# ---------- 1. system ---------------------------------------------------------

section "System"
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  info "OS: ${PRETTY_NAME:-unknown}"
fi
info "Kernel: $(uname -r)"
info "Hostname: $(hostname)"
info "Uptime: $(uptime -p 2>/dev/null || uptime)"
(( IS_ROOT )) || warn "Not running as root — some checks will be skipped. Re-run with sudo for a full audit."
(( HAS_SYSTEMD )) || info "PID 1 is not systemd (container or WSL without systemd) — service checks skipped."

# ---------- 2. updates --------------------------------------------------------

section "Updates"
if have apt; then
  upgradable=$(apt list --upgradable 2>/dev/null | grep -c '/' || true)
  security=$(apt list --upgradable 2>/dev/null | grep -c -- '-security' || true)
  if (( security > 0 )); then
    warn "$security security update(s) pending (of $upgradable upgradable). Run: sudo apt update && sudo apt upgrade"
  elif (( upgradable > 0 )); then
    info "$upgradable non-security update(s) pending (package lists may be stale — run 'sudo apt update')."
  else
    pass "No pending updates (according to the current package lists)."
  fi
  if [[ -f /var/run/reboot-required ]]; then
    warn "Reboot required to finish applying updates."
  else
    pass "No reboot pending."
  fi
  if dpkg -s unattended-upgrades > /dev/null 2>&1; then
    pass "unattended-upgrades is installed."
  else
    warn "unattended-upgrades is not installed — security updates are not automatic."
  fi
elif have dnf; then
  if dnf -q updateinfo list --security 2>/dev/null | grep -q .; then
    warn "Security updates pending. Run: sudo dnf upgrade --security"
  else
    pass "No pending security updates reported by dnf."
  fi
else
  skip "No supported package manager found."
fi

# ---------- 3. users & privileges --------------------------------------------

section "Users and privileges"

uid0=$(awk -F: '$3 == 0 {print $1}' /etc/passwd)
if [[ "$uid0" == "root" ]]; then
  pass "Only 'root' has UID 0."
else
  warn "Accounts with UID 0: $(echo "$uid0" | tr '\n' ' ')"
fi

if (( IS_ROOT )); then
  empty=$(awk -F: '$2 == "" {print $1}' /etc/shadow)
  if [[ -z "$empty" ]]; then
    pass "No accounts with an empty password."
  else
    warn "Accounts with an EMPTY password: $(echo "$empty" | tr '\n' ' ')"
  fi
else
  skip "Empty-password check needs root (reads /etc/shadow)."
fi

login_users=$(awk -F: '$7 !~ /(nologin|false|sync|shutdown|halt)$/ {print $1}' /etc/passwd | tr '\n' ' ')
info "Accounts with a login shell: $login_users"

for grp in sudo wheel adm docker lxd; do
  members=$(getent group "$grp" | cut -d: -f4)
  [[ -z "$members" ]] && continue
  case "$grp" in
    docker|lxd) warn "Group '$grp' (root-equivalent) members: $members" ;;
    *)          info "Group '$grp' members: $members" ;;
  esac
done

if (( IS_ROOT )); then
  nopass=$(grep -rhE '^[^#].*NOPASSWD' /etc/sudoers /etc/sudoers.d/ 2>/dev/null || true)
  if [[ -n "$nopass" ]]; then
    warn "sudo rules with NOPASSWD:"
    echo "$nopass" | detail
  else
    pass "No NOPASSWD sudo rules."
  fi
fi

for f in /etc/passwd:644 /etc/group:644 /etc/shadow:640 /etc/gshadow:640; do
  path=${f%%:*}; max=${f##*:}
  [[ -e "$path" ]] || continue
  mode=$(stat -c '%a' "$path")
  if (( 8#$mode & ~8#$max )); then
    warn "$path has permissions $mode (expected $max or stricter)."
  else
    pass "$path permissions $mode."
  fi
done

# ---------- 4. SSH ------------------------------------------------------------

section "SSH server"
if have sshd; then
  if (( IS_ROOT )); then
    sshd_cfg=$(sshd -T 2>/dev/null)
  else
    sshd_cfg=$(cat /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null | grep -vE '^\s*(#|$)' | tr '[:upper:]' '[:lower:]')
    info "Not root: reading config files instead of the effective config (less accurate)."
  fi
  check_ssh() {  # key, good-value-regex, message
    local val
    val=$(echo "$sshd_cfg" | awk -v k="$1" 'tolower($1) == k {print tolower($2); exit}')
    if [[ -z "$val" ]]; then
      info "sshd: $1 not set explicitly (default applies)."
    elif [[ "$val" =~ $2 ]]; then
      pass "sshd: $1 = $val"
    else
      warn "sshd: $1 = $val — $3"
    fi
  }
  check_ssh permitrootlogin        '^(no|prohibit-password)$' "set 'PermitRootLogin no'"
  check_ssh passwordauthentication '^no$'                     "use keys only: 'PasswordAuthentication no'"
  check_ssh permitemptypasswords   '^no$'                     "set 'PermitEmptyPasswords no'"
  check_ssh x11forwarding          '^no$'                     "disable unless needed: 'X11Forwarding no'"
  check_ssh maxauthtries           '^[1-4]$'                  "lower it, e.g. 'MaxAuthTries 3'"
else
  info "OpenSSH server not installed."
fi

# ---------- 5. network --------------------------------------------------------

section "Network exposure"
if have ss; then
  # Print "proto address [process]" for sockets NOT bound to loopback.
  # The %iface suffix (e.g. 127.0.0.53%lo) is stripped before matching.
  not_loopback='{ a = $5; sub(/%[^:]*/, "", a); if (a !~ /^(127\.|\[::1\]:|::1:)/) print $1, $5, $7 }'
  if (( IS_ROOT )); then
    exposed=$(ss -H -tulnp 2>/dev/null | awk "$not_loopback")
  else
    exposed=$(ss -H -tuln 2>/dev/null | awk "$not_loopback")
  fi
  if [[ -n "$exposed" ]]; then
    warn "Ports listening on non-loopback addresses (reachable from the network):"
    echo "$exposed" | detail
  else
    pass "No services listening on external interfaces."
  fi
else
  skip "'ss' not found."
fi

fw="none"
if have ufw && (( IS_ROOT )) && ufw status 2>/dev/null | grep -q 'Status: active'; then
  fw="ufw"
elif have nft && (( IS_ROOT )) && nft list ruleset 2>/dev/null | grep -qE 'hook input.*policy drop|policy drop'; then
  fw="nftables"
elif have firewall-cmd && firewall-cmd --state > /dev/null 2>&1; then
  fw="firewalld"
fi
if [[ "$fw" != "none" ]]; then
  pass "Host firewall active: $fw"
elif (( IS_ROOT )); then
  warn "No active host firewall detected (ufw/nftables/firewalld)."
else
  skip "Firewall check needs root."
fi

ipfwd=$(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo "?")
if [[ "$ipfwd" == "1" ]]; then
  info "IPv4 forwarding is ON (expected on Docker/Kubernetes hosts and routers, not elsewhere)."
fi

# ---------- 6. filesystem -----------------------------------------------------

section "Filesystem"
for mp in /tmp /var/tmp /dev/shm; do
  opts=$(findmnt -no OPTIONS "$mp" 2>/dev/null || true)
  if [[ -z "$opts" ]]; then
    info "$mp is not a separate mount (mount options can't be applied)."
    continue
  fi
  missing=""
  for o in nodev nosuid noexec; do
    [[ ",$opts," == *",$o,"* ]] || missing+="$o "
  done
  if [[ -z "$missing" ]]; then
    pass "$mp mounted with nodev,nosuid,noexec."
  else
    warn "$mp missing mount options: $missing"
  fi
done

suid=$(find / -xdev -perm -4000 -type f 2>/dev/null | sort)
info "SUID binaries: $(echo "$suid" | grep -c . ) (save a baseline and compare over time)"
echo "$suid" | grep -vE '^/(usr/)?(s?bin|lib|libexec)/' | grep . > /dev/null 2>&1 && {
  warn "SUID binaries outside standard system paths:"
  echo "$suid" | grep -vE '^/(usr/)?(s?bin|lib|libexec)/' | detail
}

if have getcap; then
  caps=$(getcap -r / 2>/dev/null | grep -vE '^/(snap|proc)/' || true)
  if [[ -n "$caps" ]]; then
    info "Binaries with file capabilities:"
    echo "$caps" | detail
    echo "$caps" | grep -qE 'cap_(setuid|setgid|dac_override|sys_admin)' && \
      warn "Dangerous capability found (setuid/setgid/dac_override/sys_admin) — review above."
  fi
fi

ww_files=$(find / -xdev -type f -perm -0002 ! -path '/proc/*' ! -path '/sys/*' 2>/dev/null | head -20)
if [[ -n "$ww_files" ]]; then
  warn "World-writable files (first 20):"
  echo "$ww_files" | detail
else
  pass "No world-writable files on the root filesystem."
fi

ww_dirs=$(find / -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null | head -20)
if [[ -n "$ww_dirs" ]]; then
  warn "World-writable directories WITHOUT the sticky bit:"
  echo "$ww_dirs" | detail
else
  pass "All world-writable directories have the sticky bit."
fi

if (( IS_ROOT )); then
  orphans=$(find / -xdev \( -nouser -o -nogroup \) 2>/dev/null | head -10)
  [[ -n "$orphans" ]] && { warn "Files without a valid owner/group (first 10):"; echo "$orphans" | detail; }
fi

# ---------- 7. services -------------------------------------------------------

section "Services"
if (( HAS_SYSTEMD )); then
  failed=$(systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1}')
  if [[ -n "$failed" ]]; then
    warn "Failed units: $(echo "$failed" | tr '\n' ' ')"
  else
    pass "No failed systemd units."
  fi
  running=$(systemctl list-units --type=service --state=running --no-legend 2>/dev/null | wc -l)
  info "$running services running."
  for svc in telnet.socket rsh.socket vsftpd.service xinetd.service avahi-daemon.service cups.service; do
    systemctl is-active --quiet "$svc" 2>/dev/null && warn "Service usually unneeded on servers is running: $svc"
  done
  if have systemd-analyze; then
    unsafe=$(systemd-analyze security --no-pager 2>/dev/null | awk '$NF == "UNSAFE" {print $1}' | head -10 | tr '\n' ' ')
    [[ -n "$unsafe" ]] && info "Services rated UNSAFE by 'systemd-analyze security' (first 10): $unsafe"
  fi
else
  skip "No systemd."
fi

# ---------- 8. logging --------------------------------------------------------

section "Logging and auditing"
if [[ -d /var/log/journal ]]; then
  pass "journald storage is persistent (/var/log/journal exists)."
else
  warn "journald is volatile — logs are lost at reboot. Create /var/log/journal or set Storage=persistent."
fi
if (( HAS_SYSTEMD )); then
  for svc in rsyslog auditd; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
      pass "$svc is running."
    else
      info "$svc is not running."
    fi
  done
fi

# ---------- 9. kernel ---------------------------------------------------------

section "Kernel parameters"
check_sysctl() {  # key expected
  local val
  val=$(sysctl -n "$1" 2>/dev/null) || { info "$1 not available."; return; }
  if [[ "$val" == "$2" ]]; then
    pass "$1 = $val"
  else
    warn "$1 = $val (recommended: $2)"
  fi
}
check_sysctl kernel.randomize_va_space 2
check_sysctl kernel.kptr_restrict 1
check_sysctl kernel.dmesg_restrict 1
check_sysctl fs.protected_hardlinks 1
check_sysctl fs.protected_symlinks 1
check_sysctl fs.suid_dumpable 0
check_sysctl net.ipv4.tcp_syncookies 1
check_sysctl net.ipv4.conf.all.accept_redirects 0
check_sysctl net.ipv4.conf.all.send_redirects 0
check_sysctl net.ipv4.conf.all.accept_source_route 0
check_sysctl net.ipv4.conf.all.log_martians 1
check_sysctl net.ipv4.conf.all.rp_filter 1

# ---------- summary -----------------------------------------------------------

section "Summary"
printf '  %d passed, %s%d warning(s)%s\n' "$PASSES" "$C_YEL" "$WARNINGS" "$C_RST"
printf '  Review each WARN. Not every warning is a problem on every system —\n'
printf '  decide, fix or document the accepted risk.\n'
exit 0
