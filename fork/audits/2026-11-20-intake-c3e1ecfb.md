# Intake audit: upstream c3e1ecfb (v0.2.0-8-gc3e1ecfb)

**Verdict: take with patches.** Use as a local tool and as a source of methods and guides; run only under the safe
launch environment of [fork/README.md](../README.md) ("What we run and what we never run"). Not cleared to run
unattended inside an agent pipeline with keys until it runs confined (no home folder, egress allow list) and the
patches below are in.

Reviewer: Claude Code session in `content-factory-agent` on the owner's order of 2026-11-20 (Fabric's CEO window,
session 53895bdc), two read-only audit passes (security; capabilities), key findings checked by hand against the code.
Nothing from upstream was installed or run. Date: 2026-11-20.

## What was read

- The whole tree at `c3e1ecfb3df8` (13,558 tracked files): install surface, `package.json` files and the lockfile,
  network hosts in shipped code, child processes and dynamic code, the MCP server, the local HTTP servers, key
  storage, telemetry, skills and agent instructions, workflows, history.
- `fork/door-audit.sh v0.1.1 v0.2.0` and `fork/door-audit.sh v0.2.0 c3e1ecfb` (the eight commits past the release:
  tests and skill text only, no install, dependency, host or telemetry change).

## Findings

| Id | Finding | Evidence | Disposition |
|---|---|---|---|
| S1 | Telemetry on by default to a shared PostHog project, with a device id from an HMAC of the Mac's IOPlatformUUID, an installation id and GeoIP | `tracking/README.md:14`, `tracking/device.ts:22`, `shared/tracking-config.json`, off switch `shared/tracking.ts:15-17` | `OPENMOTION_TELEMETRY=0` and `DO_NOT_TRACK=1` in every launch (README rule) |
| S2 | Every server start prefetches the vendor's proprietary account connector (`@powerformer/vela-cli`, UNLICENSED, native binaries) and trusts any `vela` on PATH that prints its version | `server.ts:873`, `gateway/account-connector.ts:27,75`, `gateway/account.ts:236,243` | `OPENMOTION_ACCOUNT_CLI` set to a path that does not exist; `npm ci --omit=dev` drops it; patch `prefetch()` out before unattended use (open) |
| S3 | `openmotion_import_asset` copies any absolute path up to 500 MB into the project, readable back through the MCP | `workspace.ts:491-503` | agents drive the MCP with no home folder mounted; a path allow list patch before unattended use (open) |
| S4 | Design export launches headless Chromium with `--no-sandbox --disable-gpu-sandbox` on agent-written HTML | `design-projects.ts:1179` | run inside a confined runner or container only |
| S5 | The media skill steers agents to the vendor's paid OpenDesign account or cloud first | `skills/openmotion-media/SKILL.md:27` (upstream) | **patched** (`fork/patches/guard.json`, `no-opendesign-first`; `fork/test.sh` holds it) |
| S6 | Installers follow upstream `main` and install a public skill globally from upstream | `install.sh:48-77`, `scripts/install-public-skill.ts:10,70` | never run them; install from this line (README rule) |
| S7 | Provider keys stored as plaintext JSON (0600) when set in the Studio | `gateway/settings-storage.ts:10-12`, `gateway/connections.ts:44-52` | keys only through the environment from Observatory (`use_secret.py run`); the Studio's key form unused |
| S8 | Loopback API has no token for local callers (host and origin checks against DNS rebinding and CSRF are present) | `server.ts:356-385`, bind `server.ts:807-814` | `MOTION_BIND_HOST` unset; one run per machine account |
| S9 | Codex image generation runs `codex exec --sandbox workspace-write -c approval_policy="never"` | `gateway/agents.ts:50` | not used (images go through the media service) |
| S10 | No SECURITY.md; 11 workflows, some actions pinned by tag; very high commit rate (640 commits in 2026-11), a bot is the top author; a stray tag `v0.6.8-test.21` | `.github/workflows/`, `git log` | Actions disabled on this fork; upstream taken only at release tags through the door audit |

Clean: no `eval`, `new Function`, `vm` or `shell: true` in shipped code; spawns use argv arrays; the lockfile resolves
all 477 packages from registry.npmjs.org with integrity hashes; only `esbuild` and `fsevents` carry install scripts;
runtime downloads (Node, Chrome for Testing, ffmpeg, Python, wheels) are SHA256-pinned; no committed secret (one test
fixture); servers bind 127.0.0.1 with host and origin checks.

## Not checked

`node_modules` contents (not installed), the ~1,800 vendored JavaScript files under `library/`, the Studio front end in
depth, live network behaviour, upstream's GitHub settings, `.mcp.json` and `.env.development` (a local credential guard
blocked reading them).
