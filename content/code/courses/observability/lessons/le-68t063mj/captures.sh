#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of observability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by `lab.sh reset`; the promq helper from lesson 5; flags.py and
# the three versions of compose.override.yaml, whose contents the lesson shows;
# simulated customers, five requests a second, started in the background; and,
# from the tail block on, payments told to add 1500 ms to every twenty-fifth
# charge and to fail every fortieth. Ids, times, counts and dates differ on
# every run, and the sampled counts differ by chance as well.
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

# For each of the last ten checkouts in the storefront's log that are old enough
# to have been exported: how many spans
# Jaeger holds for its trace, and the top span: the one whose parent is not in
# the trace.
LOOKUP='for t in $(docker compose logs --no-log-prefix --since 40s --until 15s storefront | grep "checkout finished" | jq -r .trace_id | tail -10); do printf "%s  " $t; curl -s localhost:16686/api/traces/$t | jq -r '"'"'if .data then (.data[0] as $d | ($d.spans | map(.spanID)) as $ids | $d.spans | "\(length) spans, top: " + (map(select(.references == [] or (.references[0].spanID | IN($ids[]) | not))) | map($d.processes[.processID].serviceName + " " + .operationName) | join(", "))) else .errors[0].msg end'"'"'; done'

lab reset
put promq <<'SH'
#!/bin/sh
# promq 'EXPRESSION': ask Prometheus for the value of an expression, now.
curl -sG localhost:9090/api/v1/query --data-urlencode "query=$1" |
  jq -r '.data.result[] | (.metric | to_entries | map("\(.key)=\(.value)") | join(" ")) + "  " + .value[1]'
SH
quiet "chmod +x promq"
put scratch/flags.py <<'PY'
"""Eight checkouts under a sampler that keeps half of all traces."""
from opentelemetry import propagate, trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.sampling import ParentBased, TraceIdRatioBased

trace.set_tracer_provider(TracerProvider(sampler=ParentBased(TraceIdRatioBased(0.5))))
tracer = trace.get_tracer("flags")

for _ in range(8):
    with tracer.start_as_current_span("POST /checkout") as span:
        headers = {}
        propagate.inject(headers)
        print(headers["traceparent"], "recorded" if span.is_recording() else "dropped")
PY
quiet "docker compose run -d --rm loadgen python -m loadgen.load 5 1800"
sleep 90

block cost
on "./promq 'sum(rate(http_server_requests_total{job=\"storefront\",route=\"/checkout\"}[1m]))'"
on "./promq 'sum(rate(otelcol_receiver_accepted_spans[1m]))'"

block flags
on "docker compose run --rm sandbox python flags.py"

block head
put compose.override.yaml <<'YAML'
services:
  storefront:
    environment:
      OTEL_TRACES_SAMPLER: parentbased_traceidratio
      OTEL_TRACES_SAMPLER_ARG: "0.1"
YAML
quiet "docker compose up -d storefront"
sleep 75
on "cat compose.override.yaml"
on "./promq 'sum(rate(otelcol_receiver_accepted_spans[1m]))'"
on "$LOOKUP"

block ignore
put compose.override.yaml <<'YAML'
services:
  storefront:
    environment:
      OTEL_TRACES_SAMPLER: parentbased_traceidratio
      OTEL_TRACES_SAMPLER_ARG: "0.1"
  orders:
    environment:
      OTEL_TRACES_SAMPLER: always_on
YAML
quiet "docker compose up -d orders"
sleep 45
on "$LOOKUP"

block tail
put compose.override.yaml <<'YAML'
services:
  otel-collector:
    volumes: ["./otel/collector-sampling.yaml:/etc/otelcol/config.yaml:ro"]
  prometheus:
    command: [--config.file=/etc/prometheus/prometheus.yml, --web.enable-lifecycle,
              --storage.tsdb.path=/prometheus, --enable-feature=exemplar-storage,
              --web.enable-otlp-receiver]
YAML
quiet "echo '{\"latency_ms\": 50, \"slow_every\": 25, \"slow_ms\": 1500, \"fail_every\": 40}' > faults/payments.json"
quiet "docker compose up -d storefront orders otel-collector prometheus"
sleep 150
on "sed -n '/^  tail_sampling:/,/^  memory_limiter:/p' otel/collector-sampling.yaml"
on "./promq 'sum by (policy) (increase(otelcol_processor_tail_sampling_count_traces_sampled{decision=\"sampled\"}[2m]))'"
on "./promq 'sum by (decision) (increase(otelcol_processor_tail_sampling_global_count_traces_sampled[2m]))'"
on "./promq 'sum(rate(otelcol_receiver_accepted_spans[1m]))'"
on "./promq 'sum(rate(otelcol_exporter_sent_spans{exporter=\"zipkin\"}[1m]))'"

block memory
on "./promq 'otelcol_processor_tail_sampling_sampling_traces_on_memory'"

block spanmetrics
on "sed -n '/^connectors:/,/^processors:/p' otel/collector-sampling.yaml"
on "./promq 'sum by (span_name, status_code) (rate(traces_span_metrics_calls_total{service_name=\"storefront\"}[1m]))'"
on "./promq 'sum by (code) (rate(http_server_requests_total{job=\"storefront\",route=\"/checkout\"}[1m]))'"
on "./promq 'histogram_quantile(0.99, sum by (le) (rate(traces_span_metrics_duration_milliseconds_bucket{service_name=\"storefront\",span_name=\"POST /checkout\"}[2m])))'"

block broken
for t in $(lab as "curl -sG localhost:9090/api/v1/query_exemplars --data-urlencode 'query=http_server_request_duration_seconds_bucket{job=\"orders\",route=\"/orders\"}' --data-urlencode start=\$(date -d '-2 min' +%s) --data-urlencode end=\$(date -d '-30 sec' +%s) | jq -r '.data[].exemplars[].labels.trace_id' | head -4"); do
  on "curl -s localhost:16686/api/traces/$t | jq -r 'if .data then \"\(.data[0].spans | length) spans\" else .errors[0].msg end'"
done
quiet "rm faults/payments.json compose.override.yaml && docker compose up -d storefront orders otel-collector prometheus"
