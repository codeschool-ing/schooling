---
title: Transporte: da saída padrão até um armazenamento
version: 2
---

A aula 8 deixou todo serviço imprimindo JSON na saída padrão e sem saber nada de para onde isso vai.
**Algo tem de recolher essas linhas e entregá-las.** O nome geral disso é um *shipper* ou *agente* de
logs: Fluent Bit, Vector, Logstash, Promtail e o sucessor dele, o Alloy, ou o OpenTelemetry Collector,
que o laboratório já roda para os rastros. Pôr esse trabalho fora do serviço é o que permite ao serviço
continuar simples, e o que permite ao destino mudar sem uma nova versão. Um serviço que manda seus
logs direto a um armazenamento por HTTP tem de tentar de novo, guardar em buffer e se autenticar
sozinho, e muda toda vez que o armazenamento muda.

No laboratório o caminho é o driver de log `fluentd` do Docker, que entrega cada linha ao Collector,
cujo processor `transform` interpreta o JSON, e um exporter por armazenamento. Acrescentar dois
armazenamentos é uma mudança só no Collector. O Compose lê o `compose.override.yaml` por cima do
`compose.yaml`, então o Collector é apontado para um segundo arquivo de configuração ao lado do
primeiro.

**Esta aula precisa de uma máquina maior que as outras.** O Elasticsearch, o OpenSearch e o Graylog
são três programas Java, e com eles rodando o laboratório pede 16 GB de memória. Numa máquina com
8 GB, leia as transcrições desta aula em vez de reproduzi-las; nada mais adiante no curso depende de
ela ter rodado.

O Graylog precisa de dois segredos antes de subir: uma senha para o usuário `admin`, e uma chave com
que ele cifra as próprias configurações. O `compose.yaml` lê as duas do `.graylog.env`, que estas
linhas escrevem. A senha também fica num arquivo próprio, porque as chamadas à API abaixo a leem de
lá:

```sh
cd ~/shop
openssl rand -hex 12 > .graylog-password
printf 'GRAYLOG_PASSWORD_SECRET=%s\nGRAYLOG_ROOT_PASSWORD_SHA2=%s\n' "$(openssl rand -hex 32)" "$(tr -d '\n' < .graylog-password | sha256sum | cut -d' ' -f1)" > .graylog.env
```

Depois o laboratório é iniciado de novo do zero com os dois perfis que trazem os armazenamentos, o
que sobe o Elasticsearch, o MongoDB, o OpenSearch e o Graylog ao lado do resto. O payments falha uma
cobrança em vinte desde o começo, para que haja falhas a procurar. O Graylog leva um ou dois minutos
até a API dele responder na porta 9000:

```sh
docker compose --profile '*' down -v
docker compose --profile elastic --profile graylog up -d
echo '{"fail_every": 20}' > faults/payments.json
```

A segunda configuração do Collector é este arquivo:

`~/shop/otel/collector-logs.yaml`

```yaml
# The same Collector, sending every log line to three stores at once:
# Loki, Elasticsearch and Graylog. Lesson 9 switches to it.
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
  elasticsearch:
    endpoints: [http://elasticsearch:9200]
  otlp_grpc/graylog:
    endpoint: graylog:4317
    tls:
      insecure: true

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
      exporters: [otlp_http/loki, elasticsearch, otlp_grpc/graylog]
```

E o override que aponta o Collector para ele são as três linhas que o `cat` abaixo imprime, salvas
como `~/shop/compose.override.yaml`. O que mudou em relação ao primeiro arquivo:

```
ana@obs:~/shop$ cat compose.override.yaml
services:
  otel-collector:
    volumes: ["./otel/collector-logs.yaml:/etc/otelcol/config.yaml:ro"]
ana@obs:~/shop$ diff otel/collector.yaml otel/collector-logs.yaml
1,2c1,2
< # The OpenTelemetry Collector: every trace and every log line of the shop
< # passes through here on its way to where it is stored.
---
> # The same Collector, sending every log line to three stores at once:
> # Loki, Elasticsearch and Graylog. Lesson 9 switches to it.
51a52,57
>   elasticsearch:
>     endpoints: [http://elasticsearch:9200]
>   otlp_grpc/graylog:
>     endpoint: graylog:4317
>     tls:
>       insecure: true
70c76
<       exporters: [otlp_http/loki]
---
>       exporters: [otlp_http/loki, elasticsearch, otlp_grpc/graylog]
```

**Dois exporters acrescentados, e uma linha mudada**: a esteira de logs agora termina em três
exporters, e toda linha é mandada aos três. A esteira de rastros fica intocada. O Collector é recriado
com o arquivo novo, e o Graylog ganha uma input para receber, do tipo *OpenTelemetry (gRPC)* na porta
padrão, pela API dele. O Graylog recusa uma mudança pela API que não traga um cabeçalho
`X-Requested-By`, contra requisições forjadas a partir de um navegador; qualquer valor serve:

```
ana@obs:~/shop$ docker compose up -d otel-collector 2>&1 | tail -1
 Container shop-otel-collector-1 Started 
ana@obs:~/shop$ curl -s -u admin:$(cat .graylog-password) -H 'X-Requested-By: ana' -H 'Content-Type: application/json' -X POST localhost:9000/api/system/inputs -d '{"title": "shop logs (OTLP)", "type": "org.graylog.inputs.otel.OTelGrpcInput", "global": true, "configuration": {"bind_address": "0.0.0.0", "port": 4317, "insecure": true, "max_inbound_msg_size": 4194304}}'; echo
{"id":"6abfd0605386fc4fd78ceb27"}
```

Daqui em diante, toda linha que qualquer serviço escreve chega ao Loki, ao Elasticsearch e ao Graylog,
pela mesma esteira, com os mesmos campos. Esse é o ponto do exercício: **a comparação a seguir é entre
três armazenamentos com dados idênticos**, não três montagens que diferem no que receberam.

Os clientes simulados rodam por um quarto de hora, e as próximas seções leem o que eles deixaram
depois de dois minutos e meio:

```sh
docker compose run -d --rm loadgen python -m loadgen.load 5 900
sleep 150
```
