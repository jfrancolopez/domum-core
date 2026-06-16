# domum-core

Production home automation services for a Raspberry Pi 5, managed by the
`domum-core` CLI. Home Assistant is the primary dashboard and automation hub.

Install or update:

```bash
curl -fsSL https://raw.githubusercontent.com/jfrancolopez/domum-core/main/install.sh | sudo bash
```

The installer clones or updates the repo, installs the CLI, creates required
directories, and creates missing live config files from examples. It does not
overwrite local config and does not run `init` or `apply` automatically.

## Start here

1. [Quick Start](docs/getting-started/first-run.md)
2. [Configure](docs/getting-started/configure.md)
3. [Daily Operations](docs/operations/cli-cheatsheet.md)
4. [Backups & Disaster Recovery](docs/backups/overview.md)
5. [Services](docs/README.md#services)

## Common commands

```bash
sudo domum-core configure --show
sudo domum-core configure --validate
sudo domum-core init
sudo domum-core apply
sudo domum-core status --counts
sudo domum-core checkup
```

Config examples are tracked in git. Live config is local-only:

- `config/domum.conf.example` -> `config/domum.conf`
- `config/domum-backup.conf.example` -> `config/domum-backup.conf`

See [docs/README.md](docs/README.md) for the full documentation index.
