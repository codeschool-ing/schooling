#!/usr/bin/env bash
# Bring the capture machine to the state a student is in when lesson N starts:
# a fresh `ana`, then every lesson before N replayed with its setup blocks.
# The author's tool. Usage: sudo bash upto.sh N
set -euo pipefail
cd "$(dirname "$0")/.."
n=$1
bash lab/reset.sh
lessons=$(python3 -c "import json; print(' '.join(json.load(open('course.json'))['lessons']))")
i=0
for l in $lessons; do
  i=$((i + 1))
  [ "$i" -ge "$n" ] && break
  mode=--setup; [ "$i" -ge 9 ] && mode=--setup-home
  (cd "lessons/$l" && python3 ../../lab/replay.py $mode --quiet $(python3 -c "import json; print(' '.join(s['slug'] + '.md' for s in json.load(open('lesson.json'))['sections'] if s['kind'] != 'practice'))") > /dev/null 2>&1) || true
  echo "lesson $i replayed"
done
# A student who stops for the day logs out, and what they left running in the
# background goes with the session; a replay's shells do not, so end them here.
pkill -u ana || true
