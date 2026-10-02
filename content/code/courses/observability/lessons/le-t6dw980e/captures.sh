#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of observability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by `lab.sh reset`; the promq helper from lesson 5;
# prometheus/rules/slo.yml, whose contents the lesson shows; simulated
# customers, five requests a second, started in the background and left
# buying for fifty-five minutes before the budget block, so that the
# one-hour window the lesson uses is full; and payments told to fail every
# twentieth charge for four minutes. Counts, times and dates differ on every
# run.
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
put promq <<'SH'
#!/bin/sh
# promq 'EXPRESSION': ask Prometheus for the value of an expression, now.
curl -sG localhost:9090/api/v1/query --data-urlencode "query=$1" |
  jq -r '.data.result[] | (.metric | to_entries | map("\(.key)=\(.value)") | join(" ")) + "  " + .value[1]'
SH
quiet "chmod +x promq"
quiet "docker compose run -d --rm loadgen python -m loadgen.load 5 4200"
START=$(date +%s)
sleep 300

block sli
on "./promq 'sum by (code) (increase(http_server_requests_total{job=\"storefront\",route=\"/checkout\"}[5m]))'"
on "./promq 'sum(rate(http_server_requests_total{job=\"storefront\",route=\"/checkout\",code!~\"5..\"}[5m])) / sum(rate(http_server_requests_total{job=\"storefront\",route=\"/checkout\"}[5m]))'"
on "./promq 'sum(rate(http_server_request_duration_seconds_bucket{job=\"storefront\",route=\"/checkout\",le=\"0.5\"}[5m])) / sum(rate(http_server_request_duration_seconds_count{job=\"storefront\",route=\"/checkout\"}[5m]))'"
on "./promq 'sum by (route) (rate(http_server_requests_total{job=\"orders\"}[5m]))'"

block rules
put prometheus/rules/slo.yml <<'YAML'
# The checkout's service level objective: 99.5% of checkouts do not fail on
# our side. The window is one hour so that a lesson can watch it move; in
# production it would be 28 days, and every expression below is the same.
groups:
  - name: checkout-slo
    interval: 30s
    rules:
      - record: checkout:sli_availability:ratio_rate5m
        expr: |
          sum(rate(http_server_requests_total{job="storefront",route="/checkout",code!~"5.."}[5m]))
          / sum(rate(http_server_requests_total{job="storefront",route="/checkout"}[5m]))
      - record: checkout:sli_availability:ratio_rate1h
        expr: |
          sum(rate(http_server_requests_total{job="storefront",route="/checkout",code!~"5.."}[1h]))
          / sum(rate(http_server_requests_total{job="storefront",route="/checkout"}[1h]))
      - record: checkout:sli_latency:ratio_rate1h
        expr: |
          sum(rate(http_server_request_duration_seconds_bucket{job="storefront",route="/checkout",le="0.5"}[1h]))
          / sum(rate(http_server_request_duration_seconds_count{job="storefront",route="/checkout"}[1h]))
      - record: checkout:error_budget_remaining:ratio_1h
        expr: 1 - (1 - checkout:sli_availability:ratio_rate1h) / (1 - 0.995)
YAML
on "cat prometheus/rules/slo.yml"
on "curl -s -X POST localhost:9090/-/reload && curl -s localhost:9090/api/v1/rules | jq -r '.data.groups[] | select(.name == \"checkout-slo\") | .rules[] | [.name, .health] | @tsv'"

sleep $(( START + 3300 - $(date +%s) ))

block budget
on "./promq 'sum(increase(http_server_requests_total{job=\"storefront\",route=\"/checkout\"}[1h]))'"
on "./promq '{__name__=~\"checkout:.*_1h|checkout:.*rate1h\"}'"

block incident
quiet "echo '{\"fail_every\": 20}' > faults/payments.json"
sleep 180
on "./promq 'checkout:sli_availability:ratio_rate5m'"
on "./promq '(1 - checkout:sli_availability:ratio_rate5m) / (1 - 0.995)'"
sleep 60
quiet "rm faults/payments.json"
sleep 90

block after
on "./promq 'sum by (code) (increase(http_server_requests_total{job=\"storefront\",route=\"/checkout\"}[1h]))'"
on "./promq '{__name__=~\"checkout:.*_1h|checkout:.*rate1h\"}'"
quiet "rm prometheus/rules/slo.yml && curl -s -X POST localhost:9090/-/reload"
