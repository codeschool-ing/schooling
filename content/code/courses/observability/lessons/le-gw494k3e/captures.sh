#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of observability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by `lab.sh reset`; checkout.json (lesson 1); scratch/baggage.py,
# whose content the lesson shows; twenty checkouts sent before the report runs,
# so that it has orders to link to; and the copy of payments/app.py taken
# before the edit and put back after it. Trace ids, times and dates differ on
# every run.
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
put scratch/baggage.py <<'PY'
from opentelemetry import baggage, context, propagate, trace
from opentelemetry.sdk.trace import TracerProvider

trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer("baggage")

ctx = baggage.set_baggage("shop.channel", "mobile-app")
token = context.attach(ctx)
with tracer.start_as_current_span("checkout"):
    headers = {}
    propagate.inject(headers)
    for name, value in headers.items():
        print(f"{name}: {value}")
context.detach(token)
PY

block traceparent
checkout
sleep 8
on "docker compose exec postgres psql -U shop -tAc 'SELECT id, traceparent FROM orders ORDER BY id DESC LIMIT 1'"
TRACE=$(last_trace)
on "curl -s localhost:16686/api/traces/$TRACE | jq -r '.data[0] as \$t | \$t.spans | sort_by(.startTime) | .[:3][] | [\$t.processes[.processID].serviceName, .operationName, .spanID] | @tsv'"
on "docker compose exec orders env | grep OTEL_PROPAGATORS || echo 'OTEL_PROPAGATORS not set'"

block missing-extract
quiet "cp services/payments/app.py /tmp/payments.app.py"
on "grep -n 'context=ctx' services/payments/app.py"
on "sed -i 's/, context=ctx, kind=SpanKind.SERVER/, kind=SpanKind.SERVER/' services/payments/app.py && docker compose restart payments 2>&1 | tail -1"
sleep 4
checkout
sleep 8
on "docker compose logs --no-log-prefix storefront | grep 'checkout finished' | tail -1 | jq -r .trace_id"
on "docker compose logs --no-log-prefix payments | grep 'charge decided' | tail -1 | jq -r .trace_id"
TRACE=$(last_trace)
on "curl -s localhost:16686/api/traces/$TRACE | jq -r '.data[0] as \$t | \$t.spans | sort_by(.startTime) | .[] | [\$t.processes[.processID].serviceName, .operationName] | @tsv'"
quiet "cp /tmp/payments.app.py services/payments/app.py && docker compose restart payments"
sleep 4

block queue
on "docker compose stop mailer"
checkout
sleep 2
on "curl -s -u guest:guest -H 'Content-Type: application/json' -X POST localhost:15672/api/queues/%2F/orders.placed/get -d '{\"count\": 1, \"ackmode\": \"ack_requeue_true\", \"encoding\": \"auto\"}' | jq '.[0] | {payload, headers: .properties.headers}'"
sleep 20
on "docker compose start mailer"
sleep 10
TRACE=$(last_trace)
on "curl -s localhost:16686/api/traces/$TRACE | jq -r '.data[0] as \$t | (\$t.spans | map(.startTime) | min) as \$t0 | \$t.spans | sort_by(.startTime) | .[] | [\$t.processes[.processID].serviceName, .operationName, \"at \" + ((.startTime - \$t0)/1000000*10|floor/10|tostring) + \" s\"] | @tsv'"

block report
for i in $(seq 1 19); do checkout; done
sleep 8
sleep 8
OUT=$(on "docker compose run --rm report 2>&1 | grep -v Container | jq -c '{message, orders, paid, trace_id}'")
echo "$OUT"
RT=$(echo "$OUT" | grep -o '"trace_id":"[0-9a-f]*"' | cut -d'"' -f4)
sleep 8
on "curl -s localhost:16686/api/traces/$RT | jq -c '.data[0].spans[] | {operationName, references: (.references | length), refType: (.references | map(.refType) | unique)}'"
on "curl -s localhost:16686/api/traces/$RT | jq -r '.data[0].spans[0].references[:3][].traceID'"
on "docker compose exec postgres psql -U shop -tAc 'SELECT id, split_part(traceparent, chr(45), 2) FROM orders ORDER BY id LIMIT 3'"

block baggage
on "docker compose run --rm sandbox python baggage.py 2>/dev/null"
