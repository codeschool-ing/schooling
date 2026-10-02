---
title: Transporte: da saída padrão até um armazenamento
version: 1
---

A aula 8 deixou todo serviço imprimindo JSON na saída padrão e sem saber nada de para onde isso vai.
**Algo tem de recolher essas linhas e entregá-las**, e o nome geral disso é um *shipper* ou *agente* de
logs: Fluent Bit, Vector, Logstash, Promtail e o sucessor dele, o Alloy, ou o OpenTelemetry Collector,
que o laboratório já roda para os rastros. Pôr esse trabalho fora do serviço é o que permite ao serviço
continuar simples, e é o que permite ao destino mudar sem uma nova versão: um serviço que manda seus
logs direto a um armazenamento por HTTP tem de tentar de novo, guardar em buffer e se autenticar
sozinho, e muda toda vez que o armazenamento muda.

No laboratório o caminho é o driver de log `fluentd` do Docker, que entrega cada linha ao Collector,
cujo processor `transform` interpreta o JSON, e um exporter por armazenamento. Acrescentar dois
armazenamentos é uma mudança só no Collector. O Compose lê o `compose.override.yaml` por cima do
`compose.yaml`, então o Collector é apontado para um segundo arquivo de configuração que o laboratório
traz ao lado do primeiro:

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
padrão, pela API dele:

```
ana@obs:~/shop$ docker compose up -d otel-collector 2>&1 | tail -1
 Container shop-otel-collector-1 Started 
ana@obs:~/shop$ curl -s -u admin:$(cat .graylog-password) -H 'X-Requested-By: ana' -H 'Content-Type: application/json' -X POST localhost:9000/api/system/inputs -d '{"title": "shop logs (OTLP)", "type": "org.graylog.inputs.otel.OTelGrpcInput", "global": true, "configuration": {"bind_address": "0.0.0.0", "port": 4317, "insecure": true, "max_inbound_msg_size": 4194304}}'; echo
{"id":"6abfd0605386fc4fd78ceb27"}
```

Daqui em diante, toda linha que qualquer serviço escreve chega ao Loki, ao Elasticsearch e ao Graylog,
pela mesma esteira, com os mesmos campos. Esse é o ponto do exercício: **a comparação a seguir é entre
três armazenamentos com dados idênticos**, não três montagens que diferem no que receberam.
