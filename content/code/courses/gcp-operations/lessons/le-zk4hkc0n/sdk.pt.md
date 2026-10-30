---
title: Instrumentando uma vez, com OpenTelemetry
version: 1
---

**O OpenTelemetry é um padrão neutro de fornecedor para produzir traces, métricas e logs: uma API que o seu
código chama, um SDK que transforma as chamadas em dados, e um protocolo de rede, o OTLP, que os carrega.** O
código diz "um span chamado *charge payment* começou e terminou" e nada sobre o Google. Para onde o span vai é
decidido em outro lugar, por um exportador, e essa separação é o que a lição 11 não pôde mostrar e esta pode:
tudo aqui roda no seu computador, contra um OpenTelemetry Collector num contêiner, e os spans são reais.

Dois pacotes, no ambiente virtual do curso:

```sh
cd ~/gcp && source venv/bin/activate
pip install -q 'opentelemetry-sdk==1.45.0' 'opentelemetry-exporter-otlp-proto-http==1.45.0'
```

## Um checkout, rastreado

O programa abaixo faz um dos checkouts da loja como quatro operações, com sleeps no lugar do trabalho, e as
rastreia. Escreva-o em `~/gcp/checkout.py`:

```python
# checkout.py
"""checkout.py: one checkout of the shop, traced with OpenTelemetry."""
import time

from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

provider = TracerProvider(resource=Resource.create(
    {"service.name": "shop-api", "service.version": "a1b2c3d"}))
provider.add_span_processor(BatchSpanProcessor(
    OTLPSpanExporter(endpoint="http://localhost:4318/v1/traces")))
trace.set_tracer_provider(provider)
tracer = trace.get_tracer("shop.checkout")

with tracer.start_as_current_span("POST /orders") as root:
    root.set_attribute("order.id", "o-1001")
    with tracer.start_as_current_span("load basket"):
        time.sleep(0.02)
    with tracer.start_as_current_span("charge payment") as pay:
        pay.set_attribute("payment.provider", "pix")
        time.sleep(0.15)
    with tracer.start_as_current_span("insert order"):
        time.sleep(0.03)
    print("trace id", format(root.get_span_context().trace_id, "032x"))

provider.shutdown()
```

Leia em quatro passos:

- **O resource** diz o que produziu os dados: `service.name` e `service.version`, o mesmo par que a lição 11
  escreveu à mão em `serviceContext`. Todo span o carrega.
- **O exportador** manda os spans com OTLP por HTTP para `localhost:4318`, a porta do Collector, em lotes. É a
  única linha que sabe para onde os dados vão, e ela não nomeia o Google.
- **Os spans** são aninhados pelos blocos `with`: os três internos são filhos de `POST /orders`, então
  compartilham o trace id dele. Atributos como `order.id` viajam com o span.
- **`provider.shutdown()`** manda o que ainda está no lote antes de o programa sair. Sem ele, um programa curto
  pode terminar antes de os spans saírem.
