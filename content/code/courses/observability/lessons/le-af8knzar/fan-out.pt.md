---
title: Mandando tudo para mais um lugar
version: 2
---

Experimentar um produto hospedado, ou sair de um, significava mexer em todo serviço. **Com um Collector
no meio, é um exportador a mais.** Os serviços continuam mandando OTLP ao Collector, e o Collector
manda cada rastro a tantos lugares quantos exportadores ele tiver.

O laboratório não tem conta em fornecedor nenhum e nem deve ter, então o lugar é um substituto: o
`standin.py`, um programa de vinte linhas na sandbox que aceita OTLP por HTTP do jeito que uma
entrada hospedada aceita e imprime quem mandou o quê:

`~/shop/scratch/standin.py`

```python
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
```

A quarta configuração do Collector é a primeira com um exportador a mais. Salve-a inteira:

`~/shop/otel/collector-fanout.yaml`

```yaml
# The Collector of collector.yaml, sending every trace to one more place
# (lesson 13): an OTLP endpoint of the kind a hosted product gives you, with the
# key that identifies the account read from the environment.
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
  otlp_http/vendor:
    endpoint: http://vendor:4318
    encoding: json
    headers:
      api-key: ${env:VENDOR_API_KEY}

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
      exporters: [otlp_grpc/jaeger, zipkin, otlp_http/vendor]
    logs:
      receivers: [fluent_forward]
      processors: [memory_limiter, transform/logs, groupbyattrs/service, transform/service, batch]
      exporters: [otlp_http/loki]
```

O exportador que aponta para o substituto:

```
ana@obs:~/shop$ sed -n '/otlp_http\/vendor:/,/api-key/p' otel/collector-fanout.yaml
  otlp_http/vendor:
    endpoint: http://vendor:4318
    encoding: json
    headers:
      api-key: ${env:VENDOR_API_KEY}
```

Toda entrada hospedada pede as mesmas três coisas: um endpoint, uma codificação e uma chave num
cabeçalho. O nome da chave varia por produto, `api-key` no endpoint OTLP do New Relic e um cabeçalho
`Authorization` no do Dynatrace, e o substituto imita o primeiro. **A chave é lida do ambiente, nunca
escrita no arquivo**, o que a mantém fora do repositório onde o arquivo mora:

```
ana@obs:~/shop$ cat compose.override.yaml
services:
  otel-collector:
    volumes: ["./otel/collector-fanout.yaml:/etc/otelcol/config.yaml:ro"]
    environment:
      VENDOR_API_KEY: lab-0000-not-a-real-key
ana@obs:~/shop$ docker compose run -d --rm --name vendor sandbox python standin.py 2>&1 | tail -1
5a6fe95e94eb75dfe46b636749a431b2284618806bd069c05d1c88e9742cc54c
```

O `cat` imprimiu o override, salvo como `~/shop/compose.override.yaml`. Com ele no lugar e o
substituto rodando, recrie o Collector, e ponha os clientes para rodar por um quarto de hora:

```sh
docker compose up -d otel-collector
docker compose run -d --rm loadgen python -m loadgen.load 5 900
sleep 30
```

Trinta segundos depois, com clientes comprando, a saída do próprio substituto:

```
ana@obs:~/shop$ docker logs vendor 2>&1 | tail -4
api-key=lab-0000-not-a-real-key spans=42 bytes=2414 from=mailer
api-key=lab-0000-not-a-real-key spans=88 bytes=4846 from=orders
api-key=lab-0000-not-a-real-key spans=46 bytes=2937 from=payments,storefront
api-key=lab-0000-not-a-real-key spans=134 bytes=6736 from=mailer,orders
```

A mesma chave em toda requisição, e entre 50 e 64 bytes por span depois de comprimido: aos 35 spans por
segundo que a aula 12 mediu, uns 170 MB por dia. É desse número que parte a conta de um produto
hospedado, medido aqui antes de alguém citar um preço.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Os serviços mandam OTLP uma vez, ao Collector. O Collector manda todo rastro a três exportadores ao mesmo tempo: Jaeger, Zipkin e a entrada de um produto hospedado, que recebe um cabeçalho api-key lido do ambiente. Cada exportador tem a própria fila, então quando a entrada hospedada para de responder, a fila dela enche e os spans dela são descartados enquanto Jaeger e Zipkin continuam recebendo.\"><defs><marker id=\"fo-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"130\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">serviços</text><text x=\"85.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">OTLP, uma vez</text><rect x=\"220\" y=\"90\" width=\"150\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Collector</text><text x=\"295.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma esteira</text><text x=\"295.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">três exportadores</text><rect x=\"460\" y=\"30\" width=\"230\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Jaeger</text><rect x=\"460\" y=\"110\" width=\"230\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Zipkin</text><rect x=\"460\" y=\"190\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"575.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">entrada hospedada</text><text x=\"575.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">api-key vinda do ambiente</text><path d=\"M152 130 L218 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fo-ah)\"></path><path d=\"M372 115 L458 52\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fo-ah)\"></path><path d=\"M372 130 L458 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fo-ah)\"></path><path d=\"M372 145 L458 212\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#fo-ah)\"></path><text x=\"400\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">fila própria,</text><text x=\"400\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">falha sozinha</text></svg>", "caption": "A distribuição acontece num lugar só, e cada destino falha sozinho. Acrescentar ou tirar um produto é uma mudança neste arquivo, não nos serviços.", "same": ["Collector", "Jaeger", "Zipkin"]}
```

**E quando o fornecedor cai?** Cada exportador tem a própria fila e as próprias novas tentativas, então
um destino falhando não deveria afetar os outros. O substituto é parado e o Collector ganha um minuto:

```
ana@obs:~/shop$ docker stop vendor
vendor
ana@obs:~/shop$ ./promq 'sum by (exporter) (rate(otelcol_exporter_sent_spans[1m]))'
exporter=zipkin  35.48888888888889
exporter=otlp_grpc/jaeger  35.48888888888889
exporter=otlp_http/vendor  0
ana@obs:~/shop$ ./promq 'sum by (exporter) (otelcol_exporter_queue_size{data_type="traces"})'
exporter=otlp_grpc/jaeger  0
exporter=zipkin  0
exporter=otlp_http/vendor  28
ana@obs:~/shop$ ./promq 'sum by (exporter) (otelcol_exporter_queue_capacity{data_type="traces"})'
exporter=otlp_grpc/jaeger  1000
exporter=zipkin  1000
exporter=otlp_http/vendor  1000
ana@obs:~/shop$ docker compose logs --no-log-prefix otel-collector 2>&1 | grep 'otlp_http/vendor' | grep -m1 -o 'dial tcp: [^\"]*'
dial tcp: lookup vendor on 127.0.0.11:53: no such host
```

O Jaeger e o Zipkin continuam recebendo 35 spans por segundo. O exportador do fornecedor não manda
nenhum, e a fila dele guarda 28 lotes esperando nova tentativa, dos 1000 para os quais tem espaço; o
log do Collector diz por quê, nas palavras da rede. **Nesse ritmo a fila dura uns três quartos de
hora**, e depois disso a cópia do fornecedor perde dados enquanto as outras não perdem nada.

Duas coisas decorrem disso para quem manda dados a um fornecedor. **A fila é memória**, e uma parada
longa no fornecedor a enche e então perde dados, então o tamanho dela é uma decisão sobre quanto
tempo de parada você aguenta. O Collector também pode mantê-la em disco com uma extensão de
armazenamento. E **a fila é uma métrica**, então o alerta que diz *o fornecedor parou de aceitar
nossos dados* pode ser escrito no seu próprio Prometheus, que continua funcionando quando o
fornecedor não funciona.

Antes da próxima seção, devolva o Collector à primeira configuração:

```sh
rm compose.override.yaml
docker compose up -d otel-collector
```
