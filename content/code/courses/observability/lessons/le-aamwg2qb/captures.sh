#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of observability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by `lab.sh reset elastic graylog`, including
# ~/shop/.graylog-password; compose.override.yaml, whose content the lesson
# shows; payments failing one charge in twenty from the start; and simulated
# customers, five requests a second, started in the background once the three
# stores are receiving. Counts, ids, times and dates differ on every run.
#
# Needs 16 GB of memory: Elasticsearch, OpenSearch and Graylog are three JVMs.
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-/var/tmp/lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@obs:~/shop$ %s\n' "$*"; lab as "$*" 2>&1 || true; }
quiet() { lab as "$*" >/dev/null 2>&1 || true; }
put() { lab as "cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }

lab reset elastic graylog
put compose.override.yaml <<'YAML'
services:
  otel-collector:
    volumes: ["./otel/collector-logs.yaml:/etc/otelcol/config.yaml:ro"]
YAML
quiet "echo '{\"fail_every\": 20}' > faults/payments.json"
GL="-u admin:\$(cat .graylog-password) -H 'X-Requested-By: ana'"

block ship
on "cat compose.override.yaml"
on "diff otel/collector.yaml otel/collector-logs.yaml"
on "docker compose up -d otel-collector 2>&1 | tail -1"
on "curl -s $GL -H 'Content-Type: application/json' -X POST localhost:9000/api/system/inputs -d '{\"title\": \"shop logs (OTLP)\", \"type\": \"org.graylog.inputs.otel.OTelGrpcInput\", \"global\": true, \"configuration\": {\"bind_address\": \"0.0.0.0\", \"port\": 4317, \"insecure\": true, \"max_inbound_msg_size\": 4194304}}'; echo"
sleep 10
quiet "docker compose run -d --rm loadgen python -m loadgen.load 5 900"
sleep 150

block loki-labels
on "curl -s localhost:3100/loki/api/v1/labels | jq -c .data"
on "curl -s localhost:3100/loki/api/v1/label/service_name/values | jq -c .data"
on "curl -sG localhost:3100/loki/api/v1/series --data-urlencode 'match[]={service_name=~\".+\"}' | jq '.data | length'"

block logql
on "curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service_name=\"payments\"} |= \"card network\"' --data-urlencode limit=2 | jq -r '.data.result[].values[][1]' | jq -c '{level, message, order_id}'"
on "curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service_name=\"payments\"} | json | approved=\"false\"' --data-urlencode limit=2 | jq -r '.data.result[].values[][1]' | jq -c '{message, order_id, approved}'"
on "curl -sG localhost:3100/loki/api/v1/query --data-urlencode 'query=sum by (service_name) (count_over_time({service_name=~\".+\"}[1m]))' | jq -r '.data.result[] | [.metric.service_name, .value[1]] | @tsv'"
on "curl -sG localhost:3100/loki/api/v1/query --data-urlencode 'query=sum by (message) (count_over_time({service_name=\"payments\"} | json [5m]))' | jq -r '.data.result[] | [.metric.message, .value[1]] | @tsv'"

block elastic
on "curl -s 'localhost:9200/_cat/indices/logs-*?h=index,health,docs.count,store.size'"
on "curl -s 'localhost:9200/logs-generic.otel-default/_mapping/field/attributes.order_id,attributes.message' | jq -c '.[].mappings | map_values(.mapping | to_entries[0].value.type)'"
on "curl -s -H 'Content-Type: application/json' localhost:9200/logs-generic.otel-default/_search -d '{\"size\": 2, \"query\": {\"match_phrase\": {\"attributes.message\": \"card network unavailable\"}}, \"_source\": [\"attributes.order_id\", \"attributes.trace_id\", \"resource.attributes.service.name\"]}' | jq -c '.hits.total, (.hits.hits[]._source)'"
on "curl -s -H 'Content-Type: application/json' localhost:9200/logs-generic.otel-default/_search -d '{\"size\": 0, \"aggs\": {\"by_service\": {\"terms\": {\"field\": \"resource.attributes.service.name\"}}}}' | jq -r '.aggregations.by_service.buckets[] | [.key, .doc_count] | @tsv'"

block graylog
on "curl -s $GL localhost:9000/api/system/inputs | jq -r '.inputs[] | [.title, .attributes.port] | @tsv'"
on "curl -s $GL -H 'Accept: text/csv' 'localhost:9000/api/search/universal/relative?query=otel_attributes_message:%22card%20network%20unavailable%22&range=600&limit=2&fields=timestamp,otel_attributes_order_id,otel_attributes_trace_id'"

block same-line
TRACE=$(lab as "docker compose logs --no-log-prefix payments | grep 'card network unavailable' | tail -1 | jq -r .trace_id")
# the Elasticsearch exporter sends in batches, so the newest lines take a
# little while to arrive there; the queries wait for them
sleep 45
on "curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service_name=\"payments\"} |= \"$TRACE\"' | jq -r '.data.result[].values[][1]' | jq -c '{message, order_id}'"
on "curl -s -H 'Content-Type: application/json' localhost:9200/logs-generic.otel-default/_search -d '{\"query\": {\"match\": {\"attributes.trace_id\": \"$TRACE\"}}}' | jq -c '.hits.hits[]._source.attributes | {message, order_id}'"
on "curl -s $GL -H 'Accept: text/csv' 'localhost:9000/api/search/universal/relative?query=otel_attributes_trace_id:$TRACE&range=900&fields=otel_attributes_message,otel_attributes_order_id'"
on "curl -s localhost:16686/api/traces/$TRACE | jq -r '.data[0].spans[] | select(.tags[] | select(.key == \"error\" and .value == true)) | .operationName'"

block memory
on "docker stats --no-stream --format 'table {{.Name}}\t{{.MemUsage}}' shop-loki-1 shop-elasticsearch-1 shop-graylog-1 shop-opensearch-1 shop-mongo-1"
on "rm faults/payments.json compose.override.yaml"
