#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of observability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by `lab.sh reset`; the promq helper from lesson 5;
# prometheus/rules/burn.yml, alertmanager/routes.yml and
# compose.override.yaml, whose contents the lesson shows; simulated
# customers, five requests a second, started in the background and left
# buying for thirty minutes so that every window holds real traffic; and the
# faults: payments failing every fiftieth charge for twelve seconds at the
# start, so that the counter of failed checkouts exists before anything is
# measured; then every fourth for forty seconds; then every tenth for six
# minutes. Times, counts, ids and dates differ on every run.
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
PAGER="docker compose logs --no-log-prefix pager | grep -E '\"(PAGE|TICKET)\"' | jq -c '{message, status, alertname, severity}'"
ALERTS="curl -s localhost:9093/api/v2/alerts | jq -c '.[] | {alertname: .labels.alertname, severity: .labels.severity, state: .status.state, inhibitedBy: .status.inhibitedBy, silencedBy: .status.silencedBy}'"

lab reset
put promq <<'SH'
#!/bin/sh
# promq 'EXPRESSION': ask Prometheus for the value of an expression, now.
curl -sG localhost:9090/api/v1/query --data-urlencode "query=$1" |
  jq -r '.data.result[] | (.metric | to_entries | map("\(.key)=\(.value)") | join(" ")) + "  " + .value[1]'
SH
quiet "chmod +x promq"
quiet "docker compose run -d --rm loadgen python -m loadgen.load 5 4200"
# One failed charge, thirty minutes before anything is measured, so that the
# storefront's counter for code="502" already exists when the blip happens.
sleep 20
quiet "echo '{\"fail_every\": 50}' > faults/payments.json"
sleep 12
quiet "rm faults/payments.json"

block rules
put prometheus/rules/burn.yml <<'YAML'
# How fast the checkout's error budget (lesson 15, 99.5%) is being spent, and
# two alerts on it. A burn rate of 1 spends the budget in exactly one window;
# 14.4 spends 2% of a 28-day budget in one hour. The lab's windows are 5m and
# 1m for the fast alert and 30m and 5m for the slow one, so that a lesson can
# watch them; production uses 1h and 5m, and 6h and 30m.
groups:
  - name: checkout-burn
    interval: 15s
    rules:
      - record: checkout:burn_rate:1m
        expr: |
          (1 - sum(rate(http_server_requests_total{job="storefront",route="/checkout",code!~"5.."}[1m]))
             / sum(rate(http_server_requests_total{job="storefront",route="/checkout"}[1m]))) / 0.005
      - record: checkout:burn_rate:5m
        expr: |
          (1 - sum(rate(http_server_requests_total{job="storefront",route="/checkout",code!~"5.."}[5m]))
             / sum(rate(http_server_requests_total{job="storefront",route="/checkout"}[5m]))) / 0.005
      - record: checkout:burn_rate:30m
        expr: |
          (1 - sum(rate(http_server_requests_total{job="storefront",route="/checkout",code!~"5.."}[30m]))
             / sum(rate(http_server_requests_total{job="storefront",route="/checkout"}[30m]))) / 0.005

      - alert: CheckoutBudgetBurningFast
        expr: checkout:burn_rate:5m > 14.4 and checkout:burn_rate:1m > 14.4
        labels:
          severity: page
          slo: checkout
        annotations:
          summary: "Checkouts are failing fast enough to spend the month's error budget in two days"
          description: "{{ $value | printf \"%.0f\" }}x the sustainable rate of failed checkouts, over 5 minutes and still now."
          runbook_url: "https://wiki.example.invalid/runbooks/checkout-failing"

      - alert: CheckoutBudgetBurningSlowly
        expr: checkout:burn_rate:30m > 3 and checkout:burn_rate:5m > 3
        labels:
          severity: ticket
          slo: checkout
        annotations:
          summary: "Checkouts are failing fast enough to spend the month's error budget in nine days"
YAML
on "sed -n '/- alert: CheckoutBudgetBurningFast/,\$p' prometheus/rules/burn.yml"
on "curl -s -X POST localhost:9090/-/reload && curl -s localhost:9090/api/v1/rules | jq -r '.data.groups[] | select(.name == \"checkout-burn\") | .rules[] | [.name, .health] | @tsv'"

block routes
put alertmanager/routes.yml <<'YAML'
# Pages and tickets go to different places, and a page silences the ticket
# about the same objective.
route:
  receiver: tickets
  group_by: [alertname, slo]
  group_wait: 10s
  group_interval: 1m
  repeat_interval: 4h
  routes:
    - matchers: ['severity="page"']
      receiver: pager

inhibit_rules:
  - source_matchers: ['severity="page"']
    target_matchers: ['severity="ticket"']
    equal: [slo]

receivers:
  - name: pager
    webhook_configs:
      - url: http://pager:8090/page
  - name: tickets
    webhook_configs:
      - url: http://pager:8090/ticket
YAML
put compose.override.yaml <<'YAML'
services:
  alertmanager:
    command: [--config.file=/etc/alertmanager/routes.yml]
YAML
on "cat alertmanager/routes.yml"
on "docker compose up -d alertmanager 2>&1 | tail -1"
sleep 1800

block blip
quiet "echo '{\"fail_every\": 4}' > faults/payments.json"
sleep 40
quiet "rm faults/payments.json"
sleep 5
on "./promq '{__name__=~\"checkout:burn_rate:.*\"}'"
on "$ALERTS"
sleep 120

block incident
quiet "echo '{\"fail_every\": 10}' > faults/payments.json"
sleep 270
on "./promq '{__name__=~\"checkout:burn_rate:.*\"}'"
on "$ALERTS"
on "$PAGER"

block silence
on "docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 silence add alertname=CheckoutBudgetBurningFast --duration=20m --author=ana --comment='payments maintenance, ticket OPS-123'"
on "docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 silence query -o extended"
on "$ALERTS"

block resolved
quiet "rm faults/payments.json"
on "docker compose exec alertmanager sh -c 'amtool --alertmanager.url=http://localhost:9093 silence expire \$(amtool --alertmanager.url=http://localhost:9093 silence query -q)'"
sleep 240
on "./promq '{__name__=~\"checkout:burn_rate:.*\"}'"
on "$PAGER"
quiet "rm prometheus/rules/burn.yml compose.override.yaml && curl -s -X POST localhost:9090/-/reload && docker compose up -d alertmanager"
