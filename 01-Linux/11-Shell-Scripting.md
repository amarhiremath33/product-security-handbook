# 11 — Shell Scripting

> **Module:** 01 – Linux · **Level:** 🟡 Intermediate → 🔴 Advanced · **Time:** ~4 hours
> **Lab environment:** WSL2, Docker or VM — see [labs/README.md](../labs/README.md)

---

## Objectives

After this chapter you will be able to:

- Write, run and debug Bash scripts.
- Use variables, quoting, arguments, conditions, loops, functions and arrays correctly.
- Handle errors with exit codes, `set -euo pipefail` and `trap`.
- Process files and command output safely.
- Avoid the security mistakes that turn scripts into vulnerabilities.
- Lint scripts with ShellCheck and read a real-world audit script.

---

## Your First Script

```bash
mkdir -p ~/labs/scripts && cd ~/labs/scripts
cat > hello.sh <<'EOF'
#!/usr/bin/env bash
# Prints a greeting and some system info
echo "Hello, $USER! Today is $(date +%A)."
echo "You are on $(hostname), running $(uname -r)."
EOF
chmod +x hello.sh
./hello.sh
```

| Piece | Meaning |
|---|---|
| `#!/usr/bin/env bash` | **Shebang**: which interpreter runs the file. `env` finds bash in `PATH`. `#!/bin/bash` is also common |
| `chmod +x` | Make it executable |
| `./hello.sh` | Run it from the current directory (`.` isn't in `PATH`, on purpose) |
| `bash hello.sh` | Run it without the execute bit |

> `sh` is not `bash`. On Ubuntu `/bin/sh` is **dash**, which lacks arrays, `[[ ]]`, and more. If you use Bash features, use a Bash shebang.

---

## 🟢 Variables and Quoting

```bash
name="Amar"                 # no spaces around =
count=3
today=$(date +%F)           # command substitution
echo "Hello $name, today is $today"
echo "Next year: $((2026 + 1))"    # arithmetic
readonly API_URL="https://api.example.com"
```

### Quoting rules — the #1 source of Bash bugs

| Syntax | Behaviour | Example |
|---|---|---|
| `"double"` | Variables and `$(...)` expand; spaces kept | `"$file"` |
| `'single'` | Nothing expands — literal text | `'$HOME'` prints `$HOME` |
| unquoted | Expands **and** splits on spaces **and** expands globs | `$file` ❌ |

```bash
file="my report.txt"
touch "$file"
ls $file        # ❌ ls: cannot access 'my': … 'report.txt': …
ls "$file"      # ✅
```

**Rule: always double-quote variables** — `"$var"`, `"$@"`, `"$(cmd)"` — unless you know exactly why not.

### Special variables

| Variable | Meaning |
|---|---|
| `$0` | Script name |
| `$1` … `$9`, `${10}` | Positional arguments |
| `$#` | Number of arguments |
| `"$@"` | All arguments, each separately quoted (use this) |
| `$?` | Exit code of the last command |
| `$$` | PID of the script |
| `$!` | PID of the last background job |

### Parameter expansion

```bash
${var:-default}       # use default if var is unset or empty
${var:=default}       # same, and assign it
${var:?error message} # exit with error if unset or empty
${#var}               # length
${var#prefix}         # remove shortest prefix match:   ${path#*/}
${var##*/}            # remove longest prefix match:   basename → file.txt
${var%/*}             # remove suffix:                 dirname
${var%.txt}.bak       # change extension
${var/old/new}        # replace first;  ${var//old/new} replaces all
${var^^} ${var,,}     # UPPER / lower case
```

---

## 🟢 Input and Arguments

```bash
#!/usr/bin/env bash
echo "Script: $0, $# argument(s)"
echo "First: ${1:-<none>}"
for arg in "$@"; do echo " - $arg"; done

read -rp "Your name: " user
read -rsp "Password: " pass; echo     # -s hides input
echo "Hi $user (password length ${#pass})"
```

Always use `read -r` (keeps backslashes literal).

---

## 🟢 Conditions

```bash
if [[ -f /etc/passwd ]]; then
  echo "exists"
elif [[ -d /etc ]]; then
  echo "is a directory"
else
  echo "missing"
fi
```

Use `[[ ... ]]` in Bash (safer than `[ ... ]`: no word splitting, supports `&&`, `||`, `=~`).

| Test | True if |
|---|---|
| `-e path` | Exists |
| `-f path` / `-d path` / `-L path` | Regular file / directory / symlink |
| `-r` / `-w` / `-x path` | Readable / writable / executable |
| `-s path` | Exists and not empty |
| `-z "$s"` / `-n "$s"` | String empty / not empty |
| `"$a" == "$b"` / `!=` | Strings equal / differ |
| `"$s" == *.log` | Glob match (no quotes on the pattern) |
| `"$s" =~ ^[0-9]+$` | Regex match |
| `$a -eq $b` (`-ne -lt -le -gt -ge`) | Integer comparison |
| `(( a > b ))` | Arithmetic comparison |

Commands are conditions too — `if` checks the exit code:

```bash
if grep -q "^$user:" /etc/passwd; then echo "user exists"; fi
if ! ping -c1 -W1 8.8.8.8 &>/dev/null; then echo "offline"; fi
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }
```

### case

```bash
case "$1" in
  start)   echo "starting" ;;
  stop)    echo "stopping" ;;
  -h|--help) echo "usage: $0 {start|stop}" ;;
  *)       echo "unknown: $1" >&2; exit 2 ;;
esac
```

---

## 🟢 Loops

```bash
for i in 1 2 3; do echo "$i"; done
for i in {1..5}; do echo "$i"; done
for ((i = 0; i < 5; i++)); do echo "$i"; done
for f in /var/log/*.log; do echo "$f: $(wc -l < "$f") lines"; done

count=0
while (( count < 3 )); do ((count++)); echo "$count"; done

until ping -c1 -W1 example.com &>/dev/null; do echo "waiting..."; sleep 2; done
```

### Read a file line by line (the correct way)

```bash
while IFS= read -r line; do
  echo "Line: $line"
done < input.txt

# Split fields while reading
while IFS=: read -r user _ uid _ _ home shell; do
  (( uid >= 1000 && uid < 65534 )) && echo "$user → $home ($shell)"
done < /etc/passwd
```

> ❌ `for line in $(cat file)` splits on **spaces**, not lines, and expands globs.

`break` exits a loop; `continue` skips to the next iteration.

---

## 🟡 Functions

```bash
log() {
  local level=$1; shift
  printf '%s [%s] %s\n' "$(date -Is)" "$level" "$*" >&2
}

is_root() { [[ $EUID -eq 0 ]]; }

backup_file() {
  local src=$1
  local dest="${src}.$(date +%Y%m%d%H%M%S).bak"
  cp -a -- "$src" "$dest" || return 1
  echo "$dest"          # "return" a value by printing it
}

log INFO "starting"
is_root || { log ERROR "run as root"; exit 1; }
bak=$(backup_file /etc/hosts) && log INFO "saved $bak"
```

- `local` keeps variables inside the function — use it always.
- `return N` sets an exit code (0–255); output is how you return data.
- Send messages for humans to **stderr** (`>&2`) so stdout stays clean for data.

---

## 🟡 Arrays

```bash
servers=("web01" "web02" "db01")
echo "${servers[0]}"          # first
echo "${#servers[@]}"         # count
servers+=("cache01")          # append
for s in "${servers[@]}"; do echo "$s"; done

declare -A owner              # associative array (dictionary)
owner[web01]="team-a"
owner[db01]="team-db"
for host in "${!owner[@]}"; do echo "$host → ${owner[$host]}"; done

mapfile -t users < <(cut -d: -f1 /etc/passwd)   # read lines into an array
echo "${#users[@]} users"
```

---

## 🟡 Exit Codes and Error Handling

```bash
#!/usr/bin/env bash
set -euo pipefail
```

| Option | Effect |
|---|---|
| `-e` | Exit as soon as a command fails |
| `-u` | Error on unset variables (catches typos like `$fiel`) |
| `-o pipefail` | A pipeline fails if **any** command in it fails, not just the last |

```bash
set -euo pipefail
false | true; echo "never printed with pipefail"
```

Caveats: `-e` is skipped inside `if` conditions, `||`/`&&` chains, and `!` — which is usually what you want. Handle expected failures explicitly:

```bash
grep -q pattern file || echo "not found"        # OK: failure handled
count=$(grep -c pattern file || true)           # grep returns 1 when no match
```

### `trap` — clean up no matter what

```bash
tmpdir=$(mktemp -d)
cleanup() { rm -rf -- "$tmpdir"; }
trap cleanup EXIT                        # runs on normal exit, error, or Ctrl+C
trap 'echo "failed at line $LINENO" >&2' ERR
```

### Exit codes you set

```bash
exit 0      # success
exit 1      # general error
exit 2      # usage error
```

---

## 🟡 Debugging

```bash
bash -n script.sh          # syntax check only
bash -x script.sh          # print each command before running it
set -x … set +x            # trace only part of a script
PS4='+ ${BASH_SOURCE}:${LINENO}: ' bash -x script.sh   # trace with line numbers
```

### ShellCheck — use it on every script

```bash
sudo apt install -y shellcheck
shellcheck script.sh
```

It catches unquoted variables, useless `cat`, `[` vs `[[` problems, unreachable code, and many security issues. Also available as a VS Code extension.

---

## 🔴 Script Template

A solid starting point for any admin script:

```bash
#!/usr/bin/env bash
#
# name.sh — one-line description
# Usage: name.sh [-v] <target>
#
set -euo pipefail
IFS=$'\n\t'

readonly SCRIPT_NAME=${0##*/}
VERBOSE=0

log()  { printf '%s [%s] %s\n' "$(date -Is)" "$1" "${*:2}" >&2; }
die()  { log ERROR "$*"; exit 1; }
usage() { echo "Usage: $SCRIPT_NAME [-v] <target>" >&2; exit 2; }

cleanup() { [[ -n ${TMPDIR_CREATED:-} ]] && rm -rf -- "$TMPDIR_CREATED"; }
trap cleanup EXIT

main() {
  while getopts ":vh" opt; do
    case $opt in
      v) VERBOSE=1 ;;
      h) usage ;;
      *) usage ;;
    esac
  done
  shift $((OPTIND - 1))
  [[ $# -eq 1 ]] || usage
  local target=$1

  command -v curl >/dev/null || die "curl is required"
  TMPDIR_CREATED=$(mktemp -d)

  (( VERBOSE )) && log INFO "checking $target"
  # ... work ...
  log INFO "done"
}

main "$@"
```

---

## In Production

- Scripts live in Git, are reviewed like code, and pass ShellCheck in CI.
- They run from systemd timers or CI pipelines, log to the journal (`logger -t`), and exit non-zero on failure so alerts fire.
- They're **idempotent**: running twice produces the same result (check before creating, use `mkdir -p`, `grep -q || echo >>`).
- When a script grows past ~200 lines or needs real data structures, move to Python or Go. For fleet configuration, use Ansible.

---

## Product Security Perspective

Shell scripts often run as **root** from cron or CI — mistakes become privilege escalation or code execution.

| Vulnerability | Bad | Good |
|---|---|---|
| **Command injection** via `eval` | `eval "ls $user_input"` | Never `eval` untrusted input; pass arguments as an array: `ls -- "$user_input"` |
| Unquoted variables | `rm -rf $DIR/*` (empty `DIR` → `rm -rf /*`) | `rm -rf -- "${DIR:?}"/*` |
| Option injection | `rm $file` where `file="-rf"` | `rm -- "$file"` (`--` ends options) |
| Predictable temp files | `tmp=/tmp/myscript.tmp` (symlink attack) | `tmp=$(mktemp)` |
| Hard-coded secrets | `PASSWORD=Summer2026` in the script | Read from a `600` file, env var injected by systemd/CI, or a secret manager |
| Secrets in arguments | `curl -u admin:pass …` (visible in `ps`) | `curl --netrc-file` / `-K config` / read from stdin |
| Writable script run by root | Script `664` owned by a user, called by root's cron | Root-owned, `755`/`700`, in a root-owned directory |
| Relative paths / PATH hijack | Calls `backup` relying on `$PATH` | Use absolute paths or set `PATH=/usr/sbin:/usr/bin:/sbin:/bin` at the top |
| `curl \| bash` | Runs whatever the server sends | Download, verify checksum/signature, read, then run |
| Trusting filenames | `for f in $(ls)` | Globs (`for f in ./*`) or `find -print0 \| xargs -0` |

Example of command injection:

```bash
# vulnerable.sh — "ping a host" helper, run via sudo
host=$1
eval "ping -c1 $host"
```

```bash
./vulnerable.sh "127.0.0.1; id"       # runs 'id' too → with sudo, as root
```

Fixed:

```bash
host=$1
[[ $host =~ ^[A-Za-z0-9.-]+$ ]] || { echo "invalid host" >&2; exit 2; }
ping -c1 -- "$host"
```

---

## Hands-on Lab 🟢→🔴

```bash
mkdir -p ~/labs/scripts && cd ~/labs/scripts
sudo apt install -y shellcheck
```

### Part 1 — Disk usage alert 🟢

Create `disk-alert.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
threshold=${1:-80}

df -P -x tmpfs -x devtmpfs -x squashfs -x efivarfs | tail -n +2 | while read -r fs size used avail pct mount; do
  usage=${pct%\%}
  if (( usage >= threshold )); then
    echo "WARNING: $mount is ${usage}% full ($fs)"
    logger -t disk-alert "$mount is ${usage}% full"
  fi
done
echo "Checked all filesystems against ${threshold}%."
```

```bash
chmod +x disk-alert.sh
./disk-alert.sh 90
./disk-alert.sh 1          # forces alerts
journalctl -t disk-alert -n 5 --no-pager
shellcheck disk-alert.sh   # warnings about unused variables are expected
```

### Part 2 — User report from /etc/passwd 🟡

Create `user-report.sh` that prints every human user, their home directory, shell, whether they're in `sudo`, and the date of last password change. Hints: `while IFS=: read -r …`, `id -nG "$user"`, `sudo chage -l "$user"`.

<details>
<summary>Solution</summary>

```bash
#!/usr/bin/env bash
set -euo pipefail
printf '%-15s %-25s %-15s %-5s %s\n' USER HOME SHELL SUDO PW_CHANGED
while IFS=: read -r user _ uid _ _ home shell; do
  (( uid >= 1000 && uid < 65534 )) || continue
  sudo_flag=no
  id -nG "$user" | grep -qwE 'sudo|wheel' && sudo_flag=yes
  changed=$(sudo chage -l "$user" 2>/dev/null | awk -F': ' '/Last password change/ {print $2}')
  printf '%-15s %-25s %-15s %-5s %s\n' "$user" "$home" "${shell##*/}" "$sudo_flag" "${changed:-?}"
done < /etc/passwd
```

</details>

### Part 3 — Log analyser with functions and arrays 🟡

Reuse `access.log` from [chapter 03](03-Linux-Commands.md) (or regenerate it). Write `log-report.sh <logfile>` that:

1. Exits with usage if no file is given or it's not readable.
2. Prints total requests, unique IPs, top 5 IPs, top 5 paths, and count of 4xx and 5xx.
3. Flags any IP that requested `/.env` or `/wp-login.php`.

<details>
<summary>Solution</summary>

```bash
#!/usr/bin/env bash
set -euo pipefail

usage() { echo "Usage: ${0##*/} <access.log>" >&2; exit 2; }
section() { printf '\n== %s ==\n' "$1"; }

main() {
  [[ $# -eq 1 && -r $1 ]] || usage
  local log=$1

  section "Totals"
  echo "Requests:   $(wc -l < "$log")"
  echo "Unique IPs: $(awk '{print $1}' "$log" | sort -u | wc -l)"
  echo "4xx:        $(awk '$9 ~ /^4/' "$log" | wc -l)"
  echo "5xx:        $(awk '$9 ~ /^5/' "$log" | wc -l)"

  section "Top 5 IPs"
  awk '{print $1}' "$log" | sort | uniq -c | sort -rn | head -5

  section "Top 5 paths"
  awk '{print $7}' "$log" | sort | uniq -c | sort -rn | head -5

  section "Suspicious probes"
  local -a probes=('/.env' '/wp-login.php')
  local p
  for p in "${probes[@]}"; do
    awk -v p="$p" '$7 == p {print $1}' "$log" | sort | uniq -c | sort -rn \
      | while read -r n ip; do echo "  $ip requested $p $n time(s)"; done
  done
}

main "$@"
```

</details>

### Part 4 — Find and fix the vulnerabilities 🔴

Save as `bad-backup.sh` and run `shellcheck` on it. Then list every security problem and write a fixed version.

```bash
#!/bin/bash
# Backs up a user-supplied directory to /tmp and uploads it
DIR=$1
PASSWORD="Backup2026!"
cd $DIR
tar czf /tmp/backup.tgz *
eval "echo Backup of $DIR complete"
curl -u admin:$PASSWORD -T /tmp/backup.tgz http://backup.internal/upload
rm -rf $TMPDIR/*
```

<details>
<summary>Problems to find</summary>

1. Unquoted `$DIR` and `$1` — breaks on spaces, glob expansion.
2. `cd $DIR` not checked — if it fails, `tar` archives the wrong directory.
3. Hard-coded password in the script.
4. Password on the command line (`ps` shows it).
5. Predictable temp file `/tmp/backup.tgz` — another user can pre-create a symlink.
6. `*` misses hidden files and breaks on names starting with `-`.
7. `eval` with user input → command injection (`./bad-backup.sh '/tmp; rm -rf ~'`).
8. Plain HTTP — credentials and data sent unencrypted.
9. `rm -rf $TMPDIR/*` — `TMPDIR` is usually unset → `rm -rf /*`.
10. No `set -euo pipefail`, no error handling, no cleanup.

</details>

### Part 5 — Run the module's audit script 🔴

Read [`labs/linux/scripts/linux-security-audit.sh`](../labs/linux/scripts/linux-security-audit.sh) top to bottom. Identify where it uses: `set -uo pipefail`, functions with `local`, `case`, arrays-like loops, `[[ =~ ]]`, `awk`, and arithmetic. Then run it:

```bash
bash ~/path/to/product-security-handbook/labs/linux/scripts/linux-security-audit.sh
sudo bash ~/path/to/product-security-handbook/labs/linux/scripts/linux-security-audit.sh
```

Why does it use `set -uo pipefail` but **not** `-e`?

**Questions**

1. What's the difference between `"$@"` and `$*`?
2. Why is `while IFS= read -r line` safer than `for line in $(cat file)`?
3. What does `pipefail` change?
4. How many vulnerabilities did you find in Part 4?

---

## Common Mistakes

- Unquoted variables.
- Missing `set -euo pipefail` (or not understanding its exceptions).
- Using `sh` shebang with Bash features.
- `cd` without checking it succeeded.
- Parsing `ls` output.
- Hard-coding secrets, or passing them as arguments.
- Temp files with fixed names in `/tmp`.
- Windows line endings (`\r`) after editing in Notepad → `bad interpreter: /bin/bash^M`. Fix: `sed -i 's/\r$//' script.sh` or set VS Code to `LF`.

---

## Interview Questions

**1. What does the shebang do?**
Tells the kernel which interpreter to run the script with, e.g. `#!/usr/bin/env bash`.

**2. What does `set -euo pipefail` do?**
Exit on errors (`-e`), treat unset variables as errors (`-u`), and make a pipeline fail if any part fails (`pipefail`).

**3. `"$@"` vs `"$*"`?**
`"$@"` expands to each argument as a separate word, preserving spaces inside them. `"$*"` joins all arguments into one string.

**4. Single vs double quotes?**
Single quotes are literal; double quotes allow variable and command expansion while preventing word splitting and globbing.

**5. How do you debug a Bash script?**
`bash -n` for syntax, `bash -x` / `set -x` for tracing, ShellCheck for static analysis, and logging to stderr.

**6. How do you ensure cleanup when a script fails?**
`trap cleanup EXIT` — runs on any exit, including errors and Ctrl+C.

**7. 🔐 What makes a shell script vulnerable to command injection?**
Passing untrusted input to `eval`, `bash -c`, `ssh host "cmd $input"`, or unquoted contexts where it's re-parsed. Validate input, quote variables, use `--`, and avoid `eval`.

**8. 🔐 Why are `/tmp/fixed-name` files dangerous in root scripts?**
Another user can pre-create the path as a symlink to a sensitive file; the root script then overwrites or reads it. Use `mktemp`.

**9. 🔐 A root cron job runs `/opt/scripts/cleanup.sh`. What do you check?**
Ownership and permissions of the script and every parent directory, any files or commands it sources or calls with relative paths, `PATH`, use of temp files, and whether it processes user-controlled input or filenames.

---

## Summary

- Quote everything, use `[[ ]]`, `local`, `read -r`, and `"$@"`.
- Start scripts with `set -euo pipefail`, clean up with `trap`, log to stderr.
- ShellCheck every script.
- Treat scripts as code that may run as root: no `eval`, no secrets, no predictable temp files, no writable paths.

**Next:** [12 — Linux Security Hardening](12-Linux-Security-Hardening.md)

---

## References

- GNU Bash manual — https://www.gnu.org/software/bash/manual/
- ShellCheck — https://www.shellcheck.net/
- Google Shell Style Guide — https://google.github.io/styleguide/shellguide.html
- BashFAQ / BashPitfalls — https://mywiki.wooledge.org/BashPitfalls
