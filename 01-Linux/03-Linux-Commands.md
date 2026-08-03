# Linux Commands – Day 1

## Objective

Learn the fundamental Linux commands required to navigate the filesystem and understand the current user and working directory.

---

# Commands Covered

* `pwd`
* `cd`
* `whoami`
* Understanding `/`
* Understanding `~`
* Understanding `$HOME`

---

# 1. `pwd` (Print Working Directory)

## Purpose

Displays the absolute path of the current working directory.

## Syntax

```bash
pwd
```

## Example

```bash
root@dev:/etc# pwd
/etc
```

## Explanation

The command prints the full path of your current location in the Linux filesystem.

---

# 2. `whoami`

## Purpose

Displays the currently logged-in user.

## Syntax

```bash
whoami
```

## Example

```bash
root@dev:/# whoami
```

Output

```text
root
```

## Use Case

Useful when working with multiple users or using `sudo` to verify which account is executing commands.

---

# 3. `cd` (Change Directory)

## Purpose

Changes the current working directory.

## Syntax

```bash
cd <directory>
```

## Examples

Go to the root user's home directory:

```bash
cd ~
```

Go to the filesystem root:

```bash
cd /
```

Go back to your home directory:

```bash
cd $HOME
```

---

# Understanding `/`

The slash (`/`) represents the **root directory**.

Every file and directory in Linux starts from this location.

Example

```text
/
├── bin
├── etc
├── home
├── root
├── usr
└── var
```

Example command

```bash
cd /
pwd
```

Output

```text
/
```

---

# Understanding `~`

The tilde (`~`) is a shortcut to the **current user's home directory**.

Examples

For user `amar`

```text
/home/amar
```

For user `root`

```text
/root
```

Example

```bash
cd ~
pwd
```

Output (root user)

```text
/root
```

---

# Understanding `$HOME`

`$HOME` is an environment variable that stores the path of the current user's home directory.

Example

```bash
echo $HOME
```

Output

```text
/root
```

Example

```bash
cd $HOME
```

---

# Difference Between `/`, `~`, and `$HOME`

| Symbol  | Meaning                                            | Example (root) |
| ------- | -------------------------------------------------- | -------------- |
| `/`     | Root of the Linux filesystem                       | `/`            |
| `~`     | Current user's home directory shortcut             | `/root`        |
| `$HOME` | Environment variable containing the home directory | `/root`        |

---

# Practical Example

```bash
cd /
pwd
```

Output

```text
/
```

```bash
cd ~
pwd
```

Output

```text
/root
```

```bash
echo $HOME
```

Output

```text
/root
```

---

# Product Security Perspective

Understanding the current working directory and user context is important because many security tools, scripts, and incident response procedures depend on executing commands from the correct location and with the correct privileges.

---

# Hands-on Lab

1. Open your Linux terminal (WSL or Linux VM).
2. Run:

```bash
pwd
whoami
echo $HOME
cd /
pwd
cd ~
pwd
cd $HOME
pwd
```

3. Observe the output after each command.

---

# Interview Questions

### What does `pwd` do?

It prints the absolute path of the current working directory.

---

### What is the difference between `~` and `$HOME`?

* `~` is a shell shortcut.
* `$HOME` is an environment variable storing the home directory path.

---

### What is the root directory?

The top-most directory in the Linux filesystem, represented by `/`.

---

### What command displays the current user?

```bash
whoami
```

---

# Summary

In this chapter, you learned:

* How to identify your current location using `pwd`
* How to identify the current user with `whoami`
* How to navigate using `cd`
* The difference between `/`, `~`, and `$HOME`
* Why these concepts are important in Linux administration and Product Security

---

# References

* Linux `pwd` manual (`man pwd`)
* Linux `cd` shell builtin documentation
* Linux `whoami` manual (`man whoami`)
