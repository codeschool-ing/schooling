#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of observability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by `lab.sh reset`; promq (lesson 5); the scripts in scratch and
# the two scrape jobs appended to prometheus.yml, whose contents the lesson
# shows; and simulated customers, five requests a second, started in the
# background with `docker compose run -d`. Values, times and dates differ on
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

lab reset
put promq <<'SH'
#!/bin/sh
# promq 'EXPRESSION': ask Prometheus for the value of an expression, now.
curl -sG localhost:9090/api/v1/query --data-urlencode "query=$1" |
  jq -r '.data.result[] | (.metric | to_entries | map("\(.key)=\(.value)") | join(" ")) + "  " + .value[1]'
SH
quiet "chmod +x promq"
put scratch/summary.py <<'PY'
from prometheus_client import CollectorRegistry, Summary, generate_latest

registry = CollectorRegistry()
took = Summary("demo_request_seconds", "A summary, observed three times.", registry=registry)
for seconds in (0.2, 0.4, 1.9):
    took.observe(seconds)
print(generate_latest(registry).decode(), end="")
PY
put scratch/logins.py <<'PY'
import random
import sys
import time

from prometheus_client import Counter, start_http_server

label = sys.argv[1]
LOGINS = Counter("demo_logins", "Logins, labelled the way the first argument says.", [label])
random.seed(7)
start_http_server(8000)
plans = ["free", "monthly", "yearly"]
for user_id in range(1, 20001):
    value = str(user_id) if label == "user_id" else random.choice(plans)
    LOGINS.labels(value).inc()
print(f"20000 logins counted by {label}", flush=True)
time.sleep(3600)
PY
quiet "docker compose run -d --rm loadgen python -m loadgen.load 5 1800"
sleep 60

block types
on "curl -s localhost:8080/metrics | grep '^# TYPE'"
on "curl -s localhost:8080/metrics | grep -E '^process_(resident_memory_bytes|open_fds) '"
on "./promq 'rate(process_cpu_seconds_total{job=\"storefront\"}[1m])'"

block histogram
on "curl -s localhost:8080/metrics | grep 'request_duration_seconds_bucket{.*checkout'"
on "./promq 'histogram_quantile(0.5, sum by (le) (rate(http_server_request_duration_seconds_bucket{job=\"storefront\",route=\"/checkout\"}[1m])))'"
on "./promq 'histogram_quantile(0.99, sum by (le) (rate(http_server_request_duration_seconds_bucket{job=\"storefront\",route=\"/checkout\"}[1m])))'"
on "echo '{\"latency_ms\": 300}' > faults/payments.json"
sleep 90
on "./promq 'histogram_quantile(0.5, sum by (le) (rate(http_server_request_duration_seconds_bucket{job=\"storefront\",route=\"/checkout\"}[1m])))'"
on "./promq 'histogram_quantile(0.99, sum by (le) (rate(http_server_request_duration_seconds_bucket{job=\"storefront\",route=\"/checkout\"}[1m])))'"
on "./promq 'sum(rate(http_server_request_duration_seconds_bucket{job=\"storefront\",route=\"/checkout\",le=\"0.5\"}[1m])) / sum(rate(http_server_request_duration_seconds_count{job=\"storefront\",route=\"/checkout\"}[1m]))'"
on "rm faults/payments.json"

block summary
on "docker compose run --rm sandbox python summary.py 2>/dev/null"

quiet "cp prometheus/prometheus.yml prometheus/prometheus.yml.orig"
lab as "cat >> prometheus/prometheus.yml" <<'YAML'
  - job_name: prometheus
    static_configs:
      - targets: [localhost:9090]
  - job_name: logins
    static_configs:
      - targets: [logins:8000]
YAML
block jobs
on "tail -6 prometheus/prometheus.yml"
on "curl -s -X POST localhost:9090/-/reload && echo reloaded"
sleep 40
on "./promq 'prometheus_tsdb_head_series'"
on "./promq 'process_resident_memory_bytes{job=\"prometheus\"}'"

block by-plan
on "docker compose run -d --rm --name logins sandbox python logins.py plan"
sleep 40
on "curl -s localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | select(.labels.job == \"logins\") | [.health, .lastScrapeDuration] | @tsv'"
on "./promq 'demo_logins_total'"
on "./promq 'prometheus_tsdb_head_series'"
on "docker stop logins"

block by-user
on "docker compose run -d --rm --name logins sandbox python logins.py user_id"
sleep 60
on "./promq 'count(demo_logins_total)'"
on "./promq 'prometheus_tsdb_head_series'"
on "./promq 'scrape_samples_scraped{job=\"logins\"}'"
on "curl -s localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | select(.labels.job == \"logins\") | [.health, .lastScrapeDuration] | @tsv'"
on "curl -s localhost:9090/api/v1/status/tsdb | jq -r '.data.seriesCountByMetricName[:3][] | [.name, .value] | @tsv'"
on "curl -s localhost:9090/api/v1/status/tsdb | jq -r '.data.labelValueCountByLabelName[:3][] | [.name, .value] | @tsv'"
on "./promq 'process_resident_memory_bytes{job=\"prometheus\"}'"

block drop
lab as "cat >> prometheus/prometheus.yml" <<'YAML'
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: demo_logins_total
        action: drop
YAML
on "tail -8 prometheus/prometheus.yml"
on "curl -s -X POST localhost:9090/-/reload && echo reloaded"
sleep 40
on "./promq 'scrape_samples_scraped{job=\"logins\"}'"
on "./promq 'scrape_samples_post_metric_relabeling{job=\"logins\"}'"
on "./promq 'count(demo_logins_total)'"
on "docker stop logins"
quiet "mv prometheus/prometheus.yml.orig prometheus/prometheus.yml"
