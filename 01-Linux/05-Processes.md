# 05 — Processes

> **Module:** 01 – Linux · **Level:** 🟢 Basic → 🔴 Advanced · **Time:** ~2.5 hours
> **Lab environment:** WSL2, Docker or VM — see [labs/README.md](../labs/README.md)

---

## Objectives

After this chapter you will be able to:

- Explain programs, processes, threads, PIDs and PPIDs.
- Explain how processes are created (`fork` + `exec`) and how they end.
- List, filter, sort and monitor processes.
- Control jobs: foreground, background, `nohup`, `nice`.
- Send the right signal and know what each does.
- Investigate a suspicious process using `/proc`, `lsof` and `strace`.

---

## Program vs Process vs Thread

| | Program | Process | Thread |
|---|---|---|---|
| What | A file on disk | A running instance of a program | A unit of execution inside a process |
| Example | `/usr/sbin/nginx` | nginx master (PID 812) + workers | Worker threads in a Java app |
| Has its own memory? | — | Yes | No — shares its process's memory |
| ID | — | PID | TID (see with `ps -L`) |

One program can run as many processes. nginx typically runs one master process (root) and several workers (`www-data`).

---

## How Processes Are Born and Die

```text
     bash (PID 2458)
        │
        │ fork()   ← creates an exact copy: child PID 2601, PPID 2458
        ▼
     bash (PID 2601)
        │
        │ execve("/usr/bin/vim")   ← replaces the copy with a new program
        ▼
     vim (PID 2601, PPID 2458)
        │
        │ exit(0)  ← finishes, returns exit code
        ▼
     zombie (Z) until the parent calls wait() and collects the exit code
        │
        ▼
     gone
```

- **PID 1** is `systemd` (or `init`). It's the ancestor of every process.
- **PID 2** is `kthreadd`, the parent of kernel threads (shown in `[brackets]` in `ps`).
- **Orphan**: a process whose parent died. It's re-parented to PID 1 (or a "subreaper" such as `systemd --user`), which collects it when it exits.
- **Zombie**: a process that has exited but whose parent hasn't collected its exit status. It uses no CPU or memory — only a process-table slot. Many zombies mean a buggy parent.

### Exit codes

```bash
ls /etc > /dev/null; echo $?     # 0 = success
ls /nope 2>/dev/null; echo $?    # non-zero = failure (2 here)
```

| Code | Meaning |
|---|---|
| `0` | Success |
| `1`, `2` … | Program-specific error |
| `126` | Found but not executable |
| `127` | Command not found |
| `128 + N` | Killed by signal N (e.g. `137` = 128+9 = SIGKILL, often the OOM killer) |

---

## Process States

| State | Meaning | Notes |
|:-:|---|---|
| `R` | Running or runnable | On CPU or waiting for it |
| `S` | Sleeping (interruptible) | Waiting for an event — most processes |
| `D` | Uninterruptible sleep | Usually waiting for disk/NFS I/O; can't be killed until it returns |
| `T` | Stopped | Paused by `Ctrl+Z` or SIGSTOP, or being debugged |
| `Z` | Zombie | Exited, not yet reaped |
| `I` | Idle kernel thread | |

Extra characters in `ps aux` STAT: `s` session leader, `+` foreground, `l` multi-threaded, `<` high priority, `N` low priority.

---

## 🟢 Viewing Processes

```bash
ps                          # processes in this terminal
ps aux                      # all processes, BSD style
ps -ef                      # all processes, with PPID
ps -ef --forest             # tree view
pstree -p                   # tree with PIDs
pgrep -a nginx              # PID + command line of matching processes
pidof sshd                  # PIDs of an exact program name
```

Reading `ps aux`:

```text
USER   PID %CPU %MEM    VSZ   RSS TTY   STAT START  TIME COMMAND
root     1  0.0  0.1 167000 12000 ?     Ss   09:00  0:02 /sbin/init
amar  2458  0.0  0.0  10000  5000 pts/0 Ss   10:00  0:00 -bash
 │     │    │    │      │     │    │     │     │     │    └── command line
 │     │    │    │      │     │    │     │     │     └── CPU time used
 │     │    │    │      │     │    │     │     └── start time
 │     │    │    │      │     │    │     └── state
 │     │    │    │      │     │    └── terminal (? = none: daemon)
 │     │    │    │      │     └── RSS: real memory in KB
 │     │    │    │      └── VSZ: virtual memory in KB
 │     │    │    └── % of RAM
 │     │    └── % CPU
 │     └── process ID
 └── user it runs as
```

### Custom output 🟡

```bash
ps -eo pid,ppid,user,stat,%cpu,%mem,etime,cmd --sort=-%cpu | head    # top CPU users
ps -eo pid,user,rss,cmd --sort=-rss | head                            # top memory users
ps -o pid,ppid,cmd -p 1234                                            # one process
ps -u www-data                                                        # by user
ps -eLf | wc -l                                                       # total threads
```

### Live monitoring

```bash
top          # P = sort by CPU, M = memory, k = kill, 1 = per-CPU, c = full command, q = quit
htop         # friendlier: F3 search, F4 filter, F5 tree, F9 kill (sudo apt install htop)
```

`top` header explained:

```text
load average: 0.52, 0.38, 0.30   ← 1, 5, 15 minute averages of runnable (+ D state) processes
                                    compare with CPU count (nproc). Load 4.0 on 4 CPUs = fully busy
%Cpu(s):  5.0 us, 2.0 sy, 0.0 ni, 92.0 id, 1.0 wa, 0.0 st
           user   kernel   nice     idle    I/O wait   stolen by hypervisor
```

High `wa` → disk bottleneck. High `st` → noisy neighbour on a cloud VM.

---

## 🟡 Jobs: Foreground and Background

```bash
sleep 300            # foreground: terminal is busy
# press Ctrl+Z       → stopped (T)
bg                   # continue it in the background
jobs                 # list jobs in this shell: [1]+ Running  sleep 300 &
fg %1                # bring job 1 to the foreground
sleep 300 &          # start directly in the background
kill %1              # signal job 1
```

Background jobs die when you close the terminal (they receive SIGHUP). To keep something running after logout:

```bash
nohup ./long-task.sh > task.log 2>&1 &     # ignore SIGHUP
disown -h %1                                 # detach an existing job from the shell
tmux / screen                                # better: re-attachable terminal sessions
systemd-run --user --unit=mytask ./long-task.sh   # best: run as a managed transient service
```

### Priority (`nice`)

Nice ranges from `-20` (highest priority) to `19` (lowest). Normal users can only lower priority.

```bash
nice -n 10 tar czf backup.tgz /data     # start with lower priority
sudo renice -n 5 -p 1234                 # change a running process
ionice -c3 rsync -a src/ dst/            # lowest disk I/O priority
```

---

## 🟡 Signals

Signals are messages the kernel delivers to a process.

| Signal | No. | Default action | Use |
|---|:-:|---|---|
| `SIGHUP` | 1 | Terminate | Terminal closed. Many daemons (nginx, sshd) **reload config** on SIGHUP by convention |
| `SIGINT` | 2 | Terminate | `Ctrl+C` |
| `SIGQUIT` | 3 | Terminate + core dump | `Ctrl+\` |
| `SIGKILL` | 9 | Terminate | **Can't be caught or ignored**; no cleanup |
| `SIGTERM` | 15 | Terminate | Polite "please exit" — default for `kill` |
| `SIGSTOP` | 19 | Stop | Can't be caught |
| `SIGTSTP` | 20 | Stop | `Ctrl+Z` |
| `SIGCONT` | 18 | Continue | Resume stopped process |
| `SIGUSR1/2` | 10/12 | Terminate | App-defined (e.g. reopen log files) |

```bash
kill 1234              # SIGTERM
kill -TERM 1234        # same, by name
kill -HUP $(pidof nginx | awk '{print $NF}')   # reload — but prefer: systemctl reload nginx
kill -9 1234           # SIGKILL — last resort
pkill -u bob           # all of bob's processes
pkill -f "python app.py"   # match against the full command line
killall nginx          # by exact name
kill -l                # list all signals
```

**Order of escalation:** `SIGTERM` → wait a few seconds → `SIGKILL`. SIGKILL skips cleanup: temp files stay, locks aren't released, data may be half-written.

> On systemd-managed services, use `systemctl stop/restart/reload` instead of `kill`, or systemd will restart the process (and you lose the logs explaining why).

---

## 🔴 Inside a Process: `/proc/<PID>`

```bash
PID=$(pgrep -o sshd)                 # oldest sshd process
sudo ls -l /proc/$PID/exe            # which binary is running
sudo tr '\0' ' ' < /proc/$PID/cmdline; echo
sudo ls -l /proc/$PID/cwd            # working directory
sudo ls -l /proc/$PID/fd | head      # open files and sockets
sudo cat /proc/$PID/status | grep -E 'Name|State|PPid|Uid|Gid|Threads|VmRSS|Cap'
sudo tr '\0' '\n' < /proc/$PID/environ   # environment (may contain secrets)
sudo cat /proc/$PID/maps | head      # loaded libraries and memory regions
cat /proc/$PID/limits                # resource limits (open files, etc.)
```

## 🔴 Open Files and Network Sockets: `lsof`

"Everything is a file" — including network connections.

```bash
sudo lsof -p 1234                # everything process 1234 has open
sudo lsof -i :22                 # who uses port 22
sudo lsof -i -P -n               # all network connections, numeric
sudo lsof -u www-data            # files opened by a user
sudo lsof /var/log/syslog        # who has this file open
sudo lsof +L1                    # deleted files still held open (disk-space mystery)
```

## 🔴 Tracing System Calls: `strace`

```bash
strace -f -e trace=openat,connect ./app       # which files and hosts does it touch?
sudo strace -p 1234 -f -e trace=network       # attach to a running process
strace -c ls                                   # syscall summary
```

## 🔴 Resource Limits and the OOM Killer

```bash
ulimit -a                         # limits for this shell
ulimit -n                         # max open files
cat /proc/1234/limits             # limits of a process
free -h                           # memory
sudo dmesg -T | grep -i -E 'killed process|out of memory'   # OOM kills
cat /proc/1234/oom_score          # how likely the OOM killer is to pick it
```

When RAM runs out, the kernel's **OOM killer** picks a process (usually the biggest) and sends SIGKILL. The process exits with code 137 and the kernel log records it.

### cgroups (preview)

Control groups limit and account CPU, memory and I/O for groups of processes. systemd puts every service in its own cgroup, and containers are built on them.

```bash
systemd-cgls | head -30          # cgroup tree
systemd-cgtop                    # resource use per cgroup (like top)
cat /proc/self/cgroup            # which cgroup am I in?
```

---

## In Production

```text
            systemd (PID 1)
           /       |        \
      sshd       nginx       containerd
        |      master(root)       |
      sshd      /     \       containerd-shim
     (amar)  worker  worker        |
        |   (www-data)        java app (UID 1001)
      bash
```

Typical questions and answers:

| Question | Command |
|---|---|
| Is the service running? | `systemctl status nginx` / `pgrep -a nginx` |
| What's eating CPU? | `top`, then `P` |
| What's eating memory? | `ps -eo pid,rss,cmd --sort=-rss \| head` |
| Why did the app die? | `journalctl -u myapp`, `dmesg -T \| grep -i oom` |
| Who's listening on port 8080? | `sudo ss -tlnp 'sport = :8080'` / `sudo lsof -i :8080` |
| Why is it hung? | Check state (`D`?), `sudo strace -p PID` |

---

## Product Security Perspective

### Signs of a suspicious process

| Indicator | How to check |
|---|---|
| Binary deleted after starting (malware hides itself) | `sudo ls -l /proc/*/exe 2>/dev/null \| grep deleted` |
| Running from `/tmp`, `/dev/shm`, `/var/tmp` | `sudo ls -l /proc/*/exe 2>/dev/null \| grep -E '/tmp\|/dev/shm'` |
| Name looks like a kernel thread but has a real binary | `[kworker]` in `ps` but `/proc/PID/exe` points to a file |
| Unexpected parent (web server spawning a shell) | `ps -ef --forest`, look for `www-data` → `sh` / `bash` |
| Unexpected network connections | `sudo ss -tnp`, `sudo lsof -i -P -n` |
| Very high CPU from an unknown process | Cryptominers |
| Running as root when it shouldn't | `ps -eo user,pid,cmd \| grep -v '^root' ` vs expectations |
| Secrets in command lines or env | `ps -eo cmd`, `/proc/PID/environ` |

### Investigate before you kill

When you find something malicious, **collect evidence first** — killing it destroys in-memory evidence.

```bash
PID=4242
sudo ls -l /proc/$PID/exe /proc/$PID/cwd
sudo tr '\0' ' ' < /proc/$PID/cmdline; echo
sudo cp /proc/$PID/exe /root/evidence-$PID.bin      # recovers the binary even if deleted
sudo sha256sum /root/evidence-$PID.bin
sudo ls -l /proc/$PID/fd
sudo ss -tnp | grep "pid=$PID"
ps -o pid,ppid,user,lstart,cmd -p $PID
sudo kill -STOP $PID        # freeze it (can't run, but evidence stays)
# ...after evidence is collected and the incident lead agrees:
sudo kill -9 $PID
```

> 🔐 `hidepid`: by default every user can see every process's command line. Mounting `/proc` with `hidepid=invisible` hides other users' processes — useful on shared systems.

---

## Hands-on Lab 🟢→🔴

### Part 1 — Explore 🟢

```bash
ps -ef --forest | head -40
pstree -p | head -30
ps -eo pid,ppid,user,stat,cmd --sort=-%mem | head
top          # press P, M, 1, then q
```

### Part 2 — Jobs and signals 🟢

```bash
sleep 1000 &
sleep 2000 &
jobs
fg %1            # then press Ctrl+Z
jobs             # job 1 is Stopped
bg %1
kill %1 %2
jobs
```

### Part 3 — Exit codes and signals 🟡

```bash
sleep 100 & PID=$!
kill -9 $PID; wait $PID; echo "exit code: $?"     # 137 = 128 + 9
sleep 100 & PID=$!
kill $PID;    wait $PID; echo "exit code: $?"     # 143 = 128 + 15
```

### Part 4 — A process that handles signals 🟡

```bash
cat > ~/labs/trap.sh <<'EOF'
#!/bin/bash
trap 'echo "Got SIGTERM, cleaning up..."; exit 0' TERM
trap 'echo "Got SIGHUP, reloading config..."' HUP
echo "My PID is $$"
while true; do sleep 1; done
EOF
chmod +x ~/labs/trap.sh
~/labs/trap.sh &
PID=$!
sleep 1
kill -HUP $PID       # handled: keeps running
kill -TERM $PID      # handled: clean exit
```

Try `kill -9` on a new copy — the trap never runs.

### Part 5 — Create and reap a zombie 🔴

```bash
bash -c 'sleep 1 & exec sleep 30' &
sleep 2
ps -eo pid,ppid,stat,cmd | grep -E 'Z|sleep' | grep -v grep
```

The inner `sleep 1` is a **zombie** (`Z`): its parent was replaced by `sleep 30`, which never calls `wait()`. When the parent exits after 30 s, the zombie is re-parented and reaped.

### Part 6 — Investigate a "suspicious" process 🔴

Simulate malware that runs from `/tmp` and deletes itself:

```bash
cp /usr/bin/sleep /tmp/.kworker
/tmp/.kworker 900 &
rm /tmp/.kworker
```

Now investigate as if you didn't know:

```bash
ls -l /proc/*/exe 2>/dev/null | grep deleted
PID=$(pgrep -x .kworker)         # -x = exact process name
ls -l /proc/$PID/exe
tr '\0' ' ' < /proc/$PID/cmdline; echo
cp /proc/$PID/exe ~/labs/recovered.bin && sha256sum ~/labs/recovered.bin /usr/bin/sleep
kill $PID
```

The hashes match — you recovered a deleted binary from memory.

### Part 7 — lsof and strace 🔴

```bash
sudo apt install -y lsof strace
python3 -m http.server 8000 >/dev/null 2>&1 &
PID=$!
sudo lsof -p $PID -a -i          # its listening socket
sudo ss -tlnp | grep 8000
strace -f -e trace=openat,connect curl -s -o /dev/null http://localhost:8000 2>&1 | tail -5
kill $PID
```

**Questions**

1. What exit code did SIGKILL produce and why?
2. Why didn't the trap run for `kill -9`?
3. How did you find the deleted binary, and how did you recover it?
4. Why collect evidence before killing a malicious process?

---

## Common Mistakes

- Reaching for `kill -9` first.
- Killing a systemd service's PID instead of using `systemctl` — it restarts and you lose context.
- Trying to `kill` a zombie — it's already dead; fix or restart the parent.
- Running long jobs in a plain SSH session without `tmux`/`nohup`.
- Treating load average as a percentage — compare it with `nproc`.
- Killing malware before capturing evidence.

---

## Interview Questions

**1. Program vs process?**
A program is a file on disk; a process is a running instance with its own PID, memory and state.

**2. How is a new process created?**
`fork()` duplicates the parent; `execve()` replaces the child's image with a new program.

**3. What is a zombie? How do you get rid of one?**
A process that has exited but whose parent hasn't reaped it with `wait()`. You can't kill it; fix or restart the parent, after which PID 1 adopts and reaps it.

**4. What is an orphan process?**
A child whose parent exited; it's adopted by PID 1 (or a subreaper) and keeps running.

**5. SIGTERM vs SIGKILL?**
SIGTERM asks the process to exit and can be handled for cleanup. SIGKILL is handled by the kernel, can't be caught, and terminates immediately without cleanup.

**6. A process exited with code 137. What happened?**
It was killed by signal 9 (128+9). Often the OOM killer — check `dmesg` or `journalctl -k`.

**7. What does load average mean?**
The average number of processes running or waiting (runnable plus uninterruptible) over 1, 5 and 15 minutes. Compare with CPU count.

**8. What is state `D` and why can't you kill it?**
Uninterruptible sleep — waiting on I/O inside the kernel. Signals are delivered only when it returns; the fix is usually the storage/NFS problem.

**9. 🔐 How would you investigate a suspicious process?**
Identify binary (`/proc/PID/exe`), command line, parent, user, start time, open files and network connections (`lsof`, `ss`), copy the binary and hash it, check persistence, freeze with SIGSTOP, then kill once evidence is preserved.

**10. 🔐 Why is it a problem that a web server spawns `/bin/sh`?**
Web servers rarely need a shell; it's a classic sign of command injection or a web shell.

---

## Summary

- Processes are created by `fork` + `exec`; PID 1 (systemd) is the ancestor of all.
- `ps`, `top`, `pgrep`, `pstree` show what's running; `/proc/PID` shows everything about one process.
- Use signals deliberately: TERM before KILL; HUP often means reload.
- `lsof`, `ss` and `strace` reveal files, sockets and syscalls.
- In an incident, collect evidence from `/proc` before killing.

**Next:** [06 — Linux Networking](06-Linux-Networking.md)

---

## References

- `man ps`, `man top`, `man 7 signal`, `man 5 proc`, `man lsof`, `man strace`, `man 7 cgroups`
- Brendan Gregg, *Linux Performance* — https://www.brendangregg.com/linuxperf.html
