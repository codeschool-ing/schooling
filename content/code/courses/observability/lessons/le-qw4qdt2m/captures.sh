#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of observability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by `lab.sh reset`; checkout.json (lesson 1); scratch/bench.py
# and compose.override.yaml, whose contents the lesson shows; and the copies of
# orders/app.py taken before each edit and put back after it. Trace ids, times
# and dates differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-/var/tmp/lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@obs:~/shop$ %s\n' "$*"; lab as "$*" 2>&1 || true; }
quiet() { lab as "$*" >/dev/null 2>&1 || true; }
put() { lab put "$1"; }
block() { printf '##### %s\n' "$1"; }
checkout() { quiet "curl -s -X POST localhost:8080/checkout -H 'Content-Type: application/json' -d @checkout.json"; }
last_trace() { lab as "docker compose logs --no-log-prefix ${1:-storefront} | grep '${2:-checkout finished}' | tail -1 | jq -r .trace_id"; }

lab reset
put checkout.json <<'JSON'
{"sku": "kettle", "qty": 1, "card": "4111 1111 1111 1111"}
JSON
put scratch/bench.py <<'PY'
import statistics
import time

import requests

times = []
for n in range(300):
    start = time.perf_counter()
    requests.post("http://orders:8081/orders", timeout=5,
                  json={"sku": "tea-500g", "qty": 1, "total_cents": 3450, "card": "4111 1111 1111 1111"})
    times.append((time.perf_counter() - start) * 1000)
print(f"300 orders: median {statistics.median(times):.1f} ms, mean {statistics.mean(times):.1f} ms")
PY

block how
on "grep -A3 '^  orders:' compose.yaml"
on "docker compose exec orders pip list 2>/dev/null | grep -i opentelemetry-instrumentation"
on "docker compose exec orders env | grep ^OTEL_ | sort"

block spans
checkout
sleep 8
TRACE=$(last_trace)
on "curl -s localhost:16686/api/traces/$TRACE | jq -r '.data[0] as \$t | \$t.spans | sort_by(.startTime) | .[] | select(\$t.processes[.processID].serviceName == \"orders\") | [.operationName, (.tags[] | select(.key == \"span.kind\") | .value)] | @tsv'"
on "curl -s localhost:16686/api/traces/$TRACE | jq -c '.data[0].spans[] | select(.operationName == \"INSERT\") | [.tags[] | select(.key | test(\"^(db|server|net)\")) | {(.key): .value}] | add'"
on "curl -s localhost:16686/api/traces/$TRACE | jq -c '.data[0].spans[] | select(.operationName == \"POST\") | [.tags[] | select(.key | test(\"^(http|url|server)\")) | {(.key): .value}] | add'"

block excluded
on "docker compose exec orders python -c 'import urllib.request as u; print([u.urlopen(\"http://localhost:8081/health\").status for i in range(3)])'"
sleep 8
on "curl -s 'localhost:16686/api/v3/operations?service=orders' | jq -r '.operations[].name' | sort"

block disabled
on "cp compose.yaml compose.yaml.orig"
on "sed -i 's/      OTEL_PYTHON_FLASK_EXCLUDED_URLS: health,metrics/&\n      OTEL_PYTHON_DISABLED_INSTRUMENTATIONS: psycopg/' compose.yaml"
on "docker compose up -d orders 2>&1 | tail -1"
sleep 5
checkout
sleep 8
TRACE=$(last_trace)
on "curl -s localhost:16686/api/traces/$TRACE | jq -r '.data[0] as \$t | \$t.spans | sort_by(.startTime) | .[] | select(\$t.processes[.processID].serviceName == \"orders\") | .operationName'"
on "mv compose.yaml.orig compose.yaml && docker compose up -d orders 2>&1 | tail -1"
sleep 5

block no-business
on "curl -s localhost:16686/api/traces/$TRACE | jq -r '[.data[0].spans[] | select(.operationName == \"POST /orders\") | .tags[].key] | join(\" \")'"

block queue
quiet "cp services/orders/app.py /tmp/orders.app.py"
on "grep -n 'propagate' services/orders/app.py"
on "sed -i '/propagate.inject(headers)/d' services/orders/app.py && docker compose restart orders 2>&1 | tail -1"
sleep 5
checkout
sleep 8
on "docker compose logs --no-log-prefix storefront | grep 'checkout finished' | tail -1 | jq -r '.trace_id'"
on "docker compose logs --no-log-prefix mailer | grep 'confirmation sent' | tail -1 | jq -r '.trace_id'"
MT=$(last_trace mailer 'confirmation sent')
on "curl -s localhost:16686/api/traces/$MT | jq -r '.data[0] as \$t | \$t.spans[] | [\$t.processes[.processID].serviceName, .operationName, (.references | length | tostring) + \" parent\"] | @tsv'"
quiet "cp /tmp/orders.app.py services/orders/app.py && docker compose restart orders"
sleep 5

block mixing
quiet "cp services/orders/app.py /tmp/orders.app.py"
on "sed -i 's/^    traceparent = request.headers.get(\"traceparent\")/&\n    trace.get_current_span().set_attribute(\"shop.sku\", body[\"sku\"])/; s/^from opentelemetry import propagate/from opentelemetry import propagate, trace/' services/orders/app.py"
on "grep -n 'trace' services/orders/app.py | head -4"
on "docker compose restart orders 2>&1 | tail -1"
sleep 5
checkout
sleep 8
TRACE=$(last_trace)
on "curl -s localhost:16686/api/traces/$TRACE | jq -c '.data[0].spans[] | select(.operationName == \"POST /orders\") | [.tags[] | select(.key | test(\"^(shop|http.route)\")) | {(.key): .value}] | add'"
quiet "cp /tmp/orders.app.py services/orders/app.py && docker compose restart orders"
sleep 5

block overhead
on "docker compose run --rm sandbox python bench.py 2>/dev/null"
put compose.override.yaml <<'YAML'
services:
  orders:
    command: waitress-serve --port 8081 --threads 16 orders.app:app
YAML
on "cat compose.override.yaml"
on "docker compose up -d orders 2>&1 | tail -1"
sleep 5
on "docker compose run --rm sandbox python bench.py 2>/dev/null"
on "rm compose.override.yaml && docker compose up -d orders 2>&1 | tail -1"
