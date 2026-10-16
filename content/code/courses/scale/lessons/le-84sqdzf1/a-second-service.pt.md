---
title: Um segundo serviço, e uma configuração para os dois
version: 1
---

Um rastro se paga quando um pedido atravessa serviços. A bilheteria até aqui é um programa e um
banco de dados, então esta aula lhe dá um segundo programa: o **payments**, um substituto da
operadora de cartão que cobra o comprador antes de o ingresso ser emitido. Ele responde uma rota,
leva uns 20 a 40 ms para isso, e não faz mais nada. As aulas 9 e 10 o deixam lento e o fazem falhar.

Os dois serviços configuram o OpenTelemetry do mesmo jeito, então esse código mora num arquivo que os
dois importam. Salve-o como `telemetry.py`:

```schooling-example
{"language": "python", "file": "telemetry.py", "parts": [{"code": "# telemetry.py\n\"\"\"One place that sets up OpenTelemetry tracing for every service of the box office.\"\"\"\nimport os\n\nfrom opentelemetry import trace\nfrom opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter\nfrom opentelemetry.sdk.resources import Resource\nfrom opentelemetry.sdk.trace import TracerProvider\nfrom opentelemetry.sdk.trace.export import BatchSpanProcessor", "note": "Quatro peças do SDK do OpenTelemetry: a API para obter um tracer, o exportador que manda spans por OTLP, o recurso que nomeia o serviço e o provedor que junta tudo."}, {"code": "\n\ndef setup(service):\n    provider = TracerProvider(resource=Resource.create({\"service.name\": service}))\n    endpoint = os.environ.get(\"OTLP_ENDPOINT\", \"http://collector:4318\") + \"/v1/traces\"\n    provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint=endpoint)))\n    trace.set_tracer_provider(provider)\n    return trace.get_tracer(service)", "note": "**Chamado uma vez por cada serviço ao subir.** Todo span que ele cria leva o `service.name`. Os spans são juntados em lotes e mandados em segundo plano para o Collector em `OTLP_ENDPOINT`, então um Collector lento nunca atrasa um pedido. Quais spans ficam é lido das variáveis de ambiente padrão, que a seção 10 usa."}]}
```

E o serviço em si, como `payments.py`:

```schooling-example
{"language": "python", "file": "payments.py", "parts": [{"code": "# payments.py\n\"\"\"payments: a stand-in for the card company, slow on purpose.\"\"\"\nimport json\nimport os\nimport time\nimport zlib\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nfrom opentelemetry import propagate, trace\n\nimport telemetry\n\ntracer = telemetry.setup(\"payments\")\nDELAY_MS = float(os.environ.get(\"PAYMENTS_DELAY_MS\", \"20\"))\n", "note": "O substituto da operadora de cartão. Ele usa o mesmo `telemetry.py`, então os spans dele vão para o mesmo lugar com o nome `payments`. `PAYMENTS_DELAY_MS` é o quão lento ele é; as aulas 9 e 10 o aumentam."}, {"code": "\nclass Handler(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n    disable_nagle_algorithm = True\n"}, {"code": "    def do_POST(self):\n        body = self.rfile.read(int(self.headers.get(\"Content-Length\", 0)))\n        print(json.dumps({\"message\": \"charge\", \"traceparent\": self.headers.get(\"traceparent\")}),\n              flush=True)\n        context = propagate.extract(self.headers)\n        with tracer.start_as_current_span(\"POST /charges\", context=context,\n                                          kind=trace.SpanKind.SERVER) as span:\n            # the same charge always takes the same time: 1x to 2x the delay\n            jitter = zlib.crc32(body) % 100 / 100\n            time.sleep(DELAY_MS * (1 + jitter) / 1000)\n            span.set_attribute(\"http.response.status_code\", 200)\n            data = json.dumps({\"charged\": True}).encode()\n            self.send_response(200)\n            self.send_header(\"Content-Type\", \"application/json\")\n            self.send_header(\"Content-Length\", str(len(data)))\n            self.end_headers()\n            self.wfile.write(data)\n", "note": "**`propagate.extract` lê o cabeçalho `traceparent`** que a bilheteria mandou, e o span de servidor começa dentro desse contexto, então vira filho do span da bilheteria, em outro processo. A linha impressa primeiro mostra o cabeçalho como chegou. A pausa depende só do corpo do pedido, entre uma e duas vezes o atraso."}, {"code": "    def log_message(self, *args):\n        pass\n\n\nif __name__ == \"__main__\":\n    ThreadingHTTPServer.request_queue_size = 128\n    ThreadingHTTPServer((\"0.0.0.0\", 8001), Handler).serve_forever()"}]}
```

Ele usa a mesma imagem da bilheteria, então não precisa de um Dockerfile próprio; o `compose.yaml` o
sobe com outro comando, na seção 06.

## O que o contexto leva

A linha essencial do `payments.py` é `propagate.extract(self.headers)`. A bilheteria, quando chama o
payments, escreve a identidade do seu span atual num cabeçalho do pedido; o payments a lê e começa o
próprio span **como filho daquele**. Nenhum dos processos sabe nada dos spans do outro; eles só
concordam no cabeçalho. A seção 08 o examina byte a byte.
