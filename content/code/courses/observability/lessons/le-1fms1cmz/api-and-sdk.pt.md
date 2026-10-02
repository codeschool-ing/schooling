---
title: A API, o SDK, e por que nada acontece sem o segundo
version: 1
---

A imagem óbvia de instrumentar é uma biblioteca só: importar, criar spans, e eles aparecem em algum
lugar. **O OpenTelemetry é feito de duas peças de propósito**, e o primeiro script mostra por quê.
O `no_sdk.py` importa só a API, pede um tracer e abre um span:

```python
from opentelemetry import trace

tracer = trace.get_tracer("no-sdk")
with tracer.start_as_current_span("hello") as span:
    print("recording:", span.is_recording())
    print("trace id:", format(span.get_span_context().trace_id, "032x"))
```

O laboratório o roda no `sandbox`, um contêiner da própria imagem da loja que executa os scripts
de `~/shop/scratch`. O Docker imprime três linhas suas antes da saída do script, dizendo que criou
o contêiner:

```
ana@obs:~/shop$ docker compose run --rm sandbox python no_sdk.py
 Container shop-otel-collector-1 Running 
 Container shop-sandbox-run-a21f65582056 Creating 
 Container shop-sandbox-run-a21f65582056 Created 
recording: False
trace id: 00000000000000000000000000000000
```

**Nenhum erro, e nada registrado.** O span existe, o código rodou, e o id do rastro é zero: um
span que não faz parte de rastro nenhum. É a API fazendo exatamente o que promete. Sem um SDK ela
devolve spans que não fazem nada, a custo baixo, para que uma biblioteca possa ser instrumentada
uma vez e distribuída a quem nunca configurou o OpenTelemetry, quase sem custo para essas pessoas.

O **SDK** é o que torna as chamadas reais, e ele é configurado uma vez, quando o programa começa.
Tem três partes, e o storefront e o payments da loja dividem uma função que as monta:

```schooling-example
{
  "language": "python",
  "file": "common/tracing.py",
  "parts": [
    {
      "code": "\"\"\"The OpenTelemetry SDK, set up by hand, for the services instrumented by hand.\"\"\"\nfrom opentelemetry import trace\nfrom opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter\nfrom opentelemetry.sdk.resources import Resource\nfrom opentelemetry.sdk.trace import TracerProvider\nfrom opentelemetry.sdk.trace.export import BatchSpanProcessor\n\n",
      "note": "Tudo o que vem de `opentelemetry.sdk` é o SDK. Só `trace`, a primeira importação, é a API, e é a única que o resto do serviço usa."
    },
    {
      "code": "def setup(service, version):\n    resource = Resource.create({\"service.name\": service, \"service.version\": version})\n",
      "note": "**O resource** descreve quem está produzindo os spans, e todo span que este processo manda o carrega. `service.name` é o único atributo pelo qual todo backend agrupa."
    },
    {
      "code": "    provider = TracerProvider(resource=resource)\n    provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))\n",
      "note": "**O provider faz spans de verdade**, e cada um, ao terminar, vai ao processor, que o entrega ao exporter. O `OTLPSpanExporter()` lê para onde mandar do ambiente, `OTEL_EXPORTER_OTLP_ENDPOINT`, que o laboratório aponta para o Collector."
    },
    {
      "code": "    trace.set_tracer_provider(provider)\n    return trace.get_tracer(service, version)",
      "note": "Registrar o provider na API é o interruptor: daqui em diante, todo `get_tracer` no processo, neste código ou em qualquer biblioteca, devolve tracers que registram."
    }
  ]
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"As peças entre uma linha de código e o Collector. Seu código chama a API: get_tracer e start_as_current_span. Sem um SDK instalado, a API devolve spans que não registram nada. Com um, o TracerProvider, que carrega o resource como service.name, cria spans reais; cada span terminado vai a um span processor, Simple ou Batch, que o entrega a um exporter, Console ou OTLP; o exporter OTLP o manda ao Collector.\"><defs><marker id=\"sdk-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"130\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">seu código</text><text x=\"85.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">start_as_current_span</text><rect x=\"180\" y=\"70\" width=\"130\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">TracerProvider</text><text x=\"245.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">resource:</text><text x=\"245.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">service.name</text><rect x=\"340\" y=\"70\" width=\"110\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"395.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">processor</text><text x=\"395.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Simple ou Batch</text><rect x=\"480\" y=\"70\" width=\"110\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">exporter</text><text x=\"535.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Console ou OTLP</text><rect x=\"620\" y=\"70\" width=\"90\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"665.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Collector</text><path d=\"M152 110 L178 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sdk-ah)\"></path><path d=\"M312 110 L338 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sdk-ah)\"></path><path d=\"M452 110 L478 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sdk-ah)\"></path><path d=\"M592 110 L618 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sdk-ah)\"></path><path d=\"M165 165 L165 205 L595 205 L595 165\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"380\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o SDK, configurado uma vez na partida</text><path d=\"M85 165 L85 205\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"85\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a API</text><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">de um span no seu código até o Collector</text></svg>", "caption": "A API é aquilo de que o código instrumentado depende; tudo à direita dela é o SDK, configurado uma vez quando o programa começa. Troque qualquer caixa da direita e o código instrumentado não muda.", "same": ["Collector", "TracerProvider", "exporter", "processor", "resource:", "service.name", "start_as_current_span"]}
```

Essa divisão decide como o resto deste curso é escrito. A instrumentação, as chamadas que criam
spans e definem atributos, depende só da API e é escrita ao lado do código que descreve. Para onde
os spans vão é configuração, escrita uma vez, e as aulas 3, 11 e 13 a mudam sem tocar numa linha
de instrumentação.

A API define mais que rastros: a mesma divisão existe para **métricas**, com meters e instrumentos,
e para logs. A loja expõe suas métricas no formato do próprio Prometheus, por um motivo que a aula
5 dá, então esta aula fica com os spans.
