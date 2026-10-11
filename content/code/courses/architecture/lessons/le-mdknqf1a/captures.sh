#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of architecture, as a script that
# produces them. Its output is not committed: every transcript in the lesson was
# copied from a run of it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo bash captures.sh
#
# The four files of ~/lab/gateway are EXTRACTED from the section "The lab:
# Consul, Traefik and three instances" (the-lab.md), as the copy button hands
# them over, and so is the variable D that section defines. Staged: the image is
# built beforehand (lab.sh, "prebuild"); the stack gets ten seconds to start,
# and the gateway's rate limit two seconds to refill before its own block.
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"
L=le-mdknqf1a
lab reset
at '~/lab/gateway'
for f in stock.py where.py Dockerfile compose.yaml; do save $L/the-lab.md $f "~/lab/gateway/$f"; done
DEFS=$(python3 - "$COURSE/lessons/$L/the-lab.md" <<'PY'
import re, sys
print(re.search(r'^D=".*"$', open(sys.argv[1]).read(), re.M).group(0))
PY
)
drun() { printf 'ana@vm:%s$ %s\n' "$HERE" "$1"; lab as "cd $(dir) && $DEFS && { $1 ; }" 2>&1 || true; }
prebuild
quiet 'docker compose up -d'
sleep 15
block where
drun '$D stock'
block raft
run 'docker compose exec consul consul operator raft list-peers'
block route
run 'for i in $(seq 6); do curl -s localhost:8080/stock/coffee; sleep 0.3; done'
block sick
run 'curl -s -X POST localhost:8002/sick'
drun 'sleep 5; $D stock'
run 'for i in $(seq 6); do curl -s localhost:8080/stock/coffee; sleep 0.3; done'
block stop
drun 'docker compose stop stock-3; $D stock'
sleep 3
block limit
run 'for i in $(seq 20); do curl -s -o /dev/null -w "%{http_code}\n" localhost:8080/stock/coffee; done | sort | uniq -c'
quiet 'docker compose down'
