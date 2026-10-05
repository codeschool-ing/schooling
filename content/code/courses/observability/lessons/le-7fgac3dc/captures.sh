#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of observability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by `lab.sh reset`; checkout.json, whose content the lesson
# shows; and one minute of simulated customers (`docker compose run loadgen`),
# run while payments is slowed down, so that the metric and the logs have more
# than one request in them. Trace ids, times and dates differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-/var/tmp/lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@obs:~/shop$ %s\n' "$*"; lab as "$*" 2>&1 || true; }
quiet() { lab as "$*" >/dev/null 2>&1 || true; }
put() { lab as "cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }

lab reset

block the-stack
on "docker compose ps --format 'table {{.Service}}\t{{.Image}}' | sort"

put checkout.json <<'JSON'
{"sku": "kettle", "qty": 1, "card": "4111 1111 1111 1111"}
JSON

block healthy
on "curl -s -X POST localhost:8080/checkout -H 'Content-Type: application/json' -d @checkout.json"
on "curl -s -o /dev/null -w '%{http_code} in %{time_total} s\n' -X POST localhost:8080/checkout -H 'Content-Type: application/json' -d @checkout.json"

block slow
on "echo '{\"latency_ms\": 1500}' > faults/payments.json"
on "curl -s -o /dev/null -w '%{http_code} in %{time_total} s\n' -X POST localhost:8080/checkout -H 'Content-Type: application/json' -d @checkout.json"
quiet "docker compose run --rm loadgen python -m loadgen.load 2 60"
sleep 20

block metrics
on "curl -s localhost:8080/metrics | grep -E '^http_server_request_duration_seconds_(bucket|count|sum)\{.*route=\"/checkout\"' | grep -E 'le=\"(0.1|0.5|1.0|2.5|\+Inf)\"|_count|_sum'"
on "curl -s localhost:9090/api/v1/query --data-urlencode 'query=histogram_quantile(0.99, sum by (le) (rate(http_server_request_duration_seconds_bucket{job=\"storefront\",route=\"/checkout\"}[2m])))' | jq -r '.data.result[0].value[1]'"

block logs
on "docker compose logs --no-log-prefix storefront | grep checkout | tail -1 | jq ."
TRACE=$(lab as "docker compose logs --no-log-prefix storefront | grep checkout | tail -1 | jq -r .trace_id")
on "docker compose logs --no-log-prefix payments orders | grep $TRACE | jq -c '{service, message, order_id}'"

block traces
sleep 5
on "curl -s localhost:16686/api/traces/$TRACE | jq -r '.data[0] as \$t | (\$t.spans | map(.startTime) | min) as \$t0 | \$t.spans | sort_by(.startTime) | .[] | [\$t.processes[.processID].serviceName, .operationName, \"at \" + ((.startTime - \$t0)/1000|floor|tostring) + \" ms\", \"took \" + (.duration/1000|floor|tostring) + \" ms\"] | @tsv'"

block loki
on "curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service_name=\"payments\"} |= \"$TRACE\"' | jq -r '.data.result[].values[][1]' | jq -c '{level, message, order_id}'"

quiet "rm faults/payments.json"
