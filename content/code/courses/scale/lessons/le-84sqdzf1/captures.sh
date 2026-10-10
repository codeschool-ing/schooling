#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of scale. Each block of output
# starts with `##### <name>`; the prose quotes the blocks byte for byte.
#
#   bash captures.sh [block ...] > captures.out   (as root, after lab.sh prepare)
#
# STAGED rather than typed:
#   - ~/tickets is written by `lab.sh stage 8`; the images
#     otel/opentelemetry-collector:0.162.0 and jaegertracing/jaeger:2.22.0
#     were pulled from mirror.gcr.io and tagged;
#   - after `docker compose up -d` the script waits 10 s, not shown, for
#     Jaeger to accept spans;
#   - trace ids are random, so every run prints different ones; the one
#     traceparent typed by hand, in "outside", is the example from the W3C
#     Trace Context specification.
# Recorded 2026-10-10 on the machine lab.sh describes.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/lib.sh"
bash "$LAB" stage 8 || exit 1
cd "$HOME/tickets"

cap_up() {
  run 'docker compose build -q'
  run 'docker compose up -d'
  sleep 10
  run 'docker compose ps --format "table {{.Service}}\t{{.Status}}"'
}

cap_first_trace() {
  run 'curl -s -X POST localhost:8080/events/1/tickets; echo'
  run 'sleep 7'
  run 'python3 trace.py'
}

cap_read_trace() {
  run 'curl -s localhost:8080/events/1; echo'
  run 'sleep 7'
  run "python3 trace.py 'GET /events/{id}'"
}

cap_collector() {
  run "docker compose logs collector --no-log-prefix | grep 'Traces' | tail -2"
}

cap_header() {
  run 'curl -s -X POST localhost:8080/events/2/tickets; echo'
  sleep 1
  run 'docker compose logs payments --no-log-prefix | tail -1'
  run "docker compose logs app --no-log-prefix | grep '\"POST\"' | tail -1"
}

cap_outside() {
  run "curl -s -X POST -H 'traceparent: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01' localhost:8080/events/3/tickets; echo"
  run 'sleep 7'
  run 'python3 trace.py'
}

cap_sampling_all() {
  run 'docker compose restart jaeger'
  sleep 3
  run 'for i in $(seq 200); do curl -s localhost:8080/events/1 >/dev/null; done'
  run 'sleep 7'
  run "python3 trace.py --count 'GET /events/{id}'"
}

cap_sampling_ratio() {
  run 'SAMPLER=parentbased_traceidratio SAMPLER_ARG=0.1 docker compose up -d app'
  run 'docker compose restart jaeger'
  sleep 3
  run 'for i in $(seq 200); do curl -s localhost:8080/events/1 >/dev/null; done'
  run 'sleep 7'
  run "python3 trace.py --count 'GET /events/{id}'"
}

captures "$@"
docker compose down >/dev/null 2>&1
