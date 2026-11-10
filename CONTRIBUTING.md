# Contributing

Thanks for helping improve the Product Security Handbook! Corrections, clearer explanations, new labs and better examples are all welcome.

## Ways to Contribute

- 🐛 **Fix a mistake** — wrong command, outdated flag, broken link, typo.
- 🧪 **Improve a lab** — clearer steps, expected output, Windows/macOS notes.
- ❓ **Add interview questions** — with concise, correct answers.
- 💡 **Suggest a topic** — open an issue first so we can agree on scope.

## Workflow

```bash
gh repo fork amarhiremath33/product-security-handbook --clone
cd product-security-handbook
git switch -c fix-<short-description>
# edit, then:
git add -p
git commit -m "Fix <what> in <chapter>"
git push -u origin HEAD
gh pr create --fill
```

## Style Guide

- Follow the chapter structure in [01-Linux/README.md](01-Linux/README.md#how-every-chapter-is-structured).
- Mark levels: 🟢 Basic · 🟡 Intermediate · 🔴 Advanced. Mark system-changing steps with ⚠️.
- Every command should be **tested** on a current Ubuntu LTS (say so if it's distro-specific).
- Use `sudo` explicitly; prefer long, readable options in examples where helpful.
- Include a **Product Security** angle: what can go wrong, how to detect or prevent it.
- Shell scripts must pass `shellcheck -S warning`.
- No real secrets, internal hostnames, or customer data — use `example.com`, `192.0.2.0/24`, `203.0.113.0/24`, `198.51.100.0/24`.

## Checks

Pull requests run automated checks (see `.github/workflows/checks.yml`):

- ShellCheck on all `*.sh` files
- PSScriptAnalyzer on all `*.ps1`, `*.psm1`, `*.psd1` files
- Internal link check on all Markdown files

Run them locally:

```bash
shellcheck -S warning $(git ls-files '*.sh')
pwsh -Command "git ls-files '*.ps1' | ForEach-Object { Invoke-ScriptAnalyzer -Path \$_ -Severity Warning,Error }"
```

## Code of Conduct

Be respectful and constructive. Assume good intent, and focus feedback on the content.
