#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of architecture, as a script that
# produces them. Its output is not committed: every transcript in the lesson was
# copied from a run of it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo bash captures.sh
#
# The four files of ~/lab/chain are EXTRACTED from the section "A chain of
# three" (the-chain.md), as the copy button hands them over. Staged: the images
# are built beforehand (lab.sh, "prebuild"). Recorded on Ubuntu 24.04,
# TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"
L=le-gdbmh2as
lab reset
at '~/lab/chain'
for f in hop.py report.py Dockerfile compose.yaml; do save $L/the-chain.md $f "~/lab/chain/$f"; done
prebuild
quiet 'docker compose up -d --quiet-build'
sleep 2
block chain-up
run 'docker compose ps --format "{{.Service}} {{.Status}} {{.Ports}}"'
run 'curl -s localhost:8000/'
block chain-broken
run 'docker compose stop stock'
run 'curl -s -w "%{http_code}\n" localhost:8000/'
block chain-restart
run 'docker compose start stock'
block slow
run 'STOCK_DELAY_MS=5000 docker compose up -d stock'
sleep 1
run 'curl -s -w "%{http_code} after %{time_total} s\n" localhost:8000/'
block timeout
run 'PRICING_TIMEOUT_S=1 STOCK_DELAY_MS=5000 docker compose up -d pricing'
sleep 1
run 'curl -s -w "%{http_code} after %{time_total} s\n" localhost:8000/'
block fast-again
run 'docker compose up -d pricing stock'
sleep 1
run 'curl -s -w "%{http_code} after %{time_total} s\n" localhost:8000/'
block report
run 'curl -s -i -X POST localhost:8001/reports'
run 'curl -s localhost:8001/reports/1'
run 'sleep 4; curl -s localhost:8001/reports/1'
quiet 'docker compose down'
