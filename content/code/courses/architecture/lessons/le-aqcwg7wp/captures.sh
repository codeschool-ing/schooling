#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of architecture, as a script that
# produces them. Its output is not committed: every transcript in the lesson was
# copied from a run of it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo bash captures.sh
#
# Every file of ~/lab/split is EXTRACTED from the section "Moving the stock
# out" (splitting-the-stock.md), as the copy button hands it over. Staged: the
# images are built beforehand (lab.sh, "prebuild"). Recorded on Ubuntu 24.04,
# TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"
L=le-aqcwg7wp
lab reset
at '~/lab/split'
for f in stock/stock.py stock/Dockerfile shop/shop.py shop/Dockerfile shop/bench.py compose.yaml; do
  save $L/splitting-the-stock.md $f "~/lab/split/$f"
done
prebuild
block split-up
run 'find . -type f | sort'
run 'docker compose up -d --build --quiet-build'
run 'docker compose ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}"'
sleep 2
block split-products
run 'curl -s localhost:8000/products'
block split-order
run "curl -s -H 'X-Request-Id: order-1' -X POST localhost:8000/orders -d '{\"sku\": \"tomato\", \"qty\": 3, \"card\": \"4111111111111111\"}'"
run 'docker compose logs --no-log-prefix | grep order-1'
block bench
run 'docker compose exec shop python bench.py'
block stock-down
run 'docker compose stop stock'
run 'curl -s -i -w "took %{time_total}s\n" localhost:8000/products'
block stock-up
run 'docker compose start stock'
sleep 2
block half-order
run 'curl -s localhost:8000/products | grep coffee'
run "curl -s -X POST localhost:8000/orders -d '{\"sku\": \"coffee\", \"qty\": 1, \"card\": \"4000000000000002\"}'"
run 'curl -s localhost:8000/products | grep coffee'
block stats
run 'docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}"'
quiet 'docker compose down -v'
