---
title: O Collector, e a pilha inteira
version: 1
---

O Collector é configurado como **pipelines**: cada um pega telemetria de alguns **receptores**
(*receivers*), passa por **processadores** e entrega a alguns **exportadores**. Salve isto como
`collector.yaml`:

```yaml
# collector.yaml
receivers:
  otlp:
    protocols:
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 1s

exporters:
  otlp:
    endpoint: jaeger:4317
    tls:
      insecure: true
  debug:
    verbosity: basic

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [otlp, debug]
```

- O **receptor `otlp`** escuta OTLP por HTTP na porta 4318, que é para onde o `telemetry.py` manda.
- O **processador `batch`** agrupa spans por até um segundo antes de passá-los adiante, para que o
  back end receba pedidos em menor número e maiores.
- Dois **exportadores**: o `otlp` encaminha todo span ao Jaeger pela forma gRPC do OTLP, sem TLS
  porque nunca sai da rede do laboratório; o `debug` escreve uma linha no log do próprio Collector
  para cada lote, que é como ver que os spans estão chegando.
- O **pipeline `traces`** os liga. Um segundo pipeline para métricas ou logs seria mais algumas
  linhas, com os próprios receptores e exportadores.

Trocar o back end, para o Tempo, o Zipkin ou um serviço hospedado, é uma mudança nos `exporters`
daqui, e nada mais na bilheteria se mexe.

## A pilha

O `compose.yaml` ganha três serviços: o payments, o Collector e o Jaeger, cuja página é publicada na
porta 16686. A bilheteria ganha duas variáveis que a seção 10 usa. O arquivo inteiro:

```yaml
# compose.yaml
services:
  db:
    image: postgres:16.15
    environment:
      POSTGRES_USER: tickets
      POSTGRES_PASSWORD: tickets
      POSTGRES_DB: tickets
    volumes:
      - ./schema.sql:/docker-entrypoint-initdb.d/1-schema.sql:ro
      - ./replication.sh:/docker-entrypoint-initdb.d/2-replication.sh:ro
    networks:
      default:
      replication:
        aliases: [primary]
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "tickets"]
      interval: 2s
      retries: 15

  replica:
    image: postgres:16.15
    user: postgres
    environment:
      PGPASSWORD: replicator
      PGDATA: /var/lib/postgresql/replica
      DELAY: ${DELAY:-0}
    command:
      - bash
      - -c
      - |
        until pg_basebackup -h primary -U replicator -D "$$PGDATA" -R -X stream; do sleep 1; done
        exec postgres -c recovery_min_apply_delay="$$DELAY"
    networks:
      - default
      - replication
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "tickets"]
      interval: 2s
      retries: 15
    depends_on:
      db:
        condition: service_healthy

  app:
    build: .
    environment:
      DATABASE_URL: postgresql://tickets:tickets@db/tickets
      REPLICA_URL: postgresql://tickets:tickets@replica/tickets
      OTEL_TRACES_SAMPLER: ${SAMPLER:-parentbased_always_on}
      OTEL_TRACES_SAMPLER_ARG: ${SAMPLER_ARG:-1}
    cpus: 1
    depends_on:
      db:
        condition: service_healthy
      replica:
        condition: service_healthy

  payments:
    build: .
    command: ["python", "payments.py"]

  collector:
    image: otel/opentelemetry-collector:0.162.0
    volumes:
      - ./collector.yaml:/etc/otelcol/config.yaml:ro

  jaeger:
    image: jaegertracing/jaeger:2.22.0
    ports:
      - "127.0.0.1:16686:16686"

  prometheus:
    image: prom/prometheus:v3.15.0
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
    ports:
      - "127.0.0.1:9090:9090"

  lb:
    image: nginx:1.27.5
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    ports:
      - "127.0.0.1:8080:80"
    depends_on:
      - app

networks:
  replication:
```

Reconstrua a imagem e suba tudo:

```
ana@lab:~/tickets$ docker compose build -q
 Image tickets-payments Building 
 Image tickets-app Building 
 Image tickets-app Built 
 Image tickets-payments Built 
ana@lab:~/tickets$ docker compose up -d
 Network tickets_replication Creating 
 Network tickets_replication Creating 
 Network tickets_default Creating 
 Network tickets_default Creating 
 Network tickets_replication Created 
 Network tickets_replication Created 
 Network tickets_default Created 
 Network tickets_default Created 
 Container tickets-prometheus-1 Creating 
 Container tickets-jaeger-1 Creating 
 Container tickets-collector-1 Creating 
 Container tickets-db-1 Creating 
 Container tickets-payments-1 Creating 
 Container tickets-collector-1 Created 
 Container tickets-prometheus-1 Created 
 Container tickets-jaeger-1 Created 
 Container tickets-payments-1 Created 
 Container tickets-db-1 Created 
 Container tickets-replica-1 Creating 
 Container tickets-replica-1 Created 
 Container tickets-app-1 Creating 
 Container tickets-app-1 Created 
 Container tickets-lb-1 Creating 
 Container tickets-lb-1 Created 
 Container tickets-db-1 Starting 
 Container tickets-jaeger-1 Starting 
 Container tickets-collector-1 Starting 
 Container tickets-prometheus-1 Starting 
 Container tickets-payments-1 Starting 
 Container tickets-db-1 Started 
 Container tickets-db-1 Waiting 
 Container tickets-jaeger-1 Started 
 Container tickets-collector-1 Started 
 Container tickets-prometheus-1 Started 
 Container tickets-payments-1 Started 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Starting 
 Container tickets-replica-1 Started 
 Container tickets-db-1 Waiting 
 Container tickets-replica-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Healthy 
 Container tickets-app-1 Starting 
 Container tickets-app-1 Started 
 Container tickets-lb-1 Starting 
 Container tickets-lb-1 Started 
ana@lab:~/tickets$ docker compose ps --format "table {{.Service}}\t{{.Status}}"
SERVICE      STATUS
app          Up 10 seconds
collector    Up 15 seconds
db           Up 15 seconds (healthy)
jaeger       Up 15 seconds
lb           Up 10 seconds
payments     Up 15 seconds
prometheus   Up 15 seconds
replica      Up 13 seconds (healthy)
```

Oito serviços. O Jaeger leva alguns segundos para aceitar spans depois de subir; até lá, o exportador do
Collector guarda os spans na fila e tenta de novo, que é o padrão dele.
