#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of architecture, as a script that
# produces them. Its output is not committed: every transcript in the lesson was
# copied from a run of it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo bash captures.sh
#
# The eight files of ~/lab/strangler are EXTRACTED from the section "The lab: a
# monolith behind an edge" (the-lab.md), as the copy button hands them over.
# The two commands in "Moving the stock" that rewrite stock-split.conf are
# extracted from that section too and run as they are written there. Staged:
# the image is built beforehand (lab.sh, "prebuild"). Recorded on Ubuntu 24.04,
# TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"
L=le-pb7n7t3q
lab reset
at '~/lab/strangler'
for f in monolith.py stock.py proxy.py gateway.py nginx.conf stock-split.conf Dockerfile compose.yaml; do
  save $L/the-lab.md $f "~/lab/strangler/$f"
done
split() { # split N: the Nth command block of "Moving the stock", as typed
  python3 - "$COURSE/lessons/$L/moving-the-stock.md" "$1" <<'PY' | lab as "cd ~/lab/strangler && bash"
import re, sys
print(re.findall(r"```sh\n(.*?)\n```", open(sys.argv[1]).read(), re.S)[int(sys.argv[2]) - 1])
PY
}
prebuild
quiet 'docker compose up -d'
sleep 3
block up
run 'curl -s localhost:8080/catalogue; curl -s localhost:8080/stock/coffee'
split 1 >/dev/null 2>&1
sleep 1
block canary
run 'for i in $(seq 40); do curl -s localhost:8080/stock/coffee; done | sort | uniq -c'
split 2 >/dev/null 2>&1
sleep 1
block all
run 'for i in $(seq 40); do curl -s localhost:8080/stock/coffee; done | sort | uniq -c'
block sidecar-logs
run 'docker compose logs sidecar --tail 5'
block ambassador
run 'for i in 1 2 3; do curl -s -X POST localhost:8080/checkout; done'
run 'docker compose logs ambassador'
quiet 'docker compose down'
