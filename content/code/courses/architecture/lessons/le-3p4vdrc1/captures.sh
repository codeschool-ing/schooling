#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of architecture, as a script that
# produces them. Its output is not committed: every transcript in the lesson was
# copied from a run of it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo bash captures.sh
#
# The six files of ~/lab/delivery are EXTRACTED from the section "The payments
# lab" (the-payments-lab.md), as the copy button hands them over. The shell
# variable R that section defines is set in every command below the same way.
# Staged: the tools image is built beforehand (lab.sh, "prebuild"); the broker
# gets 15 seconds to start. Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"
L=le-3p4vdrc1
lab reset
at '~/lab/delivery'
for f in topology.py publish.py pay.py outbox.py Dockerfile compose.yaml; do save $L/the-payments-lab.md $f "~/lab/delivery/$f"; done
RV='R="docker compose --progress quiet run --rm tools python"'
rrun() { printf 'ana@vm:%s$ %s\n' "$HERE" "$1"; lab as "cd $(dir) && $RV && { $1 ; }" 2>&1 || true; }
prebuild
quiet 'docker compose up -d'
sleep 15
block naive-crash
rrun '$R publish.py q-1 3290'
rrun '$R pay.py --naive --crash-after-charge'
block naive-again
rrun '$R pay.py --naive'
rrun '$R pay.py --list'
block idem-crash
rrun '$R publish.py q-2 2450'
rrun '$R pay.py --crash-after-charge'
block idem-again
rrun '$R pay.py'
rrun '$R pay.py --list'
block returned
rrun '$R publish.py q-3 990 refunds'
block outbox-down
run 'docker compose stop rabbitmq'
rrun 'docker compose --progress quiet run --rm --no-deps tools python outbox.py order o-1 649'
rrun 'docker compose --progress quiet run --rm --no-deps tools python outbox.py relay'
block outbox-up
run 'docker compose start rabbitmq'
sleep 12
rrun '$R outbox.py relay'
rrun '$R pay.py'
block poison
rrun '$R publish.py q-4 899 --broken'
rrun '$R pay.py'
run 'docker compose exec rabbitmq rabbitmqctl list_queues name messages --quiet'
quiet 'docker compose down -v'
