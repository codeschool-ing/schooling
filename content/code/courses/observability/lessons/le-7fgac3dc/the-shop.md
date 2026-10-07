---
title: The shop, written in full
version: 1
---

The shop is a little over five hundred lines of Python: four services, a nightly job, a pager, a program
that plays customers, and three small files they share. **All of it is on this page**, and the
next page has everything that watches it. Together they are the whole lab. Nothing in this course
uses a file that is not written out on one of these two pages or in the lesson that needs it.

A checkout arrives at `storefront`, which asks `orders` to store it. `orders` asks `payments` to
charge the card and, once it is paid, puts a message on a RabbitMQ queue that `mailer` takes off to
send the confirmation. The shop is small on purpose, and **it has the shapes production systems
have**: HTTP between services, a database, a queue and a scheduled job, which are exactly the
places where signals get lost.

You do not have to read the code now. Lessons 2 to 4 take it apart a piece at a time, and every
later lesson quotes the lines it is about. What you have to do now is save it.

::: track networks-infra
The services are written in Python, which this track has already taught you. Reading them is
reading code you know, and lessons 2 to 4 change them.
:::

::: track data-platform
The services are written in Python, which the data track this one continues has already taught
you. Reading them is reading code you know, and lessons 2 to 4 change them.
:::

::: track software-architecture
The services are written in Python, which this track has not taught, and you will not need to
write it. Every piece of code this course shows carries a note saying what it does, and what you
change in it is a line or two that the lesson gives you whole.
:::

::: track *
The services are written in Python. You need to be able to read it, not to write it. Every piece
of code this course shows carries a note saying what it does, and what you change in it is a line
or two that the lesson gives you whole.
:::

First the directories, all of them at once, including the ones the next page fills:

```sh
mkdir -p ~/shop && cd ~/shop
mkdir -p services/common services/storefront services/orders services/payments \
    services/mailer services/report services/loadgen services/pager faults scratch \
    otel prometheus/rules alertmanager loki grafana/provisioning/datasources \
    grafana/provisioning/dashboards grafana/dashboards
touch services/common/__init__.py
```

The empty `__init__.py` makes `services/common` a package the other services can import. Then the
files. **Copy each one with the button in its corner** and paste it into the editor that
`nano <path>` opens, inside `~/shop`, on the path written above it: `Ctrl+O` saves and `Ctrl+X`
leaves. Typing them is slower and adds typing mistakes, which are hard to find in a file you have
not read yet.

## The image every service runs in

One image serves every program of the shop, built from Python's official slim image. `Dockerfile`
says how to build it and `requirements.txt` says what to install, each package at the version the
transcripts were recorded with:

`~/shop/Dockerfile`

```dockerfile
FROM python:3.12-slim
COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir -r /requirements.txt
COPY services /app
WORKDIR /app
ENV PYTHONUNBUFFERED=1 PYTHONPATH=/app
```

`~/shop/requirements.txt`

```ini
flask==3.1.3
waitress==3.0.2
requests==2.34.2
psycopg[binary]==3.3.6
pika==1.4.4
prometheus-client==0.26.0
opentelemetry-api==1.45.0
opentelemetry-sdk==1.45.0
opentelemetry-exporter-otlp-proto-http==1.45.0
opentelemetry-distro==0.66b0
opentelemetry-instrumentation-flask==0.66b0
opentelemetry-instrumentation-requests==0.66b0
opentelemetry-instrumentation-psycopg==0.66b0
sentry-sdk==2.71.0
```

The code itself is not baked in for good. The image copies `services` into `/app`, and the next
page also mounts `./services` over `/app` in every container. **An edit to a service takes effect on
`docker compose restart <service>`**, without building the image again, which is how lessons 2 to 4
change the code and then put it back.

## What every service shares

Three modules in `services/common`. `logs.py` makes every service write one JSON object per line,
with the trace id in it when there is one; lesson 8 is about this file:

`~/shop/services/common/logs.py`

```python
"""One JSON object per line on stdout: how every service of the shop logs.

The platform collects stdout; nothing here knows where the lines end up.
"""
import json
import logging
import os
import sys
from datetime import datetime, timezone

from opentelemetry import trace

SERVICE = os.environ.get("OTEL_SERVICE_NAME", "unknown")


class JsonFormatter(logging.Formatter):
    def format(self, record):
        line = {
            "time": datetime.fromtimestamp(record.created, timezone.utc)
            .isoformat(timespec="milliseconds")
            .replace("+00:00", "Z"),
            "level": record.levelname,
            "service": SERVICE,
            "logger": record.name,
            "message": record.getMessage(),
        }
        ctx = trace.get_current_span().get_span_context()
        if ctx.is_valid:
            line["trace_id"] = format(ctx.trace_id, "032x")
            line["span_id"] = format(ctx.span_id, "016x")
        line.update(getattr(record, "fields", {}))
        if record.exc_info:
            line["exception"] = self.formatException(record.exc_info)
        return json.dumps(line)


def setup(level=None):
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    root = logging.getLogger()
    root.handlers[:] = [handler]
    root.setLevel(level or os.environ.get("LOG_LEVEL", "INFO"))
    logging.getLogger("waitress").setLevel(logging.WARNING)
    logging.getLogger("pika").setLevel(logging.CRITICAL)
    return logging.getLogger(SERVICE)
```

`tracing.py` sets up the OpenTelemetry SDK for the services instrumented by hand; lesson 2 builds
these lines one at a time:

`~/shop/services/common/tracing.py`

```python
"""The OpenTelemetry SDK, set up by hand, for the services instrumented by hand."""
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor


def setup(service, version):
    resource = Resource.create({"service.name": service, "service.version": version})
    provider = TracerProvider(resource=resource)
    provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))
    trace.set_tracer_provider(provider)
    return trace.get_tracer(service, version)
```

And `web.py` counts and times every request a service answers, and publishes the numbers at
`/metrics` for Prometheus; lessons 5 and 6 read what it produces:

`~/shop/services/common/web.py`

```python
"""Rate, errors and duration for every Flask route, in Prometheus's format."""
import time

from flask import Response, g, request
from opentelemetry import trace
from prometheus_client import REGISTRY, Counter, Histogram
from prometheus_client.exposition import choose_encoder

REQUESTS = Counter(
    "http_server_requests",
    "HTTP requests answered, by route, method and status code.",
    ["route", "method", "code"],
)
DURATION = Histogram(
    "http_server_request_duration_seconds",
    "Time taken to answer an HTTP request.",
    ["route", "method"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5),
)


def measure(app):
    @app.before_request
    def start():
        g.started = time.perf_counter()

    @app.after_request
    def finish(response):
        route = request.url_rule.rule if request.url_rule else "unmatched"
        if route != "/metrics":
            REQUESTS.labels(route, request.method, str(response.status_code)).inc()
            ctx = trace.get_current_span().get_span_context()
            exemplar = {"trace_id": format(ctx.trace_id, "032x")} if ctx.is_valid else None
            DURATION.labels(route, request.method).observe(time.perf_counter() - g.started, exemplar)
        return response

    @app.get("/metrics")
    def metrics():
        # OpenMetrics, which carries exemplars, for a scraper that asks for it
        encoder, content_type = choose_encoder(request.headers.get("Accept"))
        return Response(encoder(REGISTRY), content_type=content_type)
```

## The four services

`storefront` is where a checkout arrives. Its spans are written by hand, in the code:

`~/shop/services/storefront/app.py`

```python
"""The storefront: where a customer's checkout arrives. Instrumented by hand."""
import os

import requests
from flask import Flask, jsonify, request
from opentelemetry import propagate, trace
from opentelemetry.trace import SpanKind, Status, StatusCode

from common import logs, tracing, web

VERSION = os.environ.get("SHOP_VERSION", "1.4.0")
ORDERS = os.environ.get("ORDERS_URL", "http://orders:8081")
PRODUCTS = {"tea-500g": 3450, "mug-blue": 5900, "kettle": 18990}

log = logs.setup()
tracer = tracing.setup("storefront", VERSION)
app = Flask(__name__)
web.measure(app)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/products")
def products():
    return jsonify([{"sku": s, "price_cents": p} for s, p in PRODUCTS.items()])


@app.post("/checkout")
def checkout():
    with tracer.start_as_current_span("POST /checkout", kind=SpanKind.SERVER) as span:
        body = request.get_json()
        sku, qty = body["sku"], int(body.get("qty", 1))
        span.set_attribute("http.request.method", "POST")
        span.set_attribute("http.route", "/checkout")
        span.set_attribute("shop.sku", sku)
        span.set_attribute("shop.quantity", qty)
        if sku not in PRODUCTS:
            span.set_attribute("http.response.status_code", 404)
            log.info("unknown product", extra={"fields": {"sku": sku}})
            return {"error": f"no product {sku}"}, 404
        total = PRODUCTS[sku] * qty
        span.set_attribute("shop.total_cents", total)

        headers = {}
        propagate.inject(headers)
        try:
            answer = requests.post(
                f"{ORDERS}/orders",
                json={"sku": sku, "qty": qty, "total_cents": total, "card": body["card"]},
                headers=headers,
                timeout=5,
            )
        except requests.RequestException as e:
            span.record_exception(e)
            span.set_status(Status(StatusCode.ERROR, "orders unreachable"))
            span.set_attribute("http.response.status_code", 503)
            log.error("orders unreachable", extra={"fields": {"error": str(e)}})
            return {"error": "try again later"}, 503

        span.set_attribute("http.response.status_code", answer.status_code)
        if answer.status_code >= 500:
            span.set_status(Status(StatusCode.ERROR, f"orders answered {answer.status_code}"))
            log.error("checkout failed", extra={"fields": {"sku": sku, "orders_status": answer.status_code}})
            return {"error": "try again later"}, 502
        order = answer.json()
        log.info("checkout finished", extra={"fields": {
            "sku": sku, "order_id": order.get("id"), "outcome": order.get("status")}})
        return order, answer.status_code
```

`orders` stores the order, asks `payments` to charge it and puts a paid order on the queue. It has
almost no OpenTelemetry code, because it runs under `opentelemetry-instrument`, which lesson 3 is
about:

`~/shop/services/orders/app.py`

```python
"""Orders: stores an order, asks payments to charge it, and announces it.

It runs under opentelemetry-instrument, which instruments Flask, requests and
psycopg for it. The only OpenTelemetry code in the file is the two lines in
publish() that carry the trace into the message, because nothing instruments
the queue client here.
"""
import json
import os

import pika
import psycopg
import requests
from flask import Flask, request
from opentelemetry import propagate

from common import logs, web

DB = os.environ.get("DATABASE_URL", "postgresql://shop:shop@postgres/shop")
PAYMENTS = os.environ.get("PAYMENTS_URL", "http://payments:8082")
RABBIT = os.environ.get("RABBIT_HOST", "rabbitmq")

log = logs.setup()
app = Flask(__name__)
web.measure(app)


def db():
    return psycopg.connect(DB, autocommit=True)


def publish(order):
    headers = {}
    propagate.inject(headers)
    with pika.BlockingConnection(pika.ConnectionParameters(RABBIT)) as conn:
        channel = conn.channel()
        channel.queue_declare("orders.placed", durable=True)
        channel.basic_publish(
            exchange="",
            routing_key="orders.placed",
            body=json.dumps(order),
            properties=pika.BasicProperties(headers=headers, delivery_mode=2),
        )


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/ready")
def ready():
    """Ready to take an order: the database answers and the broker takes a connection."""
    checks = {}
    try:
        with psycopg.connect(DB, connect_timeout=2) as conn:
            conn.execute("SELECT 1")
        checks["postgres"] = "ok"
    except psycopg.Error as e:
        checks["postgres"] = type(e).__name__
    try:
        params = pika.ConnectionParameters(RABBIT, socket_timeout=2, connection_attempts=1)
        with pika.BlockingConnection(params):
            checks["rabbitmq"] = "ok"
    except pika.exceptions.AMQPError as e:
        checks["rabbitmq"] = type(e).__name__
    ok = all(v == "ok" for v in checks.values())
    return {"ready": ok, "checks": checks}, 200 if ok else 503


@app.post("/orders")
def create():
    body = request.get_json()
    traceparent = request.headers.get("traceparent")
    with db() as conn:
        order_id = conn.execute(
            "INSERT INTO orders (sku, qty, total_cents, status, traceparent)"
            " VALUES (%s, %s, %s, 'pending', %s) RETURNING id",
            (body["sku"], body["qty"], body["total_cents"], traceparent),
        ).fetchone()[0]
        charge = requests.post(
            f"{PAYMENTS}/charge",
            json={"order_id": order_id, "amount_cents": body["total_cents"], "card": body["card"]},
            timeout=3,
        )
        if charge.status_code >= 500:
            conn.execute("UPDATE orders SET status = 'failed' WHERE id = %s", (order_id,))
            log.error("payment failed", extra={"fields": {"order_id": order_id, "payments_status": charge.status_code}})
            return {"id": order_id, "status": "failed"}, 502
        status = "paid" if charge.json()["approved"] else "declined"
        conn.execute("UPDATE orders SET status = %s WHERE id = %s", (status, order_id))
    order = {"id": order_id, "sku": body["sku"], "qty": body["qty"], "status": status}
    if status == "paid":
        publish(order)
    log.info("order stored", extra={"fields": {"order_id": order_id, "status": status}})
    return order, 201 if status == "paid" else 402


@app.get("/orders")
def listing():
    since = request.args.get("since", "1970-01-01")
    with db() as conn:
        rows = conn.execute(
            "SELECT id, sku, qty, total_cents, status, traceparent, created_at FROM orders"
            " WHERE created_at >= %s ORDER BY id",
            (since,),
        ).fetchall()
    return [
        {"id": r[0], "sku": r[1], "qty": r[2], "total_cents": r[3], "status": r[4],
         "traceparent": r[5], "created_at": r[6].isoformat()}
        for r in rows
    ]
```

`payments` decides whether a card is charged. **It can be told to misbehave**: it reads
`faults/payments.json` on every charge, and that file is how the lessons make it slow or make it
fail. With no such file it behaves:

`~/shop/services/payments/app.py`

```python
"""Payments: approves or declines a charge. Instrumented by hand.

It can be told to misbehave: /faults/payments.json is read on every request.
  {"latency_ms": 800}   every charge waits that long before answering
  {"fail_every": 20}    every twentieth charge answers 503
  {"slow_every": 25, "slow_ms": 1500}
                        every twenty-fifth charge waits that much longer
"""
import itertools
import json
import os
import time

from flask import Flask, request
from opentelemetry import propagate, trace
from opentelemetry.trace import SpanKind, Status, StatusCode
from prometheus_client import Counter

from common import logs, tracing, web

VERSION = os.environ.get("SHOP_VERSION", "1.4.0")
DECLINED_CARDS = {"4000000000000002"}

log = logs.setup()
tracer = tracing.setup("payments", VERSION)
app = Flask(__name__)
web.measure(app)
CHARGES = Counter("payments_charges", "Charges decided, by outcome.", ["outcome"])
counter = itertools.count(1)


def faults():
    try:
        with open("/faults/payments.json") as f:
            return json.load(f)
    except FileNotFoundError:
        return {}


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/charge")
def charge():
    ctx = propagate.extract(request.headers)
    with tracer.start_as_current_span("POST /charge", context=ctx, kind=SpanKind.SERVER) as span:
        n = next(counter)
        body = request.get_json()
        span.set_attribute("http.request.method", "POST")
        span.set_attribute("http.route", "/charge")
        span.set_attribute("shop.order_id", body["order_id"])
        span.set_attribute("shop.amount_cents", body["amount_cents"])
        fault = faults()
        wait_ms = fault.get("latency_ms", 0)
        if fault.get("slow_every") and n % fault["slow_every"] == 0:
            wait_ms += fault.get("slow_ms", 0)
        if wait_ms:
            with tracer.start_as_current_span("wait for the card network"):
                time.sleep(wait_ms / 1000)
        if fault.get("fail_every") and n % fault["fail_every"] == 0:
            span.set_status(Status(StatusCode.ERROR, "card network unavailable"))
            span.set_attribute("http.response.status_code", 503)
            CHARGES.labels("error").inc()
            log.error("card network unavailable", extra={"fields": {"order_id": body["order_id"]}})
            return {"error": "card network unavailable"}, 503
        approved = body["card"].replace(" ", "") not in DECLINED_CARDS
        span.set_attribute("shop.approved", approved)
        span.set_attribute("http.response.status_code", 200)
        CHARGES.labels("approved" if approved else "declined").inc()
        log.info("charge decided", extra={"fields": {
            "order_id": body["order_id"], "approved": approved}})
        return {"approved": approved}
```

`mailer` takes each paid order off the queue and logs the confirmation it would have sent:

`~/shop/services/mailer/worker.py`

```python
"""Mailer: takes each paid order off the queue and sends the confirmation.

The e-mail is not really sent; the line it would have carried is logged.
"""
import json
import os
import time

import pika
from opentelemetry import propagate
from opentelemetry.trace import SpanKind
from prometheus_client import Counter, start_http_server

from common import logs, tracing

VERSION = os.environ.get("SHOP_VERSION", "1.4.0")
log = logs.setup()
tracer = tracing.setup("mailer", VERSION)
SENT = Counter("mailer_messages", "Order messages handled.", ["outcome"])


def handle(channel, method, properties, body):
    ctx = propagate.extract(properties.headers or {})
    with tracer.start_as_current_span("orders.placed process", context=ctx, kind=SpanKind.CONSUMER) as span:
        order = json.loads(body)
        span.set_attribute("messaging.system", "rabbitmq")
        span.set_attribute("messaging.destination.name", "orders.placed")
        span.set_attribute("shop.order_id", order["id"])
        with tracer.start_as_current_span("send confirmation"):
            time.sleep(0.02)
            log.info("confirmation sent", extra={"fields": {"order_id": order["id"]}})
        SENT.labels("sent").inc()
        channel.basic_ack(method.delivery_tag)


def main():
    start_http_server(9102)
    while True:
        try:
            conn = pika.BlockingConnection(pika.ConnectionParameters(os.environ.get("RABBIT_HOST", "rabbitmq")))
            channel = conn.channel()
            channel.queue_declare("orders.placed", durable=True)
            channel.basic_consume("orders.placed", handle)
            log.info("waiting for orders")
            channel.start_consuming()
        except pika.exceptions.AMQPConnectionError:
            log.warning("rabbitmq not reachable, retrying in 2 s")
            time.sleep(2)


if __name__ == "__main__":
    main()
```

## Three programs that are not services

`report` is the nightly job of lesson 4. Nothing calls it; it runs, counts yesterday's orders and
leaves:

`~/shop/services/report/job.py`

```python
"""The nightly report: run once by a scheduler, never by a request.

It has no caller, so its trace starts here. Each order it counts was created by
a request with a trace of its own, and the report links to those.

It is gone before Prometheus could scrape it, so it pushes its metrics to the
Pushgateway on the way out, and Prometheus scrapes them there.
"""
import os
import sys

import requests
from opentelemetry import trace
from opentelemetry.trace import Link, SpanContext, TraceFlags
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway

from common import logs, tracing

VERSION = os.environ.get("SHOP_VERSION", "1.4.0")
log = logs.setup()
tracer = tracing.setup("report", VERSION)


def link_to(traceparent):
    _, trace_id, span_id, flags = traceparent.split("-")
    return Link(SpanContext(int(trace_id, 16), int(span_id, 16), is_remote=True,
                            trace_flags=TraceFlags(int(flags, 16))))


def main(since):
    orders = requests.get(f"{os.environ.get('ORDERS_URL', 'http://orders:8081')}/orders",
                          params={"since": since}, timeout=10).json()
    links = [link_to(o["traceparent"]) for o in orders if o["traceparent"]][:100]
    with tracer.start_as_current_span("nightly report", links=links) as span:
        paid = [o for o in orders if o["status"] == "paid"]
        span.set_attribute("report.orders", len(orders))
        span.set_attribute("report.paid", len(paid))
        log.info("report written", extra={"fields": {
            "orders": len(orders), "paid": len(paid),
            "revenue_cents": sum(o["total_cents"] for o in paid)}})
    registry = CollectorRegistry()
    Gauge("report_orders", "Orders the last report counted.", registry=registry).set(len(orders))
    Gauge("report_last_success_timestamp_seconds", "When the report last finished.",
          registry=registry).set_to_current_time()
    push_to_gateway(os.environ.get("PUSHGATEWAY", "pushgateway:9091"), job="report", registry=registry)
    trace.get_tracer_provider().shutdown()


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "1970-01-01")
```

`loadgen` plays customers. **The lessons run it whenever a signal needs more than one request in
it**, always with the rate and the duration written in the command:

`~/shop/services/loadgen/load.py`

```python
"""Customers, simulated: a fixed mix of browsing and checkouts at a steady rate.

  python -m loadgen.load RATE SECONDS     e.g. 5 60: five requests a second for a minute

The mix repeats every 20 requests, so two runs of the same length send the same
requests: 2 product listings, 17 checkouts with a good card and 1 with a card
that is declined.
"""
import collections
import sys
import time
from concurrent.futures import ThreadPoolExecutor

import requests

URL = "http://storefront:8080"
SKUS = ["tea-500g", "mug-blue", "kettle"]
GOOD, DECLINED = "4111 1111 1111 1111", "4000 0000 0000 0002"


def request_number(n, http):
    if n % 10 == 0:
        return http.get(f"{URL}/products", timeout=10)
    card = DECLINED if n % 20 == 7 else GOOD
    return http.post(f"{URL}/checkout", timeout=10,
                        json={"sku": SKUS[n % 3], "qty": 1 + n % 2, "card": card})


def one(n):
    try:
        return request_number(n, requests).status_code
    except requests.RequestException:
        return "no answer"


def main(rate, seconds):
    start = time.monotonic()
    with ThreadPoolExecutor(16) as pool:
        answers = []
        for n in range(int(rate * seconds)):
            time.sleep(max(0, start + n / rate - time.monotonic()))
            answers.append(pool.submit(one, n))
    counts = collections.Counter(a.result() for a in answers)
    print(" ".join(f"{k}={v}" for k, v in sorted(counts.items(), key=str)))


if __name__ == "__main__":
    main(float(sys.argv[1]), float(sys.argv[2]))
```

`pager` is where Alertmanager sends an alert, in lesson 16 and after. A real team's would be a
paging service or a phone; this one writes a line:

`~/shop/services/pager/app.py`

```python
"""The lab's pager: Alertmanager's webhooks land here, and each alert becomes a line.

/page is what would wake somebody, and /ticket what would wait for the morning.
In production the first would be PagerDuty, Opsgenie or a phone, and the second
a queue of tickets; here both are a log.
"""
from flask import Flask, request

from common import logs

log = logs.setup()
app = Flask(__name__)


def record(kind):
    note = request.get_json()
    for alert in note["alerts"]:
        log.warning(kind, extra={"fields": {
            "status": alert["status"],
            "alertname": alert["labels"].get("alertname"),
            "severity": alert["labels"].get("severity"),
            "summary": alert["annotations"].get("summary"),
            "receiver": note["receiver"],
        }})
    return {"ok": True}


@app.post("/page")
def page():
    return record("PAGE")


@app.post("/ticket")
def ticket():
    return record("TICKET")
```

## The one table

`orders` keeps its orders in PostgreSQL, in one table that the database creates the first time it
starts:

`~/shop/postgres-init.sql`

```sql
CREATE TABLE orders (
  id          bigserial PRIMARY KEY,
  sku         text NOT NULL,
  qty         integer NOT NULL,
  total_cents integer NOT NULL,
  status      text NOT NULL,
  traceparent text,
  created_at  timestamptz NOT NULL DEFAULT now()
);
```
