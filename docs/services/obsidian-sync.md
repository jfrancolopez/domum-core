# Obsidian Sync

Obsidian Sync is a private sync backend for Obsidian notes. It runs CouchDB for
the community `Self-hosted LiveSync` plugin, also known as `obsidian-livesync`.

Use it for:

- syncing an Obsidian vault between laptop, desktop, phone, and tablet
- keeping notes on this server instead of using Obsidian's paid cloud sync
- local-first notes where each device still has its own copy

This service does not replace the Obsidian app. You still install Obsidian on
each device, then point the plugin at this server.

## Enable the Service

Enable it only after setting a strong CouchDB password:

```bash
sudo domum-core configure
ENABLE_OBSIDIAN_SYNC=1
OBSIDIAN_COUCHDB_USER="obsidian"
OBSIDIAN_COUCHDB_PASSWORD="replace-me"
sudo domum-core apply
```

`domum-core configure --validate` and `domum-core apply` reject Obsidian Sync
when the password is empty or still set to `changeme`.

The service is exposed as `https://obsidian.${DOMUM_DOMAIN}` unless
`OBSIDIAN_DOMAIN` overrides it. CouchDB tuning for authenticated access and CORS lives in
`compose/productivity/obsidian-sync/local.ini`; `domum-core apply` copies it into
the ignored runtime config directory.

Do not add a CouchDB `[admins]` block or password hashes to that tracked file.
The admin user and password come from `OBSIDIAN_COUCHDB_USER` and
`OBSIDIAN_COUCHDB_PASSWORD`. CouchDB-generated runtime config such as
`compose/productivity/obsidian-sync/etc/docker.ini` is ignored by git.

After applying, open `https://obsidian.${DOMUM_DOMAIN}` in a browser. A simple
CouchDB response means the backend is reachable. You normally do not write notes
in this web page; it is only the sync database.

## Set Up the First Device

1. Install Obsidian on the device.
2. Open or create the vault you want to sync.
3. In Obsidian, enable Community plugins.
4. Install the `Self-hosted LiveSync` community plugin.
5. Open the plugin settings or setup wizard.
6. Choose the CouchDB/self-hosted option.
7. Enter the server URL: `https://obsidian.${DOMUM_DOMAIN}`.
8. Enter `OBSIDIAN_COUCHDB_USER` and `OBSIDIAN_COUCHDB_PASSWORD` from config.
9. Choose a database name for this vault, for example `main-vault`.
10. Let the plugin test the connection and create or initialize the database.
11. Start sync from this first device.

Use one database per Obsidian vault. Reusing the same database for different
vaults will mix their notes together.

## Set Up More Devices

Repeat the same plugin setup on each device and use the same database name for
the same vault.

Before changing many notes on a new device, wait for the first sync to finish.
That avoids duplicate files and sync conflicts.

## Daily Use

Keep using Obsidian normally. The plugin syncs changes in the background when
the device is online.

Good habits:

- Open Obsidian and let it sync before editing on a second device.
- Avoid editing the same note on two devices at the same time.
- If the plugin reports conflicts, review both copies before deleting anything.

## Backups and Recovery

Data lives at `/opt/domum-core/compose/productivity/obsidian-sync/data` and is included by
`domum-core backups run` when `BACKUP_OBSIDIAN=1`.

Recovery is a file restore of that data directory followed by `sudo domum-core apply`.
Unlike Actual Budget and Vaultwarden, Obsidian Sync does not currently have an
app-consistent archive included offsite. A hot CouchDB tar would not be safer
than the raw bind mount, so the future improvement is a CouchDB-native export if
restore verification shows the raw copy is not enough.

Your devices also keep local copies of the vault, but the server data still
matters because it lets all devices converge again after a restore.

## Quick Checks

If sync does not work:

- Open `https://obsidian.${DOMUM_DOMAIN}` in a browser and confirm CouchDB answers.
- Confirm the Obsidian plugin URL, username, password, and database name match.
- Run `sudo domum-core checkup` on the server.

If one device works and another does not, the problem is usually that device's
plugin settings or network access, not the server.
