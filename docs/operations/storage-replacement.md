# Storage replacement runbook

**Rebuild-from-scratch (fresh Debian image + bootstrap + restore) is the
recovery path — it is the one that gets tested. Drive cloning is only a
time-saving convenience for *planned* swaps where the old drive is healthy
and in hand.**

Decision rule: **old drive healthy and you have an hour → clone; anything
else, or any doubt → rebuild** via the
[disaster recovery runbook](../backups/disaster-recovery.md).

## 1. Planned boot-drive replacement (SSD→NVMe, small→big NVMe)

1. **Fresh backup first:**

   ```bash
   sudo domum-core backups run && sudo domum-core recovery-pack create
   ```

2. Attach the new drive via a USB adapter (or the second NVMe slot if you
   have one). Identify it with `lsblk` — double-check you have the right
   device before partitioning.

3. Partition the new drive to match the boot layout (a FAT32 `/boot/firmware`
   partition + an ext4 root), then copy. Two options:
   - `rpi-clone` (simplest — handles partitions, copy, and PARTUUID fixes in
     one step): `sudo rpi-clone nvme0n1` (use *your* target device).
   - Manual: replicate the partition table with `sfdisk -d /dev/<old> |
     sfdisk /dev/<new>` (grow the root partition afterwards if the drive is
     bigger), `mkfs`, mount, then:

     ```bash
     sudo rsync -aHAX --exclude={/proc/*,/sys/*,/dev/*,/run/*,/tmp/*,/mnt/*,/media/*} / /mnt/newroot/
     ```

4. **Stop containers before the final copy pass** so databases are
   consistent, then rsync the delta:

   ```bash
   sudo docker stop $(sudo docker ps -q)
   sudo rsync -aHAX --delete --exclude={/proc/*,/sys/*,/dev/*,/run/*,/tmp/*,/mnt/*,/media/*} / /mnt/newroot/
   ```

5. If you copied manually, fix the boot references on the **new** drive
   (rpi-clone does this for you): get the new PARTUUIDs with `blkid`, then
   update `root=PARTUUID=...` in `/boot/firmware/cmdline.txt` and both
   entries in `/etc/fstab`.

6. EEPROM boot order (once per board, for the PCIe/NVMe HAT):

   ```bash
   sudo rpi-eeprom-config --edit    # BOOT_ORDER=0xf416  (NVMe first, then SD, USB)
   ```

7. Swap drives, boot, verify:

   ```bash
   findmnt /                        # root is the new drive?
   sudo docker ps                   # containers up?
   sudo domum-core checkup
   ```

Keep the old drive untouched for a week — it is your instant rollback
(swap it back).

## 2. Failed boot drive

- **Drive still readable on another Linux box (USB adapter)?** Clone it to
  the replacement per section 1 steps 3–7, run `fsck` on the copy first.
  If anything about the copy is doubtful, stop — rebuild instead; a clone of
  damaged data just moves the damage.
- **Drive unreadable, or any doubt?** Full
  [disaster recovery](../backups/disaster-recovery.md): fresh Debian 13
  image → `install.sh` → restore secrets/config/data from the recovery pack
  and restic. This path is exercised by the restore drills; trust it.

## 3. Replacing the Pi itself (drive healthy)

Move the NVMe (and both USB radios) to the new board. The only thing that
needs attention is the **EEPROM boot order on the new board** (step 6 above)
— everything else carries over: the OS is on the drive, and
`/dev/serial/by-id/*` radio paths follow the dongles, not the Pi.

If the new Pi is a different model generation, expect to reflash EEPROM
firmware first (`sudo rpi-eeprom-update -a`) before it will boot NVMe.
