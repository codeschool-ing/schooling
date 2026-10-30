#!/usr/bin/env bash
# redo.sh LESSON [--no-capture]: run a lesson's captures and put everything back in place.
#
# 1. captures.sh, its output kept in /tmp/anglab/LESSON.txt
# 2. fill.py on every section that has a transcript fence
# 3. pt.py on every translation, so its fences are the English ones again
# 4. fig.py, if the lesson has figures
# A capture run changes the English fences; forgetting step 3 is how a
# translation ends up quoting yesterday's run, so the three go together.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
L=$1
D=$HERE/../lessons/$L
mkdir -p /tmp/anglab
# The examples first: a capture takes files out of them.
for md in "$D"/*.md; do case $md in *.pt.md) ;; *) python3 "$HERE/ex.py" "$md" >/dev/null ;; esac; done
if [ "${2:-}" != "--no-capture" ] && [ -f "$D/captures.sh" ]; then
  bash "$D/captures.sh" > /tmp/anglab/$L.txt 2>&1
fi
# The sections in the lesson's order, all in one call: a command typed in two
# sections is two blocks, and each section has to get its own.
if [ -f /tmp/anglab/$L.txt ]; then
  mapfile -t MDS < <(python3 -c "import json,sys; print('\n'.join(sys.argv[2]+'/'+s['slug']+'.md' for s in json.load(open(sys.argv[1]))['sections']))" "$D/lesson.json" "$D")
  python3 "$HERE/fill.py" "${MDS[@]}" /tmp/anglab/$L.txt
fi
for pt in "$D"/*.pt.md; do
  md=${pt%.pt.md}.md
  if grep -q '^```' "$md"; then python3 "$HERE/pt.py" "$md" "$pt" >/dev/null || echo "pt.py failed on $pt"; fi
done
[ -f "$HERE/figures/$L.py" ] && python3 "$HERE/fig.py" "$L" >/dev/null
# A helper that gave up says so in the output, and a fence would carry it.
if [ -f /tmp/anglab/$L.txt ] && grep -nE '^(rebuilt|wait_port|wait_log|shown|restore|expect): ' /tmp/anglab/$L.txt; then
  echo "$L: a capture step failed, see above" >&2; exit 1
fi
echo "$L: done"
