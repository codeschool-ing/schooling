#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of observability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Nothing here reaches a vendor. The error tracker's SDK is the real one, with
# a transport that writes the event to a file; the "vendor" the Collector sends
# to is standin.py, a local program that prints what it receives.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by `lab.sh reset`; the promq helper from lesson 5; tracked.py
# in two versions, standin.py and compose.override.yaml, whose contents the
# lesson shows; and simulated customers, five requests a second, started in
# the background. Ids, times, sizes and dates differ on every run.
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
put scratch/tracked.py <<'PY'
"""An error reported the way an error tracker's SDK reports it.

The DSN names a project and points nowhere; the transport writes each event
to event.json instead of sending it.
"""
import json
import logging

import sentry_sdk
from sentry_sdk.transport import Transport


class ToFile(Transport):
    def capture_envelope(self, envelope):
        for item in envelope.items:
            if item.type == "event":
                with open("event.json", "w") as f:
                    json.dump(item.payload.json, f, indent=1)


sentry_sdk.init(
    dsn="https://key@errors.example.invalid/1",
    transport=ToFile,
    release="shop@1.4.0",
    environment="lab",
)
logging.basicConfig(level=logging.INFO)
log = logging.getLogger("checkout")

COUPONS = {"WELCOME10": 10, "FRIEND15": 15}


def apply_coupon(total_cents, coupon):
    return total_cents * (100 - COUPONS[coupon]) // 100


def checkout(sku, qty, card, coupon):
    sentry_sdk.set_tag("sku", sku)
    log.info("pricing %s x %d", sku, qty)
    total_cents = 4900 * qty
    log.info("applying coupon %s", coupon)
    return apply_coupon(total_cents, coupon)


try:
    checkout("kettle", 2, "4111 1111 1111 1111", "WELCOME20")
except KeyError:
    sentry_sdk.capture_exception()
sentry_sdk.flush()
PY
put scratch/standin.py <<'PY'
"""A stand-in for a hosted product's intake: it takes OTLP over HTTP, as JSON,
and prints who sent it and how much. It stores nothing."""
import gzip
import json
import logging

from flask import Flask, request

logging.getLogger("werkzeug").setLevel(logging.ERROR)
app = Flask(__name__)


@app.post("/v1/traces")
def traces():
    sent = request.get_data()
    body = gzip.decompress(sent) if request.headers.get("Content-Encoding") == "gzip" else sent
    data = json.loads(body)
    spans = sum(len(s["spans"]) for r in data["resourceSpans"] for s in r["scopeSpans"])
    services = sorted({a["value"]["stringValue"] for r in data["resourceSpans"]
                       for a in r["resource"]["attributes"] if a["key"] == "service.name"})
    print(f"api-key={request.headers.get('api-key')} spans={spans} bytes={len(sent)}"
          f" from={','.join(services)}", flush=True)
    return {}


app.run(host="0.0.0.0", port=4318)
PY

block tracked
on "docker compose run --rm sandbox python tracked.py"
on "jq '{level, release, environment, tags, exception: [.exception.values[] | {type, value, frames: [.stacktrace.frames[] | select(.function != \"<module>\") | {function, lineno, vars}]}], breadcrumbs: [.breadcrumbs.values[] | .message]}' scratch/event.json"

block scrubbed
put scratch/tracked.py <<'PY'
"""An error reported the way an error tracker's SDK reports it.

The DSN names a project and points nowhere; the transport writes each event
to event.json instead of sending it.
"""
import json
import logging

import sentry_sdk
from sentry_sdk.scrubber import DEFAULT_DENYLIST, EventScrubber
from sentry_sdk.transport import Transport


class ToFile(Transport):
    def capture_envelope(self, envelope):
        for item in envelope.items:
            if item.type == "event":
                with open("event.json", "w") as f:
                    json.dump(item.payload.json, f, indent=1)


sentry_sdk.init(
    dsn="https://key@errors.example.invalid/1",
    transport=ToFile,
    release="shop@1.4.0",
    environment="lab",
    event_scrubber=EventScrubber(denylist=DEFAULT_DENYLIST + ["card"]),
)
logging.basicConfig(level=logging.INFO)
log = logging.getLogger("checkout")

COUPONS = {"WELCOME10": 10, "FRIEND15": 15}


def apply_coupon(total_cents, coupon):
    return total_cents * (100 - COUPONS[coupon]) // 100


def checkout(sku, qty, card, coupon):
    sentry_sdk.set_tag("sku", sku)
    log.info("pricing %s x %d", sku, qty)
    total_cents = 4900 * qty
    log.info("applying coupon %s", coupon)
    return apply_coupon(total_cents, coupon)


try:
    checkout("kettle", 2, "4111 1111 1111 1111", "WELCOME20")
except KeyError:
    sentry_sdk.capture_exception()
sentry_sdk.flush()
PY
on "sed -n '/^sentry_sdk.init/,/^)/p' scratch/tracked.py"
on "docker compose run --rm sandbox python tracked.py 2>&1 | tail -2"
on "jq '.exception.values[0].stacktrace.frames[] | select(.function == \"checkout\") | .vars' scratch/event.json"

block fanout
put compose.override.yaml <<'YAML'
services:
  otel-collector:
    volumes: ["./otel/collector-fanout.yaml:/etc/otelcol/config.yaml:ro"]
    environment:
      VENDOR_API_KEY: lab-0000-not-a-real-key
YAML
on "sed -n '/otlp_http\/vendor:/,/api-key/p' otel/collector-fanout.yaml"
on "cat compose.override.yaml"
on "docker compose run -d --rm --name vendor sandbox python standin.py 2>&1 | tail -1"
quiet "docker compose up -d otel-collector"
quiet "docker compose run -d --rm loadgen python -m loadgen.load 5 900"
sleep 30
on "docker logs vendor 2>&1 | tail -4"

block outage
on "docker stop vendor"
sleep 75
on "./promq 'sum by (exporter) (rate(otelcol_exporter_sent_spans[1m]))'"
on "./promq 'sum by (exporter) (otelcol_exporter_queue_size{data_type=\"traces\"})'"
on "./promq 'sum by (exporter) (otelcol_exporter_queue_capacity{data_type=\"traces\"})'"
on "docker compose logs --no-log-prefix otel-collector 2>&1 | grep 'otlp_http/vendor' | grep -m1 -o 'dial tcp: [^\\\"]*'"
quiet "rm compose.override.yaml && docker compose up -d otel-collector"
