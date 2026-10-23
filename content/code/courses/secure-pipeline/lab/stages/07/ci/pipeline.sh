#!/usr/bin/env bash
# The pipeline: every stage named in a list, in order. The list is ci/stages,
# what runs on every push, unless another is given, such as ci/nightly. A
# stage is the script ci/<name>.sh, run from the repository's root, and its
# exit status is its verdict: 0 passes, 3 passes with a warning that is
# counted and shown, and anything else breaks the build and stops the run.
set -uo pipefail
cd "$(dirname "$0")/.."
LIST=${1:-ci/stages}
LOGS=${CI_LOGS:-ci-logs}
mkdir -p "$LOGS"
warnings=0
while read -r stage; do
  case $stage in '' | '#'*) continue ;; esac
  start=$SECONDS
  bash "ci/$stage.sh" >"$LOGS/$stage.log" 2>&1
  status=$?
  took=$((SECONDS - start))
  if [ "$status" -eq 0 ]; then
    echo "$stage: passed in ${took}s"
  elif [ "$status" -eq 3 ]; then
    warnings=$((warnings + 1))
    echo "$stage: WARNING in ${took}s, the end of $stage.log:"
    tail -n 8 "$LOGS/$stage.log" | sed 's/^/  /'
  else
    echo "$stage: FAILED in ${took}s, the end of $stage.log:"
    tail -n 15 "$LOGS/$stage.log" | sed 's/^/  /'
    exit 1
  fi
done <"$LIST"
echo "pipeline passed with $warnings warning(s)"
