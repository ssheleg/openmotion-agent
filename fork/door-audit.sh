#!/usr/bin/env bash
# The security door audit of an upstream update (fork/README.md, "Taking an upstream update").
# Lists what changed between two upstream refs in the places a supply-chain attack or a quiet capability change lands:
# install scripts and package hooks, dependencies and their sources, GitHub workflows, new network hosts, new child
# processes and dynamic code, files that ship binaries or minified blobs, telemetry, and the instructions the
# repository gives coding agents (AGENTS.md, CLAUDE.md, skills). It reads git only; it never installs or runs the
# upstream code. It reports; an agent or a person reads every hit and writes the verdict into fork/audits/.
#
#   fork/door-audit.sh <from-ref> <to-ref>            # markdown report on stdout
#   fork/door-audit.sh <from-ref> <to-ref> --counts   # one line of counts per section (for status and tests)
#
# Exit 0 when the report was written (hits or not), 2 on bad input.
set -euo pipefail

[ $# -ge 2 ] || { echo "usage: fork/door-audit.sh <from-ref> <to-ref> [--counts]" >&2; exit 2; }
FROM="$1"; TO="$2"; MODE="${3:-report}"
cd "$(git rev-parse --show-toplevel)"
for r in "$FROM" "$TO"; do
  git rev-parse -q --verify "$r^{commit}" >/dev/null || { echo "unknown ref $r (git fetch upstream --tags)" >&2; exit 2; }
done

# Shipped code: everything but tests, fixtures and docs.
SHIPPED=(. ':(exclude)**/*.test.*' ':(exclude)**/*.spec.*' ':(exclude)**/tests/**' ':(exclude)**/test/**'
  ':(exclude)**/__tests__/**' ':(exclude)**/__fixtures__/**' ':(exclude)**/fixtures/**' ':(exclude)docs/**'
  ':(exclude)**/*.md' ':(exclude)**/*.mdx' ':(exclude)package-lock.json' ':(exclude)**/package-lock.json'
  ':(exclude)fork/**' ':(exclude)library/**' ':(exclude)template-library/**' ':(exclude)templates/**' ':(exclude)examples/**')
# Content libraries (templates, design systems, examples): HTML and JSON that a browser renders. Counted in their own
# section; read a sample of them when the count jumps or a template gains a <script src> to a new host.
CONTENT=(library template-library templates examples)
added() { git diff "$FROM" "$TO" -- "${SHIPPED[@]}" | awk '/^\+\+\+ b\//{f=substr($0,7)} /^\+[^+]/{print f": "substr($0,2)}'; }

declare -a NAMES=() COUNTS=()
OUT=""
section() {  # section <title> <command output>
  local title="$1" body="$2" n=0
  [ -n "$body" ] && n=$(printf '%s\n' "$body" | grep -c . || true)
  NAMES+=("$title"); COUNTS+=("$n")
  OUT+=$'\n'"## $title ($n)"$'\n'
  if [ "$n" -gt 0 ]; then OUT+=$(printf '%s\n' "$body" | cut -c1-240 | awk 'NR<=200; NR==201{print "... (" '"$n"' - 200 " more)"}')$'\n'; else OUT+="none"$'\n'; fi
}

section "Install scripts and package hooks" "$(
  git diff --name-only "$FROM" "$TO" -- 'install.sh' '**/install*.sh' 'scripts/install*' | sed 's/^/changed file: /'
  git diff "$FROM" "$TO" -- 'package.json' '**/package.json' | grep -E '^\+.*"(preinstall|install|postinstall|prepare|prepublish|prepack|postpack)"' | sed 's/^+[[:space:]]*/added hook: /' || true
)"

section "Dependencies added or moved to another source" "$(
  git diff "$FROM" "$TO" -- 'package.json' '**/package.json' | grep -E '^\+[[:space:]]+"(@[^"]+/)?[a-z0-9._-]+": "[^"]+",?$' | grep -vE '"(name|version|description|main|module|types|license|type)":' | sed 's/^+[[:space:]]*/dep: /' || true
  git diff "$FROM" "$TO" -- 'package-lock.json' '**/package-lock.json' | grep -E '^\+[[:space:]]+"resolved": "' | grep -v 'https://registry.npmjs.org/' | sed 's/^+[[:space:]]*/off-registry: /' || true
  git diff "$FROM" "$TO" -- 'package.json' '**/package.json' | grep -E '^\+.*"(git\+|git:|github:|https?://|file:)' | sed 's/^+[[:space:]]*/non-registry spec: /' || true
)"

section "GitHub workflows added or changed (Actions stay disabled on this fork)" "$(
  git diff --name-status "$FROM" "$TO" -- .github/workflows | sed 's/^/workflow: /'
)"

section "Network hosts added in shipped code" "$(
  added | grep -oE '^[^:]+: .*https?://[a-zA-Z0-9.-]+' | sed -E 's#^([^:]+): .*https?://([a-zA-Z0-9.-]+).*#\2\t\1#' \
    | grep -vE '^(localhost|127\.0\.0\.1|example\.(com|org)|www\.w3\.org|schema\.org|json-schema\.org)'$'\t' \
    | sort -u | awk -F'\t' '{n[$1]++; if(!($1 in f)) f[$1]=$2} END{for(h in n) printf "%s  (%d files, e.g. %s)\n", h, n[h], f[h]}' | sort || true
)"

section "Child processes, dynamic code and remote code" "$(
  added | grep -E '(^|[^.[:alnum:]_])(spawn|spawnSync|execFile|execFileSync|execSync|exec|fork)\(|\beval\(|new Function\(|import\(["'"'"'`]https?:|require\(["'"'"'`]https?:|child_process|curl[^|]*\|[[:space:]]*(ba|z)?sh' | cut -c1-240 || true
)"

section "Telemetry, analytics and phone-home" "$(
  added | grep -iE 'posthog|segment\.(io|com)|mixpanel|amplitude|sentry\.io|@sentry/|telemetry|sendBeacon|gtag\(|googletagmanager|plausible|umami' | cut -c1-240 || true
)"

section "Binaries, archives and minified blobs added" "$(
  git diff --name-status --diff-filter=AM "$FROM" "$TO" | awk '{print $2}' \
    | grep -E '\.(node|wasm|exe|dll|dylib|so|bin|jar|zip|tgz|tar|gz|7z|pkg|dmg|app|min\.js)$' | sed 's/^/file: /' || true
)"

section "Instructions to coding agents (AGENTS.md, CLAUDE.md, skills, MCP tools)" "$(
  git diff --name-status "$FROM" "$TO" -- 'AGENTS.md' '**/AGENTS.md' 'CLAUDE.md' '**/CLAUDE.md' 'skills/**' '**/SKILL.md' 'mcp.ts' 'mcp-tools.ts' 'integrations/**' \
    | awk '{n=split($2,a,"/"); k=(n>2? a[1]"/"a[2] : $2); c[k]++} END{for(k in c) print "changed: "k" ("c[k]" files)"}' | sort
  git diff "$FROM" "$TO" -- 'AGENTS.md' '**/AGENTS.md' 'CLAUDE.md' '**/CLAUDE.md' 'skills/**' | grep -E '^\+' | grep -iE 'curl .*\| *(ba|z)?sh|--dangerously|bypass|disable.*(sandbox|permission)|auto-?update|send .* to https?://' | sed 's/^+/risky instruction: /' || true
)"

section "Content libraries: files changed, and external scripts added to templates" "$(
  git diff --name-only "$FROM" "$TO" -- "${CONTENT[@]}" | awk -F/ '{print $1"/"$2}' | sort | uniq -c | awk '{print "changed: "$2" ("$1" files)"}'
  git diff "$FROM" "$TO" -- "${CONTENT[@]}" | grep -E '^\+.*<script[^>]+src="https?://' | grep -oE 'src="https?://[^/"]+' | sort | uniq -c | awk '{print "script host: "$2" ("$1" lines)"}' || true
)"

if [ "$MODE" = "--counts" ]; then
  for i in "${!NAMES[@]}"; do printf '%s\t%s\n' "${COUNTS[$i]}" "${NAMES[$i]}"; done
  exit 0
fi

echo "# Door audit $FROM..$TO"
echo
echo "Upstream commits: $(git rev-list --count --no-merges "$FROM..$TO"); files changed: $(git diff --name-only "$FROM" "$TO" | grep -c . || true)."
echo "Read every hit; write the verdict (take, take with a patch, refuse) into fork/audits/<date>-<from>..<to>.md."
printf '%s' "$OUT"
