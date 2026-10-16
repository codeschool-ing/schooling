#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of scale. Each block of output
# starts with `##### <name>`; the prose quotes the blocks byte for byte.
#
#   bash captures.sh [block ...] > captures.out   (as root, after lab.sh prepare)
#
# STAGED rather than typed:
#   - ~/tickets is written by `lab.sh stage 7`, so app.py, compose.yaml,
#     prometheus.yml and requirements.txt are the ones the lesson shows;
#     prom/prometheus:v3.15.0 was pulled from mirror.gcr.io and tagged;
#   - "rates" runs two load generators in the background for 40 s, a sale
#     load and a read load, and asks Prometheus its questions 30 s in; the
#     generators' own output is printed after, as blocks "rates-sales" and
#     "rates-reads";
#   - the waits that let Prometheus discover the copies and take a few
#     scrapes (15 s after scaling, 10 s before "buckets") are not shown, nor the 3 s after the
#     first `up` while the box office starts.
# Recorded 2026-10-10 on the machine lab.sh describes.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/lib.sh"
bash "$LAB" stage 7 || exit 1
cd "$HOME/tickets"
T=$(mktemp -d)
PQ="docker compose exec prometheus promtool query instant http://localhost:9090"

cap_up() {
  run 'docker compose build -q'
  run 'docker compose up -d'
  sleep 3
}

cap_metrics_first() {
  run 'curl -s localhost:8080/events/1 >/dev/null; curl -s -X POST localhost:8080/events/1/tickets >/dev/null'
  run "curl -s localhost:8080/metrics | grep '^tickets_'"
}

cap_scale() {
  run 'docker compose up -d --scale app=3'
  run 'docker compose restart lb'
}

cap_targets() {
  sleep 15
  run "$PQ 'up'"
}

cap_rates() {
  python3 load.py -m POST -c 16 -d 40 --events 100 'http://localhost:8080/events/{event}/tickets' > "$T/s" 2>&1 &
  python3 load.py -c 4 -d 40 --events 100 'http://localhost:8080/events/{event}' > "$T/r" 2>&1 &
  sleep 30
  run "$PQ 'sum by (route, status) (rate(tickets_requests_total[30s]))'"
  run "$PQ 'sum(tickets_in_flight)'"
  run "$PQ 'rate(process_cpu_seconds_total[30s])'"
  run "$PQ 'histogram_quantile(0.95, sum by (le, route) (rate(tickets_request_seconds_bucket[30s])))'"
  wait
  printf '##### rates-sales\n'
  printf 'ana@lab:~/tickets$ %s\n' "python3 load.py -m POST -c 16 -d 40 --events 100 'http://localhost:8080/events/{event}/tickets'"; cat "$T/s"
  printf '##### rates-reads\n'
  printf 'ana@lab:~/tickets$ %s\n' "python3 load.py -c 4 -d 40 --events 100 'http://localhost:8080/events/{event}'"; cat "$T/r"
}

cap_buckets() {
  sleep 10
  run "$PQ 'sum by (le) (tickets_request_seconds_bucket{route=\"/events/{id}/tickets\"})'"
}

cap_logs() {
  run 'docker compose logs app --no-log-prefix | tail -3'
}

cap_error() {
  run 'docker compose stop replica'
  run 'curl -s localhost:8080/events/1; echo'
  run "docker compose logs app --no-log-prefix | grep '\"level\": \"error\"' | tail -1"
  sleep 6
  run "$PQ 'sum by (route, status) (tickets_requests_total{status=\"500\"})'"
  run 'docker compose start replica'
}

cap_cardinality() {
  run "$PQ 'count by (__name__) ({__name__=~\"tickets_.*\"})'"
}

cap_slo() {
  python3 load.py -m POST -c 16 -d 35 --events 100 'http://localhost:8080/events/{event}/tickets' > /dev/null 2>&1 &
  sleep 31
  run "$PQ 'sum(rate(tickets_request_seconds_bucket{route=\"/events/{id}/tickets\", le=\"0.25\"}[30s])) / sum(rate(tickets_request_seconds_count{route=\"/events/{id}/tickets\"}[30s]))'"
  wait
}

captures "$@"
docker compose down >/dev/null 2>&1
rm -rf "$T"
