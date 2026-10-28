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
