# 01 — Installing and Configuring Git

> **Module:** 00 – Development Environment · **Level:** 🟢 Basic · **Time:** ~30 minutes

---

## Objectives

- Install Git on Linux and Windows.
- Configure your identity and sensible defaults.
- Understand the basic Git workflow: working tree → staging → commit → push.
- Use branches and avoid committing secrets.

---

## Install

| OS | Command |
|---|---|
| Ubuntu / Debian | `sudo apt update && sudo apt install -y git` |
| RHEL / Fedora | `sudo dnf install -y git` |
| Windows | `winget install --id Git.Git -e` (includes Git Bash) |
| macOS | `xcode-select --install` or `brew install git` |

```bash
git --version
```

---

## Configure (once per machine)

```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"      # or your GitHub noreply address
git config --global init.defaultBranch main
git config --global pull.rebase false                 # merge on pull (simple default)
git config --global core.autocrlf input               # Linux/macOS: keep LF line endings
# Windows: git config --global core.autocrlf true
git config --global core.editor "code --wait"         # use VS Code for commit messages
git config --list --show-origin                       # see everything and where it's set
```

> 🔐 **Privacy:** your commit email is public on GitHub. Use the address GitHub gives you under **Settings → Emails → Keep my email address private** (`<id>+<username>@users.noreply.github.com`).

---

## How Git Works

```text
 Working tree ──git add──► Staging area ──git commit──► Local repository ──git push──► GitHub
      ▲                                                        │
      └────────────────────── git pull / git switch ◄──────────┘
```

| Command | Does |
|---|---|
| `git status` | What changed? What's staged? |
| `git diff` / `git diff --staged` | Changes not staged / staged |
| `git add file` / `git add -p` | Stage a file / stage hunks interactively |
| `git commit -m "msg"` | Save a snapshot |
| `git log --oneline --graph -20` | History |
| `git switch -c feature-x` | Create and switch to a branch |
| `git push -u origin feature-x` | Publish the branch |
| `git pull` | Get and merge remote changes |
| `git restore file` | Discard local changes ⚠️ |
| `git restore --staged file` | Unstage |

---

## A Good Workflow (even when working alone)

```bash
git switch main && git pull
git switch -c linux-chapter-06
# ... edit ...
git add -p
git commit -m "Add Linux networking lab"
git push -u origin linux-chapter-06
gh pr create --fill          # open a pull request, review the diff on GitHub, then merge
```

Commit message style:

```text
Add Linux networking lab           ← imperative, ≤ 50 chars

Covers ip, ss, dig and tcpdump with a      ← optional body: what and why
plain-text password sniffing exercise.
```

---

## Never Commit Secrets

- Keep `.env`, keys and tokens out of the repo — `.gitignore` already excludes `.env`, `*.pem`, `*.key`.
- Check before committing: `git diff --staged | grep -iE 'password|secret|token|BEGIN .*PRIVATE KEY'`
- If a secret is pushed: **revoke/rotate it first** (it's already exposed), then clean history.
- GitHub **secret scanning with push protection** blocks many secrets automatically.

---

## Hands-on Lab 🟢

```bash
mkdir -p ~/labs/git-practice && cd ~/labs/git-practice
git init
echo "# Practice" > README.md
git add README.md && git commit -m "Initial commit"
git switch -c feature
echo "New line" >> README.md
git commit -am "Add a line"
git switch main && git merge feature
git log --oneline --graph
```

---

## References

- Pro Git book (free) — https://git-scm.com/book
- GitHub Git cheat sheet — https://education.github.com/git-cheat-sheet-education.pdf
