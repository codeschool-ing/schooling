---
title: Decidindo na cauda
version: 2
---

**A amostragem na cauda decide depois de o rastro terminar**, então pode decidir pelo que aconteceu. Os
serviços voltam a registrar todo rastro, e o Collector segura cada um até ele ficar completo, e então o
guarda se alguma das políticas dele mandar. A configuração que faz isso é um terceiro arquivo do Collector. Salve-o
inteiro:

`~/shop/otel/collector-sampling.yaml`

```yaml
# The Collector of collector.yaml, deciding which traces to keep (lesson 12).
# Every span still feeds the span metrics; only the traces worth reading go
# on to Jaeger and Zipkin.
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  fluent_forward:
    endpoint: 0.0.0.0:24224

connectors:
  # Rate, errors and duration per service and span name, computed from every
  # span before any of them is dropped.
  spanmetrics:
    metrics_flush_interval: 15s
    histogram:
      explicit:
        buckets: [10ms, 50ms, 100ms, 250ms, 500ms, 1s, 2.5s, 5s]

processors:
  # Wait until a trace has had time to finish, then keep it if any policy says so.
  tail_sampling:
    decision_wait: 10s
    num_traces: 20000
    policies:
      - name: errors
        type: status_code
        status_code: {status_codes: [ERROR]}
      - name: slow
        type: latency
        latency: {threshold_ms: 1000}
      - name: a-few-of-the-rest
        type: probabilistic
        probabilistic: {sampling_percentage: 5}
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
  otlp_http/prometheus:
    endpoint: http://prometheus:9090/api/v1/otlp

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
    traces/all:
      receivers: [otlp]
      processors: [memory_limiter]
      exporters: [spanmetrics]
    traces:
      receivers: [otlp]
      processors: [memory_limiter, tail_sampling, batch]
      exporters: [otlp_grpc/jaeger, zipkin]
    metrics/spans:
      receivers: [spanmetrics]
      processors: [batch]
      exporters: [otlp_http/prometheus]
    logs:
      receivers: [fluent_forward]
      processors: [memory_limiter, transform/logs, groupbyattrs/service, transform/service, batch]
      exporters: [otlp_http/loki]
```

O processor `tail_sampling` dele tem três políticas:

```
ana@obs:~/shop$ sed -n '/^  tail_sampling:/,/^  memory_limiter:/p' otel/collector-sampling.yaml
  tail_sampling:
    decision_wait: 10s
    num_traces: 20000
    policies:
      - name: errors
        type: status_code
        status_code: {status_codes: [ERROR]}
      - name: slow
        type: latency
        latency: {threshold_ms: 1000}
      - name: a-few-of-the-rest
        type: probabilistic
        probabilistic: {sampling_percentage: 5}
  memory_limiter:
```

- **`errors`**: qualquer span com status de erro guarda o rastro inteiro.
- **`slow`**: um rastro de mais de um segundo é guardado.
- **`a-few-of-the-rest`**: 5% de tudo, para haver rastros comuns com que comparar os lentos. Sem uma
  base, todo rastro no armazenamento é um problema e ninguém sabe dizer como é o normal.

O `decision_wait` é quanto o Collector espera depois do primeiro span de um rastro antes de decidir.
Para as políticas terem o que achar, o payments recebe a ordem de somar 1500 ms a cada vigésima quinta
cobrança e de falhar a cada quadragésima. A vitrine e o orders perdem os amostradores, o Collector
passa ao arquivo novo, e o Prometheus ganha duas
flags: uma guarda exemplares, como na aula 11, e a outra deixa o Collector mandar a ele as métricas
da seção sobre métricas de spans. É tudo um override só, no lugar do anterior:

`~/shop/compose.override.yaml`

```yaml
services:
  otel-collector:
    volumes: ["./otel/collector-sampling.yaml:/etc/otelcol/config.yaml:ro"]
  prometheus:
    command: [--config.file=/etc/prometheus/prometheus.yml, --web.enable-lifecycle,
              --storage.tsdb.path=/prometheus, --enable-feature=exemplar-storage,
              --web.enable-otlp-receiver]
```

```sh
echo '{"latency_ms": 50, "slow_every": 25, "slow_ms": 1500, "fail_every": 40}' > faults/payments.json
docker compose up -d storefront orders otel-collector prometheus
sleep 150
```

Depois de dois minutos, as métricas do próprio Collector dizem o que cada política guardou:

```
ana@obs:~/shop$ ./promq 'sum by (policy) (increase(otelcol_processor_tail_sampling_count_traces_sampled{decision="sampled"}[2m]))'
policy=a-few-of-the-rest  34.285714285714285
policy=errors  13.714285714285714
policy=slow  21.71428571428571
```

```
ana@obs:~/shop$ ./promq 'sum by (decision) (increase(otelcol_processor_tail_sampling_global_count_traces_sampled[2m]))'
decision=not_sampled  475.4285714285714
decision=sampled  65.14285714285714
```

Uns 540 checkouts em dois minutos, e 65 guardados, 12%. `errors` guardou 14, que é cada quadragésima
cobrança; `slow` guardou 22, cada vigésima quinta; `a-few-of-the-rest` guardou 34, perto dos 5% dele.
As três somam mais que 65 porque um rastro pode satisfazer duas políticas ao mesmo tempo, e as
contagens são fracionárias porque o `increase` extrapola até as bordas da janela, como a aula 5 mostrou.

E o que isso faz com o volume:

```
ana@obs:~/shop$ ./promq 'sum(rate(otelcol_receiver_accepted_spans[1m]))'
  39.86666666666666
ana@obs:~/shop$ ./promq 'sum(rate(otelcol_exporter_sent_spans{exporter="zipkin"}[1m]))'
  4.933333333333334
```

Chegam quarenta spans por segundo e saem cinco. **Os rastros no armazenamento agora são os que vale
abrir**. Uma busca no Jaeger por erros acha todo erro dos últimos dois minutos, e uma busca por
checkouts lentos acha todo checkout lento, não um em dez.

As políticas são avaliadas juntas e qualquer uma basta. O processador tem mais tipos que esses três:
pelo valor de um atributo, por número de spans, por taxa por segundo, e combinações deles. Uma política
por atributo é como uma equipe guarda todo rastro de um cliente importante, ou de uma versão nova, por
uma semana.
