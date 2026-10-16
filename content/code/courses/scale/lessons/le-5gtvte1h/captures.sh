#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of scale. Each block of output
# starts with `##### <name>`; the prose quotes the blocks byte for byte.
#
#   bash captures.sh [block ...] > captures.out   (as root, after lab.sh prepare)
#
# STAGED rather than typed:
#   - ~/tickets is written by `lab.sh stage 12 a-stress-test`, so that
#     nginx.conf is still lesson 1's; "nginx-fixed" then copies in the
#     nginx.conf that section 07 shows, and "plan" the onsale.js of
#     section 08, as a student would save them;
#   - the image grafana/k6:2.3.0 was pulled from mirror.gcr.io and tagged;
#   - after `docker compose up -d` of the whole stack the script waits 10 s,
#     not shown, for Jaeger and the replica; after recreating or restarting
#     a service it waits 4 s;
#   - timings differ on every run, and the stress test's most of all.
# Recorded 2026-10-10 on the machine lab.sh describes.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/lib.sh"
bash "$LAB" stage 12 a-stress-test || exit 1
cd "$HOME/tickets"

SAVED=$(mktemp -d)
python3 "$HERE/../../lab/extract.py" "$HERE/../.." "$SAVED" 12 >/dev/null
K6='docker run --rm -i --network host grafana/k6:2.3.0 run -q --log-output=none'
PAUSE='(sleep 5; docker compose pause app; sleep 2; docker compose unpause app) >/dev/null 2>&1 &'

cap_up() {
  run 'docker compose build -q'
  run 'docker compose up -d'
  sleep 10
  run 'docker compose ps --format "table {{.Service}}\t{{.Status}}"'
}

cap_first() {
  run "$K6 - < sale.js"
}

cap_omission() {
  shown 'export BUYER_RATE=100000 BUYER_BURST=100000'
  export BUYER_RATE=100000 BUYER_BURST=100000
  run 'docker compose up -d app'
  sleep 4
  run "$PAUSE python3 load.py -m POST 'http://localhost:8080/events/{event}/tickets' --events 50 -c 4 -d 15; wait"
  run "$PAUSE $K6 -e DURATION=15s - < sale.js; wait"
}

cap_stress() {
  run "for rate in 100 200 300 400; do $K6 -e RATE=\$rate -e DURATION=15s - < sale.js; echo; done"
  run "docker compose logs lb --no-log-prefix | grep -m1 alert"
}

cap_nginx_fixed() {
  cp "$SAVED/nginx.conf" nginx.conf && chown ana: nginx.conf
  run 'docker compose restart lb'
  sleep 4
  run "$K6 -e RATE=400 -e DURATION=15s - < sale.js"
}

cap_plan() {
  cp "$SAVED/onsale.js" onsale.js && chown ana: onsale.js
  run "$K6 - < onsale.js; echo \"exit code \$?\""
  run 'docker compose up -d --scale app=3'
  run 'docker compose restart lb'
  sleep 4
  run "$K6 - < onsale.js; echo \"exit code \$?\""
}

captures "$@"
docker compose down >/dev/null 2>&1
rm -rf "$SAVED"
