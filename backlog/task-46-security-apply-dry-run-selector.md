# Task 46 - Make security-apply dry-run use unattended-upgrades selection

## Objective

Make `domum-core os-updates security-apply --dry-run` report the same package
selection policy that a real `security-apply` run uses.

## Background

The real command invokes `unattended-upgrade -d`, which honors
`Unattended-Upgrade::Origins-Pattern`. Its current dry-run branch invokes
`apt-get -s upgrade` instead, which lists all APT-upgradable packages including
Docker, Raspberry Pi Foundation, Tailscale, and Debian regular-update packages.

## Why This Exists

The dry-run output can imply that a scheduled security patch run would upgrade
non-security packages even though the real unattended-upgrades selector rejects
them. This weakens operator confidence in a safety check.

## Current Behavior

`security-apply --dry-run` returns success but simulates the general APT upgrade
set. A real `security-apply` uses unattended-upgrades and its configured allowed
origins.

## Desired Behavior

The dry-run invokes unattended-upgrades in dry-run mode, returns its status, and
does not install, remove, reboot, or alter allowed origins. Its selected-package
output must match the real command's policy.

## Implementation Plan

1. Replace the `apt-get -s upgrade` dry-run branch in `os_updates_security_apply`
   with `unattended-upgrade --dry-run`.
2. Preserve explicit nonzero propagation from unattended-upgrades.
3. Update the OS security-patches documentation if command output changes.

## Affected Files

- `bin/domum-core`
- `docs/operations/security-patches.md` if needed

## Testing Plan

1. Run `bash -n bin/domum-core` and ShellCheck.
2. Run `sudo domum-core os-updates security-apply --dry-run` on the Pi.
3. Confirm the output excludes configured-disallowed Docker, Raspberry Pi
   Foundation, Tailscale, and regular Debian origins.
4. Confirm `apt` history has no new install or removal entry and no reboot
   marker is created.

## Rollback

Revert the dry-run branch change. This affects simulation only and has no data
migration or service restart.

## Dependencies

None. It assumes unattended-upgrades remains the production selector.

## Risks

Low. `unattended-upgrade --dry-run` may download packages as documented by its
own help text, but it must not install them. Do not replace the real selector
with a hand-maintained APT filter.

## Complexity

Trivial.

## Suggested Order

After the security-patch exit-status fix, before relying on CLI dry-run output
for future patch reviews.

## Decision Record

- Chosen: use unattended-upgrades directly so simulation and production share
  one selector.
- Rejected: parse `apt-get -s upgrade` output for origin strings. It can diverge
  from unattended-upgrades pinning and allowed-origin resolution.
