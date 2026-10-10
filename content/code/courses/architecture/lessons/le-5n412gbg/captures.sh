#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of architecture, as a script that
# produces them. Its output is not committed: every transcript in the lesson was
# copied from a run of it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo bash captures.sh
#
# The eight files of ~/lab/saga are EXTRACTED from the section "The lab: stock,
# payments and shipping" (the-lab.md), as the copy button hands them over, and
# so is the variable R that section defines. Staged: the image is built
# beforehand (lab.sh, "prebuild"); the broker gets 15 seconds to start, and the
# choreography three seconds to finish before its logs are read. The services'
# containers run in UTC, which is the clock their log lines show. Recorded on
# Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"
L=le-5n412gbg
lab reset
at '~/lab/saga'
for f in common.py stock.py payments.py shipping.py saga.py place.py Dockerfile compose.yaml; do
  save $L/the-lab.md $f "~/lab/saga/$f"
done
DEFS=$(python3 - "$COURSE/lessons/$L/the-lab.md" <<'PY'
import re, sys
print(re.search(r'^R=".*"$', open(sys.argv[1]).read(), re.M).group(0))
PY
)
rrun() { printf 'ana@vm:%s$ %s\n' "$HERE" "$1"; lab as "cd $(dir) && $DEFS && { $1 ; }" 2>&1 || true; }
prebuild
quiet 'docker compose up -d'
sleep 15
block orch-ok
rrun '$R saga.py o-1'
block orch-declined
rrun '$R saga.py o-2 --card 4000-0002'
block orch-city
rrun '$R saga.py o-3 --city Noronha'
block orch-state
rrun 'curl -s localhost:8001; echo; curl -s localhost:8002; echo'
block lock
rrun '$R saga.py o-4 --units 2 --card 4000-0002 --pause 5 & sleep 2; $R saga.py o-5; wait'
rrun 'curl -s localhost:8001; echo'
block choreo-place
rrun '$R place.py o-6; $R place.py o-7 --city Noronha; $R place.py o-8 --card 4000-0002'
sleep 3
block choreo-logs
rrun 'docker compose logs --no-log-prefix stock payments shipping | sort'
quiet 'docker compose down'
