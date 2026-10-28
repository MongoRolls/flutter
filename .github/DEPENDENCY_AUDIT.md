# Dependency audit coverage

- `web`: pnpm **8.15.9**, lockfile **6.0**, matching packageManager and engines.
- `backend`: pnpm **10.28.2**, lockfile **9.0**.
- Both include development dependencies, use the public npm audit registry, run no
  project install/lifecycle scripts, and fail on low-or-higher findings.
- The guard rejects unsupported lock formats, mismatched manifests, missing/empty
  root/package/snapshot graphs, unresolved direct dependency entries, failed audit
  commands, malformed responses, and empty/incomplete audited dependency totals.
  Tool failures and registry errors cannot produce a successful audit.
- Pub is **only an SDK advisory-hint check**, not a complete vulnerability scan.
  It rejects missing or non-boolean hints and malformed package/current-version
  data, and fails on any affected hint. Even a well-formed `false` may reflect
  unavailable/unknown upstream advisory data hidden by the SDK. Success does not
  prove complete advisory coverage or absence of vulnerabilities. A CI warning
  keeps this limitation visible. A separate direct advisory-source integration is
  required before claiming complete Pub vulnerability scanning.

Regression fixtures are synthetic protocol cases, not vulnerability findings:

```sh
python3 -m pip install PyYAML==6.0.3
python3 -m unittest discover -s .github/scripts -p 'test_*.py' -v
```

Run `python3 ../.github/scripts/audit_pnpm.py` from each Node project directory
with its exact pnpm version on PATH. The response and real exit status remain
visible in CI; findings are not suppressed or converted into a zero count.


## Backend compatible update

Backend direct packages and their transitive graph are refreshed within existing
major ranges (including Express 4, Prisma 7 and Vitest 3). Express's declaration
inference uses @types/express-serve-static-core, now an explicit dev dependency.
HTTP regressions cover proxy-address trust, valid proxy behavior, JSON limits,
invalid limit rejection and compressed-body error recovery without loading
application secrets or connecting to a database. A separate CI job runs all
backend tests, generates Prisma client with an unused local database URL, and
builds. No database connection/migration is performed.

Local audit after compatible updates: 415 dependencies, 0 low / 3 moderate /
1 high / 2 critical; still exit 1. Remaining high: Zod 3 (fix requires 4.6.6+;
the application uses ZodError.errors, so a blind upgrade would break validation).
Remaining critical/moderate: Vitest 3's tinypool/mocker graph; requires a reviewed
test-runner migration. Local 8 tests pass; client generation was blocked by
HTTP 403 from binaries.prisma.sh, so full backend build needs hosted CI.

Pub hints are matched to the checked-in lock versions. `pub outdated` may include
future-only dependencies with null `current`; these are skipped only when absent
from the lock. Every locked non-SDK package must still have matching current
version data; missing current versions or omitted locked packages fail closed.
The advisory-source availability limitation above still applies.


## Web compatible update

Next and eslint-config-next move together from 16.2.1 to 16.4.3; the framework
stays on major 16. Other dependencies refresh within their existing major ranges,
with no overrides or business rewrite. The theme toggle replaces effect-driven
mount state with matching server/hydration snapshots via useSyncExternalStore
(https://react.dev/reference/react/useSyncExternalStore#adding-support-for-server-rendering),
keeping the initial button disabled and enabling theme selection after hydration.
This satisfies the updated React hooks lint rule without disabling that rule.

Local lint and TypeScript checks pass. Local production build is blocked by Google
Fonts fetch failures; a separate hosted CI job runs the real lint/build. The
updated guarded audit scans 600 dependencies: 1 low, 0 moderate/high/critical,
exit 1. The remaining deepmerge advisory has no published fixed version according
to the audit response; it is retained as a failure, not ignored.

Pub JSON output always includes transitive packages; do not pass --transitive
alongside --json (the SDK rejects that combination). Lock coverage remains checked
by the Python script.
