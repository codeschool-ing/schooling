#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of observability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The incident is staged: a "release" of payments that is the lab's fault file
# telling payments to fail every eighth charge, and a "rollback" that removes
# it. Everything after the release is what the lab then did.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by `lab.sh reset`; the promq helper from lesson 5; lesson 16's
# burn-rate rules and Alertmanager routes, unchanged; a Grafana service
# account and its token in .grafana-token, made as lesson 7 made them;
# simulated customers, five requests a second, started in the background;
# the fault file, written right after the release annotation and removed
# right after the rollback annotation; a minute between declaring the incident
# and rolling back, standing for the investigation the lesson describes; and
# waiting for the page, for its resolution, and for the five-minute burn rate
# to fall below 1. Times, counts, ids and dates differ on every run.
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
mark() { on "curl -s -H \"Authorization: Bearer \$(cat .grafana-token)\" -H 'Content-Type: application/json' -d '{\"tags\": [\"$1\"], \"text\": \"$2\"}' localhost:3000/api/annotations | jq -c ."; }
wait_pager() { for _ in $(seq 1 90); do lab as "docker compose logs --no-log-prefix pager" | grep '"PAGE"' | grep -q "\"$1\"" && return; sleep 5; done; }

lab reset
put promq <<'SH'
#!/bin/sh
# promq 'EXPRESSION': ask Prometheus for the value of an expression, now.
curl -sG localhost:9090/api/v1/query --data-urlencode "query=$1" |
  jq -r '.data.result[] | (.metric | to_entries | map("\(.key)=\(.value)") | join(" ")) + "  " + .value[1]'
SH
quiet "chmod +x promq"
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
quiet "curl -s -X POST localhost:9090/-/reload && docker compose up -d alertmanager"
quiet "curl -s -u admin:\$(cat .grafana-password) -H 'Content-Type: application/json' -d '{\"name\": \"deploy-bot\", \"role\": \"Editor\"}' localhost:3000/api/serviceaccounts"
SA=$(lab as "curl -s -u admin:\$(cat .grafana-password) localhost:3000/api/serviceaccounts/search?query=deploy-bot | jq -r '.serviceAccounts[0].id'")
quiet "curl -s -u admin:\$(cat .grafana-password) -H 'Content-Type: application/json' -d '{\"name\": \"incidents\"}' localhost:3000/api/serviceaccounts/$SA/tokens | jq -r .key > .grafana-token"
quiet "docker compose run -d --rm loadgen python -m loadgen.load 5 2400"
sleep 180

block release
mark deploy "payments 1.4.2"
quiet "echo '{\"fail_every\": 8}' > faults/payments.json"
wait_pager firing

block page
on "docker compose logs --no-log-prefix pager | grep '\"PAGE\"' | jq -c '{time, status, alertname, summary}'"
on "./promq '{__name__=~\"checkout:burn_rate:.*\"}'"

block declare
mark incident "SEV-2 declared: checkouts failing, IC ana"
on "./promq 'sum by (job) (rate(http_server_requests_total{code=~\"5..\"}[2m])) / sum by (job) (rate(http_server_requests_total[2m]))'"
on "curl -s -H \"Authorization: Bearer \$(cat .grafana-token)\" 'localhost:3000/api/annotations?from='\$(date -d '-30 min' +%s000) | jq -r '.[] | [(.time/1000 | strftime(\"%H:%M:%S\")), (.tags | join(\",\")), .text] | @tsv'"

sleep 60
block mitigate
mark deploy "payments rolled back to 1.4.0"
quiet "rm faults/payments.json"
sleep 90
on "./promq '{__name__=~\"checkout:burn_rate:.*\"}'"
wait_pager resolved
for _ in $(seq 1 60); do
  lab as "./promq 'checkout:burn_rate:5m < 1'" | grep -q . && break
  sleep 10
done
on "./promq '{__name__=~\"checkout:burn_rate:.*\"}'"

block resolved
mark incident "resolved: 5-minute burn rate below 1, checkouts normal"
on "docker compose logs --no-log-prefix pager | grep '\"PAGE\"' | jq -c '{time, status, alertname}'"

block timeline
on "{ curl -s -H \"Authorization: Bearer \$(cat .grafana-token)\" 'localhost:3000/api/annotations?from='\$(date -d '-30 min' +%s000) | jq -r '.[] | [(.time/1000 | strftime(\"%H:%M:%S\")), \"mark\", .text] | @tsv'; docker compose logs --no-log-prefix pager | grep '\"PAGE\"' | jq -r '[.time[11:19], \"pager\", \"\\(.status) \\(.alertname)\"] | @tsv'; } | sort"
quiet "rm prometheus/rules/burn.yml compose.override.yaml && curl -s -X POST localhost:9090/-/reload && docker compose up -d alertmanager"
