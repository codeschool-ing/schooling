#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of observability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by `lab.sh reset`; selftime.jq and compose.override.yaml, whose
# contents the lesson shows; payments slowed by 400 ms for the whole session;
# simulated customers, five requests a second, started in the background; the
# mailer stopped for thirty seconds while they kept buying; and every tenth
# charge failing for a minute before the errors block. Ids, times and dates
# differ on every run.
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
put selftime.jq <<'JQ'
# One line per span of a Jaeger trace: service, name, duration, and self time,
# the part of the duration not spent waiting for a child span.
.data[0] as $t
| ($t.spans | map({key: .spanID, value: 0}) | from_entries) as $zero
| (reduce ($t.spans[] | select(.references | length > 0) | {p: .references[0].spanID, d: .duration})
     as $c ($zero; .[$c.p] += $c.d)) as $children
| $t.spans | sort_by(.startTime) | .[]
| [$t.processes[.processID].serviceName, .operationName,
   "\(.duration / 1000 | floor) ms", "self \((.duration - $children[.spanID]) / 1000 | floor) ms"]
| @tsv
JQ
put compose.override.yaml <<'YAML'
services:
  prometheus:
    command: [--config.file=/etc/prometheus/prometheus.yml, --web.enable-lifecycle,
              --storage.tsdb.path=/prometheus, --enable-feature=exemplar-storage]
YAML
quiet "echo '{\"latency_ms\": 400}' > faults/payments.json"
quiet "docker compose up -d prometheus"
quiet "docker compose run -d --rm loadgen python -m loadgen.load 5 1500"
sleep 90

block read
TRACE=$(lab as "docker compose logs --no-log-prefix storefront | grep 'checkout finished' | tail -1 | jq -r .trace_id")
on "curl -s localhost:16686/api/traces/$TRACE | jq -r -f selftime.jq"

block jaeger
START=$(date -u -d '-3 min' +%Y-%m-%dT%H:%M:%SZ); END=$(date -u +%Y-%m-%dT%H:%M:%SZ)
on "curl -sG localhost:16686/api/v3/traces --data-urlencode query.service_name=storefront --data-urlencode 'query.operation_name=POST /checkout' --data-urlencode query.duration_min=400ms --data-urlencode query.start_time_min=$START --data-urlencode query.start_time_max=$END --data-urlencode query.search_depth=5 | jq -r '[.result.resourceSpans[].scopeSpans[].spans[] | select(.name == \"POST /checkout\")] | .[] | [.traceId, ((.endTimeUnixNano | tonumber) - (.startTimeUnixNano | tonumber)) / 1e6 | floor] | @tsv'"

block zipkin
on "curl -s localhost:9411/api/v2/trace/$TRACE | jq -r 'sort_by(.timestamp) | .[] | [.localEndpoint.serviceName, .kind // \"-\", .name, \"\(.duration / 1000 | floor) ms\"] | @tsv'"
on "curl -sG localhost:9411/api/v2/dependencies --data-urlencode endTs=\$(date +%s000) --data-urlencode lookback=300000 | jq -r '.[] | [.parent, .child, .callCount, (.errorCount // 0)] | @tsv'"

block queue
on "docker compose stop mailer 2>&1 | tail -1"
sleep 30
on "docker compose start mailer 2>&1 | tail -1"
sleep 20
for t in $(lab as "docker compose logs --no-log-prefix --since 60s mailer | grep 'confirmation sent' | jq -r .trace_id | awk 'NR % 30 == 1' | head -5"); do
  on "curl -s localhost:16686/api/traces/$t | jq -r '.data[0].spans as \$s | (\$s[] | select(.operationName == \"POST /orders\") | .startTime + .duration) as \$published | (\$s[] | select(.operationName == \"orders.placed process\") | .startTime) as \$taken | \"waited in the queue: \((\$taken - \$published) / 1000 | floor) ms\"'"
done

block errors
quiet "echo '{\"latency_ms\": 400, \"fail_every\": 10}' > faults/payments.json"
sleep 60
quiet "echo '{\"latency_ms\": 400}' > faults/payments.json"
sleep 10
on "curl -sG localhost:9411/api/v2/traces --data-urlencode serviceName=payments --data-urlencode annotationQuery=error --data-urlencode lookback=120000 --data-urlencode limit=3 | jq -r '.[] | .[] | select(.tags.error) | [.traceId, .localEndpoint.serviceName, .name, .tags.error] | @tsv'"

block exemplars
on "cat compose.override.yaml"
on "curl -s -H 'Accept: application/openmetrics-text' localhost:8080/metrics | grep -m2 'duration_seconds_bucket{.*checkout.* # '"
on "curl -sG localhost:9090/api/v1/query_exemplars --data-urlencode 'query=http_server_request_duration_seconds_bucket{job=\"storefront\",route=\"/checkout\"}' --data-urlencode start=\$(date -d '-2 min' +%s) --data-urlencode end=\$(date +%s) | jq -r '.data[].exemplars[:3][] | [.labels.trace_id, .value] | @tsv'"
EX=$(lab as "curl -sG localhost:9090/api/v1/query_exemplars --data-urlencode 'query=http_server_request_duration_seconds_bucket{job=\"storefront\",route=\"/checkout\"}' --data-urlencode start=\$(date -d '-2 min' +%s) --data-urlencode end=\$(date +%s) | jq -r '.data[0].exemplars[0].labels.trace_id'")
on "curl -s localhost:16686/api/traces/$EX | jq -r -f selftime.jq | head -3"
quiet "rm faults/payments.json compose.override.yaml && docker compose up -d prometheus"
