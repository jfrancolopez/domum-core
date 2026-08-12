# Task 66 — Evaluate Glance expansion and Dynacat

## Objective

After the complete Glance dashboard is stable, evaluate two optional directions
without replacing production: additional Work/Code/Utilities/Home Automation/AI
pages, and an isolated Dynacat compatibility-experiment proposal. Produce
evidence and a go/no-go decision; do not create an experiment or cut production
over.

## Background

The operator ultimately wants a centralized daily source for home, work, gaming,
utilities, and code across multiple computers, but selected the seven-page plan
for the first program. Some needs may fit Home, Hosting, News, or Social better
than new tabs. Extra pages should be justified by observed use, not aspiration.

Dynacat is a Glance fork focused on dynamic updates, integrations, OIDC, and
migration. It may improve future behavior but has more churn and a smaller
ecosystem. The approved strategy is production Glance at
`glance.ladomum.com` and, only after explicit operator approval, a temporary
isolated Dynacat experiment at a separate hostname with copied configuration.

## Current Behavior

Task 65 should leave a pinned, modular, measured, recoverable seven-page Glance
deployment. There is no authorized Dynacat service, hostname, credential set, or
production replacement plan.

## Desired Behavior

The operator receives a factual decision based on usage gaps, compatibility,
security, resource cost, mobile behavior, reload/dynamic-update behavior, and
maintenance burden. Production Glance and its files remain untouched by the
proposal. No experiment is implemented in this task.

## Implementation Plan

1. Review at least several weeks of operator feedback: which page is used, what
   is hard to find, and which work/code/utility needs cannot fit existing pages.
2. For each proposed extra page, define unique purpose, candidate real sources,
   privacy, frequency, and why bookmarks/search/existing pages are insufficient.
   Recommend no page when evidence is weak.
3. Review current Dynacat repository, release cadence, license, image provenance,
   security model, supported Glance version/config syntax, migration docs, OIDC,
   dynamic behavior, and open compatibility issues at immutable versions.
4. Write a test matrix covering every important production page/widget/include,
   CSS/assets, env substitution, custom template, failure state, and mobile size.
5. Design, but do not create, a separate experiment: exact proposed catalog,
   Compose/config/CI/docs files, hostname/DNS/proxy impact, image/version,
   credential isolation, resource ceiling, test matrix, rollback, and removal.
6. Record one decision: reject, revisit, or create a new self-contained numbered
   implementation task with explicit approval. Do not create a service, route,
   credentials, experiment, or production migration here.

## Affected Files

- `docs/glance-future-evaluation.md` (new)
- `docs/README.md`
- `backlog/README.md` (status only)

Do not add an experimental tree or modify production Glance, Homepage, source
services, DNS, Traefik, firewall, or authentication. A later task is required.

## Testing Plan

- Validate research against immutable upstream release/source references.
- Run normal repository checks and gitleaks for documentation.
- Review the proposed comparison matrix against task 65's final evidence.
- Verify `git diff --name-only` contains documentation/backlog files only.

## Rollback

Revert the documentation commit. No runtime rollback exists because this task
must not implement an experiment. Migration requires a different task.

## Dependencies

Requires completed, stable, operator-approved task 65.

## Risks

A fork experiment can create route/auth conflicts, duplicate API load, credential
sprawl, and pressure to migrate based on novelty. Isolation, measured comparison,
and a no-cutover boundary are mandatory.

## Complexity

Medium research; no operational risk because implementation is out of scope.

## Suggested Order

Optional final task after sustained use of production Glance.
