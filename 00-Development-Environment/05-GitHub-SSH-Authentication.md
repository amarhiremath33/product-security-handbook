# GitHub SSH Authentication

---

# Objective

By the end of this chapter, you will be able to:

- Understand why SSH is preferred over HTTPS for GitHub authentication.
- Install and verify Git.
- Check for existing SSH keys.
- Reuse an existing SSH key or create a new one.
- Configure the SSH Agent.
- Add your SSH key to GitHub.
- Test SSH authentication.
- Convert an existing repository from HTTPS to SSH.
- Push code securely to GitHub.
- Troubleshoot common authentication problems.
- Understand Product Security best practices related to SSH authentication.

---

# Why SSH Instead of HTTPS?

GitHub repositories can be accessed using two authentication methods:

- HTTPS
- SSH

Both methods are secure, but SSH provides a smoother experience for developers working regularly with Git repositories.

## HTTPS Authentication

Example:

```text
https://github.com/username/repository.git
```

Typical workflow:

- Username
- Personal Access Token (PAT)
- Authentication required repeatedly (depending on credential manager)

Advantages:

- Easy for beginners
- Works everywhere

Disadvantages:

- Requires Personal Access Tokens
- Credential management can become difficult
- Automation is less convenient

---

## SSH Authentication

Example:

```text
git@github.com:username/repository.git
```

Authentication happens using a cryptographic key pair.

Advantages:

- No password required after setup
- Faster workflow
- Better for automation
- Ideal for CI/CD
- Industry standard for developers

---

# HTTPS vs SSH

| Feature | HTTPS | SSH |
|----------|--------|-----|
| Password Required | Yes (PAT) | No |
| Uses Key Pair | No | Yes |
| Good for Automation | Limited | Excellent |
| Secure | Yes | Yes |
| Recommended for Developers | Good | Excellent |

---

# How SSH Authentication Works

```text
                +-----------------------+
                |    Local Computer     |
                |                       |
                | Private Key           |
                | id_ed25519            |
                +-----------+-----------+
                            |
                            |
                    Encrypted SSH
                            |
                            |
                +-----------v-----------+
                |       GitHub          |
                |                       |
                | Public Key            |
                +-----------------------+
```

The private key never leaves your computer.

GitHub stores only the public key.

When you connect:

1. GitHub sends a challenge.
2. Your private key signs the challenge.
3. GitHub verifies it using your public key.
4. Authentication succeeds.

---

# Prerequisites

- Windows, Linux, or macOS
- Internet connection
- GitHub account
- Git installed
- Terminal
- SSH client (OpenSSH)

---

# Installing Git

## Windows

Download Git from:

https://git-scm.com/downloads

Run the installer using default settings.

---

## Ubuntu

```bash
sudo apt update
sudo apt install git -y
```

---

## Fedora

```bash
sudo dnf install git
```

---

## macOS

```bash
brew install git
```

or

```bash
xcode-select --install
```

---

# Verify Git Installation

Run:

```bash
git --version
```

Example:

```text
git version 2.50.1
```

If Git is installed successfully, its version will be displayed.

---

# Check Existing SSH Keys

Before creating a new key, check whether one already exists.

Linux/macOS:

```bash
ls ~/.ssh
```

Windows PowerShell:

```powershell
dir $HOME\.ssh
```

Example:

```text
id_ed25519
id_ed25519.pub
known_hosts
config
```

---

# Understanding SSH Key Files

| File | Purpose |
|------|----------|
| id_ed25519 | Private key |
| id_ed25519.pub | Public key |
| known_hosts | Trusted hosts |
| config | SSH configuration |

---

# Reusing an Existing SSH Key

If you already have:

```text
id_ed25519
id_ed25519.pub
```

there is usually no need to create another key.

Simply add the existing public key to GitHub.

Reusing an existing key helps avoid unnecessary key management.

---

# Creating a New SSH Key (Optional)

If no key exists:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Example:

```bash
ssh-keygen -t ed25519 -C "amar@example.com"
```

Output:

```text
Generating public/private ed25519 key pair.
```

Press Enter to accept the default location.

Optionally enter a passphrase.

Generated files:

```text
~/.ssh/id_ed25519
~/.ssh/id_ed25519.pub
```

---

# Start the SSH Agent

Linux/macOS:

```bash
eval "$(ssh-agent -s)"
```

Example:

```text
Agent pid 2531
```

Windows PowerShell:

```powershell
Start-Service ssh-agent
```

---

# Add the SSH Key to the Agent

```bash
ssh-add ~/.ssh/id_ed25519
```

Output:

```text
Identity added:
~/.ssh/id_ed25519
```

---

# Copy the Public Key

Display the public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Windows:

```powershell
type $HOME\.ssh\id_ed25519.pub
```

Example:

```text
ssh-ed25519 AAAAC3Nz...yourkey... user@example.com
```

Copy the entire contents.

---

# Add SSH Key to GitHub

Open GitHub.

Navigate to:

```text
Settings
    ↓
SSH and GPG Keys
    ↓
New SSH Key
```

Provide:

Title

Example:

```text
Work Laptop
```

Key

Paste the copied public key.

Click:

```text
Add SSH Key
```

---

# Test SSH Authentication

Run:

```bash
ssh -T git@github.com
```

The first connection may display:

```text
The authenticity of host 'github.com' can't be established.
```

Type:

```text
yes
```

Expected output:

```text
Hi username!

You've successfully authenticated,
but GitHub does not provide shell access.
```

---

# Why GitHub Says "GitHub Does Not Provide Shell Access"

Many beginners think this message indicates an error.

It does not.

GitHub is not a Linux server intended for interactive shell sessions.

The SSH connection exists only for Git operations such as:

- clone
- fetch
- pull
- push

The message:

```text
GitHub does not provide shell access.
```

actually confirms that:

- Authentication succeeded
- Your SSH key is valid
- GitHub recognizes your account

---

# Change Repository Remote from HTTPS to SSH

Check the current remote:

```bash
git remote -v
```

Example:

```text
origin
https://github.com/user/repository.git
```

Change it:

```bash
git remote set-url origin git@github.com:username/repository.git
```

Example:

```bash
git remote set-url origin git@github.com:amarhiremath33/product-security-handbook.git
```

---

# Verify the Remote

Run:

```bash
git remote -v
```

Expected:

```text
origin
git@github.com:amarhiremath33/product-security-handbook.git (fetch)

origin
git@github.com:amarhiremath33/product-security-handbook.git (push)
```

---

# Test Git Push

Make a small change.

```bash
git add .
```

Commit:

```bash
git commit -m "Test SSH authentication"
```

Push:

```bash
git push
```

Expected:

```text
Enumerating objects...

Counting objects...

Writing objects...

To github.com:user/repository.git
```

The push should complete without asking for a password.

---

# Complete Authentication Flow

```text
Developer

    │

    │ git push

    ▼

SSH Client

    │

    │ Uses Private Key

    ▼

GitHub

    │

    │ Verifies Public Key

    ▼

Authentication Successful

    │

    ▼

Repository Updated
```

---

# Common Authentication Errors

## Permission denied (publickey)

Example:

```text
Permission denied (publickey).
```

Possible causes:

- SSH key not added
- Wrong private key
- SSH Agent not running
- Public key missing from GitHub

---

## Repository Not Found

```text
Repository not found.
```

Possible causes:

- Wrong repository name
- No repository access
- Incorrect remote URL

---

## Could Not Read from Remote Repository

```text
Could not read from remote repository.
```

Possible causes:

- Wrong SSH URL
- Missing permissions
- Deleted repository

---

## Authentication Failed

Occurs when:

- HTTPS credentials are outdated
- PAT expired
- Incorrect authentication method

Switching to SSH typically resolves this issue.

---

# Troubleshooting

## Verify SSH Authentication

```bash
ssh -T git@github.com
```

---

## Verify SSH Agent

```bash
ssh-add -l
```

---

## Verify Remote

```bash
git remote -v
```

---

## Display SSH Configuration

```bash
cat ~/.ssh/config
```

---

## Enable Verbose SSH Logging

```bash
ssh -vT git@github.com
```

This command displays detailed information useful for diagnosing authentication problems.

---

# Product Security Perspective

SSH authentication aligns with secure software development practices.

Benefits include:

- Strong cryptographic authentication
- Reduced credential exposure
- Better support for automation
- Elimination of password reuse
- Easier integration with secure CI/CD pipelines

In Product Security, protecting source code repositories is critical because repositories often contain:

- Source code
- Infrastructure as Code (IaC)
- Deployment pipelines
- Security configurations
- Build automation
- Secrets scanning workflows

Compromised repository access can lead to supply chain attacks, malicious code injection, or unauthorized changes. SSH key-based authentication reduces reliance on reusable passwords and is considered a security best practice.

---

# Best Practices

- Prefer Ed25519 keys over RSA for new deployments.
- Protect private keys with a strong passphrase.
- Never share your private key.
- Add only the public key to GitHub.
- Regularly review and remove unused SSH keys from your GitHub account.
- Use separate SSH keys for personal and work accounts when appropriate.
- Store private keys securely.
- Rotate keys if compromise is suspected.
- Verify repository URLs before pushing sensitive code.
- Enable Multi-Factor Authentication (MFA) on your GitHub account.

---

# Common Mistakes

- Uploading the private key instead of the public key.
- Creating unnecessary SSH keys without checking for existing ones.
- Forgetting to start the SSH Agent.
- Forgetting to add the key to GitHub.
- Using an incorrect repository URL.
- Assuming "GitHub does not provide shell access" is an error.
- Mixing HTTPS and SSH remotes within the same workflow.
- Storing private keys in publicly accessible locations.

---

# Hands-on Lab

## Objective

Configure SSH authentication for GitHub and verify secure repository access.

## Lab Steps

1. Install Git.
2. Verify the Git installation.
3. Check for existing SSH keys.
4. Reuse an existing key or generate a new Ed25519 key.
5. Start the SSH Agent.
6. Add the private key to the agent.
7. Copy the public key.
8. Add the public key to your GitHub account.
9. Test SSH authentication using `ssh -T git@github.com`.
10. Convert an existing repository from HTTPS to SSH.
11. Verify the configured remote.
12. Commit a small change.
13. Push the change to GitHub using SSH.

### Success Criteria

- SSH authentication succeeds.
- The repository remote uses the SSH URL.
- `git push` completes without prompting for a password.
- Changes appear successfully on GitHub.

---

# Interview Questions

## Basic

1. What is SSH?
2. What is the difference between SSH and HTTPS for Git?
3. Why is SSH preferred for developers?
4. What is an SSH key pair?
5. What is the difference between a public key and a private key?

---

## Intermediate

6. What does `ssh-agent` do?
7. Why is `ssh-add` required?
8. Why does GitHub display "GitHub does not provide shell access"?
9. How do you convert an existing repository from HTTPS to SSH?
10. How do you verify the configured Git remote?

---

## Advanced

11. Why is Ed25519 generally preferred over RSA for new SSH keys?
12. How would you troubleshoot a `Permission denied (publickey)` error?
13. How can SSH authentication improve CI/CD security?
14. How should SSH keys be managed across personal and enterprise environments?
15. What are the security risks if a private SSH key is compromised?

---

# Summary

In this chapter, you learned how to:

- Install and verify Git.
- Understand the benefits of SSH authentication.
- Check for existing SSH keys.
- Reuse or generate an SSH key pair.
- Configure and use the SSH Agent.
- Add an SSH public key to GitHub.
- Test SSH authentication successfully.
- Understand why GitHub does not provide shell access.
- Convert repository remotes from HTTPS to SSH.
- Verify repository configuration.
- Push code securely without password prompts.
- Troubleshoot common SSH authentication issues.
- Apply Product Security best practices for secure repository access.

SSH authentication is the recommended approach for developers and security engineers because it provides secure, reliable, and efficient access to Git repositories while supporting modern development and DevSecOps workflows.

---

# References

- Git Documentation: https://git-scm.com/doc
- Git Downloads: https://git-scm.com/downloads
- GitHub SSH Documentation: https://docs.github.com/authentication/connecting-to-github-with-ssh
- OpenSSH Documentation: https://www.openssh.com/manual.html
- GitHub Security Best Practices: https://docs.github.com/authentication
- Ed25519 Information: https://ed25519.cr.yp.to/