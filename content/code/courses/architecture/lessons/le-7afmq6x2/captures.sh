#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of architecture, as a script that
# produces them. Its output is not committed: every transcript in the lesson was
# copied from a run of it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo bash captures.sh
#
# The four files of ~/lab/events are EXTRACTED from the section "The lab: orders
# as events" (the-lab.md), as the copy button hands them over, and so is the
# variable O that section defines. Staged: the tools image is built beforehand
# (lab.sh, "prebuild"); PostgreSQL gets ten seconds to start. Recorded on Ubuntu
# 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"
L=le-7afmq6x2
lab reset
at '~/lab/events'
for f in schema.sql orders.py Dockerfile compose.yaml; do save $L/the-lab.md $f "~/lab/events/$f"; done
DEFS=$(python3 - "$COURSE/lessons/$L/the-lab.md" <<'PY'
import re, sys
print(re.search(r'^O=".*"$', open(sys.argv[1]).read(), re.M).group(0))
PY
)
orun() { printf 'ana@vm:%s$ %s\n' "$HERE" "$1"; lab as "cd $(dir) && $DEFS && { $1 ; }" 2>&1 || true; }
prebuild
quiet 'docker compose up -d'
sleep 10
Q='docker compose exec -T db psql -U postgres'
block o1
orun '$O place o-1'
orun '$O add o-1 coffee 2'
orun '$O add o-1 tea 1'
orun '$O remove o-1 tea'
orun '$O add o-1 rice 3'
orun '$O pay o-1'
orun '$O add o-1 tea 1'
block o1-events
orun "$Q -c 'SELECT position, stream, version, type, data FROM events'"
block o1-show
orun '$O show o-1'
block project
orun '$O place o-2'
orun '$O add o-2 tea 4'
orun '$O project'
orun "$Q -c 'SELECT * FROM order_summary' -c 'SELECT * FROM units_sold'"
block project-again
orun '$O pay o-2'
orun "$Q -c 'SELECT * FROM units_sold'"
orun '$O project'
orun "$Q -c 'SELECT * FROM units_sold'"
block o1-past
orun '$O show o-1 3'
block removed
orun "$Q -c \"SELECT data->>'product' AS product, count(*) AS removed FROM events WHERE type = 'ItemRemoved' GROUP BY 1\""
block rebuild
orun '$O rebuild'
orun "$Q -c 'SELECT * FROM units_sold'"
block conflict
orun '$O place o-3'
orun '$O add o-3 tea 2 --think & sleep 0.5; $O add o-3 coffee 1 --think; wait'
orun '$O show o-3'
quiet 'docker compose down -v'
