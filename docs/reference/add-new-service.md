# Adding a New Service

New services should be added through the service catalog so compose, status,
updates, and backups share one source of truth.

## 1. Create a Compose Fragment

Create a focused compose file:

```text
compose/<category>/<service-name>.yml
```

Use the existing fragments as examples and prefer bind mounts under
`/opt/domum-core/compose/<category>/<service-name>/` for persistent state.

## 2. Add Configuration Defaults

Add an `ENABLE_<SERVICE>` toggle to `config/domum.conf.example`. Add
`<SERVICE>_AUTO_UPDATE` and `<SERVICE>_UPDATE_DELAY_DAYS` defaults if the app
should participate in the update policy. If the service has persistent data,
add a `BACKUP_<SERVICE>` flag to `config/domum-backup.conf.example`.

## 3. Register in the Catalog

Add one row to `service_catalog()` in `bin/domum-core`:

```text
logical-name|ENABLE_VAR|category|label|BACKUP_VAR|compose/path.yml|host:port
```

The `label` field is for docs/UI grouping only. Update behavior comes from the
per-app `*_AUTO_UPDATE` and `*_UPDATE_DELAY_DAYS` settings.

## 4. Add Backup Coverage

If the service uses a simple bind mount, add it to `backup_src_dir_for()`
so `domum-core backups run` can tar it before restic runs.

## 5. Validate

```bash
bash -n bin/domum-core
sudo domum-core configure --validate
sudo domum-core backups run --dry-run
sudo domum-core apply
```
