#!/usr/bin/env bash
# The machine every transcript in the observability course was recorded on.
#
# IT IS ONE LINUX COMPUTER RUNNING DOCKER. The shop the course instruments is
# five small Python services and a nightly job, written for this course and
# printed in full below; everything that watches it is real, unmodified
# open-source software, each in the official image named beside it:
#
#   the shop (written for the course, image shop:1.4.0 built from python:3.12-slim)
#     storefront   where a checkout arrives; instrumented by hand (lesson 2)
#     orders       stores the order; no telemetry code, run under
#                  opentelemetry-instrument (lesson 3)
#     payments     approves or declines a charge; can be told to be slow or
#                  to fail through faults/payments.json
#     mailer       takes paid orders off a RabbitMQ queue (lesson 4)
#     report       the nightly job, run by hand with `docker compose run`
#     loadgen      simulated customers: a fixed mix of 20 requests, repeated
#     sandbox      the same image, for running the small scripts in ~/shop/scratch
#     pager        Alertmanager's webhook lands here and becomes a log line
#   what it runs on
#     postgres 16.15, rabbitmq 4.2
#   what watches it
#     OpenTelemetry Collector contrib 0.161.0, Prometheus 3.15.0,
#     Alertmanager 0.34.1, Pushgateway 1.11.3, node_exporter 1.12.1,
#     postgres_exporter 0.20.1,
#     blackbox_exporter 0.28.0, Grafana 13.0.10, Loki 3.7.8, Jaeger 2.21.0,
#     Zipkin 3.6.1
#   and, only in the lessons that need them (compose profiles)
#     elastic      Elasticsearch 9.5.3 (lesson 9)
#     graylog      Graylog 7.0.13, MongoDB 8.0, OpenSearch 2.19.6 (lesson 9)
#     mesh         Envoy 1.39.2 (lesson 19)
#   and a Kubernetes cluster for lessons 14 and 19: kind 0.33.0, node v1.37.0
#
# Every port is published on 127.0.0.1 only. Nothing here reaches the internet
# once the images and the Python wheels are downloaded.
#
#   sudo bash lab.sh up           write ~/shop, build the image, start it all
#   sudo bash lab.sh reset        stop it, delete every volume, start again
#   sudo bash lab.sh down
#   sudo bash lab.sh as 'cmd'     run a command as ana, in ~/shop
#   sudo bash lab.sh up PROFILE   also start a profile: elastic, graylog, mesh
#   sudo bash lab.sh kind-up | kind-down
#
# Recorded on Ubuntu 24.04 with Docker Engine 29.6 and Compose 5.3,
# TZ=America/Sao_Paulo. The machine needs 4 CPUs and 8 GB of memory, and
# 16 GB while the graylog profile runs.
set -euo pipefail

USER_LAB=ana
SHOP=/home/$USER_LAB/shop
export TZ=America/Sao_Paulo

as_ana() { su - "$USER_LAB" -c "cd $SHOP && $*"; }

write_files() {
  mkdir -p "$SHOP/faults" "$SHOP/grafana/dashboards" "$SHOP/scratch"
  mkdir -p "$SHOP/."
  cat > "$SHOP/Dockerfile" <<'LABFILE'
FROM python:3.12-slim
COPY wheels /wheels
COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir --no-index --find-links /wheels -r /requirements.txt \
 && opentelemetry-bootstrap --action=requirements | grep -q . || true
COPY services /app
WORKDIR /app
ENV PYTHONUNBUFFERED=1 PYTHONPATH=/app
LABFILE
  mkdir -p "$SHOP/alertmanager"
  cat > "$SHOP/alertmanager/alertmanager.yml" <<'LABFILE'
route:
  receiver: pager
  group_by: [alertname, job]
  group_wait: 10s
  group_interval: 1m
  repeat_interval: 4h

receivers:
  - name: pager
    webhook_configs:
      - url: http://pager:8090/page
LABFILE
  mkdir -p "$SHOP/."
  cat > "$SHOP/blackbox.yml" <<'LABFILE'
modules:
  http_2xx:
    prober: http
    timeout: 5s
LABFILE
  mkdir -p "$SHOP/."
  cat > "$SHOP/compose.yaml" <<'LABFILE'
# The shop, and everything that watches it. One machine, one command:
#   docker compose up -d
# The shop's code is mounted from ./services, so an edit takes effect on
# `docker compose restart <service>`, without building the image again.
name: shop

x-shop: &shop
  image: shop:1.4.0
  build: .
  restart: unless-stopped
  environment: &env
    SHOP_VERSION: 1.4.0
    OTEL_EXPORTER_OTLP_ENDPOINT: http://otel-collector:4318
  logging:
    driver: fluentd
    options:
      fluentd-address: 127.0.0.1:24224
      fluentd-async: "true"
      tag: "{{.Name}}"
  volumes: ["./services:/app:ro"]
  depends_on: [otel-collector]

services:
  storefront:
    <<: *shop
    command: waitress-serve --port 8080 --threads 16 storefront.app:app
    environment:
      <<: *env
      OTEL_SERVICE_NAME: storefront
    ports: ["127.0.0.1:8080:8080"]

  orders:
    <<: *shop
    command: opentelemetry-instrument waitress-serve --port 8081 --threads 16 orders.app:app
    environment:
      <<: *env
      OTEL_SERVICE_NAME: orders
      OTEL_TRACES_EXPORTER: otlp
      OTEL_METRICS_EXPORTER: none
      OTEL_LOGS_EXPORTER: none
      OTEL_EXPORTER_OTLP_PROTOCOL: http/protobuf
      OTEL_PYTHON_FLASK_EXCLUDED_URLS: health,metrics
    depends_on: [otel-collector, postgres, rabbitmq]

  payments:
    <<: *shop
    command: waitress-serve --port 8082 --threads 16 payments.app:app
    environment:
      <<: *env
      OTEL_SERVICE_NAME: payments
    volumes: ["./services:/app:ro", "./faults:/faults:ro"]

  mailer:
    <<: *shop
    command: python -m mailer.worker
    environment:
      <<: *env
      OTEL_SERVICE_NAME: mailer
    depends_on: [otel-collector, rabbitmq]

  report:
    <<: *shop
    profiles: [jobs]
    restart: "no"
    command: python -m report.job
    environment:
      <<: *env
      OTEL_SERVICE_NAME: report

  loadgen:
    <<: *shop
    profiles: [jobs]
    restart: "no"
    command: python -m loadgen.load 5 60
    logging: {driver: json-file}

  sandbox:
    <<: *shop
    profiles: [jobs]
    restart: "no"
    working_dir: /scratch
    volumes: ["./scratch:/scratch"]
    environment:
      <<: *env
      OTEL_SERVICE_NAME: sandbox
    logging: {driver: json-file}
    command: python

  pager:
    <<: *shop
    command: waitress-serve --port 8090 pager.app:app
    environment:
      <<: *env
      OTEL_SERVICE_NAME: pager

  postgres:
    image: postgres:16.15
    environment:
      POSTGRES_USER: shop
      POSTGRES_PASSWORD: shop
    volumes: ["./postgres-init.sql:/docker-entrypoint-initdb.d/init.sql:ro"]

  rabbitmq:
    image: rabbitmq:4.2-management
    ports: ["127.0.0.1:15672:15672"]

  otel-collector:
    image: otel/opentelemetry-collector-contrib:0.161.0
    command: ["--config=/etc/otelcol/config.yaml"]
    volumes: ["./otel/collector.yaml:/etc/otelcol/config.yaml:ro"]
    ports: ["127.0.0.1:24224:24224", "127.0.0.1:4318:4318"]

  prometheus:
    image: prom/prometheus:v3.15.0
    command: [--config.file=/etc/prometheus/prometheus.yml, --web.enable-lifecycle,
              --storage.tsdb.path=/prometheus]
    volumes: ["./prometheus:/etc/prometheus:ro"]
    ports: ["127.0.0.1:9090:9090"]

  alertmanager:
    image: prom/alertmanager:v0.34.1
    command: [--config.file=/etc/alertmanager/alertmanager.yml]
    volumes: ["./alertmanager:/etc/alertmanager:ro"]
    ports: ["127.0.0.1:9093:9093"]

  pushgateway:
    image: prom/pushgateway:v1.11.3

  node-exporter:
    image: prom/node-exporter:v1.12.1

  postgres-exporter:
    image: prometheuscommunity/postgres-exporter:v0.20.1
    environment:
      DATA_SOURCE_NAME: postgresql://shop:shop@postgres:5432/shop?sslmode=disable

  blackbox-exporter:
    image: prom/blackbox-exporter:v0.28.0
    command: [--config.file=/etc/blackbox.yml]
    volumes: ["./blackbox.yml:/etc/blackbox.yml:ro"]

  grafana:
    image: grafana/grafana:13.0.10
    environment:
      GF_SECURITY_ADMIN_PASSWORD__FILE: /run/secrets/grafana
      GF_ANALYTICS_REPORTING_ENABLED: "false"
      GF_ANALYTICS_CHECK_FOR_UPDATES: "false"
      GF_NEWS_NEWS_FEED_ENABLED: "false"
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
      - ./grafana/dashboards:/var/lib/grafana/dashboards:ro
      - ./.grafana-password:/run/secrets/grafana:ro
    ports: ["127.0.0.1:3000:3000"]

  loki:
    image: grafana/loki:3.7.8
    command: [-config.file=/etc/loki/loki.yaml]
    volumes: ["./loki/loki.yaml:/etc/loki/loki.yaml:ro"]
    ports: ["127.0.0.1:3100:3100"]

  jaeger:
    image: jaegertracing/jaeger:2.21.0
    ports: ["127.0.0.1:16686:16686"]

  zipkin:
    image: openzipkin/zipkin:3.6.1
    ports: ["127.0.0.1:9411:9411"]
LABFILE
  mkdir -p "$SHOP/grafana/provisioning/dashboards"
  cat > "$SHOP/grafana/provisioning/dashboards/shop.yaml" <<'LABFILE'
apiVersion: 1
providers:
  - name: shop
    folder: Shop
    type: file
    options:
      path: /var/lib/grafana/dashboards
LABFILE
  mkdir -p "$SHOP/grafana/provisioning/datasources"
  cat > "$SHOP/grafana/provisioning/datasources/shop.yaml" <<'LABFILE'
apiVersion: 1
datasources:
  - name: Prometheus
    uid: prometheus
    type: prometheus
    url: http://prometheus:9090
    isDefault: true
  - name: Loki
    uid: loki
    type: loki
    url: http://loki:3100
  - name: Jaeger
    uid: jaeger
    type: jaeger
    url: http://jaeger:16686
LABFILE
  mkdir -p "$SHOP/loki"
  cat > "$SHOP/loki/loki.yaml" <<'LABFILE'
auth_enabled: false

server:
  http_listen_port: 3100
  log_level: warn

common:
  instance_addr: 127.0.0.1
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2026-01-01
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

limits_config:
  allow_structured_metadata: true
  retention_period: 168h

compactor:
  working_directory: /loki/compactor
  retention_enabled: true
  delete_request_store: filesystem
LABFILE
  mkdir -p "$SHOP/otel"
  cat > "$SHOP/otel/collector.yaml" <<'LABFILE'
# The OpenTelemetry Collector: every trace and every log line of the shop
# passes through here on its way to where it is stored.
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  fluent_forward:
    endpoint: 0.0.0.0:24224

processors:
  memory_limiter:
    check_interval: 1s
    limit_mib: 400
  batch: {}
  transform/logs:
    error_mode: ignore
    log_statements:
      - context: log
        conditions:
          - IsMatch(body, "^\\{")
        statements:
          - merge_maps(attributes, ParseJSON(body), "upsert")
          - set(severity_text, attributes["level"])
          - set(resource.attributes["service.name"], attributes["service"])

exporters:
  debug:
    verbosity: basic
  otlp_grpc/jaeger:
    endpoint: jaeger:4317
    tls:
      insecure: true
  zipkin:
    endpoint: http://zipkin:9411/api/v2/spans
  otlp_http/loki:
    endpoint: http://loki:3100/otlp

service:
  telemetry:
    metrics:
      readers:
        - pull:
            exporter:
              prometheus:
                host: 0.0.0.0
                port: 8888
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [otlp_grpc/jaeger, zipkin]
    logs:
      receivers: [fluent_forward]
      processors: [memory_limiter, transform/logs, batch]
      exporters: [otlp_http/loki]
LABFILE
  mkdir -p "$SHOP/."
  cat > "$SHOP/postgres-init.sql" <<'LABFILE'
CREATE TABLE orders (
  id          bigserial PRIMARY KEY,
  sku         text NOT NULL,
  qty         integer NOT NULL,
  total_cents integer NOT NULL,
  status      text NOT NULL,
  traceparent text,
  created_at  timestamptz NOT NULL DEFAULT now()
);
LABFILE
  mkdir -p "$SHOP/prometheus"
  cat > "$SHOP/prometheus/prometheus.yml" <<'LABFILE'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - /etc/prometheus/rules/*.yml

alerting:
  alertmanagers:
    - static_configs:
        - targets: [alertmanager:9093]

scrape_configs:
  - job_name: storefront
    static_configs:
      - targets: [storefront:8080]
  - job_name: orders
    static_configs:
      - targets: [orders:8081]
  - job_name: payments
    static_configs:
      - targets: [payments:8082]
  - job_name: mailer
    static_configs:
      - targets: [mailer:9102]
  - job_name: otel-collector
    static_configs:
      - targets: [otel-collector:8888]
  - job_name: pushgateway
    honor_labels: true
    static_configs:
      - targets: [pushgateway:9091]
  - job_name: node
    static_configs:
      - targets: [node-exporter:9100]
  - job_name: postgres
    static_configs:
      - targets: [postgres-exporter:9187]
  - job_name: rabbitmq
    static_configs:
      - targets: [rabbitmq:15692]
  - job_name: blackbox
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets: [http://storefront:8080/health]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115
LABFILE
  mkdir -p "$SHOP/prometheus/rules"
  cat > "$SHOP/prometheus/rules/shop.yml" <<'LABFILE'
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
LABFILE
  mkdir -p "$SHOP/."
  cat > "$SHOP/requirements.txt" <<'LABFILE'
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
LABFILE
  mkdir -p "$SHOP/services/common"
  cat > "$SHOP/services/common/__init__.py" <<'LABFILE'
LABFILE
  mkdir -p "$SHOP/services/common"
  cat > "$SHOP/services/common/logs.py" <<'LABFILE'
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
LABFILE
  mkdir -p "$SHOP/services/common"
  cat > "$SHOP/services/common/tracing.py" <<'LABFILE'
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
LABFILE
  mkdir -p "$SHOP/services/common"
  cat > "$SHOP/services/common/web.py" <<'LABFILE'
"""Rate, errors and duration for every Flask route, in Prometheus's format."""
import time

from flask import Response, g, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

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
            DURATION.labels(route, request.method).observe(time.perf_counter() - g.started)
        return response

    @app.get("/metrics")
    def metrics():
        return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)
LABFILE
  mkdir -p "$SHOP/services/loadgen"
  cat > "$SHOP/services/loadgen/load.py" <<'LABFILE'
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
LABFILE
  mkdir -p "$SHOP/services/mailer"
  cat > "$SHOP/services/mailer/worker.py" <<'LABFILE'
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
LABFILE
  mkdir -p "$SHOP/services/orders"
  cat > "$SHOP/services/orders/app.py" <<'LABFILE'
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
LABFILE
  mkdir -p "$SHOP/services/pager"
  cat > "$SHOP/services/pager/app.py" <<'LABFILE'
"""The lab's pager: Alertmanager's webhook lands here, and each alert becomes a line.

In production this would be PagerDuty, Opsgenie or a phone; here it is a log.
"""
from flask import Flask, request

from common import logs

log = logs.setup()
app = Flask(__name__)


@app.post("/page")
def page():
    note = request.get_json()
    for alert in note["alerts"]:
        log.warning("PAGE", extra={"fields": {
            "status": alert["status"],
            "alertname": alert["labels"].get("alertname"),
            "severity": alert["labels"].get("severity"),
            "summary": alert["annotations"].get("summary"),
            "receiver": note["receiver"],
        }})
    return {"ok": True}
LABFILE
  mkdir -p "$SHOP/services/payments"
  cat > "$SHOP/services/payments/app.py" <<'LABFILE'
"""Payments: approves or declines a charge. Instrumented by hand.

It can be told to misbehave: /faults/payments.json is read on every request.
  {"latency_ms": 800}   every charge waits that long before answering
  {"fail_every": 20}    every twentieth charge answers 503
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
        if fault.get("latency_ms"):
            with tracer.start_as_current_span("wait for the card network"):
                time.sleep(fault["latency_ms"] / 1000)
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
LABFILE
  mkdir -p "$SHOP/services/report"
  cat > "$SHOP/services/report/job.py" <<'LABFILE'
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
LABFILE
  mkdir -p "$SHOP/services/storefront"
  cat > "$SHOP/services/storefront/app.py" <<'LABFILE'
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
LABFILE
}

wheels() {
  # The image installs from these and from nothing else, so a build never
  # depends on the index answering on the day.
  [ -d "$SHOP/wheels" ] && return
  pip3 download -q -d "$SHOP/wheels" --python-version 3.12 --only-binary=:all: \
    --platform manylinux_2_17_x86_64 --platform manylinux2014_x86_64 \
    --platform manylinux_2_28_x86_64 -r "$SHOP/requirements.txt"
}

wait_for() {
  local what=$1 url=$2 i
  for i in $(seq 1 90); do
    curl -fs -o /dev/null "$url" && return 0
    sleep 2
  done
  echo "lab: $what did not come up at $url" >&2
  return 1
}

up() {
  id "$USER_LAB" >/dev/null 2>&1 || useradd -m -s /bin/bash -G docker "$USER_LAB"
  write_files
  wheels
  [ -f "$SHOP/.grafana-password" ] || openssl rand -hex 12 > "$SHOP/.grafana-password"
  chown -R "$USER_LAB:$USER_LAB" "$SHOP"
  local profiles=""
  for p in "$@"; do profiles+=" --profile $p"; done
  as_ana "docker compose$profiles build -q && docker compose$profiles up -d --quiet-pull" >/dev/null 2>&1
  wait_for storefront http://127.0.0.1:8080/health
  wait_for prometheus http://127.0.0.1:9090/-/ready
  wait_for loki http://127.0.0.1:3100/ready
  wait_for jaeger http://127.0.0.1:16686/
  wait_for grafana http://127.0.0.1:3000/api/health
  wait_for zipkin http://127.0.0.1:9411/health
  # the mailer connects when rabbitmq is ready, which is a few seconds later
  for i in $(seq 1 60); do
    as_ana "docker compose logs mailer" 2>/dev/null | grep -q 'waiting for orders' && break
    sleep 2
  done
}

down() { [ -d "$SHOP" ] && as_ana "docker compose --profile '*' down -v --remove-orphans" >/dev/null 2>&1 || true; }

kind_up() {
  # Two settings that only a nested machine needs, like the one this was
  # recorded on: its cgroups are v1, and a container inside it may not lower
  # its own OOM score. A cluster on an ordinary Linux machine needs neither.
  cat > /tmp/kind-lab.yaml <<'KIND'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
  - |-
    [plugins."io.containerd.cri.v1.runtime"]
      restrict_oom_score_adj = true
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: KubeletConfiguration
        failCgroupV1: false
KIND
  kind get clusters 2>/dev/null | grep -qx lab || kind create cluster --name lab --config /tmp/kind-lab.yaml >/dev/null 2>&1
  mkdir -p /home/$USER_LAB/.kube
  kind get kubeconfig --name lab > /home/$USER_LAB/.kube/config
  chown -R "$USER_LAB:$USER_LAB" /home/$USER_LAB/.kube
  kind load docker-image shop:1.4.0 --name lab >/dev/null 2>&1
}

case "${1:-}" in
  up) shift; up "$@" ;;
  reset) shift; down; rm -rf "$SHOP"; up "$@" ;;
  down) down ;;
  as) shift; as_ana "$*" ;;
  kind-up) kind_up ;;
  kind-down) kind delete cluster --name lab >/dev/null 2>&1 || true ;;
  *) sed -n '2,/^set -e/p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
