# 04 — Your First GitHub Repository

> **Module:** 00 – Development Environment · **Level:** 🟢 Basic · **Time:** ~30 minutes

---

## Objectives

- Create a repository on GitHub and clone it.
- Add the files every good repository needs.
- Push changes, use branches and pull requests.
- Turn on GitHub's security features.

---

## Create and Clone

With the GitHub CLI (after [05 — SSH Authentication](05-GitHub-SSH-Authentication.md)):

```bash
gh repo create my-security-notes --public --add-readme --license mit --gitignore Python --clone
cd my-security-notes
```

Or create it on github.com (**New repository**) and clone with SSH:

```bash
git clone git@github.com:<username>/my-security-notes.git
```

---

## Files Every Repository Should Have

| File | Purpose |
|---|---|
| `README.md` | What it is, how to use it, where to start |
| `LICENSE` | Tells others what they may do with your work (MIT is simple and permissive) |
| `.gitignore` | Files Git must never track (secrets, build output, editor files) |
| `CONTRIBUTING.md` | How others can help |
| `SECURITY.md` | How to report a security problem privately |
| `CHANGELOG.md` | What changed and when |

---

## Everyday Flow

```bash
git switch -c add-notes
echo "## Day 1" >> notes.md
git add notes.md
git commit -m "Add day 1 notes"
git push -u origin add-notes
gh pr create --fill
gh pr merge --squash --delete-branch      # after reviewing the diff
git switch main && git pull
```

---

## Turn On Security Features

```bash
gh repo edit --enable-secret-scanning --enable-secret-scanning-push-protection
```

Or on github.com: **Settings → Code security** → enable Secret scanning, Push protection, Dependabot alerts, Private vulnerability reporting.

Add topics so people can find your work:

```bash
gh repo edit --add-topic linux --add-topic product-security --add-topic devsecops
```

---

## Hands-on Lab 🟢

1. Create a practice repository with a README, MIT license and `.gitignore`.
2. Create a branch, add a file, open a pull request, and merge it.
3. Enable secret scanning with push protection, then check **Settings → Code security** to confirm it's on.

---

## References

- GitHub Docs: Quickstart for repositories — https://docs.github.com/repositories/creating-and-managing-repositories/quickstart-for-repositories
- Choose a license — https://choosealicense.com/
