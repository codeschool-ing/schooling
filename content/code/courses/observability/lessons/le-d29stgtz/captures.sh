#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of observability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by `lab.sh reset`, including ~/shop/.grafana-password; the
# dashboard file and query.json, whose contents the lesson shows; simulated
# customers, five requests a second, started in the background; and the two
# faults: payments slowed to 600 ms for two minutes after the "deploy"
# annotation, and every tenth charge failing for seventy seconds before the
# last block. Values, ids, times and dates differ on every run.
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
quiet "docker compose run -d --rm loadgen python -m loadgen.load 5 1800"
put query.json <<'JSON'
{
  "from": "now-5m",
  "to": "now",
  "queries": [
    {
      "refId": "A",
      "datasource": {"uid": "prometheus"},
      "expr": "sum(rate(http_server_requests_total{job=\"storefront\"}[1m]))",
      "instant": true
    }
  ]
}
JSON
put grafana/dashboards/shop.json <<'JSON'
{
  "uid": "shop",
  "title": "Shop: requests, errors, duration",
  "tags": ["shop"],
  "time": {"from": "now-30m", "to": "now"},
  "refresh": "30s",
  "templating": {
    "list": [
      {
        "name": "job",
        "type": "query",
        "datasource": {"uid": "prometheus"},
        "query": "label_values(http_server_requests_total, job)",
        "current": {"text": "storefront", "value": "storefront"}
      }
    ]
  },
  "annotations": {
    "list": [
      {"name": "Deploys", "datasource": {"uid": "-- Grafana --"}, "enable": true, "iconColor": "orange",
       "target": {"type": "tags", "tags": ["deploy"]}}
    ]
  },
  "panels": [
    {
      "id": 1, "type": "timeseries", "title": "Requests per second, by status code",
      "gridPos": {"x": 0, "y": 0, "w": 12, "h": 8},
      "targets": [{"refId": "A", "datasource": {"uid": "prometheus"},
        "expr": "sum by (code) (rate(http_server_requests_total{job=\"$job\"}[1m]))", "legendFormat": "{{code}}"}]
    },
    {
      "id": 2, "type": "timeseries", "title": "Share of requests failing (5xx)",
      "gridPos": {"x": 12, "y": 0, "w": 12, "h": 8},
      "fieldConfig": {"defaults": {"unit": "percentunit", "min": 0}},
      "targets": [{"refId": "A", "datasource": {"uid": "prometheus"},
        "expr": "sum(rate(http_server_requests_total{job=\"$job\", code=~\"5..\"}[1m])) / sum(rate(http_server_requests_total{job=\"$job\"}[1m]))"}]
    },
    {
      "id": 3, "type": "timeseries", "title": "Duration, 50th and 99th percentile",
      "gridPos": {"x": 0, "y": 8, "w": 24, "h": 8},
      "fieldConfig": {"defaults": {"unit": "s", "min": 0}},
      "targets": [
        {"refId": "A", "datasource": {"uid": "prometheus"}, "legendFormat": "p50",
         "expr": "histogram_quantile(0.5, sum by (le) (rate(http_server_request_duration_seconds_bucket{job=\"$job\"}[1m])))"},
        {"refId": "B", "datasource": {"uid": "prometheus"}, "legendFormat": "p99",
         "expr": "histogram_quantile(0.99, sum by (le) (rate(http_server_request_duration_seconds_bucket{job=\"$job\"}[1m])))"}
      ]
    }
  ]
}
JSON
sleep 60
G="-u admin:\$(cat .grafana-password)"

block health
on "curl -s localhost:3000/api/health | jq -c ."
on "cat grafana/provisioning/datasources/shop.yaml"
on "curl -s $G localhost:3000/api/datasources | jq -r '.[] | [.name, .type, .uid, .url] | @tsv'"

block ds-query
on "cat query.json"
on "curl -s $G -H 'Content-Type: application/json' -d @query.json localhost:3000/api/ds/query | jq -c '.results.A.frames[0].data.values'"
on "curl -sG localhost:9090/api/v1/query --data-urlencode 'query=sum(rate(http_server_requests_total{job=\"storefront\"}[1m]))' | jq -c '.data.result[0].value'"

block token
on "curl -s $G -H 'Content-Type: application/json' -d '{\"name\": \"deploy-bot\", \"role\": \"Editor\"}' localhost:3000/api/serviceaccounts | jq -c '{id, name, role}'"
SA=$(lab as "curl -s -u admin:\$(cat .grafana-password) localhost:3000/api/serviceaccounts/search?query=deploy-bot | jq -r '.serviceAccounts[0].id'")
on "curl -s $G -H 'Content-Type: application/json' -d '{\"name\": \"annotations\"}' localhost:3000/api/serviceaccounts/$SA/tokens | jq -r .key > .grafana-token && wc -c < .grafana-token"
on "curl -s -o /dev/null -w '%{http_code}\n' -H \"Authorization: Bearer \$(cat .grafana-token)\" localhost:3000/api/search"
on "curl -s -o /dev/null -w '%{http_code}\n' -H \"Authorization: Bearer \$(cat .grafana-token)\" -X DELETE localhost:3000/api/datasources/uid/prometheus"

block dashboard
on "curl -s -H \"Authorization: Bearer \$(cat .grafana-token)\" 'localhost:3000/api/search?query=Shop' | jq -c '.[] | {uid, title, folderTitle, tags}'"
on "curl -s -H \"Authorization: Bearer \$(cat .grafana-token)\" localhost:3000/api/dashboards/uid/shop | jq -r '.meta.provisioned, (.dashboard.panels[] | .title)'"
on "curl -s -o /dev/null -w '%{http_code}\n' -H \"Authorization: Bearer \$(cat .grafana-token)\" -H 'Content-Type: application/json' -d '{\"dashboard\": {\"uid\": \"shop\", \"title\": \"edited by hand\"}, \"overwrite\": true}' localhost:3000/api/dashboards/db"

block variables
on "curl -s -H \"Authorization: Bearer \$(cat .grafana-token)\" localhost:3000/api/datasources/uid/prometheus/resources/api/v1/label/job/values | jq -c .data"

block annotate
T0=$(date +%s)
on "curl -s -H \"Authorization: Bearer \$(cat .grafana-token)\" -H 'Content-Type: application/json' -d '{\"dashboardUID\": \"shop\", \"tags\": [\"deploy\"], \"text\": \"payments 1.4.1\"}' localhost:3000/api/annotations | jq -c ."
quiet "echo '{\"latency_ms\": 600}' > faults/payments.json"
sleep 120
on "curl -s -H \"Authorization: Bearer \$(cat .grafana-token)\" -H 'Content-Type: application/json' -d '{\"dashboardUID\": \"shop\", \"tags\": [\"deploy\", \"rollback\"], \"text\": \"payments back to 1.4.0\"}' localhost:3000/api/annotations | jq -c ."
quiet "rm faults/payments.json"
sleep 120
on "curl -s -H \"Authorization: Bearer \$(cat .grafana-token)\" 'localhost:3000/api/annotations?tags=deploy' | jq -r '.[] | [(.time/1000 | strftime(\"%H:%M:%S\")), .text, (.tags | join(\",\"))] | @tsv'"
END=$(date +%s); START=$((T0 - 120))
echo "##### series"
lab as "curl -sG localhost:9090/api/v1/query_range --data-urlencode 'query=histogram_quantile(0.99, sum by (le) (rate(http_server_request_duration_seconds_bucket{job=\"storefront\",route=\"/checkout\"}[1m])))' --data-urlencode start=$START --data-urlencode end=$END --data-urlencode step=15 | jq -r '.data.result[0].values[] | [(.[0] - $T0), .[1]] | @tsv'"

block windows
quiet "echo '{\"fail_every\": 10}' > faults/payments.json"
sleep 70
quiet "rm faults/payments.json"
sleep 30
on "curl -sG localhost:9090/api/v1/query --data-urlencode 'query=sum(rate(http_server_requests_total{job=\"payments\",code=~\"5..\"}[1m])) / sum(rate(http_server_requests_total{job=\"payments\"}[1m]))' | jq -r '.data.result[0].value[1]'"
on "curl -sG localhost:9090/api/v1/query --data-urlencode 'query=sum(rate(http_server_requests_total{job=\"payments\",code=~\"5..\"}[10m])) / sum(rate(http_server_requests_total{job=\"payments\"}[10m]))' | jq -r '.data.result[0].value[1]'"
