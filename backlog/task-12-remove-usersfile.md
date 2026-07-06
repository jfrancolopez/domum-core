# Task 12 — Remove the tracked traefik `usersfile` placeholder

## Objective
Remove `compose/proxy/traefik/usersfile` (a comment-only placeholder) from
the repo and put its instructions where instructions live: the secrets doc.

## Files involved
- `compose/proxy/traefik/usersfile` (delete)
- `docs/reference/secrets.md` (absorb the htpasswd instructions)
- `compose/proxy/traefik/traefik.yml` + `dynamic/*.yml` (verify nothing
  references the in-repo path)

## Reason
The real dashboard credentials live at
`/etc/domum-core/secrets/traefik_dashboard_users` and are mounted by
`compose/proxy/traefik.yml` (line 24). The tracked `usersfile` contains only
setup comments, but because the whole `compose/proxy/traefik/` directory is
mounted read-only into the container at `/etc/traefik`, a file named
`usersfile` sits inside the proxy container inviting future confusion (and
someone could one day put real hashes in it and commit them). The sibling
repo keeps no such placeholder — instructions live in its Traefik setup doc.

## Implementation plan
1. Grep the traefik static/dynamic configs for `usersfile` to confirm only
   the secrets mount path is referenced by the basic-auth middleware.
2. Move the four comment lines (htpasswd command, chmod 600) into
   `docs/reference/secrets.md` under a "Traefik dashboard auth" heading,
   deduplicating with whatever that doc already says.
3. `git rm compose/proxy/traefik/usersfile`.

## Testing plan
- `grep -rn usersfile compose docs` → only docs and the secrets mount remain.
- On host after pull: traefik dashboard auth still works (nothing consumed
  the placeholder, so no behavior change expected).

## Risk
Low. Verification in step 1 is the guard.

## Rollback
Revert.

## Dependencies
None.

## Estimated complexity / token size
Trivial (~3k tokens).

## Suggested order
12 (any time).
