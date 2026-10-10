#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of architecture, as a script that
# produces them. Its output is not committed: every transcript in the lesson was
# copied from a run of it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo bash captures.sh
#
# The four files of ~/lab/resilience are EXTRACTED from the section "The lab: a
# service with a fixed capacity" (the-lab.md), as the copy button hands them
# over, and so is the variable C that section defines. Staged: the image is
# built beforehand (lab.sh, "prebuild"). Every run's numbers depend on timing,
# so the prose quotes the run below and not a rule. Recorded on Ubuntu 24.04,
# TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"
L=le-ga0mejnz
lab reset
at '~/lab/resilience'
for f in stock.py client.py Dockerfile compose.yaml; do save $L/the-lab.md $f "~/lab/resilience/$f"; done
DEFS=$(python3 - "$COURSE/lessons/$L/the-lab.md" <<'PY'
import re, sys
print(re.search(r'^C=".*"$', open(sys.argv[1]).read(), re.M).group(0))
PY
)
crun() { printf 'ana@vm:%s$ %s\n' "$HERE" "$1"; lab as "cd $(dir) && $DEFS && { $1 ; }" 2>&1 || true; }
prebuild
quiet 'docker compose up -d'
sleep 3
block healthy
crun '$C --seconds 10'
block fail-plain
crun 'curl -s -X POST localhost:8001/fail/0.2'
crun '$C --rate 20 --seconds 6'
block fail-retry
crun '$C --rate 20 --seconds 6 --retries 2'
quiet 'curl -s -X POST localhost:8001/fail/0'
block storm-plain
crun '$C --freeze-at 6'
block storm-retry
crun '$C --freeze-at 6 --retries 3'
block storm-jitter
crun '$C --freeze-at 6 --retries 3 --backoff jitter'
block storm-breaker
crun '$C --freeze-at 6 --retries 3 --backoff jitter --breaker'
quiet 'docker compose down'
