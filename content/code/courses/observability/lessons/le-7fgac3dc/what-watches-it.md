---
title: What watches it, and starting it all
version: 1
---

Everything else in the lab is real, unmodified software in its official image. The OpenTelemetry
Collector receives traces and logs and forwards them. Prometheus stores metrics and Alertmanager
routes the alerts it raises. Loki stores logs, Jaeger and Zipkin store traces, and Grafana draws
all of them. The exporters turn the machine, the database and an outside probe into metrics. None
of it needs installing: **Docker downloads each image the first time it starts it**, and this page
is the configuration that tells each one what to do.

## The file that starts everything

`compose.yaml` names every container, the image it runs, the files it reads and the ports it
publishes. Three services near the end carry a `profiles` line and do not start with the rest:
Elasticsearch and Graylog belong to lesson 9 and Envoy to lesson 19, and each of those lessons says
how to start them.

`~/shop/compose.yaml`

```yaml
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

  envoy:
    image: envoyproxy/envoy:v1.39.2
    profiles: [mesh]
    command: [envoy, -c, /etc/envoy/envoy.yaml, --log-level, warn]
    volumes: ["./envoy/envoy.yaml:/etc/envoy/envoy.yaml:ro"]
    ports: ["127.0.0.1:10000:10000", "127.0.0.1:9901:9901"]

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

  elasticsearch:
    image: elasticsearch:9.5.3
    profiles: [elastic]
    environment:
      discovery.type: single-node
      xpack.security.enabled: "false"
      cluster.routing.allocation.disk.threshold_enabled: "false"
      ES_JAVA_OPTS: -Xms1g -Xmx1g
    ports: ["127.0.0.1:9200:9200"]

  mongo:
    image: mongo:8.0
    profiles: [graylog]

  opensearch:
    image: opensearchproject/opensearch:2.19.6
    profiles: [graylog]
    environment:
      discovery.type: single-node
      DISABLE_SECURITY_PLUGIN: "true"
      DISABLE_INSTALL_DEMO_CONFIG: "true"
      cluster.routing.allocation.disk.threshold_enabled: "false"
      OPENSEARCH_JAVA_OPTS: -Xms512m -Xmx512m

  graylog:
    image: graylog/graylog:7.0.13
    profiles: [graylog]
    env_file: [.graylog.env]
    environment:
      GRAYLOG_HTTP_EXTERNAL_URI: http://127.0.0.1:9000/
      GRAYLOG_ELASTICSEARCH_HOSTS: http://opensearch:9200
      GRAYLOG_MONGODB_URI: mongodb://mongo:27017/graylog
    depends_on: [mongo, opensearch]
    ports: ["127.0.0.1:9000:9000"]
```

Two settings in it hold the lab together. **Every shop container sends its output to the
Collector** through Docker's `fluentd` logging driver, so its log lines reach Loki without the
service knowing Loki exists. And **every port is published on `127.0.0.1` only**. From a
shell on the lab machine `localhost:8080` is the shop and `localhost:9090` is Prometheus, and
nothing on your network can reach any of it, nor anything on the internet if the machine is rented.

## Where the signals go

The Collector's configuration. Lesson 9 explains the part that turns Docker's log lines back into
fields, and lesson 12 changes the traces pipeline:

`~/shop/otel/collector.yaml`

```yaml
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
  # A batch from Docker mixes every container's lines under one resource, so
  # the lines are regrouped by their own "service" field, one resource each,
  # before that field becomes the resource's service.name.
  groupbyattrs/service:
    keys: [service]
  transform/service:
    error_mode: ignore
    log_statements:
      - context: resource
        statements:
          - set(attributes["service.name"], attributes["service"]) where attributes["service"] != nil
  transform/logs:
    error_mode: ignore
    log_statements:
      - context: log
        conditions:
          - IsMatch(body, "^\\{")
        statements:
          - merge_maps(attributes, ParseJSON(body), "upsert")
          - set(severity_text, attributes["level"])
          - set(trace_id.string, attributes["trace_id"]) where attributes["trace_id"] != nil
          - set(span_id.string, attributes["span_id"]) where attributes["span_id"] != nil

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
      processors: [memory_limiter, transform/logs, groupbyattrs/service, transform/service, batch]
      exporters: [otlp_http/loki]
```

Prometheus: what it scrapes, every fifteen seconds, and where its alert rules live. Lesson 5 goes
through both:

`~/shop/prometheus/prometheus.yml`

```yaml
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
```

`~/shop/prometheus/rules/shop.yml`

```yaml
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
```

Alertmanager sends every alert to the pager; lesson 16 splits them:

`~/shop/alertmanager/alertmanager.yml`

```yaml
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
```

The blackbox exporter probes the shop from the outside, the way a customer would. Lesson 14 uses the
second module:

`~/shop/blackbox.yml`

```yaml
modules:
  http_2xx:
    prober: http
    timeout: 5s
  # A synthetic checkout (lesson 14): the path a customer takes, not a
  # health endpoint. Every probe is a real order of one kettle.
  checkout:
    prober: http
    timeout: 5s
    http:
      method: POST
      headers:
        Content-Type: application/json
      body: '{"sku": "kettle", "qty": 1, "card": "4111 1111 1111 1111"}'
      valid_status_codes: [201]
```

Loki, in the smallest configuration that keeps a week of logs on the local disk. Lesson 10 is about
the last block:

`~/shop/loki/loki.yaml`

```yaml
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
```

And Grafana's two provisioning files: where its data comes from, and where it finds dashboards.
Lesson 7 is about both:

`~/shop/grafana/provisioning/datasources/shop.yaml`

```yaml
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
```

`~/shop/grafana/provisioning/dashboards/shop.yaml`

```yaml
apiVersion: 1
providers:
  - name: shop
    folder: Shop
    type: file
    options:
      path: /var/lib/grafana/dashboards
```

Grafana also needs an administrator's password, which `compose.yaml` reads from a file so that it
is written down nowhere else. This makes one up and saves it:

```sh
openssl rand -hex 12 > ~/shop/.grafana-password
```

## Starting it

```sh
cd ~/shop
docker compose up -d --build
```

`--build` builds the shop's image from the `Dockerfile` before starting anything. **The first time
takes a while**: Docker downloads every image, about a gigabyte and a half of them, and installs
the Python packages into the shop's. After that a start takes seconds. When it returns, every container is
running:

```
ana@obs:~/shop$ docker compose ps --format 'table {{.Service}}\t{{.Image}}' | sort
SERVICE             IMAGE
alertmanager        prom/alertmanager:v0.34.1
blackbox-exporter   prom/blackbox-exporter:v0.28.0
grafana             grafana/grafana:13.0.10
jaeger              jaegertracing/jaeger:2.21.0
loki                grafana/loki:3.7.8
mailer              shop:1.4.0
node-exporter       prom/node-exporter:v1.12.1
orders              shop:1.4.0
otel-collector      otel/opentelemetry-collector-contrib:0.161.0
pager               shop:1.4.0
payments            shop:1.4.0
postgres            postgres:16.15
postgres-exporter   prometheuscommunity/postgres-exporter:v0.20.1
prometheus          prom/prometheus:v3.15.0
pushgateway         prom/pushgateway:v1.11.3
rabbitmq            rabbitmq:4.2-management
storefront          shop:1.4.0
zipkin              openzipkin/zipkin:3.6.1
```

**The mailer is the last to be ready**, a few seconds after the rest, because it waits for RabbitMQ
to accept a connection; `docker compose logs mailer` says `waiting for orders` once it is.

## Starting again from nothing

Every lesson's transcripts begin from a lab that has just been started from empty volumes, so **what
you see after these three commands is what the lesson shows**:

```sh
cd ~/shop
docker compose --profile '*' down -v
docker compose up -d
```

`down -v` stops every container and deletes their volumes, which is every metric, log line, trace
and order the lab has stored; `--profile '*'` includes the ones lessons 9 and 19 start. The files in
`~/shop` stay as they are. A lesson that edits one says how to put it back at its end. The exceptions
to "what the lesson shows" are the parts that are different on every run: dates, durations to the
millisecond, and the random ids every trace gets.
