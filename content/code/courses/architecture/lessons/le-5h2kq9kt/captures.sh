#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of architecture, as a script that
# produces them. Its output is not committed: every transcript in the lesson was
# copied from a run of it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo bash captures.sh
#
# The five files of ~/lab/bulkheads are EXTRACTED from the section "The lab: a
# shop with eight threads" (the-lab.md), as the copy button hands them over, and
# so is the variable L that section defines. Staged: the image is built
# beforehand (lab.sh, "prebuild"), and between experiments the script waits for
# calls still in flight to the slow stock service to finish. Recorded on Ubuntu
# 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"
L=le-5h2kq9kt
lab reset
at '~/lab/bulkheads'
for f in stock.py shop.py load.py Dockerfile compose.yaml; do save $L/the-lab.md $f "~/lab/bulkheads/$f"; done
DEFS=$(python3 - "$COURSE/lessons/$L/the-lab.md" <<'PY'
import re, sys
print(re.search(r'^L=".*"$', open(sys.argv[1]).read(), re.M).group(0))
PY
)
lrun() { printf 'ana@vm:%s$ %s\n' "$HERE" "$1"; lab as "cd $(dir) && $DEFS && { $1 ; }" 2>&1 || true; }
prebuild
quiet 'docker compose up -d'
sleep 3
block healthy
lrun '$L mixed'
block slow
lrun 'curl -s -X POST localhost:8001/slow/5'
lrun '$L mixed'
quiet 'curl -s -X POST localhost:8001/slow/0.02'
sleep 8
block bulkhead
lrun 'BULKHEAD=3 docker compose up -d'
sleep 2
lrun 'curl -s -X POST localhost:8001/slow/5'
lrun '$L mixed'
quiet 'curl -s -X POST localhost:8001/slow/0.02'
sleep 8
block greedy
lrun 'RATE=10 docker compose up -d'
sleep 2
lrun '$L greedy'
block burst-unbounded
lrun 'docker compose up -d'
sleep 2
lrun '$L burst 100'
lrun 'sleep 11; curl -s localhost:8002/orders'
block burst-bounded
lrun 'QUEUE=20 docker compose up -d'
sleep 2
lrun '$L burst 100'
lrun 'sleep 4; curl -s localhost:8002/orders'
quiet 'docker compose down'
