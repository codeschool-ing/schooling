#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of architecture, as a script that
# produces them. Its output is not committed: every transcript in the lesson was
# copied from a run of it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo bash captures.sh
#
# The five files of ~/lab/eventual are EXTRACTED from the section "The lab: the
# stock and two copies of it" (the-stock-lab.md), as the copy button hands them
# over. Staged: the image is built beforehand (lab.sh, "prebuild"), so the
# shown build is the cache. The broker gets 15 seconds to start, and the waits
# between commands are the ones the lesson shows. Recorded on Ubuntu 24.04,
# TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"
L=le-mgpsdvb4
lab reset
at '~/lab/eventual'
for f in bus.py stock.py shop.py Dockerfile compose.yaml; do save $L/the-stock-lab.md $f "~/lab/eventual/$f"; done
prebuild
block up
run 'docker compose up -d --build --quiet-build'
sleep 15
block first
run 'curl -s -X PUT localhost:8001/stock/coffee -d 12; curl -s localhost:8002/product/coffee; curl -s localhost:8003/product/coffee'
run 'sleep 3; curl -s localhost:8003/product/coffee'
block first-logs
run 'docker compose logs shop-a shop-b'
block window
run 'curl -s -X PUT localhost:8001/stock/coffee -d 11; for i in $(seq 6); do curl -s localhost:8003/product/coffee; sleep 0.5; done'
sleep 2
block burst
run 'for n in $(seq 10 -1 1); do curl -s -X PUT localhost:8001/stock/coffee -d $n > /dev/null; done'
run 'curl -s localhost:8001/stock/coffee; curl -s localhost:8002/product/coffee; curl -s localhost:8003/product/coffee'
run 'docker compose exec rabbitmq rabbitmqctl list_queues name messages'
block caught-up
run 'sleep 25; docker compose exec rabbitmq rabbitmqctl list_queues name messages'
run 'curl -s localhost:8002/product/coffee; curl -s localhost:8003/product/coffee'
block ryw-stale
run 'curl -s -X PUT localhost:8001/stock/coffee -d 0; curl -s localhost:8003/product/coffee'
block ryw-after
run "curl -s 'localhost:8003/product/coffee?after=13'"
sleep 3
block monotonic
run 'curl -s -X PUT localhost:8001/stock/coffee -d 7'
run 'sleep 0.5; curl -s localhost:8002/product/coffee; sleep 0.5; curl -s localhost:8003/product/coffee'
block monotonic-after
run "curl -s 'localhost:8003/product/coffee?after=14'"
sleep 3
block resend
run 'curl -s -X PUT localhost:8001/stock/coffee -d 5; curl -s -X PUT localhost:8001/stock/coffee -d 4'
run 'sleep 5; curl -s -X POST localhost:8001/resend/coffee/15'
run 'sleep 3; curl -s localhost:8001/stock/coffee; curl -s localhost:8003/product/coffee'
block resend-logs
run 'docker compose logs shop-b --tail 3'
block checked
run 'CHECK_VERSION=1 docker compose up -d'
sleep 5
run 'curl -s -X PUT localhost:8001/stock/coffee -d 5; curl -s -X PUT localhost:8001/stock/coffee -d 4'
run 'sleep 5; curl -s -X POST localhost:8001/resend/coffee/17'
run 'sleep 3; curl -s localhost:8001/stock/coffee; curl -s localhost:8003/product/coffee'
run 'docker compose logs shop-b --tail 3'
block lww
run 'curl -s -X PUT localhost:8002/basket/ana/tea; curl -s -X PUT localhost:8003/basket/ana/coffee'
run 'sleep 5; curl -s localhost:8002/basket/ana; curl -s localhost:8003/basket/ana'
block union
run 'MERGE=union CHECK_VERSION=1 docker compose up -d'
sleep 5
run 'curl -s -X PUT localhost:8002/basket/ana/tea; curl -s -X PUT localhost:8003/basket/ana/coffee'
run 'sleep 5; curl -s localhost:8002/basket/ana; curl -s localhost:8003/basket/ana'
block comes-back
run 'curl -s -X DELETE localhost:8002/basket/ana/tea; sleep 0.5; curl -s -X PUT localhost:8003/basket/ana/bread'
run 'sleep 5; curl -s localhost:8002/basket/ana; curl -s localhost:8003/basket/ana'
quiet 'docker compose down -v'
