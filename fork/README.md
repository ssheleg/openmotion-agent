# OpenMotion Agent: our line of OpenMotion

`ssheleg/openmotion-agent` is our own line of [nexu-io/openmotion](https://github.com/nexu-io/openmotion) (an agentic
motion-graphics studio: a reference video or a brief to editable motion graphics, exported as MP4). It was forked on
2026-11-20 on the owner's order (Fabric's CEO window, session 53895bdc, brief
`2026-11-20-openmotion-fork-content-factory-brain-brief.md`): «Отдельно сделаем еще к себе форк ... будем его обновлять
периодически ... будем делать периодически security audit ... не будем напрямую все затягивать оттуда, чтобы мы не
подвержены были уязвимостям, которые могут залить люди, которые выпускают этот софт». It is built the way our
HyperFrames line is (`ssheleg/hyperframes-agent`, `fork/README.md` there): one line we can always read, and upstream
taken only through a door audit.

The research behind the choice (what it does, licence, quality, security, how it compares with HyperFrames, Frame
Agent and Asset Foundry): `content-factory-agent` `docs/reports/2026-11-20-openmotion/README.md`.

## What we run and what we never run

| Rule | Why |
|---|---|
| Nothing here is pulled from upstream straight into `main`. An upstream change reaches `main` only as a merge of an audited upstream ref, with its audit file in `fork/audits/`. | a release of someone else's software can carry a planted change; we read it before we run it |
| Consumers pin a commit or a tag of this line (`fork-v<base>-sshlg.<n>`), never upstream, never a moving branch, never `npm i openmotion@latest`. | the version we run is always one we audited |
| GitHub Actions are disabled on this repository (repository setting, checked by `fork/status.sh`). Every workflow came from upstream and targets its infrastructure. | an upstream workflow must never run with our repository's token |
| Upstream telemetry stays off: `OPENMOTION_TELEMETRY=0` and `DO_NOT_TRACK=1` in every environment that runs the line (`shared/tracking.ts:15-17`; upstream reports to a shared PostHog project by default, with a device id derived from the Mac's hardware UUID and GeoIP). | no usage data leaves our machines |
| The safe launch environment: `MOTION_TEMPLATE_SOURCE=repository` (no hosted catalogue), `OPENMOTION_SKIP_PUBLIC_SKILL=1` (no global skill install from upstream), `OPENMOTION_ACCOUNT_CLI` pointed at a path that does not exist (no proprietary account connector fetched at start, `server.ts:873`), `MOTION_DATA_DIR` a folder of its own per run, `MOTION_BIND_HOST` unset (loopback). Never run upstream's `install.sh` or `scripts/install-motion.command`: they follow upstream `main`. Install from this line with `npm ci --ignore-scripts --omit=dev`. | each closes a finding of the intake audit |
| An agent driving the MCP runs with no home folder mounted: `openmotion_import_asset` copies any absolute path into the project (`workspace.ts:491`). | a prompt-injected agent must not reach keys or private files |
| The studio and its servers bind to loopback only and run under a confined runner when an agent drives them (the media-production template's rule: no network except the service's own proxy). | an agent run must not reach the network on its own |
| Provider keys come from Observatory by slot name (`use_secret.py run`), never a file, an argument or upstream's settings store. | the operator's key rule |

## Branches

| Branch | What it is | How it moves |
|---|---|---|
| `main` | our line: an audited upstream ref plus our `fork/` folder and our patches | merges and commits; never rewritten, never force-pushed |
| `upstream` | a mirror of `nexu-io/openmotion` `main` | `git push origin upstream/main:refs/heads/upstream` (fast-forward only); reading it runs nothing |

Base today: upstream `c3e1ecfb3df8` (`v0.2.0-8-gc3e1ecfb`, release `v0.2.0` of 2026-11-20 plus eight commits), recorded
in [UPSTREAM.json](UPSTREAM.json). Its intake audit: [audits/2026-11-20-intake-c3e1ecfb.md](audits/2026-11-20-intake-c3e1ecfb.md).

## Taking an upstream update (the security door)

Run it on a schedule (weekly, and at every upstream release a consumer wants), never as a blind pull:

1. `git fetch upstream --tags` and `fork/status.sh`: the base of `main`, upstream releases and commits not merged yet,
   and whether Actions are still disabled.
2. Pick the candidate: an upstream release tag, not a moving branch, unless a fix we need is only on `main`.
3. `fork/door-audit.sh <base> <candidate> > fork/audits/<date>-<base>..<candidate>.md`. It reads git only and lists
   every change in the doors an attack or a quiet capability change uses: install scripts and package hooks,
   dependencies and their sources (off-registry tarballs, git and file specs), workflows, new network hosts in shipped
   code, new child processes and dynamic code, telemetry, binaries and minified blobs, the instructions the repository
   gives coding agents (AGENTS.md, CLAUDE.md, skills, MCP tools), and changes to the content libraries.
4. Read every hit and write the verdict at the top of that file: `take`, `take with a patch` (name the patch) or
   `refuse` (name what would change it), with the reviewer (session or person) and the date. A new dependency gets its
   registry page, maintainers and install scripts read; a new host gets its purpose; a new instruction to agents gets
   read in full.
5. Install and build only in a throwaway, confined copy (no keys, no network but the registry), run upstream's tests
   there, and note the result in the audit file.
6. On `take`: `git merge --no-ff <candidate>` into `main` with the message `merge upstream <candidate> (audit
   fork/audits/<file>)`, update [UPSTREAM.json](UPSTREAM.json) (base, date, audit), push `main` and the `upstream`
   mirror, and tag a release of the line when a consumer needs one (`fork-v<base>-sshlg.<n>`).
7. On `refuse`: nothing merges; the audit file stays as the record of why.

`fork/test.sh` tests the door audit itself in a throwaway repository (a clean update has no hits; a postinstall hook,
a git dependency, a workflow, a new host, exec and `new Function`, and a curl piped to a shell in a skill are all named).

## Add, never replace

What this line shipped is never changed or deleted (the content farm's rule R28): a published tag or release asset is
never moved; a fix ships under the next number; every patch and merge is recorded with its reason in
[HANDOFF.md](HANDOFF.md).

## Where it goes

- The content factory takes it as a base tool beside HyperFrames: it ships with the factory's agents the way the
  HyperFrames line ships with Frame Agent, pinned to a tag of this line (plan row in `content-factory-agent`
  `docs/plan.md`).
- Asset Foundry's tools catalogue carries its entry (`registry/tools.yaml`, id `openmotion`) with its cases, strengths,
  weaknesses and test mark; the catalogue reaches PassionCode's media tools knowledge base at Foundry's release.
- The template receipt ([../template-receipt.json](../template-receipt.json)): `media-production`, variant
  `engine-line`, `org: personal`, `role: source`.

## Licence

Upstream's code is Apache-2.0 ([../LICENSE](../LICENSE)) and keeps it; our files in `fork/` are under the same
licence. One library skill's starter (`library/design/skills/chat-motion-overlay/assets/remotion-template`) depends on
Remotion, which has its own licence, free only for individuals and small companies: do not use that starter for a
company's work without checking it (the research report, section «Лицензия»). The engine itself is HyperFrames
(Apache-2.0); the 287 catalogue guides study third-party brand films whose rights stay with their owners.
