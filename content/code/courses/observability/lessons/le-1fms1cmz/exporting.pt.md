---
title: Enviando spans: OTLP, e para que serve um processor
version: 1
---

O console era para ler. Os serviços da loja mandam seus spans com **OTLP**, o protocolo do
OpenTelemetry, ao Collector, por HTTP na porta 4318 neste laboratório. Nada no código dá o
endereço: o `OTLPSpanExporter()` lê `OTEL_EXPORTER_OTLP_ENDPOINT` do ambiente, e o `compose.yaml` do
laboratório o define uma vez para todo serviço da loja:

```yaml
    OTEL_EXPORTER_OTLP_ENDPOINT: http://otel-collector:4318
```

Sobra o **processor**, que parecia uma formalidade no primeiro script. Ele decide *quando* um span
terminado é exportado, e a decisão tem preço. O `cost.py` cria 2000 spans vazios e os manda ao
Collector, uma vez com cada tipo de processor:

```python
import sys
import time

from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor, SimpleSpanProcessor

kind = sys.argv[1]
processor = {"simple": SimpleSpanProcessor, "batch": BatchSpanProcessor}[kind]
provider = TracerProvider(resource=Resource.create({"service.name": f"cost-{kind}"}))
provider.add_span_processor(processor(OTLPSpanExporter()))
tracer = provider.get_tracer("cost")

start = time.perf_counter()
for i in range(2000):
    with tracer.start_as_current_span("unit of work"):
        pass
print(f"{kind}: 2000 spans in {time.perf_counter() - start:.2f} s")
provider.shutdown()
```

```
ana@obs:~/shop$ docker compose run --rm sandbox python cost.py simple
 Container shop-otel-collector-1 Running 
 Container shop-sandbox-run-4b60f407ca99 Creating 
 Container shop-sandbox-run-4b60f407ca99 Created 
simple: 2000 spans in 1.85 s
ana@obs:~/shop$ docker compose run --rm sandbox python cost.py batch
 Container shop-otel-collector-1 Running 
 Container shop-sandbox-run-b31b18bf4c1d Creating 
 Container shop-sandbox-run-b31b18bf4c1d Created 
batch: 2000 spans in 0.08 s
```

**1,85 segundo contra 0,08**, para os mesmos 2000 spans. O processor simples exporta cada span no
momento em que ele termina, então cada bloco `with` esperou uma requisição HTTP ao Collector ir e
voltar. É quase um milissegundo por span, somado ao código sendo medido. O processor em lote põe o
span terminado numa fila e retorna. Uma thread própria manda a fila em lotes, a cada poucos segundos
ou quando bastante coisa se acumulou, e o código nunca espera pela rede.

Então **o processor em lote é o de um serviço**, e o simples é para um script que você está lendo
num console. O processor em lote tem um custo próprio. É o motivo de o `cost.py` terminar com
`provider.shutdown()`: spans esperando na fila se perdem se o processo morrer antes do próximo
envio. Uma saída normal os descarrega, porque o SDK registra um encerramento quando o provider é
criado. Um processo morto de uma vez, pelo kernel sem memória ou por `kill -9`, leva junto seus
últimos segundos de spans. Costumam ser justamente os segundos que explicam por que ele morreu.

A fila também é limitada. Se o Collector parar de responder, o processor em lote guarda um número
fixo de spans, 2048 por padrão em Python, e descarta o resto em vez de crescer até o serviço ficar
sem memória. **Perder telemetria é a falha certa**; derrubar o serviço porque a telemetria dele não
pôde ser entregue é a errada.
