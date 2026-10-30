#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of azure-data (delivery
# guarantees), as a script that produces them. Every transcript in the lesson
# was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE PROGRAMS ARE THE LESSON'S. pay.py is read out of the example in
# where-duplicates.md and totals.py out of the one in the-replay.md; the
# exported variable is the first sh fence of where-duplicates.md and the
# containers are made by the first sh fence of the-replay.md.
#
# STAGED: Azurite is started by `services`; the Event Hubs emulator by the
# command the lesson shows, with the wait for its "Successfully Up" line done
# here by a loop. The crash is the program's own `os._exit`, as the lesson
# says.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services azurite || exit 1
example "$HERE/where-duplicates.md" pay.py pay.py || exit 1
example "$HERE/the-replay.md" totals.py totals.py || exit 1

block up
run 'docker compose --profile eventhubs up -d 2>&1 | tail -1'
for _ in $(seq 240); do docker compose logs eventhubs 2>&1 | grep -q 'Successfully Up' && break; sleep 0.5; done
eval "$(fence "$HERE/where-duplicates.md" 1)"
bash -e <(fence "$HERE/the-replay.md" 1) || exit 1

block pay
run 'python pay.py'
block add
run 'python totals.py add 5'
run 'python totals.py add'
block upsert
run 'python totals.py upsert 5'
run 'python totals.py upsert'
block refuse
run "echo 4590 > o-301.json && az storage blob upload -c sink-upsert -n o-301 -f o-301.json --if-none-match '*' 2>&1 | tail -2"
block guard
run 'python totals.py guard 5'
run 'python totals.py guard'
