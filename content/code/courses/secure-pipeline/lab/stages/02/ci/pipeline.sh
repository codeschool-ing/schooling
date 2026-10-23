#!/usr/bin/env bash
# The pipeline: every stage named in a list, in order. The list is ci/stages,
# what runs on every push, unless another is given, such as ci/nightly. A
# stage is the script ci/<name>.sh, run from the repository's root. Exit 0
# passes it; anything else breaks the build, and the run stops at that stage.
# A list that is not there breaks it too, rather than passing with no stages.
set -uo pipefail
cd "$(dirname "$0")/.."
LIST=${1:-ci/stages}
[ -f "$LIST" ] || { echo "no list of stages at $LIST"; exit 1; }
LOGS=${CI_LOGS:-ci-logs}
mkdir -p "$LOGS"
while read -r stage; do
  case $stage in '' | '#'*) continue ;; esac
  start=$SECONDS
  if bash "ci/$stage.sh" >"$LOGS/$stage.log" 2>&1; then
    echo "$stage: passed in $((SECONDS - start))s"
  else
    echo "$stage: FAILED in $((SECONDS - start))s, the end of $stage.log:"
    tail -n 15 "$LOGS/$stage.log" | sed 's/^/  /'
    exit 1
  fi
done <"$LIST"
echo "pipeline passed"
