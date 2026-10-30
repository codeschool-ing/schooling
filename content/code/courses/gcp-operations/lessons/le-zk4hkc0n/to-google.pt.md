---
title: Mandando para o Google, e para qualquer outro
version: 1
---

**Mandar os spans da loja ao Cloud Trace é uma mudança no arquivo do Collector, e nada mais.** O programa fica
como está: continua mandando OTLP para `localhost:4318`. O exportador do Collector muda de `debug` para
`googlecloud`, que escreve traces no Cloud Trace (e métricas no Cloud Monitoring, logs no Cloud Logging, em
pipelines próprios). Escreva-o em `~/gcp/collector-gcp.yaml`:

```yaml
# collector-gcp.yaml
receivers:
  otlp:
    protocols:
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 2s
  resourcedetection:
    detectors: [gcp]

exporters:
  googlecloud:
    project: planner-dev

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [resourcedetection, batch]
      exporters: [googlecloud]
```

O Collector confere uma configuração sem iniciá-la:

```
ana@laptop:~/gcp$ docker run --rm -v "$PWD/collector-gcp.yaml":/c.yaml otel/opentelemetry-collector-contrib:0.137.0 validate --config=/c.yaml; echo "exit $?"
exit 0
```

**Exit 0 diz que o arquivo está bem formado**: todo componente existe nesta build do Collector, e toda chave é uma
que o componente conhece. Uma chave escrita errado o faz falhar:

```
ana@laptop:~/gcp$ sed 's/googlecloud:/googlecloud:\n    projectt: x/' collector-gcp.yaml > bad.yaml
ana@laptop:~/gcp$ docker run --rm -v "$PWD/bad.yaml":/c.yaml otel/opentelemetry-collector-contrib:0.137.0 validate --config=/c.yaml 2>&1 | tail -3
'exporters' error reading configuration for "googlecloud": decoding failed due to the following error(s):

'' has invalid keys: projectt
```

O que a validação não sabe dizer é se o Google aceitaria os spans: **o Collector não foi iniciado com este
arquivo**, porque o exportador tentaria se autenticar no Google e não há conta aqui. No Google Cloud, o
exportador acha as credenciais como o provider da lição 5 achou, pelas Application Default Credentials, que no
Cloud Run ou no GKE é a conta de serviço com que o Collector roda; essa conta precisa de `roles/cloudtrace.agent`
para escrever traces. `resourcedetection` com o detector `gcp` lê o servidor de metadados ali e acrescenta o
projeto, a região e o serviço a todo span.

## Onde o Collector roda

| em | como |
|---|---|
| Cloud Run | um contêiner sidecar no mesmo serviço, recebendo em `localhost:4318` |
| GKE | um DaemonSet (um por nó) ou um Deployment para onde os serviços mandam |
| Compute Engine | o Ops Agent do Google, que é um Collector por baixo, ou o próprio Collector |

## O que a portabilidade compra, e o que não compra

O código é portável: fala OTLP, e mudar de fornecedor é um exportador novo num arquivo. A **semântica também é
portável**, porque as convenções semânticas do OpenTelemetry nomeiam os atributos do mesmo jeito em todo lugar
(`http.request.method`, `server.address`). O que não é portável é tudo do outro lado: os painéis, as políticas de
alerta e os SLOs das lições 8, 13 e 14 são escritos contra o Cloud Monitoring e seriam reescritos para outro
fornecedor. O OpenTelemetry leva junto a instrumentação, que é a parte cara de refazer em cada serviço, e deixa o
resto onde estava.
