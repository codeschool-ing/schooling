---
title: O Collector, entre o código e o destino
version: 1
---

**O OpenTelemetry Collector é um programa que recebe telemetria, a processa e a exporta, configurado como
pipelines.** Um pipeline tem receivers (por onde os dados entram), processors (o que acontece com eles) e
exporters (para onde vão). O código da loja manda para o Collector e nunca para um fornecedor; o Collector guarda
as credenciais, os lotes e a escolha do destino. Mudar o destino é uma mudança no arquivo do Collector, não em
cada serviço.

A primeira configuração imprime o que recebe, para você ver os spans. Escreva-a em `~/gcp/collector.yaml`:

```yaml
# collector.yaml
receivers:
  otlp:
    protocols:
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 2s

exporters:
  debug:
    verbosity: normal

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [debug]
```

`debug` é um exportador que escreve os dados no próprio log do Collector. Inicie o Collector com esse arquivo,
depois rode o checkout:

```
ana@laptop:~/gcp$ docker run -d --rm --name otel -p 4318:4318 -v "$PWD/collector.yaml":/etc/otelcol-contrib/config.yaml otel/opentelemetry-collector-contrib:0.137.0
1721c394743fa582cc23943bd5a973870832e787439d574d2ecb4162f65350c5
ana@laptop:~/gcp$ python3 checkout.py
trace id 05ff145145343c86f543a2515ba5c99f
```

E leia o que o Collector recebeu:

```
ana@laptop:~/gcp$ docker logs otel 2>&1 | grep -A5 '^ScopeTraces'
ScopeTraces #0 shop.checkout
load basket 05ff145145343c86f543a2515ba5c99f 2a625d4a41f3f63e
charge payment 05ff145145343c86f543a2515ba5c99f 39c4173bc0c9bed9 payment.provider=pix
insert order 05ff145145343c86f543a2515ba5c99f e5df3da9c89b932d
POST /orders 05ff145145343c86f543a2515ba5c99f 6b91678415ea4966 order.id=o-1001
	{"resource": {"service.instance.id": "97f0242e-2c00-442e-8bc4-3db34d94b5c0", "service.name": "otelcol-contrib", "service.version": "0.137.0"}, "otelcol.component.id": "debug", "otelcol.component.kind": "exporter", "otelcol.signal": "traces"}
```

Quatro spans, todos com o mesmo trace id, o que o programa imprimiu. Cada linha é o nome de um span, o trace id,
o id do próprio span e os atributos dele. A ordem no log é a ordem em que os spans **terminaram**, os internos
primeiro, e por isso `POST /orders`, o pai, vem por último: ele termina quando o último filho terminou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Uma pipeline do Collector como três caixas da esquerda para a direita: o receiver otlp recebe spans do programa, o processor batch os agrupa, e o exporter debug os escreve. Mudar o destino é mudar só o exporter.\"><defs><marker id=\"ah5\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">programa</text><rect x=\"190\" y=\"40\" width=\"130\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"255\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">otlp</text><text x=\"255\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">receiver</text><rect x=\"380\" y=\"40\" width=\"130\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"445\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">batch</text><text x=\"445\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">processor</text><rect x=\"570\" y=\"40\" width=\"130\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"635\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">debug</text><text x=\"635\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">exporter</text><line x1=\"142\" y1=\"75\" x2=\"188\" y2=\"75\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah5)\"></line><line x1=\"322\" y1=\"75\" x2=\"378\" y2=\"75\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah5)\"></line><line x1=\"512\" y1=\"75\" x2=\"568\" y2=\"75\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah5)\"></line><text x=\"360\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">troque o exporter para mandar a outro lugar; o programa não muda</text></svg>", "caption": "Receivers, processors, exporters: o programa só conhece o primeiro."}
```

## Para que servem os processors

`batch` agrupa spans e os manda a cada dois segundos ou quando juntou o bastante, em vez de uma requisição por
span. Outros processors são o motivo de um Collector valer a pena mesmo com um destino só:

| processor | o que faz |
|---|---|
| `batch` | menos exportações, maiores |
| `memory_limiter` | recusa dados antes de o Collector ficar sem memória |
| `resourcedetection` | acrescenta onde o Collector roda: projeto, região, serviço do Cloud Run, cluster do GKE |
| `attributes` | acrescenta, renomeia ou remove atributos, como apagar um que carrega dado pessoal |
| `tail_sampling` | guarda traces inteiros por regra (erros, lentos), depois de vê-los |

**Remover dado pessoal no Collector** é o que vale lembrar: um atributo de span com um endereço de e-mail é dado
pessoal guardado no Cloud Trace, e um processor `attributes` que o apaga cobre todos os serviços de uma vez.
