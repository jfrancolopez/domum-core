# Git workflow

This repo is operated directly on a production home server, so the workflow is
small and explicit. The goal is a readable history and a safe path from git to
the Pi, not process for its own sake.

## Commits

Use:

```text
<area>: <imperative summary>
```

Examples:

```text
mqtt: require broker authentication
compose: tidy automation hygiene
docs: complete docs index
```

Good areas are service names or broad repo areas: `bin`, `docs`, `compose`,
`config`, `backup`, `mqtt`, `mariadb`, `traefik`. Existing `feat:` and `fix:`
style commits are fine; do not rewrite history just for naming.

Keep one logical change per commit. For backlog tasks, commit the implementation
first, then mark the backlog row done with the implementation commit hash.

## Branches

Working on `main` is acceptable for solo docs and small config hygiene. Use a
short-lived branch for riskier code or compose changes when CI review would help
before production pulls the change.

Do not force-push shared history unless there is an explicit recovery decision.

## Deploy Flow

The production contract is:

```text
commit -> push -> on the Pi: sudo domum-core update -> sudo domum-core apply -> sudo domum-core checkup
```

Skip `apply` only for docs/backlog-only changes. If `bin/` or `systemd/` changed,
refresh installed commands or maintenance units as documented by the specific
change.

## Remotes

Root-run update and install flows should fetch anonymously over HTTPS. If the
operator pushes from the Pi, keep SSH for push only:

```bash
sudo git -C /opt/domum-core remote set-url origin https://github.com/jfrancolopez/domum-core.git
sudo git -C /opt/domum-core remote set-url --push origin git@github.com:jfrancolopez/domum-core.git
```

`sudo domum-core update` warns when the fetch URL is not HTTPS, but it does not
rewrite remotes automatically.

## Never Commit

Never commit live config, secrets, runtime state, or backups. Common examples:

```text
config/domum.conf
config/domum-backup.conf
/etc/domum-core/secrets/*
compose/**/data/**
compose/automation/zigbee2mqtt/secret.yaml
compose/automation/mqtt/config/passwd
```

If a local-only file was accidentally staged, unstage it:

```bash
git restore --staged PATH
```

If a local-only file was accidentally tracked in the latest work, stop tracking
it without deleting the live file:

```bash
git rm --cached PATH
```

If a real secret was committed, stop and treat it as an incident. Do not try to
hide it with a normal follow-up commit.
