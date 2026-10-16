---
title: OpenTelemetry, e tracing que não fica preso a um fornecedor
version: 1
---

Os SDKs do X-Ray eram o jeito da própria AWS de instrumentar um serviço, um por linguagem, e só falam
X-Ray. O **OpenTelemetry** é o padrão aberto que substituiu os SDKs próprios da maioria dos
fornecedores: uma API para criar spans, um formato de transporte, o OTLP, e exportadores para qualquer
backend que o fale, o X-Ray inclusive. A AWS agora recomenda o OpenTelemetry para instrumentação nova,
e anunciou que os SDKs e o daemon do X-Ray estão passando para manutenção; leia as datas no anúncio da
própria AWS antes de planejar em torno delas.

As peças batem com o vocabulário desta lição, com outros nomes:

| OpenTelemetry | X-Ray |
|---|---|
| span | segmento ou subsegmento |
| id de trace (32 dígitos hexadecimais) | id de trace (`1-` hora, parte aleatória) |
| cabeçalho `traceparent`, W3C Trace Context | cabeçalho `X-Amzn-Trace-Id` |
| coletor | daemon do X-Ray |

## O coletor

Um serviço que usa o SDK do OpenTelemetry manda os spans para um **coletor**, um processo separado ao
lado dele, que os agrupa, acrescenta atributos como a região e o cluster, e os exporta. A AWS publica um
build próprio, a **AWS Distro for OpenTelemetry**, com o exportador do X-Ray dentro. A configuração de
um coletor são três listas, receivers, processors e exporters, unidas num pipeline:

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317

processors:
  batch:
    timeout: 5s

exporters:
  awsxray:
    region: sa-east-1

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [awsxray]
```

O serviço manda OTLP para a porta 4317; o coletor agrupa por cinco segundos e entrega os spans ao
X-Ray, que converte os ids de trace para o formato dele. **Esse coletor não foi executado para este
curso**: o X-Ray para onde ele mandaria é o do moto, que aceita segmentos pela API do X-Ray e não tem
endpoint OTLP.

## Por que o padrão importa para a operação

- **uma instrumentação, qualquer backend**: trocar de fornecedor de tracing é uma mudança no coletor, não
  em cada serviço;
- **um cabeçalho entre linguagens e nuvens**: um serviço em Go e um em Python, ou a AWS e outro
  provedor, continuam o mesmo trace;
- **métricas e logs do mesmo SDK**, com o id do trace anexado aos dois, que é a junção que a seção
  anterior pediu.

O custo de um coletor é mais um processo para rodar e vigiar por host ou por tarefa, normalmente como
contêiner sidecar ao lado do serviço, na mesma tarefa do ECS.
