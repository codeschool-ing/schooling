---
title: Um primeiro span, impresso
version: 1
---

O `first_span.py` é o `no_sdk.py` com o SDK configurado na frente, usando as duas partes mais
simples que existem: um processor que exporta cada span quando ele termina, e um exporter que o
imprime.

```schooling-example
{
  "language": "python",
  "file": "first_span.py",
  "parts": [
    {
      "code": "from opentelemetry import trace\nfrom opentelemetry.sdk.resources import Resource\nfrom opentelemetry.sdk.trace import TracerProvider\nfrom opentelemetry.sdk.trace.export import ConsoleSpanExporter, SimpleSpanProcessor\n\nprovider = TracerProvider(resource=Resource.create({\"service.name\": \"first-span\"}))\nprovider.add_span_processor(SimpleSpanProcessor(ConsoleSpanExporter()))\ntrace.set_tracer_provider(provider)\n\n",
      "note": "As mesmas três peças da loja, com duas trocadas: o exporter imprime no terminal em vez de enviar, e o processor exporta cada span no momento em que ele termina."
    },
    {
      "code": "tracer = trace.get_tracer(\"first-span\")\nwith tracer.start_as_current_span(\"hello\") as span:\n    print(\"recording:\", span.is_recording())",
      "note": "O código dentro do `with` é exatamente o do `no_sdk.py`. O span começa ao entrar no bloco e termina ao sair dele, e terminar é o que o manda ao processor."
    }
  ]
}
```

```
ana@obs:~/shop$ docker compose run --rm sandbox python first_span.py
 Container shop-otel-collector-1 Running 
 Container shop-sandbox-run-d11530ae7036 Creating 
 Container shop-sandbox-run-d11530ae7036 Created 
recording: True
{
    "name": "hello",
    "context": {
        "trace_id": "0xaf4d466b3c7618bf2de7b34a82bbc28d",
        "span_id": "0x7e3af0e482e0f939",
        "trace_state": "[]"
    },
    "kind": "SpanKind.INTERNAL",
    "parent_id": null,
    "start_time": "2026-10-02T03:33:35.497358Z",
    "end_time": "2026-10-02T03:33:35.497481Z",
    "status": {
        "status_code": "UNSET"
    },
    "attributes": {},
    "events": [],
    "links": [],
    "resource": {
        "attributes": {
            "telemetry.sdk.language": "python",
            "telemetry.sdk.name": "opentelemetry",
            "telemetry.sdk.version": "1.45.0",
            "service.instance.id": "d126c213-03dc-433f-b884-a98615eadeda",
            "service.name": "first-span"
        },
        "schema_url": ""
    }
}
```

**`recording: True`**, e o span terminado impresso como JSON. Cada campo nele é algo que um backend
vai depois guardar, buscar ou desenhar:

| campo | o que guarda aqui |
|---|---|
| `name` | `hello`, como o trabalho se chama |
| `context.trace_id` | 128 bits, aleatório, compartilhado por todo span de uma requisição |
| `context.span_id` | 64 bits, aleatório, só deste span |
| `kind` | `INTERNAL`: nenhuma das pontas de uma chamada entre serviços |
| `parent_id` | `null`, então este span é a **raiz** do seu rastro |
| `start_time`, `end_time` | quando começou e terminou, em UTC; aqui com 123 microssegundos de diferença |
| `status` | `UNSET`, o que quer dizer que ninguém disse que falhou |
| `attributes`, `events`, `links` | vazios; o resto desta aula preenche os dois primeiros, e a aula 4 o terceiro |
| `resource` | quem o produziu: o SDK, a versão dele e o `service.name` |

Dois desses campos merecem uma segunda olhada. O resource traz um `service.instance.id` que
ninguém definiu, um id aleatório que o SDK gerou para esta execução do programa, para que duas
cópias de um serviço possam ser distinguidas. E **os ids são aleatórios em vez de contados**:
nenhum serviço precisa pedir um número a outro, e é isso que permite a cem processos começar
rastros cada um sem se coordenar.
