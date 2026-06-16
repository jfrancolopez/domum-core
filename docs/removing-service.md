# Removing a Service

Removal is intentionally conservative: stop managing the service first, then
delete data only after you confirm it is no longer needed.

## 1. Disable the Toggle

Set the service flag to `0` in `config/domum.conf`:

```bash
ENABLE_EXAMPLE_SERVICE=0
sudo domum-core apply
```

`apply` uses compose with `--remove-orphans`, so disabled containers are stopped
without deleting bind mounts or volumes.

## 2. Remove Catalog and Compose References

For repo-level removals, delete the compose fragment and remove the row from
`service_catalog()` in `bin/domum-core`. Also remove any `BACKUP_<SERVICE>` flag
and service-specific docs.

## 3. Clean Data Manually

Only after a verified backup and a deliberate decision, remove old bind mounts
or docker volumes by hand.

```bash
docker volume ls
docker volume rm <volume-name>
sudo rm -rf /opt/domum-core/compose/<category>/<service-name>
```

Do not automate data deletion in `apply` or `install.sh`.
