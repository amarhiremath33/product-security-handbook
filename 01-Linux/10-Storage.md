# 10 — Storage

> **Module:** 01 – Linux · **Level:** 🟡 Intermediate → 🔴 Advanced · **Time:** ~3 hours
> **Lab environment:** VM (best) or WSL2. All labs use **loop devices** (files pretending to be disks), so you can't damage a real disk. Not possible in Docker. See [labs/README.md](../labs/README.md)

---

## Objectives

After this chapter you will be able to:

- Find out how much space is used, where, and why.
- Identify disks, partitions and filesystems.
- Partition, format, mount and unmount storage, and make mounts permanent with `/etc/fstab`.
- Use LVM to create and grow volumes.
- Create and manage swap.
- Encrypt a volume with LUKS.
- Use mount options (`noexec`, `nosuid`, `nodev`) as a security control.

---

## The Storage Stack

```text
 Files and directories           /var/lib/mysql/data.ibd
          │
 Filesystem                      ext4 · xfs · btrfs · vfat · tmpfs
          │
 (optional) Encryption           LUKS / dm-crypt   → /dev/mapper/secure
          │
 (optional) Volume manager       LVM: PV → VG → LV → /dev/vg0/data
          │
 Partition                       /dev/sda1, /dev/nvme0n1p2
          │
 Block device (disk)             /dev/sda, /dev/nvme0n1, /dev/vda (VM), /dev/xvda (AWS)
```

### Device names

| Name | Type |
|---|---|
| `/dev/sda`, `/dev/sdb` | SATA/SCSI/USB disks; `sda1` = partition 1 |
| `/dev/nvme0n1` | NVMe SSD; partitions are `nvme0n1p1` |
| `/dev/vda` | VirtIO disk (KVM/cloud VMs) |
| `/dev/loop0` | Loop device: a file used as a disk (snaps, labs) |
| `/dev/mapper/*` | Device-mapper targets: LVM volumes, LUKS containers |
| `/dev/sr0` | CD/DVD |

> Device names can change between boots. In `/etc/fstab`, use **UUIDs**, not `/dev/sdb1`.

---

## 🟢 How Full Is It? — `df`, `du`, `ncdu`

```bash
df -h                      # usage per mounted filesystem
df -hT                     # + filesystem type
df -h /var                 # the filesystem that holds /var
df -ih                     # inode usage — 100% = can't create files even with free space
df -h -x tmpfs -x squashfs -x efivarfs    # hide virtual filesystems
```

```text
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda2       916G   14G  856G   2% /
/dev/sda1       511M  6.1M  505M   2% /boot/efi
tmpfs           3.9G     0  3.9G   0% /dev/shm
```

`Size ≠ Used + Avail`: ext4 reserves ~5% for root so the system can keep working when users fill the disk (`sudo tune2fs -l /dev/sda2 | grep -i reserved`).

```bash
du -sh /var/log                         # total size of a directory
du -sh /var/* 2>/dev/null | sort -h     # what's big in /var
sudo du -xh --max-depth=1 / 2>/dev/null | sort -h | tail   # biggest top-level dirs (-x: stay on this filesystem)
du -ah ~/Downloads | sort -h | tail     # biggest files and folders
sudo find / -xdev -type f -size +500M -exec ls -lh {} + 2>/dev/null   # files over 500 MB
ncdu /                                  # interactive explorer (sudo apt install ncdu)
```

### `df` and `du` disagree?

A file that was **deleted while a process still has it open** keeps using space until the process closes it. `du` can't see it (no name), `df` still counts it.

```bash
sudo lsof +L1                           # open files with link count 0 (deleted)
sudo systemctl restart <service>        # frees the space
```

Classic case: someone `rm`s a huge log file instead of truncating it. Truncate safely with `: > /var/log/big.log` or `truncate -s 0 file`.

---

## 🟢 What Disks and Filesystems Exist?

```bash
lsblk                       # tree of disks, partitions, mount points
lsblk -f                    # + filesystem type, label, UUID
sudo blkid                  # UUIDs and types of all block devices
sudo fdisk -l               # partition tables
findmnt                     # all mounts as a tree
findmnt /                   # what's mounted at /, with options
mount | column -t           # classic view
cat /proc/mounts            # what the kernel sees
```

### Filesystem types

| FS | Notes |
|---|---|
| **ext4** | Default on Debian/Ubuntu; mature, reliable |
| **xfs** | Default on RHEL; great for large files; can grow but **not shrink** |
| **btrfs** | Snapshots, compression, checksums (Fedora/openSUSE default) |
| **vfat / exfat** | USB sticks, EFI partition; no Linux permissions |
| **tmpfs** | In RAM; `/run`, `/dev/shm`, often `/tmp` |
| **overlayfs** | Container image layers |
| **nfs / cifs** | Network shares |

---

## 🟡 Partition → Format → Mount ⚠️

Always confirm the device name first. Formatting the wrong disk is irreversible.

```bash
lsblk                                                # which is the new, empty disk?

# Partition (GPT, one partition using the whole disk)
sudo parted /dev/sdb --script mklabel gpt mkpart primary ext4 0% 100%
lsblk /dev/sdb                                       # /dev/sdb1 appears

# Format
sudo mkfs.ext4 -L data /dev/sdb1                     # -L sets a label

# Mount
sudo mkdir -p /data
sudo mount /dev/sdb1 /data
df -h /data

# Unmount
sudo umount /data                                    # "target is busy"? → sudo lsof +f -- /data  or  fuser -vm /data
```

Interactive alternatives: `sudo fdisk /dev/sdb`, `sudo cfdisk /dev/sdb`, `sudo gdisk /dev/sdb`.

### Permanent mounts: `/etc/fstab`

```text
# <device>                                 <mount point>  <type>  <options>                  <dump> <fsck>
UUID=3b2f1c9e-5a7d-4e0b-9c1a-0f2e8d7b6a54  /data          ext4    defaults,nofail            0      2
UUID=...                                   /tmp           ext4    defaults,nodev,nosuid,noexec 0    2
tmpfs                                      /dev/shm       tmpfs   defaults,nodev,nosuid,noexec 0    0
```

| Field | Meaning |
|---|---|
| device | `UUID=…` (from `blkid`) or `LABEL=…` |
| options | `defaults`, plus extras; `nofail` = don't block boot if missing |
| fsck | `1` for `/`, `2` for others, `0` = never check |

**Always test before rebooting** — a broken fstab can drop the machine into emergency mode:

```bash
sudo findmnt --verify          # checks fstab syntax and devices
sudo mount -a                  # mounts everything in fstab — errors here, not at boot
```

### Mount options

| Option | Effect |
|---|---|
| `ro` / `rw` | Read-only / read-write |
| `noexec` | Can't execute binaries from this filesystem |
| `nosuid` | SUID/SGID bits are ignored |
| `nodev` | Device files are not interpreted |
| `noatime` | Don't update access time (performance) |
| `nofail` | Boot continues if the device is missing |
| `defaults` | `rw,suid,dev,exec,auto,nouser,async` |

Remount with new options without unmounting:

```bash
sudo mount -o remount,noexec /tmp
findmnt /tmp
```

---

## 🔴 LVM — Logical Volume Manager

LVM puts a flexible layer between disks and filesystems: volumes can span disks, be **resized online**, and be snapshotted.

```text
 Physical Volumes (PV)   /dev/sdb      /dev/sdc         ← whole disks or partitions
                             \            /
 Volume Group (VG)            vgdata (30 GB pool)
                             /            \
 Logical Volumes (LV)   lvapp (10 GB)   lvlogs (5 GB)   ← used like partitions
                            │               │
 Filesystems              ext4            xfs
 Mounted at              /srv/app       /var/log/app
```

```bash
sudo pvcreate /dev/sdb /dev/sdc               # initialise disks for LVM
sudo vgcreate vgdata /dev/sdb /dev/sdc        # pool them
sudo lvcreate -n lvapp -L 10G vgdata          # carve a 10 GB volume
sudo lvcreate -n lvlogs -l 50%FREE vgdata     # half of the remaining space
sudo mkfs.ext4 /dev/vgdata/lvapp
sudo mount /dev/vgdata/lvapp /srv/app

sudo pvs; sudo vgs; sudo lvs                  # summaries
sudo lvdisplay /dev/vgdata/lvapp              # details

# Grow a volume AND its filesystem, online
sudo lvextend -r -L +5G /dev/vgdata/lvapp     # -r resizes the filesystem too

# Add a new disk to the pool
sudo pvcreate /dev/sdd && sudo vgextend vgdata /dev/sdd

# Snapshot (point-in-time copy, e.g. before an upgrade)
sudo lvcreate -s -n lvapp-snap -L 2G /dev/vgdata/lvapp
```

Ubuntu Server's installer puts `/` on LVM by default (`ubuntu-vg/ubuntu-lv`) — and often leaves half the disk unallocated. Grow it with `sudo lvextend -r -l +100%FREE /dev/ubuntu-vg/ubuntu-lv`.

---

## 🟡 Swap

Swap is disk space used when RAM is full. Slow, but it can prevent the OOM killer from striking.

```bash
swapon --show
free -h

sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile                 # swap can contain secrets from memory!
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

sysctl vm.swappiness                     # 0–100: how eagerly the kernel swaps (default 60)
```

---

## 🔴 Disk Encryption with LUKS

LUKS (Linux Unified Key Setup) encrypts a whole block device. Data at rest is unreadable without the passphrase or key — essential for laptops, and for compliance on servers.

```text
 /dev/sdb1 (encrypted bytes)
     │  cryptsetup open  (passphrase/keyfile)
     ▼
 /dev/mapper/secure (decrypted view)
     │  mkfs / mount
     ▼
 /secure
```

```bash
sudo cryptsetup luksFormat /dev/sdb1          # ⚠️ destroys data; asks for a passphrase
sudo cryptsetup open /dev/sdb1 secure         # unlock → /dev/mapper/secure
sudo mkfs.ext4 /dev/mapper/secure
sudo mount /dev/mapper/secure /secure
sudo umount /secure && sudo cryptsetup close secure    # lock

sudo cryptsetup luksDump /dev/sdb1            # header: cipher, key slots
sudo cryptsetup luksAddKey /dev/sdb1          # add a second passphrase (up to 8+ key slots)
sudo cryptsetup luksHeaderBackup /dev/sdb1 --header-backup-file sdb1-header.img   # lose the header = lose the data
```

Unlock at boot: `/etc/crypttab` (`secure UUID=… none luks`) plus an `/etc/fstab` entry for `/dev/mapper/secure`.

> Encryption at rest protects against **stolen disks, decommissioned hardware and snapshots leaking**. It does **not** protect a running, unlocked system from an attacker who is logged in. In the cloud, the equivalent is EBS/managed-disk encryption with KMS keys.

---

## 🔴 Filesystem Health

```bash
sudo dmesg -T | grep -iE 'I/O error|ext4-fs error|xfs.*error'    # disk errors
sudo smartctl -H /dev/sda           # disk health (sudo apt install smartmontools)
sudo fsck -f /dev/sdb1              # check ext4 — ONLY on an UNMOUNTED filesystem
sudo xfs_repair /dev/sdb1           # xfs equivalent (unmounted)
sudo tune2fs -l /dev/sda2 | grep -E 'mount count|Last checked|Reserved'
```

A filesystem that hits errors may be **remounted read-only** by the kernel to protect data — symptoms: "Read-only file system" errors everywhere.

---

## In Production

| Situation | Approach |
|---|---|
| Disk full alert | `df -h` → `du -xh --max-depth=1 / \| sort -h` → logs? Docker? core dumps? → `lsof +L1` |
| App data growing | Separate volume (LVM or cloud disk) mounted at `/var/lib/<app>`; grow online |
| `/var/log` fills `/` | Separate `/var/log` filesystem + logrotate + journald limits |
| Docker eats the disk | `docker system df`, `docker system prune` (careful), separate `/var/lib/docker` |
| Cloud disk resize | Resize in console → `growpart /dev/xvda 1` → `resize2fs` / `xfs_growfs` |
| Before risky change | LVM or cloud snapshot |

---

## Product Security Perspective

| Control | Why |
|---|---|
| Separate partitions for `/tmp`, `/var`, `/var/log`, `/var/tmp`, `/home` | A full `/var/log` or `/tmp` can't take down `/`; mount options can be applied per area (CIS Benchmark) |
| `/tmp`, `/var/tmp`, `/dev/shm` with `nodev,nosuid,noexec` | Blocks the classic "download payload to /tmp and run it" step and SUID tricks |
| `/home` with `nodev,nosuid` | Users can't bring SUID binaries or device files |
| Removable media `nodev,nosuid,noexec` | USB-borne malware |
| Encryption at rest (LUKS / cloud KMS) | Stolen disks, snapshots, decommissioned hardware |
| Swap encrypted or `600` swapfile | Swap may hold passwords and keys from RAM |
| Secure deletion awareness | `rm` doesn't erase data; SSDs and copy-on-write filesystems make `shred` unreliable — **encrypt from day one, then destroy the key** |
| Monitor disk usage | Full disks cause outages and can stop logging (an attacker's friend) |

> `noexec` is a speed bump, not a wall: `bash /tmp/script.sh` or `python3 /tmp/x.py` still work because the interpreter lives elsewhere. Combine it with other controls.

Audit:

```bash
findmnt -no TARGET,OPTIONS /tmp /var/tmp /dev/shm /home 2>/dev/null
lsblk -o NAME,TYPE,FSTYPE,MOUNTPOINT | grep -i crypt     # any encrypted volumes?
swapon --show; ls -l /swapfile 2>/dev/null
```

---

## Hands-on Lab ⚠️ (VM or WSL2 — uses loop devices only)

```bash
sudo apt install -y lvm2 cryptsetup parted
mkdir -p ~/labs/storage && cd ~/labs/storage
```

### Part 1 — Investigate usage 🟢

```bash
df -hT -x tmpfs -x squashfs
df -ih /
sudo du -xh --max-depth=1 / 2>/dev/null | sort -h | tail
lsblk -f
findmnt /
```

### Part 2 — Create a virtual disk 🟡

```bash
truncate -s 1G disk1.img                        # 1 GB empty file
LOOP1=$(sudo losetup -fP --show disk1.img)      # attach as a block device
echo $LOOP1                                      # e.g. /dev/loop10
lsblk $LOOP1
```

### Part 3 — Partition, format, mount, fstab 🟡

```bash
sudo parted $LOOP1 --script mklabel gpt mkpart primary ext4 0% 100%
lsblk $LOOP1                                     # ${LOOP1}p1 appears
sudo mkfs.ext4 -L labdata ${LOOP1}p1
sudo mkdir -p /mnt/labdata
sudo mount ${LOOP1}p1 /mnt/labdata
df -h /mnt/labdata
sudo blkid ${LOOP1}p1
```

### Part 4 — Mount options as a security control 🔴

```bash
sudo cp /usr/bin/id /mnt/labdata/myid
printf '#!/bin/sh\necho "script ran as $(id -un)"\n' | sudo tee /mnt/labdata/payload.sh > /dev/null
sudo chmod +x /mnt/labdata/payload.sh
/mnt/labdata/myid -un                            # runs
/mnt/labdata/payload.sh                          # runs

sudo mount -o remount,noexec,nosuid,nodev /mnt/labdata
findmnt /mnt/labdata
/mnt/labdata/myid -un                            # Permission denied
/mnt/labdata/payload.sh                          # Permission denied
sh /mnt/labdata/payload.sh                       # still runs! noexec doesn't stop interpreters
sudo umount /mnt/labdata
```

### Part 5 — The df/du mystery 🔴

```bash
sudo mount ${LOOP1}p1 /mnt/labdata
sudo dd if=/dev/zero of=/mnt/labdata/big.log bs=1M count=300 status=none
sudo bash -c 'exec 3</mnt/labdata/big.log; sleep 600' &   # a process holds it open
sleep 1
sudo rm /mnt/labdata/big.log
df -h /mnt/labdata                       # still ~300 MB used!
sudo du -sh /mnt/labdata                 # but du sees almost nothing
sudo lsof +L1 | grep big.log             # the culprit
sudo pkill -f 'sleep 600'
sleep 1; df -h /mnt/labdata              # space is back
sudo umount /mnt/labdata
```

### Part 6 — LVM 🔴

```bash
truncate -s 1G disk2.img
LOOP2=$(sudo losetup -fP --show disk2.img)
sudo wipefs -a $LOOP1                      # reuse disk 1 for LVM
sudo pvcreate $LOOP1 $LOOP2
sudo vgcreate vglab $LOOP1 $LOOP2
sudo lvcreate -n lvapp -L 500M vglab
sudo mkfs.ext4 -q /dev/vglab/lvapp
sudo mkdir -p /mnt/lvapp && sudo mount /dev/vglab/lvapp /mnt/lvapp
df -h /mnt/lvapp
sudo lvextend -r -L +700M /dev/vglab/lvapp   # grow online — spans both disks now
df -h /mnt/lvapp
sudo pvs; sudo vgs; sudo lvs
```

### Part 7 — LUKS encryption 🔴

```bash
sudo umount /mnt/lvapp
sudo lvcreate -n lvsecret -L 200M vglab
sudo cryptsetup luksFormat /dev/vglab/lvsecret       # type YES, then a passphrase
sudo cryptsetup open /dev/vglab/lvsecret labsecret
sudo mkfs.ext4 -q /dev/mapper/labsecret
sudo mkdir -p /mnt/secret && sudo mount /dev/mapper/labsecret /mnt/secret
echo "top secret: API_KEY=abc123" | sudo tee /mnt/secret/creds.txt
sudo umount /mnt/secret && sudo cryptsetup close labsecret

sudo strings /dev/vglab/lvsecret | grep -c API_KEY  # 0 — the raw device is ciphertext
sudo cryptsetup luksDump /dev/vglab/lvsecret | head -15
```

### Clean up

```bash
sudo umount /mnt/lvapp /mnt/secret 2>/dev/null
sudo cryptsetup close labsecret 2>/dev/null
sudo vgremove -y vglab
sudo pvremove $LOOP1 $LOOP2
sudo losetup -d $LOOP1 $LOOP2
rm -f ~/labs/storage/disk*.img
sudo rmdir /mnt/labdata /mnt/lvapp /mnt/secret
```

**Questions**

1. Why did `df` and `du` disagree in Part 5, and how would you fix it in production?
2. Which attack does `noexec` on `/tmp` slow down, and how can it be bypassed?
3. What did `lvextend -r` do besides growing the volume?
4. What does LUKS protect against, and what doesn't it protect against?

---

## Common Mistakes

- Formatting the wrong device — always `lsblk` first.
- `/dev/sdX` names in fstab — use UUIDs.
- Editing fstab and rebooting without `findmnt --verify` / `mount -a`.
- Deleting open log files instead of truncating them.
- Running `fsck` on a mounted filesystem.
- Forgetting to grow the filesystem after growing the volume/disk (`-r`, `resize2fs`, `xfs_growfs`).
- World-readable swap files.
- Believing `rm` or `shred` securely erases data on SSDs.

---

## Interview Questions

**1. `df` vs `du`?**
`df` reports filesystem-level usage from metadata; `du` walks directories and sums file sizes.

**2. The disk shows 100% but `du` finds nothing big. Why?**
Deleted files still held open by a process (`lsof +L1`), files hidden under a mount point, or inode exhaustion (`df -i`). Restart the holding process or truncate the file.

**3. Why use UUIDs in `/etc/fstab`?**
Device names like `/dev/sdb` can change between boots; UUIDs are stable.

**4. What is LVM and why use it?**
A volume manager that pools disks into volume groups and allocates logical volumes, allowing online resizing, spanning disks and snapshots.

**5. How do you extend a filesystem on LVM?**
`lvextend -r -L +SIZE /dev/vg/lv` (or `lvextend` then `resize2fs` / `xfs_growfs`).

**6. What are `noexec`, `nosuid` and `nodev`?**
Mount options that prevent executing binaries, honouring SUID/SGID bits, and interpreting device files on that filesystem.

**7. 🔐 Why does CIS recommend separate partitions for `/tmp`, `/var`, `/var/log` and `/home`?**
To contain disk-filling (accidental or malicious) and to apply restrictive mount options to world-writable or user-controlled areas.

**8. 🔐 What does disk encryption protect against?**
Data exposure from stolen or discarded disks, leaked snapshots and offline access. It doesn't protect a running system where the volume is unlocked.

---

## Summary

- `df` for filesystems, `du`/`ncdu` for directories, `lsof +L1` for the "phantom" usage.
- `lsblk`, `blkid`, `findmnt` show the storage layout.
- Partition → format → mount; make it permanent with a UUID in fstab and test with `mount -a`.
- LVM makes storage flexible; LUKS makes it confidential.
- Mount options and separate partitions are cheap, effective hardening.

**Next:** [11 — Shell Scripting](11-Shell-Scripting.md)

---

## References

- `man lsblk`, `man fstab`, `man mount`, `man lvm`, `man cryptsetup`, `man losetup`
- Arch Wiki — LVM, dm-crypt (excellent for any distro) — https://wiki.archlinux.org/
- CIS Ubuntu Linux Benchmark — filesystem configuration section
