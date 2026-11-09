# 03 — Linux Commands

> **Module:** 01 – Linux · **Level:** 🟢 Basic → 🟡 Intermediate → 🔴 Advanced · **Time:** ~3 hours
> **Lab environment:** WSL2, Docker or VM — see [labs/README.md](../labs/README.md)

---

## Objectives

After this chapter you will be able to:

- Navigate, create, copy, move and delete files safely.
- Read files of any size and follow logs live.
- Use wildcards, redirection and pipes to combine commands.
- Search by file name (`find`) and by content (`grep`).
- Slice and summarise text with `cut`, `sort`, `uniq`, `awk` and `sed`.
- Use history, aliases and environment variables.
- Answer security questions using one-line pipelines.

---

## Anatomy of a Command

```text
 ls   -l -a   --human-readable   /var/log
 │    │        │                  │
 │    │        │                  └── argument (what to act on)
 │    │        └── long option (double dash, a word)
 │    └── short options (can combine: -la)
 └── command
```

Getting help — use these before searching the web:

```bash
man ls              # full manual (q quits, /word searches, n next match)
ls --help           # short summary of options
whatis ls           # one-line description
apropos "copy file" # find commands by keyword
type cd             # builtin, alias, or program?
tldr tar            # practical examples (sudo apt install tldr)
```

---

## 🟢 Level 1 — Basic

### Where am I, who am I?

| Command | Does | Example output |
|---|---|---|
| `pwd` | Print current directory | `/home/amar` |
| `whoami` | Current user | `amar` |
| `id` | User, group IDs and groups | `uid=1000(amar) gid=1000(amar) groups=1000(amar),27(sudo)` |
| `hostname` | Machine name | `ubuntu-lab` |
| `date` | Date and time | `Mon Nov  9 10:00:00 UTC 2026` |
| `uptime` | How long it's been running, load | `up 3 days, load average: 0.10, 0.05, 0.01` |

### Navigate

```bash
cd /etc            # go to an absolute path
cd ssh             # relative: now in /etc/ssh
cd ..              # up one level
cd ~               # home (or just: cd)
cd -               # back to the previous directory
```

### List

```bash
ls                 # names
ls -l              # long: permissions, owner, size, date
ls -la             # include hidden files (start with .)
ls -lh             # sizes like 4.0K, 12M
ls -ltr            # sort by time, newest last — great for logs
ls -lS             # sort by size, biggest first
ls -ld /etc        # info about the directory itself, not its contents
tree -L 2          # tree view (sudo apt install tree)
```

### Create, copy, move, delete

```bash
mkdir projects
mkdir -p a/b/c                 # create parent folders as needed
touch notes.txt                # create empty file / update timestamp

cp file.txt copy.txt
cp -r dir1 dir2                # copy a directory
cp -a src/ backup/             # archive mode: keep perms, owners, times, links
cp -i file.txt existing.txt    # ask before overwriting

mv old.txt new.txt             # rename
mv file.txt /tmp/              # move

rm file.txt
rm -i *.log                    # ask for each file
rm -r folder                   # delete a directory and everything inside
rmdir emptydir                 # only removes EMPTY directories
```

> ⚠️ **There is no recycle bin.** `rm -rf` deletes immediately and without asking. Before running it:
> 1. `pwd` — am I where I think I am?
> 2. `ls <target>` — is this what I expect?
> 3. Never use an unchecked variable: `rm -rf "$DIR/"` with an empty `$DIR` becomes `rm -rf /`.

### View files

| Command | Use when |
|---|---|
| `cat file` | Short file, print everything |
| `less file` | Long file — scroll (`Space`/`b`), search (`/word`, `n`), quit (`q`), jump to end (`G`) |
| `head -n 20 file` | First 20 lines |
| `tail -n 50 file` | Last 50 lines |
| `tail -f file` | Follow a growing log live (`Ctrl+C` to stop) |
| `tail -F file` | Follow even if the log is rotated |
| `wc -l file` | Count lines |
| `file thing` | Detect the real file type |

```bash
sudo tail -f /var/log/syslog          # watch system log live
less +F /var/log/syslog               # follow mode in less (Ctrl+C to scroll, F to resume)
```

### Edit files

```bash
nano notes.txt      # Ctrl+O save, Ctrl+X exit — easiest
vim notes.txt       # i = insert, Esc, :w save, :q quit, :wq both, :q! quit without saving
```

### Keyboard shortcuts

| Keys | Action |
|---|---|
| `Tab` / `Tab Tab` | Autocomplete / show options |
| `↑` `↓` | Previous / next command |
| `Ctrl+R` | Search history (press again for older matches) |
| `Ctrl+C` | Stop the running command |
| `Ctrl+Z` | Pause it (`fg` resumes, `bg` sends to background) |
| `Ctrl+L` | Clear screen |
| `Ctrl+A` / `Ctrl+E` | Start / end of line |
| `Ctrl+U` / `Ctrl+K` | Delete to start / end of line |
| `Ctrl+W` | Delete previous word |
| `Ctrl+D` | Exit shell (end of input) |

---

## 🟡 Level 2 — Intermediate

### Wildcards (globbing)

The **shell** expands these before the command runs.

| Pattern | Matches | Example |
|---|---|---|
| `*` | Anything (not hidden files) | `ls *.log` |
| `?` | Exactly one character | `ls file?.txt` → `file1.txt` |
| `[abc]` | One of the listed characters | `ls file[12].txt` |
| `[0-9]` | A range | `ls log[0-9]` |
| `{a,b}` | Each alternative (brace expansion) | `mkdir {dev,test,prod}` |
| `{1..5}` | A sequence | `touch day{1..5}.txt` |

```bash
echo *.txt          # see what a glob expands to before using it with rm
cp config.yml{,.bak}   # → cp config.yml config.yml.bak
```

### Redirection

Every program has three streams:

```text
          ┌─────────────┐
 stdin  ──►   program   ├──► stdout (1)  normal output
  (0)     │             ├──► stderr (2)  errors
          └─────────────┘
```

| Syntax | Does |
|---|---|
| `cmd > file` | Write stdout to file (**overwrites**) |
| `cmd >> file` | Append stdout to file |
| `cmd 2> err.txt` | Write errors to a file |
| `cmd > out.txt 2>&1` | Both stdout and stderr to the same file |
| `cmd &> out.txt` | Same, bash shorthand |
| `cmd 2>/dev/null` | Throw errors away |
| `cmd < file` | Read input from a file |
| `cmd <<'EOF' … EOF` | "Here-document": multi-line input |

```bash
find / -name "*.conf" 2>/dev/null > conf-files.txt
echo "line" | sudo tee -a /etc/somefile       # append to a root-owned file
```

> `sudo echo x > /etc/file` **fails**: the redirect is done by *your* shell, not by sudo. Use `| sudo tee`.

### Pipes

`|` sends one command's output into the next command's input. This is the core Linux idea: small tools, combined.

```bash
ps aux | grep nginx                  # find a process
ls -l /etc | wc -l                   # count entries
history | tail -20                   # last 20 commands
dmesg | less                         # page through kernel messages
cat access.log | cut -d' ' -f1 | sort | uniq -c | sort -rn | head   # top client IPs
```

### Search file names — `find`

```bash
find . -name "*.log"                        # by name (case-sensitive)
find / -iname "sshd_config" 2>/dev/null     # case-insensitive
find /etc -type f -name "*.conf"            # files only (-type d = directories)
find /var -size +100M 2>/dev/null           # bigger than 100 MB
find . -mtime -1                            # modified in the last 24 hours
find . -mmin -30                            # modified in the last 30 minutes
find /home -user bob                        # owned by bob
find . -empty                               # empty files and directories
find /tmp -type f -mtime +7 -delete         # delete files older than 7 days ⚠️
find . -name "*.sh" -exec chmod +x {} \;    # run a command on each result
find . -name "*.log" -exec grep -l "ERROR" {} +   # + passes many files at once (faster)
```

`locate` is much faster but uses a database that may be out of date:

```bash
sudo apt install -y plocate && sudo updatedb
locate sshd_config
```

### Search inside files — `grep`

```bash
grep "error" app.log                 # lines containing "error"
grep -i "error" app.log              # ignore case
grep -n "error" app.log              # show line numbers
grep -c "error" app.log              # count matching lines
grep -v "DEBUG" app.log              # lines NOT matching
grep -w "root" /etc/passwd           # whole word only
grep -r "password" /etc 2>/dev/null  # recursive
grep -rl "TODO" src/                 # only file names
grep -E "error|warn|fail" app.log    # extended regex: OR
grep -A 3 -B 2 "panic" app.log       # 3 lines after, 2 before each match
grep -o "[0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}" access.log   # print only IP addresses
```

Regex basics used with `grep -E`:

| Pattern | Means |
|---|---|
| `^abc` | Line starts with abc |
| `abc$` | Line ends with abc |
| `.` | Any single character |
| `a*` / `a+` / `a?` | 0+ / 1+ / 0 or 1 of `a` |
| `[0-9]` | A digit |
| `(a\|b)` | a or b |
| `\b` | Word boundary |

### Archives and compression

```bash
tar -czvf backup.tar.gz folder/      # create (c), gzip (z), verbose (v), file (f)
tar -tzvf backup.tar.gz              # list contents (t) — always check before extracting
tar -xzvf backup.tar.gz              # extract here
tar -xzvf backup.tar.gz -C /tmp/x    # extract into another directory
tar -cJvf backup.tar.xz folder/      # xz: smaller, slower
zip -r archive.zip folder/ && unzip archive.zip
gzip big.log && zcat big.log.gz | less
```

> 🔐 Always list (`-t`) an untrusted archive first. Archives can contain paths like `../../etc/cron.d/evil` ("path traversal" / "zip slip").

### Variables and environment

```bash
NAME="amar"               # shell variable (no spaces around =)
echo "Hello $NAME"
export APP_ENV=dev        # environment variable — passed to child programs
env | sort                # all environment variables
echo "$PATH"              # where the shell searches for commands
echo "$HOME $USER $SHELL"
which python3             # which file runs for "python3"
```

### History and aliases

```bash
history | tail                 # recent commands
!!                             # repeat last command
sudo !!                        # repeat last command with sudo
!42                            # run history entry 42
!$                             # last argument of the previous command
alias ll='ls -alF'             # define an alias (put it in ~/.bashrc to keep it)
unalias ll
```

> 🔐 Bash history is saved to `~/.bash_history`. Passwords typed on the command line (`mysql -pSecret`) end up there. Prefix a command with a **space** to keep it out of history (works when `HISTCONTROL` includes `ignorespace`, the Ubuntu default).

---

## 🔴 Level 3 — Advanced Text Processing

### `cut`, `sort`, `uniq`, `tr`, `column`

```bash
cut -d: -f1 /etc/passwd                 # field 1, ':' delimiter → usernames
cut -d: -f1,7 /etc/passwd               # usernames and shells
cut -c1-10 file                         # characters 1-10

sort names.txt                          # alphabetical
sort -n numbers.txt                     # numeric
sort -rn                                # numeric, reverse
sort -t, -k3 -n data.csv                # by 3rd comma-separated column
sort -u                                 # sort and remove duplicates
sort -h                                 # human sizes: 1K < 2M < 3G

uniq -c                                 # count consecutive duplicates (sort first!)
tr 'a-z' 'A-Z' < file                   # uppercase
tr -d '\r' < windows.txt > unix.txt     # remove Windows line endings
column -t -s: /etc/passwd | head        # align into a table
```

The classic "top N" pattern:

```bash
<produce lines> | sort | uniq -c | sort -rn | head
```

### `awk` — columns and logic

`awk` splits each line into fields: `$1`, `$2`… `$NF` is the last field, `NR` is the line number.

```bash
awk '{print $1}' access.log                       # first column
awk -F: '{print $1, $7}' /etc/passwd              # user and shell
awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd   # human users
awk -F: '$3 == 0 {print $1}' /etc/passwd          # anyone with UID 0 (should be only root)
awk '$9 >= 500 {print $7}' access.log             # URLs that returned 5xx (nginx log)
awk '{sum += $10} END {print sum/1024/1024 " MB"}' access.log   # total bytes sent
df -h | awk 'NR > 1 && $5+0 > 80 {print $6, $5}'  # filesystems over 80% full
ps aux | awk '$3 > 50 {print $2, $3, $11}'        # processes using >50% CPU
```

### `sed` — find and replace, filter lines

```bash
sed 's/http:/https:/' file           # replace first match on each line (prints result)
sed 's/http:/https:/g' file          # replace every match
sed -i.bak 's/old/new/g' file        # edit in place, keep file.bak ⚠️
sed -n '10,20p' file                 # print only lines 10–20
sed '/^#/d; /^$/d' sshd_config       # remove comments and blank lines
sed -n '/BEGIN/,/END/p' file         # print a block between two patterns
```

### `xargs` — turn output into arguments

```bash
find . -name "*.tmp" -print0 | xargs -0 rm -f      # -print0/-0 handle spaces in names
cat hosts.txt | xargs -I{} ping -c1 -W1 {}
grep -rl "oldname" src/ | xargs sed -i 's/oldname/newname/g'
```

### Comparing files

```bash
diff old.conf new.conf               # line differences
diff -u old.conf new.conf            # unified format (like git)
diff <(sort a.txt) <(sort b.txt)     # compare command outputs (process substitution)
comm -13 <(sort old.txt) <(sort new.txt)   # lines only in new.txt
sha256sum file.iso                   # checksum — compare with the published value
cmp -s a.bin b.bin && echo same      # byte-by-byte comparison
```

### Run commands on a schedule / repeatedly

```bash
watch -n 2 'ss -tan | wc -l'         # rerun every 2 seconds
time ./script.sh                     # how long it takes
cmd1 && cmd2                         # cmd2 only if cmd1 succeeded
cmd1 || cmd2                         # cmd2 only if cmd1 failed
cmd1 ; cmd2                          # both, regardless
```

---

## In Production

A typical "the app is broken" investigation, entirely with this chapter's commands:

```bash
ssh app01
sudo tail -n 100 /var/log/myapp/app.log              # what happened recently?
sudo grep -c "ERROR" /var/log/myapp/app.log          # how bad?
sudo grep "ERROR" /var/log/myapp/app.log | awk '{print $5}' | sort | uniq -c | sort -rn | head   # which error type?
sudo find /etc/myapp -mmin -60                        # did someone change config in the last hour?
diff -u /etc/myapp/app.yml.bak /etc/myapp/app.yml     # what changed?
```

---

## Product Security Perspective

Commands from this chapter answer real security questions:

| Question | Command |
|---|---|
| Which IPs failed SSH logins most often? | `sudo grep "Failed password" /var/log/auth.log \| awk '{print $(NF-3)}' \| sort \| uniq -c \| sort -rn \| head` |
| Are there accounts with UID 0 besides root? | `awk -F: '$3==0' /etc/passwd` |
| Which users can log in with a shell? | `grep -vE 'nologin\|false$' /etc/passwd \| cut -d: -f1,7` |
| Are secrets hard-coded in the source? | `grep -rnEi '(password\|secret\|api_key\|token)\s*[:=]' src/` |
| Are there AWS keys in the repo? | `grep -rnE 'AKIA[0-9A-Z]{16}' .` |
| What changed in `/etc` today? | `sudo find /etc -type f -mtime -1` |
| Did a downloaded file get tampered with? | `sha256sum file` vs. vendor checksum |
| Is SSH root login allowed? | `sudo grep -Ei '^\s*PermitRootLogin' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*` |

> Real secret-scanning tools (gitleaks, trufflehog) do this properly, but knowing the `grep` version helps you understand what they look for.

---

## Hands-on Lab 🟢→🔴

**Setup**

```bash
mkdir -p ~/labs/cmd && cd ~/labs/cmd
```

### Part 1 — Files 🟢

```bash
mkdir -p project/{src,docs,logs}
touch project/src/app{1..3}.py project/docs/README.md
tree project 2>/dev/null || find project
cp -r project project-backup
mv project/docs/README.md project/docs/INDEX.md
rm -r project-backup
ls -R project
```

### Part 2 — Create a fake web log 🟡

Copy this block in one go — it creates 200 log lines:

```bash
for i in $(seq 1 200); do
  ip="10.0.0.$((RANDOM % 6 + 1))"
  code=$(shuf -n1 -e 200 200 200 200 301 404 404 500)
  path=$(shuf -n1 -e / /login /admin /api/users /wp-login.php /.env)
  min=$(printf '%02d' $((i % 60)))
  echo "$ip - - [09/Nov/2026:10:$min:00 +0000] \"GET $path HTTP/1.1\" $code $((RANDOM % 5000))"
done > access.log
head -3 access.log
```

Now answer with pipelines:

```bash
wc -l access.log                                               # 1. total requests
awk '{print $1}' access.log | sort | uniq -c | sort -rn        # 2. requests per IP
awk '$9 == 404 {print $7}' access.log | sort | uniq -c | sort -rn   # 3. most common 404 paths
grep -E '"GET /(\.env|wp-login\.php|admin)' access.log | awk '{print $1}' | sort | uniq -c  # 4. who probed sensitive paths?
awk '$9 >= 500' access.log | wc -l                             # 5. how many server errors?
awk '{sum += $10} END {print sum " bytes"}' access.log         # 6. total bytes
```

### Part 3 — find, grep, sed 🟡

```bash
cat > app.conf <<'EOF'
# Application config
debug = true
db_password = SuperSecret123
api_url = http://api.internal
EOF

grep -nEi 'password|secret' app.conf             # find secrets
sed 's/debug = true/debug = false/' app.conf     # preview the change
sed -i.bak 's#http://#https://#' app.conf        # apply, keep backup
diff -u app.conf.bak app.conf
find ~/labs -name "*.bak" -mmin -10
```

### Part 4 — Security one-liners on your system 🔴

```bash
awk -F: '$3 == 0 {print "UID 0:", $1}' /etc/passwd
awk -F: '$3 >= 1000 && $3 < 65534 {print $1, $6, $7}' /etc/passwd
grep -vE 'nologin|false$' /etc/passwd | cut -d: -f1
sudo find /etc -type f -mtime -1 2>/dev/null
ls -la ~ | grep '^\-.*\.' | awk '{print $1, $NF}'     # hidden files in your home and their permissions
```

**Questions**

1. Which IP probed `/.env` most often? What would an attacker want from that file?
2. What's the difference between `>` and `>>`? What happens to `access.log` if you run Part 2's loop again with `>`?
3. Why does `sort` have to come before `uniq -c`?
4. Why did we use `#` instead of `/` as the `sed` delimiter in Part 3?

---

## Common Mistakes

- `rm -rf` in the wrong directory, or with an empty variable.
- Using `>` when you meant `>>` — the file is wiped before the command even runs.
- `uniq` without `sort` first — it only removes *adjacent* duplicates.
- `sed -i` without a backup on an important file.
- Forgetting quotes: `find . -name *.log` lets the shell expand `*.log` first. Use `"*.log"`.
- Parsing `ls` output in scripts — use `find` or globs instead.
- Typing passwords as command arguments — they appear in history and in `ps` output.

---

## Interview Questions

**1. What's the difference between `>` and `>>`?**
`>` truncates the file and writes; `>>` appends.

**2. What does `2>&1` mean?**
Redirect stderr (2) to wherever stdout (1) currently points, so both go to the same place.

**3. `find` vs `grep` vs `locate`?**
`find` searches the filesystem by name, size, time, owner, permissions. `grep` searches *inside* files for text. `locate` searches a prebuilt name database — fast but possibly out of date.

**4. How do you find the 10 IPs with the most requests in an access log?**
`awk '{print $1}' access.log | sort | uniq -c | sort -rn | head`

**5. How do you replace a string in many files?**
`grep -rl old . | xargs sed -i 's/old/new/g'` — after testing on one file and with a backup or version control.

**6. Why does `sudo echo text > /etc/file` fail?**
The redirection is performed by the calling (unprivileged) shell before `sudo` runs. Use `echo text | sudo tee /etc/file`.

**7. 🔐 How would you quickly check a codebase for hard-coded secrets?**
`grep -rnEi '(password|secret|token|api_key)\s*[:=]'` plus known patterns like `AKIA[0-9A-Z]{16}`, then use a dedicated scanner like gitleaks in CI.

**8. 🔐 Why is it risky to pass passwords as command-line arguments?**
They're visible to other users in `ps` / `/proc/<pid>/cmdline` and saved in shell history. Use prompts, files with restricted permissions, or environment/secret managers instead.

---

## Summary

- Learn a few commands deeply: `ls`, `cd`, `cp`, `mv`, `rm`, `less`, `tail -f`, `find`, `grep`.
- Redirection and pipes turn small tools into powerful one-liners.
- `cut`, `sort`, `uniq -c`, `awk` and `sed` answer most log questions in seconds.
- Be deliberate with destructive commands and careful with secrets on the command line.

**Next:** [04 — Users, Groups & Permissions](04-Users-Groups-Permissions.md)

---

## References

- GNU Coreutils manual — https://www.gnu.org/software/coreutils/manual/
- GNU grep, sed, gawk manuals — https://www.gnu.org/manual/
- `man bash` (sections REDIRECTION, Pattern Matching)
- explainshell — https://explainshell.com/ (paste any command to see what each part does)
