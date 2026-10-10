#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of scale. Each block of output
# starts with `##### <name>`; the prose quotes the blocks byte for byte.
#
#   bash captures.sh [block ...] > captures.out   (as root, after lab.sh prepare)
#
# STAGED rather than typed:
#   - ~/tickets is written by `lab.sh stage 10`;
#   - after `docker compose up -d` of the whole stack the script waits 10 s,
#     not shown, for Jaeger and the replica; after recreating one service it
#     waits 4 s;
#   - payments fails and waits at random, and trace ids are random, so every
#     run prints different numbers.
# Recorded 2026-10-10 on the machine lab.sh describes.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/lib.sh"
bash "$LAB" stage 10 || exit 1
cd "$HOME/tickets"

LOAD="python3 load.py -m POST 'http://localhost:8080/events/{event}/tickets' --events 50"

cap_up() {
  run 'docker compose build -q'
  run 'docker compose up -d'
  sleep 10
  run 'docker compose ps --format "table {{.Service}}\t{{.Status}}"'
}

cap_flaky() {
  shown 'export BUYER_RATE=1000 BUYER_BURST=1000'
  export BUYER_RATE=1000 BUYER_BURST=1000
  run 'PAYMENTS_FAIL_PERCENT=10 docker compose up -d payments'
  run 'CHARGE_ATTEMPTS=1 docker compose up -d app'
  sleep 4
  run "$LOAD -c 4 -d 10"
  run 'docker compose up -d app'
  sleep 4
  run "$LOAD -c 4 -d 10"
}

cap_backoff() {
  run 'PAYMENTS_FAIL_PERCENT=100 docker compose up -d payments'
  sleep 4
  run "curl -s -w ' %{http_code} in %{time_total} s\n' -X POST localhost:8080/events/1/tickets"
  run "docker compose logs app --no-log-prefix | grep 'charge retry' | tail -2"
  run 'sleep 7'
  run 'python3 trace.py'
}

cap_storm() {
  run 'python3 storm.py'
}

cap_twice() {
  run 'PAYMENTS_DELAY_MS=600 docker compose up -d payments'
  run 'IDEMPOTENCY_KEYS=off docker compose up -d app'
  sleep 4
  run "$LOAD -c 4 -d 10"
  run 'curl -s localhost:8001/charges; echo'
}

cap_keys() {
  run 'docker compose restart payments'
  run 'docker compose up -d app'
  sleep 4
  run "$LOAD -c 4 -d 10"
  run 'curl -s localhost:8001/charges; echo'
}

cap_polite() {
  run 'docker compose up -d payments'
  run 'MAX_IN_FLIGHT=8 docker compose up -d app'
  sleep 4
  run "$LOAD -c 128 -d 20"
  run "$LOAD -c 128 -d 20 --polite"
}

captures "$@"
docker compose down >/dev/null 2>&1
