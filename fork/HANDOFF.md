# Handoff: OpenMotion Agent line

## Objective

Our own line of OpenMotion (`nexu-io/openmotion`), taken from upstream only through a security door audit, used as a
base tool of the content factory beside HyperFrames (owner, 2026-11-20, Fabric's CEO window, session 53895bdc).

## Done (2026-11-20)

- Forked as `ssheleg/openmotion-agent` (public, as upstream is; Actions disabled in the repository settings).
- `main` at upstream `c3e1ecfb3df8` plus `fork/`: [README](README.md) (the rules and the update procedure),
  [UPSTREAM.json](UPSTREAM.json), `door-audit.sh`, `status.sh`, `test.sh` (9 cases), the intake audit
  [audits/2026-11-20-intake-c3e1ecfb.md](audits/2026-11-20-intake-c3e1ecfb.md), and `template-receipt.json` at the root.
- `upstream` branch mirrors upstream `main`.
- Patch S5 `no-opendesign-first` on `skills/openmotion-media/SKILL.md`, held by `fork/patches/guard.json` and `fork/test.sh`.

## Patches

| Id | File | Why | Drop when |
|---|---|---|---|
| `no-opendesign-first` | `skills/openmotion-media/SKILL.md` | media goes through the operator's media service; the vendor's paid services only on the user's word | never (our policy, not an upstream bug) |

## Open

1. Patch `prefetch()` of the account connector out (S2) and an allow list for `openmotion_import_asset` (S3), each
   with a guard entry and a test, before any unattended run.
2. A confined trial: install from this line (`npm ci --ignore-scripts --omit=dev`) in a throwaway confined copy, run
   upstream's tests, render one template to MP4 with the safe launch environment; record it in the audit file and move
   Asset Foundry's `openmotion` entry from `untested` to `smoke` with that evidence.
3. The engine pin: OpenMotion pins HyperFrames 0.9.7, our HyperFrames line is at 0.9.52. Decide whether this line
   moves its pin to our HyperFrames line (a patch with a guard) or stays on upstream's.
4. The first scheduled door audit: weekly, or at upstream's next release tag (`fork/status.sh` exits 10 when one waits).

## Checks run

`bash fork/test.sh` (9 of 9 ok), `bash fork/status.sh` (exit 0, Actions disabled),
`fork/door-audit.sh v0.1.1 v0.2.0` and `v0.2.0 c3e1ecfb` (reports read; summary in the intake audit).

## Next task

Open item 2 (the confined trial), then item 1.
