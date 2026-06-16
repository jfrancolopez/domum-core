# First run

After install, review config before converging services:

```bash
sudo domum-core configure --show
sudo domum-core configure --validate
sudo domum-core init
sudo domum-core apply
sudo domum-core status --counts
sudo domum-core checkup
```

`init` creates missing local config files from examples and required host
directories. It does not overwrite existing config.

`apply` starts the enabled compose services. Run it only after config review on
the production Pi.

## Config safety

Tracked examples:

- `config/domum.conf.example`
- `config/domum-backup.conf.example`

Local only:

- `config/domum.conf`
- `config/domum-backup.conf`
- `.env`
- `secrets/`
- `data/`
- `logs/`

The live config contains local domain, email, IPs, enabled services, update
policy, and future site-specific settings. It must not be committed.

If a live config is tracked, remove it from git without deleting the file:

```bash
git rm --cached config/domum.conf
git rm --cached config/domum-backup.conf
```
