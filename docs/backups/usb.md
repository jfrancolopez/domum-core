# Manual USB Backups

This runbook is for an offline USB copy of the domum-core backup set. Run it
only when you are physically near the Raspberry Pi and can plug in an external
drive.

USB backup is not a replacement for Hetzner. It is the offline copy you can put
in a drawer after a successful backup.

## What To Buy

Use a dedicated external USB SSD if possible.

Recommended:

- 500 GB or larger USB SSD for this server and one other server.
- 1 TB USB SSD if you want generous history, multiple servers, and less capacity
  anxiety.
- USB 3 enclosure/cable from a reputable brand.

Acceptable for a one-off emergency test:

- 128 GB USB stick.

Avoid for this job:

- 16 GB or 32 GB sticks. They are too small for comfortable restic history and
  tend to be slow/unreliable under sustained writes.
- A random old flash drive with unknown health.

Current domum-core snapshots are roughly hundreds of MiB each, but restic history
and future service growth matter. Buy for reliability and headroom, not just
today's first backup size.

## Can The Disk Hold Other Backups?

Yes. The command writes this server into its own folder:

```text
<USB mount>/domum-backups/domum-core/restic/
```

The middle folder comes from the server hostname. On this server it should be
`domum-core`. If you ever need to override it for a one-off run, use:

```bash
sudo DOMUM_USB_BACKUP_ID=domum-core domum-core backups usb /mnt/domum-usb
```

Another server should use its own folder, for example:

```text
<USB mount>/domum-backups/domum-media/restic/
```

Do not point two servers at the same `restic/` directory. Each server gets one
independent restic repository.

You may store non-restic files elsewhere on the disk, but the safest operating
model is a dedicated backup SSD with only backup folders on it. If you already
have a good ext4 disk with enough free space, you do not have to format it; the
backup command creates only the `domum-backups/<host>/restic` folder. Format only
when you want a clean dedicated backup disk.

## Format Decision

If the SSD is dedicated to backups, format it as Linux `ext4`.

Why ext4:

- reliable on Debian;
- preserves normal permissions;
- no extra packages needed;
- better than exFAT/NTFS for Linux backup repositories.

Formatting destroys everything on the selected disk. Only do the formatting
steps when you are at the Pi and have positively identified the USB SSD.

## One-Time Disk Setup

Plug in the SSD, then identify it:

```bash
lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,LABEL,MOUNTPOINTS
```

Find the external USB SSD by size/model. In the examples below, replace `sdX`
with the real device, such as `sda`. Do **not** guess.

Create one partition and format it. This deletes the selected disk:

```bash
sudo parted /dev/sdX --script mklabel gpt
sudo parted /dev/sdX --script mkpart primary ext4 0% 100%
sudo mkfs.ext4 -L DOMUM-USB /dev/sdX1
```

Create the mount point:

```bash
sudo mkdir -p /mnt/domum-usb
```

Mount it by label:

```bash
sudo mount /dev/disk/by-label/DOMUM-USB /mnt/domum-usb
df -h /mnt/domum-usb
```

Expected: `df` shows the external SSD mounted at `/mnt/domum-usb`.

## Run The Backup

Confirm the server is healthy first:

```bash
cd /opt/domum-core
git status --short
sudo domum-core checkup
```

Run the USB backup:

```bash
sudo domum-core backups usb /mnt/domum-usb
```

Expected behavior:

- first run initializes `/mnt/domum-usb/domum-backups/domum-core/restic`;
- restic backs up the normal domum-core source set;
- the command prints recent USB snapshots;
- it records `/var/lib/domum-core/backups/last-usb-success`.

Check health again:

```bash
sudo domum-core checkup
```

Expected: no new criticals. If the USB backup succeeded, `checkup` shows the
last manual USB backup timestamp.

Unmount before unplugging:

```bash
sync
sudo umount /mnt/domum-usb
```

If `umount` says the target is busy, do not unplug. Close shells or file browsers
that are inside `/mnt/domum-usb`, then retry.

## Verify The Disk Later

When you plug the disk in later:

```bash
sudo mount /dev/disk/by-label/DOMUM-USB /mnt/domum-usb
sudo RESTIC_PASSWORD_FILE=/etc/domum-core/secrets/restic_password_local \
  RESTIC_REPOSITORY=/mnt/domum-usb/domum-backups/domum-core/restic \
  restic snapshots
sudo umount /mnt/domum-usb
```

Expected: restic lists snapshots for `domum-core`.

## Restore Note

For a real disaster, prefer the guided restore flow in
[Disaster recovery](disaster-recovery.md). The USB restic repository is a normal
restic repository; mount the disk and point a temporary backup target at:

```text
/mnt/domum-usb/domum-backups/domum-core/restic
```

Use the LOCAL restic password file. Keep that password off the Pi too; without it
the USB repo is unreadable.

## Routine

Suggested habit:

1. Bring the SSD to the Pi once a month or before travel.
2. Mount it.
3. Run `sudo domum-core backups usb /mnt/domum-usb`.
4. Run `sudo domum-core checkup`.
5. Unmount it.
6. Store it away from the Pi.

Do not leave the USB SSD permanently attached. Its value is that it is offline
when the Pi, power supply, filesystem, or operator makes a mistake.
