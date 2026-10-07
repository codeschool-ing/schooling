#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of observability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by `lab.sh reset`; the promq helper and the rules file, whose
# contents the lesson shows; and simulated customers, five requests a second,
# started in the background with `docker compose run -d` and left running for
# the whole session. Values, times and dates differ on every run.
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

lab reset
put promq <<'SH'
#!/bin/sh
# promq 'EXPRESSION': ask Prometheus for the value of an expression, now.
curl -sG localhost:9090/api/v1/query --data-urlencode "query=$1" |
  jq -r '.data.result[] | (.metric | to_entries | map("\(.key)=\(.value)") | join(" ")) + "  " + .value[1]'
SH
quiet "chmod +x promq"
quiet "docker compose run -d --rm loadgen python -m loadgen.load 5 1500"
sleep 75

block targets
on "curl -s localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | [.labels.job, .labels.instance, .health, .lastScrapeDuration] | @tsv' | sort"
on "curl -s localhost:8080/metrics | grep -A3 '^# HELP http_server_requests_total'"

block selectors
on "cat promq"
on "./promq 'up{job=\"payments\"}'"
on "./promq 'http_server_requests_total{job=\"storefront\"}'"
on "./promq 'http_server_requests_total{job=\"storefront\", code=~\"4..\"}'"

block rate
on "./promq 'rate(http_server_requests_total{job=\"storefront\", route=\"/checkout\"}[1m])'"
on "./promq 'sum by (route) (rate(http_server_requests_total{job=\"storefront\"}[1m]))'"
on "./promq 'sum(increase(http_server_requests_total{job=\"storefront\"}[1m]))'"

block reset
on "./promq 'sum(http_server_requests_total{job=\"storefront\"})'"
on "docker compose restart storefront 2>&1 | tail -1"
sleep 35
on "./promq 'sum(http_server_requests_total{job=\"storefront\"})'"
on "./promq 'sum(rate(http_server_requests_total{job=\"storefront\"}[2m]))'"
on "./promq 'resets(http_server_requests_total{job=\"storefront\", route=\"/checkout\", code=\"201\"}[5m])'"

block errors
on "echo '{\"fail_every\": 20}' > faults/payments.json"
sleep 90
on "./promq 'sum by (code) (rate(http_server_requests_total{job=\"payments\"}[1m]))'"
on "./promq 'sum(rate(http_server_requests_total{job=\"payments\", code=~\"5..\"}[1m])) / sum(rate(http_server_requests_total{job=\"payments\"}[1m]))'"

block exporters
on "./promq 'node_load1'"
on "./promq 'pg_up'"
on "./promq 'rabbitmq_queue_messages_ready'"
on "./promq 'probe_success'"
on "./promq 'probe_http_duration_seconds'"

block pushgateway
on "./promq 'report_last_success_timestamp_seconds' ; echo '(nothing yet)'"
on "docker compose run --rm report 2>&1 | grep -v Container | jq -c '{message, orders}'"
sleep 20
on "./promq 'report_last_success_timestamp_seconds'"
on "./promq 'time() - report_last_success_timestamp_seconds'"

put prometheus/rules/shop.yml <<'YAML'
groups:
  - name: shop
    rules:
      - alert: TargetDown
        expr: up == 0
        for: 1m
        labels:
          severity: ticket
        annotations:
          summary: "{{ $labels.job }} has not answered a scrape for a minute"

      - record: job:http_server_requests:rate1m
        expr: sum by (job, code) (rate(http_server_requests_total[1m]))

      - alert: PaymentsFailing
        expr: |
          sum(job:http_server_requests:rate1m{job="payments", code=~"5.."})
            / sum(job:http_server_requests:rate1m{job="payments"}) > 0.02
        for: 2m
        labels:
          severity: page
        annotations:
          summary: "More than 2% of charges are failing"

      - alert: ReportNotRun
        expr: time() - report_last_success_timestamp_seconds > 26 * 3600
        labels:
          severity: ticket
        annotations:
          summary: "The nightly report has not finished for over 26 hours"
YAML
block rules
on "docker run --rm -v ./prometheus:/etc/prometheus --entrypoint promtool prom/prometheus:v3.15.0 check rules /etc/prometheus/rules/shop.yml"
on "curl -s -X POST localhost:9090/-/reload && echo reloaded"
sleep 20
on "./promq 'job:http_server_requests:rate1m{job=\"payments\"}'"
on "curl -s localhost:9090/api/v1/alerts | jq -r '.data.alerts[] | [.labels.alertname, .state, .activeAt] | @tsv'"
sleep 120
on "curl -s localhost:9090/api/v1/alerts | jq -r '.data.alerts[] | [.labels.alertname, .state, .activeAt] | @tsv'"
sleep 20
on "curl -s localhost:9093/api/v2/alerts | jq -r '.[] | [.labels.alertname, .labels.severity, .status.state] | @tsv'"
on "docker compose logs --no-log-prefix pager | grep PAGE | jq -c '{status, alertname, severity, summary}'"
on "rm faults/payments.json"
