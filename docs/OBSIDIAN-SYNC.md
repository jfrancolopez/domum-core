# Obsidian Sync

domum-core uses CouchDB for the community `obsidian-livesync` plugin. CouchDB was chosen
because it supports real-time replication, works across desktop and mobile clients, and is
the best-supported self-hosted backend for this plugin.

Enable it only after setting a strong CouchDB password:

```bash
ENABLE_OBSIDIAN_SYNC=1
OBSIDIAN_COUCHDB_USER="obsidian"
OBSIDIAN_COUCHDB_PASSWORD="replace-me"
sudo domum-core apply
```

The service is exposed as `https://obsidian.${DOMUM_DOMAIN}` unless
`OBSIDIAN_DOMAIN` overrides it. CouchDB tuning for authenticated access and CORS lives in
`compose/productivity/obsidian-sync/etc/local.ini`.

Data lives at `/opt/domum-core/compose/productivity/obsidian-sync/data` and is included by
`domum-core backups run` when `BACKUP_OBSIDIAN=1`.
