---
title: O que a vigia, e como subir tudo
version: 1
---

Todo o resto do laboratório é software real, sem modificações, na sua imagem oficial. O
OpenTelemetry Collector recebe traces e logs e os encaminha. O Prometheus guarda métricas e o
Alertmanager encaminha os alertas que ele dispara. O Loki guarda logs, o Jaeger e o Zipkin guardam
traces, e o Grafana desenha todos eles. Os exporters transformam a máquina, o banco de dados e uma
sonda externa em métricas. Nada disso precisa ser instalado: **o Docker baixa cada imagem na
primeira vez que a sobe**, e esta página é a configuração que diz a cada uma o que fazer.

## O arquivo que sobe tudo

O `compose.yaml` dá nome a cada contêiner, à imagem que ele roda, aos arquivos que lê e às portas que
publica. Três serviços perto do fim têm uma linha `profiles` e não sobem com o resto: o
Elasticsearch e o Graylog são da aula 9 e o Envoy é da aula 19, e cada uma dessas aulas diz como
subi-los.

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

Duas configurações nele seguram o laboratório. **Todo contêiner da loja manda sua saída para o
Collector** pelo driver de log `fluentd` do Docker, então as linhas de log chegam ao Loki sem que o
serviço saiba que o Loki existe. E **toda porta é publicada só em `127.0.0.1`**. De um shell
na máquina do laboratório, `localhost:8080` é a loja e `localhost:9090` é o Prometheus, e nada na sua
rede alcança qualquer parte disso, nem nada na internet se a máquina for alugada.

## Para onde os sinais vão

A configuração do Collector. A aula 9 explica a parte que transforma as linhas de log do Docker de
volta em campos, e a aula 12 muda o pipeline de traces:

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

O Prometheus: o que ele coleta, a cada quinze segundos, e onde ficam as regras de alerta. A aula 5
percorre as duas coisas:

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

O Alertmanager manda todo alerta para o pager; a aula 16 os separa:

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

O blackbox exporter sonda a loja de fora, do jeito que um cliente faria. A aula 14 usa o segundo
módulo:

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

O Loki, na menor configuração que guarda uma semana de logs no disco local. A aula 10 é sobre o
último bloco:

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

E os dois arquivos de provisionamento do Grafana: de onde vêm os dados dele, e onde ele encontra os
dashboards. A aula 7 é sobre os dois:

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

O Grafana também precisa de uma senha de administrador, que o `compose.yaml` lê de um arquivo para
que ela não fique escrita em nenhum outro lugar. Isto inventa uma e a salva:

```sh
openssl rand -hex 12 > ~/shop/.grafana-password
```

## Subindo

```sh
cd ~/shop
docker compose up -d --build
```

O `--build` constrói a imagem da loja a partir do `Dockerfile` antes de subir qualquer coisa. **A
primeira vez demora**: o Docker baixa todas as imagens, cerca de um gigabyte e meio, e instala os
pacotes Python na da loja. Depois disso, subir leva segundos. Quando o comando volta, todos os
contêineres estão rodando:

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

**O mailer é o último a ficar pronto**, alguns segundos depois do resto, porque espera o RabbitMQ
aceitar uma conexão; `docker compose logs mailer` diz `waiting for orders` quando está.

## Começando de novo do zero

As transcrições de toda aula partem de um laboratório que acabou de subir com volumes vazios, então
**o que você vê depois destes três comandos é o que a aula mostra**:

```sh
cd ~/shop
docker compose --profile '*' down -v
docker compose up -d
```

O `down -v` para todos os contêineres e apaga os volumes deles, que são todas as métricas, linhas
de log, traces e pedidos que o laboratório guardou; o `--profile '*'` inclui os que as aulas 9 e 19
sobem. Os arquivos em `~/shop` ficam como estão. Uma aula que edita um deles diz como devolvê-lo
ao que era no final. As exceções a "o que a aula mostra" são as partes que mudam a cada execução:
datas, durações em milissegundos e os ids aleatórios que todo trace recebe.
