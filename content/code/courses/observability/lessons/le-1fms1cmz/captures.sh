#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of observability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by `lab.sh reset`; the scripts in ~/shop/scratch, written below
# by put, whose contents the lesson shows in full; and checkout.json, the same
# file as lesson 1. Trace ids, span ids, times and dates differ on every run.
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
put checkout.json <<'JSON'
{"sku": "kettle", "qty": 1, "card": "4111 1111 1111 1111"}
JSON

put scratch/no_sdk.py <<'PY'
from opentelemetry import trace

tracer = trace.get_tracer("no-sdk")
with tracer.start_as_current_span("hello") as span:
    print("recording:", span.is_recording())
    print("trace id:", format(span.get_span_context().trace_id, "032x"))
PY

put scratch/first_span.py <<'PY'
from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import ConsoleSpanExporter, SimpleSpanProcessor

provider = TracerProvider(resource=Resource.create({"service.name": "first-span"}))
provider.add_span_processor(SimpleSpanProcessor(ConsoleSpanExporter()))
trace.set_tracer_provider(provider)

tracer = trace.get_tracer("first-span")
with tracer.start_as_current_span("hello") as span:
    print("recording:", span.is_recording())
PY

put scratch/nested.py <<'PY'
import time

from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import ConsoleSpanExporter, SimpleSpanProcessor


def one_line(span):
    parent = format(span.parent.span_id, "016x") if span.parent else "none"
    took = (span.end_time - span.start_time) / 1e6
    return f"{span.name:<16} span {span.context.span_id:016x}  parent {parent:<16}  {took:5.1f} ms\n"


provider = TracerProvider()
provider.add_span_processor(SimpleSpanProcessor(ConsoleSpanExporter(formatter=one_line)))
trace.set_tracer_provider(provider)
tracer = trace.get_tracer("nested")

PRICES = {"tea-500g": 3450, "kettle": 18990}


def price(sku):
    with tracer.start_as_current_span("look up price") as span:
        span.set_attribute("shop.sku", sku)
        time.sleep(0.01)
        return PRICES[sku]


with tracer.start_as_current_span("price basket"):
    total = price("tea-500g") + price("kettle")
print("total:", total)
PY

put scratch/cost.py <<'PY'
import sys
import time

from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor, SimpleSpanProcessor

kind = sys.argv[1]
processor = {"simple": SimpleSpanProcessor, "batch": BatchSpanProcessor}[kind]
provider = TracerProvider(resource=Resource.create({"service.name": f"cost-{kind}"}))
provider.add_span_processor(processor(OTLPSpanExporter()))
tracer = provider.get_tracer("cost")

start = time.perf_counter()
for i in range(2000):
    with tracer.start_as_current_span("unit of work"):
        pass
print(f"{kind}: 2000 spans in {time.perf_counter() - start:.2f} s")
provider.shutdown()
PY

put scratch/names.py <<'PY'
import sys

from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

style = sys.argv[1]
provider = TracerProvider(resource=Resource.create({"service.name": f"names-{style}"}))
provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))
tracer = provider.get_tracer("names")

for order_id in range(1001, 1051):
    if style == "bad":
        name = f"GET /orders/{order_id}"
        attributes = {}
    else:
        name = "GET /orders/{id}"
        attributes = {"shop.order_id": order_id}
    with tracer.start_as_current_span(name, attributes=attributes):
        pass
provider.shutdown()
PY

block api-only
on "docker compose run --rm sandbox python no_sdk.py"
block first-span
on "docker compose run --rm sandbox python first_span.py"
block nested
on "docker compose run --rm sandbox python nested.py"

block attributes
quiet "curl -s -X POST localhost:8080/checkout -H 'Content-Type: application/json' -d @checkout.json"
sleep 8
TRACE=$(lab as "docker compose logs --no-log-prefix storefront | grep 'checkout finished' | tail -1 | jq -r .trace_id")
on "curl -s localhost:16686/api/traces/$TRACE | jq -c '.data[0].spans[] | select(.operationName == \"POST /checkout\") | .tags[] | {key, value}'"

block error
on "docker compose stop orders"
on "curl -s -w ' %{http_code}\n' -X POST localhost:8080/checkout -H 'Content-Type: application/json' -d @checkout.json"
on "docker compose start orders"
sleep 8
on "docker compose logs --no-log-prefix storefront | grep unreachable | jq -c '{level, message, trace_id}'"
TRACE=$(lab as "docker compose logs --no-log-prefix storefront | grep unreachable | tail -1 | jq -r .trace_id")
on "curl -s localhost:16686/api/traces/$TRACE | jq '.data[0].spans[0] | {tags: ([.tags[] | select(.key | test(\"^(otel.status|error)\")) | {(.key): .value}] | add), events: [.logs[].fields | from_entries | {event, \"exception.type\"}]}'"

block cost
on "docker compose run --rm sandbox python cost.py simple"
on "docker compose run --rm sandbox python cost.py batch"

block names
quiet "docker compose run --rm sandbox python names.py bad"
quiet "docker compose run --rm sandbox python names.py good"
sleep 8
on "curl -s 'localhost:16686/api/v3/operations?service=names-bad' | jq '.operations | length'"
on "curl -s 'localhost:16686/api/v3/operations?service=names-bad' | jq -r '.operations[:3][].name'"
on "curl -s 'localhost:16686/api/v3/operations?service=names-good' | jq -r '.operations[].name'"
