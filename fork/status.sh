#!/usr/bin/env bash
# Where the line stands: its base, upstream releases and commits not merged yet, and whether Actions stay disabled.
#   fork/status.sh     exit 10 when an upstream update waits for its door audit, 0 when nothing does, 1 on a broken rule
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
base="$(python3 -c 'import json;print(json.load(open("fork/UPSTREAM.json"))["base"]["commit"])')"
echo "base: ${base:0:12} ($(git describe --tags "$base" 2>/dev/null || echo untagged))"
rc=0
if git rev-parse -q --verify upstream/main >/dev/null; then
  ahead="$(git rev-list --count "$base..upstream/main")"
  echo "upstream main: $(git rev-parse --short=12 upstream/main), $ahead commit(s) past the base"
  newer="$(git tag --contains "$base" --merged upstream/main | grep -E '^v[0-9]' | grep -v "$(git describe --tags --abbrev=0 "$base" 2>/dev/null || echo none)" || true)"
  [ -n "$newer" ] && echo "upstream releases not merged: $(echo $newer)"
  [ "$ahead" -gt 0 ] && { echo "next: fork/door-audit.sh ${base:0:12} <release tag> > fork/audits/$(date +%F)-<range>.md (fork/README.md, step 3)"; rc=10; }
else
  echo "no upstream remote fetched: git remote add upstream https://github.com/nexu-io/openmotion.git && git fetch upstream --tags"
fi
if command -v gh >/dev/null; then
  enabled="$(gh api repos/ssheleg/openmotion-agent/actions/permissions --jq .enabled 2>/dev/null || echo unknown)"
  echo "actions enabled: $enabled"
  [ "$enabled" = "true" ] && { echo "BROKEN: Actions must stay disabled (gh api -X PUT repos/ssheleg/openmotion-agent/actions/permissions -F enabled=false)"; rc=1; }
fi
exit $rc
