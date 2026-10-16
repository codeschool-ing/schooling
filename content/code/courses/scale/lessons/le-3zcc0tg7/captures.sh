#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of scale. Each block of output
# starts with `##### <name>`; the prose quotes the blocks byte for byte.
#
#   bash captures.sh [block ...] > captures.out   (as root, after lab.sh prepare)
#
# STAGED rather than typed:
#   - ~/tickets is written by `lab.sh stage 11`;
#   - after `docker compose up -d` of the whole stack the script waits 10 s,
#     not shown, for Jaeger and the replica; after starting or recreating
#     one service it waits 4 s;
#   - trace ids, hosts and timings differ on every run.
# Recorded 2026-10-10 on the machine lab.sh describes.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/lib.sh"
bash "$LAB" stage 11 || exit 1
cd "$HOME/tickets"

GET='curl -s localhost:8080/events/1; echo'

cap_up() {
  run 'docker compose build -q'
  run 'docker compose up -d'
  sleep 10
  run 'docker compose ps --format "table {{.Service}}\t{{.Status}}"'
}

cap_replica_down() {
  run "$GET"
  run 'docker compose stop replica'
  run "$GET"
  run "docker compose logs app --no-log-prefix | grep 'fell back' | tail -1"
}

cap_no_database() {
  run 'docker compose stop db'
  run 'sleep 5'
  run "$GET"
  run 'curl -s localhost:8080/events/2; echo'
  run "curl -s -X POST localhost:8080/events/1/tickets; echo"
}

cap_back() {
  run 'docker compose start db replica'
  sleep 6
  run "$GET"
  run "$GET"
}

cap_redis_down() {
  run 'docker compose stop redis'
  run "curl -s -X POST -H 'X-Buyer: fan-1' localhost:8080/events/1/tickets; echo"
  run "docker compose logs app --no-log-prefix | grep 'rate limit unavailable' | tail -1"
  run 'docker compose start redis'
}

cap_payments_down() {
  run 'docker compose stop payments'
  run "for i in \$(seq 6); do curl -s -w ' %{http_code}\n' -X POST -H \"X-Buyer: fan-\$i\" localhost:8080/events/1/tickets; done"
  run "curl -s -w ' %{http_code} in %{time_total} s\n' localhost:8080/events/1"
  run 'docker compose start payments'
}

cap_sold_out() {
  run "docker compose exec db psql -U tickets -c 'UPDATE events SET sold = capacity WHERE id = 7'"
  run 'curl -s localhost:8001/charges; echo'
  run "curl -s -X POST -H 'X-Buyer: fan-20' localhost:8080/events/7/tickets; echo"
  run 'curl -s localhost:8001/charges; echo'
}

cap_queueing() {
  run 'python3 queueing.py'
}

cap_capacity() {
  shown 'export BUYER_RATE=100000 BUYER_BURST=100000'
  export BUYER_RATE=100000 BUYER_BURST=100000
  run 'docker compose up -d app'
  sleep 4
  run "python3 load.py 'http://localhost:8080/events/{event}' --events 50 -c 16 -d 10"
  run "python3 load.py -m POST 'http://localhost:8080/events/{event}/tickets' --events 50 -c 16 -d 10"
}

captures "$@"
docker compose down >/dev/null 2>&1
