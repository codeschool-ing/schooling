#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of scale. Each block of output
# starts with `##### <name>`; the prose quotes the blocks byte for byte.
#
#   bash captures.sh [block ...] > captures.out   (as root, after lab.sh prepare)
#
# STAGED rather than typed:
#   - "overload" runs on ~/tickets as section 02 leaves it, which is lesson
#     8's box office, written by `lab.sh stage 9 more-than-it-can-do`; every
#     later block runs on `lab.sh stage 9`. The image redis:7.4.11 was pulled
#     from mirror.gcr.io and tagged;
#   - after each `docker compose up -d` of the whole stack the script waits
#     10 s, not shown, for Jaeger and the replica; after recreating one
#     service it waits 4 s;
#   - trace ids are random, so every run prints different ones.
# Recorded 2026-10-10 on the machine lab.sh describes.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/lib.sh"

LOAD="python3 load.py -m POST -d 10 'http://localhost:8080/events/{event}/tickets' --events 50"
SALE="curl -s -w ' %{http_code} in %{time_total} s\n' -X POST"

cap_overload() {
  bash "$LAB" stage 9 more-than-it-can-do || exit 1
  cd "$HOME/tickets"
  docker compose build -q >/dev/null 2>&1
  docker compose up -d >/dev/null 2>&1
  sleep 10
  run "$LOAD -c 8"
  run "$LOAD -c 32"
  run "$LOAD -c 128"
  run "docker compose logs app --no-log-prefix | grep -m1 '\"error\"'"
  run "docker compose exec db psql -U tickets -tAc \"SELECT count(*) FROM pg_stat_activity WHERE backend_type = 'client backend'\""
}

cap_up() {
  bash "$LAB" stage 9 || exit 1
  cd "$HOME/tickets"
  run 'docker compose build -q'
  run 'docker compose up -d'
  sleep 10
  run 'docker compose ps --format "table {{.Service}}\t{{.Status}}"'
}

cap_bucket() {
  run 'python3 attempts.py bot-7'
  run 'python3 attempts.py fan-12 -d 2'
}

cap_copies() {
  run 'docker compose up -d --scale app=3'
  run 'docker compose restart lb'
  sleep 4
  run 'python3 attempts.py bot-9'
}

cap_shed() {
  run 'docker compose up -d --scale app=1'
  run 'docker compose restart lb'
  sleep 2
  run 'BUYER_RATE=1000 BUYER_BURST=1000 docker compose up -d app'
  sleep 4
  run "$LOAD -c 128"
  run "docker compose exec db psql -U tickets -tAc \"SELECT count(*) FROM pg_stat_activity WHERE backend_type = 'client backend'\""
}

cap_timeout() {
  run 'docker compose up -d app'
  run 'PAYMENTS_DELAY_MS=5000 docker compose up -d payments'
  sleep 4
  run "$SALE -H 'X-Buyer: fan-1' localhost:8080/events/1/tickets"
  run 'sleep 12'
  run 'python3 trace.py'
}

cap_breaker() {
  run "for i in \$(seq 2 9); do $SALE -H \"X-Buyer: fan-\$i\" localhost:8080/events/1/tickets; done"
  run 'curl -s localhost:8080/metrics | grep ^tickets_breaker'
}

cap_half_open() {
  run 'sleep 10'
  run "$SALE -H 'X-Buyer: fan-10' localhost:8080/events/1/tickets"
  run "$SALE -H 'X-Buyer: fan-11' localhost:8080/events/1/tickets"
  run 'docker compose up -d payments'
  run 'sleep 10'
  run "$SALE -H 'X-Buyer: fan-12' localhost:8080/events/1/tickets"
  run "$SALE -H 'X-Buyer: fan-13' localhost:8080/events/1/tickets"
  run 'curl -s localhost:8080/metrics | grep ^tickets_breaker'
}

captures "$@"
docker compose down >/dev/null 2>&1
