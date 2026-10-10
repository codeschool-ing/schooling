#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of architecture, as a script that
# produces them. Its output is not committed: every transcript in the lesson was
# copied from a run of it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo bash captures.sh
#
# The four files of ~/lab/live are EXTRACTED from the section "The lab: an
# order-status service" (the-lab.md), as the copy button hands them over, and
# so is the variable W that section defines. Staged: the image is built
# beforehand (lab.sh, "prebuild"). Recorded on Ubuntu 24.04,
# TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"
L=le-mkfxz0vc
lab reset
at '~/lab/live'
for f in live.py watch.py Dockerfile compose.yaml; do save $L/the-lab.md $f "~/lab/live/$f"; done
DEFS=$(python3 - "$COURSE/lessons/$L/the-lab.md" <<'PY'
import re, sys
print(re.search(r'^W=".*"$', open(sys.argv[1]).read(), re.M).group(0))
PY
)
wrun() { printf 'ana@vm:%s$ %s\n' "$HERE" "$1"; lab as "cd $(dir) && $DEFS && { $1 ; }" 2>&1 || true; }
prebuild
quiet 'docker compose up -d'
sleep 3
block poll
run 'curl -s "localhost:8001/poll?since=0"; echo'
run 'curl -s -X POST localhost:8001/publish -d "o-1 paid"'
run 'curl -s "localhost:8001/poll?since=0"; echo'
block long-poll
run '(sleep 2; curl -s -X POST localhost:8001/publish -d "o-1 packed" > /dev/null) & time curl -s "localhost:8001/long-poll?since=1"; echo'
block sse
run 'timeout 4 curl -sN localhost:8001/events & sleep 1; curl -s -X POST localhost:8001/publish -d "o-1 shipped" > /dev/null; wait'
block sse-resume
run 'timeout 2 curl -sN localhost:8001/events -H "Last-Event-ID: 2"'
block ws
wrun '$W ws://live-a:8000/ws 3 & sleep 1.5; curl -s -X POST localhost:8001/publish -d "o-1 out for delivery" > /dev/null; wait'
block no-backplane
wrun '$W ws://live-b:8000/ws 3 & sleep 1.5; curl -s -X POST localhost:8001/publish -d "o-2 paid"; wait'
block backplane
wrun 'BACKPLANE=redis://redis:6379 docker compose up -d'
sleep 3
wrun '$W ws://live-b:8000/ws 3 & sleep 1.5; curl -s -X POST localhost:8001/publish -d "o-2 paid"; wait'
quiet 'docker compose down'
