# Migrating between hosts

Planned migration and disaster recovery are the same procedure with different
urgency — follow the [disaster recovery runbook](disaster-recovery.md).
For boot-drive swaps or moving the NVMe to a new Pi, see the
[storage replacement runbook](../operations/storage-replacement.md).

One migration-specific shortcut: with both hosts alive you can rsync service
data directly host-to-host instead of going through restic — stop the
containers first (`sudo docker stop $(sudo docker ps -q)`) so the copy is
consistent.
