# 02 — Creating and Securing a GitHub Account

> **Module:** 00 – Development Environment · **Level:** 🟢 Basic · **Time:** ~20 minutes

---

## Objectives

- Create a GitHub account with a professional username.
- Secure it with 2FA and recovery codes.
- Keep your email private.
- Set up a profile that works as a portfolio.

---

## Create the Account

1. Go to https://github.com/signup.
2. Choose a username you'd be happy to show an employer — it appears in every repository URL.
3. Use a password manager to generate a unique password.

---

## Secure It (do this immediately)

| Setting | Where | Why |
|---|---|---|
| **Two-factor authentication** | Settings → Password and authentication | Stops account takeover with a stolen password. Prefer a **passkey** or **security key**, then an authenticator app; avoid SMS |
| **Recovery codes** | Shown when enabling 2FA | Store them in your password manager — losing 2FA without them can lock you out permanently |
| **Private email** | Settings → Emails → Keep my email address private | Your real email isn't exposed in commits |
| **Block pushes that expose email** | Same page | Prevents accidental exposure |
| **Review sessions** | Settings → Sessions | Sign out devices you don't recognise |
| **Review authorised apps** | Settings → Applications | Revoke OAuth apps and tokens you don't use (e.g. old GitHub CLI tokens) |
| **SSH keys** | Settings → SSH and GPG keys | Remove keys from old machines |

---

## Make Your Profile a Portfolio

- Add a photo, short bio ("Learning Product Security · Linux · DevSecOps"), and location.
- Create a profile README: a repository named exactly like your username, with a `README.md`.
- **Pin** your best repositories (this handbook!).
- Commit regularly — consistent small progress is visible on your contribution graph.

---

## Repository Security Settings

For each public repository: **Settings → Code security**:

- ✅ Secret scanning + **Push protection**
- ✅ Dependabot alerts
- ✅ Private vulnerability reporting

---

## References

- GitHub 2FA — https://docs.github.com/authentication/securing-your-account-with-two-factor-authentication-2fa
- Email privacy — https://docs.github.com/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-email-preferences/setting-your-commit-email-address
