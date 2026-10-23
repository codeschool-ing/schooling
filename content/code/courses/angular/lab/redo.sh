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
for md in "$D"/*.md; do
  case $md in *.pt.md) continue ;; esac
  if [ -f /tmp/anglab/$L.txt ] && grep -q "^ana@dev:" "$md"; then python3 "$HERE/fill.py" "$md" /tmp/anglab/$L.txt; fi
done
for pt in "$D"/*.pt.md; do
  md=${pt%.pt.md}.md
  if grep -q '^```' "$md"; then python3 "$HERE/pt.py" "$md" "$pt" >/dev/null || echo "pt.py failed on $pt"; fi
done
[ -f "$HERE/figures/$L.py" ] && python3 "$HERE/fig.py" "$L" >/dev/null
echo "$L: done"
