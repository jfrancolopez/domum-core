# Task 81 - Harden Glance access repair diagnostics

## Objective

Correct safety and accuracy defects discovered while reviewing task 80's
Glance/Tailscale access repair, without weakening the private access policy or
touching the production host.

## Background

Task 80 added Docker daemon convergence and live Glance label diagnostics. A
follow-up review found that checkup could recommend restarting Docker before
validating `daemon.json`, label checks used substrings instead of exact values,
warning text could disclose the private LAN CIDR, and daemon repair reset an
existing file's mode to `0644`.

## Current Behavior

- A newer invalid `daemon.json` can produce a Docker restart action.
- Glance policy checks can accept malformed ranges or a stale LAN CIDR.
- Mismatch warnings can print the complete private sourcerange.
- Repairing an existing daemon file does not preserve its mode and ownership.
- Container age is used as a stale-label heuristic even when effective labels
  can be compared directly.

## Desired Behavior

- Recommend a Docker restart only when valid on-disk configuration sets
  `userland-proxy=false` and appears newer than the running daemon.
- Inspect exact Glance label keys and require exact configured values.
- Never print the configured or live private CIDR in checkup output.
- Preserve existing daemon file mode and ownership during an approved atomic
  repair.
- Cover the safety-critical branches with automated regression tests.

## Implementation Plan

1. Reorder checkup so invalid or unsafe daemon configuration directs the
   operator to `domum-core init`, never directly to a Docker restart.
2. Stage merged daemon JSON in the destination directory with the existing mode
   and numeric ownership, then atomically rename it into place.
3. Read exact Glance labels with `docker inspect`, compare the effective
   sourcerange and middleware chain exactly, and remove the mtime heuristic.
4. Add a sourceable CLI guard and focused tests for JSON validation, metadata
   preservation, exact labels, private-value redaction, and empty CIDR Compose
   rendering.
5. Clarify that the client-side DNS test requires explicit local values.

## Affected Files

- `bin/domum-core`
- `compose/monitoring/glance.yml` (test coverage only; no policy change planned)
- `.github/workflows/validate.yml`
- `tests/glance-access-policy-smoke.sh`
- `docs/services/glance.md`
- `backlog/README.md`
- `backlog/task-81-harden-glance-access-repair.md`

## Testing Plan

- Run the new focused smoke test.
- Run Bash syntax, Shellcheck, YAML lint, Compose rendering with empty and
  populated LAN CIDRs, all existing smoke/unit tests, and tracked-file gitleaks.
- Confirm warnings contain neither test LAN CIDR.
- Production Pi path tests remain explicitly out of scope for this checkout.

## Rollback

Revert the task commit. This task changes only repository code, tests, and docs;
it does not modify `/etc/docker/daemon.json`, containers, or production data.

## Dependencies

- Task 80 implementation.
- Existing Debian `jq`, `stat`, `install`, Docker, and Docker Compose tooling.

## Risks

Overly strict exact comparison could warn after an intentional policy change;
the remedy remains the normal `update` then `apply` convergence path. Docker
restart advice must remain conservative because it interrupts all containers.

## Complexity

Small-medium.

## Suggested Order

Complete before further production attempts to repair Glance access.

## Decisions and Rejected Alternatives

- Decision: compare exact effective labels instead of container/file mtimes.
- Decision: redact all sourcerange values from reports and journals.
- Decision: preserve existing daemon metadata rather than normalizing it.
- Rejected: trust forwarded headers or add a client `/32`; either weakens the
  private access boundary and does not fix convergence.
- Rejected: infer policy freshness from compose mtime; local config changes are
  not represented by that timestamp.
