# 03 — Installing VS Code

> **Module:** 00 – Development Environment · **Level:** 🟢 Basic · **Time:** ~20 minutes

---

## Objectives

- Install Visual Studio Code on Ubuntu (from Microsoft's signed repository) or Windows.
- Install the extensions used throughout this handbook.
- Configure VS Code for Linux-friendly files (LF line endings, final newline).
- Open a repository, preview Markdown and use the built-in terminal and Git.

---

## Why VS Code?

- Free, open source core, runs on Linux, Windows and macOS.
- Built-in Git, terminal and Markdown preview.
- Extensions for Bash (ShellCheck), PowerShell, Docker, YAML, Kubernetes, Terraform.
- **Remote - SSH**: edit files on a server or VM as if they were local.

---

## Install on Ubuntu / Debian

Use Microsoft's apt repository so VS Code updates with `apt upgrade`. The key is trusted **only** for this repository (`signed-by=`) — see [Linux chapter 08](../01-Linux/08-Package-Management.md).

```bash
sudo apt install -y wget gpg apt-transport-https
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/microsoft.gpg
sudo install -D -o root -g root -m 644 /tmp/microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
rm -f /tmp/microsoft.gpg

echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
  | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

sudo apt update
sudo apt install -y code
code --version
```

Alternative (one command, auto-updating snap): `sudo snap install code --classic`. Use **one** method, not both.

## Install on Windows

```powershell
winget install --id Microsoft.VisualStudioCode -e
```

During setup, tick **"Add to PATH"** and **"Open with Code"** context-menu options.

For WSL users: install the **WSL** extension, then in an Ubuntu terminal run `code .` — VS Code on Windows opens the folder inside Linux.

---

## Recommended Extensions

```bash
code --install-extension timonwong.shellcheck               # Bash linting (needs: sudo apt install shellcheck)
code --install-extension DavidAnson.vscode-markdownlint      # Markdown style checks
code --install-extension yzhang.markdown-all-in-one         # Markdown shortcuts, table of contents
code --install-extension ms-vscode.powershell               # PowerShell (needs pwsh)
code --install-extension ms-vscode-remote.remote-ssh        # Edit files on VMs/servers over SSH
code --install-extension redhat.vscode-yaml                 # YAML (GitHub Actions, Kubernetes)
code --install-extension ms-azuretools.vscode-docker        # Dockerfiles and containers
```

> 🔐 Extensions run with **your** permissions and can read your files and tokens. Install only well-known extensions from verified publishers, and remove ones you don't use (`code --list-extensions`).

---

## Recommended Settings

`Ctrl+Shift+P` → **Preferences: Open User Settings (JSON)** and add:

```json
{
  "files.eol": "\n",
  "files.insertFinalNewline": true,
  "files.trimTrailingWhitespace": true,
  "editor.renderWhitespace": "boundary",
  "markdown.preview.breaks": false,
  "telemetry.telemetryLevel": "off"
}
```

`files.eol: "\n"` avoids the classic Windows problem where a script fails with `/bin/bash^M: bad interpreter`.

---

## Daily Use

```bash
cd ~/Claude_CLI/product_security/linux/product-security-handbook
code .
```

| Action | Shortcut |
|---|---|
| Command palette | `Ctrl+Shift+P` |
| Open file by name | `Ctrl+P` |
| Search in all files | `Ctrl+Shift+F` |
| Built-in terminal | `` Ctrl+` `` |
| Markdown preview side by side | `Ctrl+K V` |
| Source control (Git) | `Ctrl+Shift+G` |

### Remote - SSH (edit files on a lab VM)

1. `Ctrl+Shift+P` → **Remote-SSH: Connect to Host…**
2. Enter `user@192.168.122.50` (or a host from `~/.ssh/config`).
3. VS Code installs a small server on the VM and opens a window "inside" it.

---

## Hands-on Lab 🟢

1. Install VS Code and the extensions above.
2. Open this repository with `code .`.
3. Open `labs/linux/scripts/linux-security-audit.sh` — ShellCheck warnings (if any) appear underlined.
4. Open any chapter and press `Ctrl+K V` to preview it.
5. Make a small change, see it in the Source Control panel, and discard it.

---

## Common Mistakes

- Installing both the snap and the apt version — two `code` commands, confusing updates.
- Windows line endings in shell scripts.
- Installing random extensions with broad permissions.
- Committing `.vscode/` settings that contain personal paths or secrets (this repo's `.gitignore` excludes `.vscode/`).

---

## References

- VS Code on Linux — https://code.visualstudio.com/docs/setup/linux
- VS Code Remote - SSH — https://code.visualstudio.com/docs/remote/ssh
- Extension runtime security — https://code.visualstudio.com/docs/editor/extension-runtime-security
