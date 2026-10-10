#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of architecture, as a script that
# produces them. Its output is not committed: every transcript in the lesson was
# copied from a run of it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo bash captures.sh
#
# The four files of ~/lab/perf are EXTRACTED from the section "The lab: a
# database a millisecond away" (the-lab.md), as the copy button hands them
# over, and so is the variable P that section defines. Staged: the tools image
# is built beforehand (lab.sh, "prebuild"); PostgreSQL gets ten seconds to
# start. Timings depend on the machine; the prose quotes this run. Recorded on
# Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"
L=le-ewexv70q
lab reset
at '~/lab/perf'
for f in latency.py shop.py Dockerfile compose.yaml; do save $L/the-lab.md $f "~/lab/perf/$f"; done
DEFS=$(python3 - "$COURSE/lessons/$L/the-lab.md" <<'PY'
import re, sys
print(re.search(r'^P=".*"$', open(sys.argv[1]).read(), re.M).group(0))
PY
)
prun() { printf 'ana@vm:%s$ %s\n' "$HERE" "$1"; lab as "cd $(dir) && $DEFS && { $1 ; }" 2>&1 || true; }
prebuild
quiet 'docker compose up -d'
sleep 10
Q='docker compose exec -T db psql -U postgres'
block seed
prun '$P seed'
block n1
prun '$P history-n1 c-7'
prun '$P history-join c-7'
block fetch
prun '$P catalogue-star'
prun '$P catalogue-columns'
block busy
prun "$Q -c 'SELECT pg_stat_statements_reset()'"
prun '$P front-page'
prun "$Q -c 'SELECT calls, round(total_exec_time) AS total_ms, rows, left(query, 50) AS query FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 3'"
block cached
prun '$P front-page --cached'
block plan
prun "$Q -c 'EXPLAIN ANALYZE SELECT product_id, units FROM items WHERE order_id = 42'"
prun "$Q -c 'CREATE INDEX ON items (order_id)' -c 'EXPLAIN ANALYZE SELECT product_id, units FROM items WHERE order_id = 42'"
quiet 'docker compose down -v'
