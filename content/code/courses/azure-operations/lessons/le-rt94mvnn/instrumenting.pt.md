---
title: Um checkout, instrumentado à mão
version: 1
---

O SDK vai para o mesmo ambiente virtual da linha de comando, fixado:

```sh
cd ~/azure && source venv/bin/activate
pip install -q 'opentelemetry-sdk==1.45.1'
mkdir -p ~/azure/otel && cd ~/azure/otel
```

```
ana@laptop:~/azure/otel$ pip list 2>/dev/null | grep opentelemetry
opentelemetry-api                              1.45.1
opentelemetry-sdk                              1.45.1
opentelemetry-semantic-conventions             0.66b1
```

Este é um handler de checkout reduzido às suas chamadas, instrumentado com OpenTelemetry e mais nada. Salve como
`shop_trace.py`:

```schooling-example
{
  "language": "python",
  "file": "shop_trace.py",
  "parts": [
    {
      "code": "# shop_trace.py: one checkout, traced with OpenTelemetry, printed to the terminal\nimport time\n\nfrom opentelemetry import trace\nfrom opentelemetry.sdk.resources import Resource\nfrom opentelemetry.sdk.trace import TracerProvider\nfrom opentelemetry.sdk.trace.export import ConsoleSpanExporter, SimpleSpanProcessor\nfrom opentelemetry.trace import SpanKind, Status, StatusCode\n\n",
      "note": "A API (`opentelemetry.trace`) e o SDK (`opentelemetry.sdk`) são imports separados, como são pacotes separados: uma biblioteca de que você depende pode usar a API sem escolher um SDK por você."
    },
    {
      "code": "def one_line(span):\n    parent = f\"{span.parent.span_id:016x}\"[:8] if span.parent else \"-\"\n    ms = (span.end_time - span.start_time) / 1e6\n    return (f\"trace {span.context.trace_id:032x}\"[:14] + f\"  span {span.context.span_id:016x}\"[:15]\n            + f\"  parent {parent:<8}  {span.kind.name:<6}  {span.name:<16}  {span.status.status_code.name:<5}  {ms:4.0f} ms\\n\")\n\n",
      "note": "O exportador de console aceita um formatador. Este imprime um span numa linha, com os ids cortados em oito dígitos hexadecimais para os três caberem; os ids completos têm 32 e 16 dígitos."
    },
    {
      "code": "provider = TracerProvider(resource=Resource.create({\"service.name\": \"shop-api\"}))\nprovider.add_span_processor(SimpleSpanProcessor(ConsoleSpanExporter(formatter=one_line)))\ntrace.set_tracer_provider(provider)\ntracer = trace.get_tracer(\"shop\")\n\n",
      "note": "A preparação: um provider com um **resource** que nomeia o serviço, um processador que exporta cada span quando termina, e um tracer. Este bloco é a única parte que sabe para onde a telemetria vai."
    },
    {
      "code": "def insert_order(order_id, slow):\n    with tracer.start_as_current_span(\"INSERT orders\", kind=SpanKind.CLIENT) as span:\n        span.set_attribute(\"db.system\", \"mssql\")\n        span.set_attribute(\"server.address\", \"sql-shop.database.windows.net\")\n        time.sleep(0.3 if slow else 0.02)\n        if slow:\n            span.set_status(Status(StatusCode.ERROR, \"timeout\"))\n            raise TimeoutError(\"Execution Timeout Expired\")\n\n",
      "note": "Um span `CLIENT` para a chamada ao banco, com os atributos das convenções semânticas para banco. Num timeout ele define o status como `ERROR` e lança a exceção, como um driver de verdade faria."
    },
    {
      "code": "def charge(order_id):\n    with tracer.start_as_current_span(\"POST /v1/charges\", kind=SpanKind.CLIENT) as span:\n        span.set_attribute(\"server.address\", \"api.payments.example\")\n        span.set_attribute(\"http.response.status_code\", 201)\n        time.sleep(0.01)\n\n",
      "note": "Um segundo span `CLIENT`, para o provedor de pagamentos."
    },
    {
      "code": "def checkout(order_id, slow=False):\n    with tracer.start_as_current_span(\"POST /checkout\", kind=SpanKind.SERVER) as span:\n        span.set_attribute(\"http.route\", \"/checkout\")\n        try:\n            insert_order(order_id, slow)\n            charge(order_id)\n            span.set_attribute(\"http.response.status_code\", 200)\n        except TimeoutError as error:\n            span.record_exception(error)\n            span.set_attribute(\"http.response.status_code\", 500)\n            span.set_status(Status(StatusCode.ERROR))\n\n",
      "note": "O span `SERVER` envolve a requisição inteira. Spans iniciados dentro dele viram filhos automaticamente, pelo contexto atual. Uma exceção capturada é registrada no span como evento, e o status vira `ERROR`."
    },
    {
      "code": "checkout(1042)\ncheckout(1043, slow=True)\n",
      "note": "Dois checkouts: um que funciona, e um cuja chamada ao banco estoura o tempo, como os de quinta."
    }
  ]
}
```

```
ana@laptop:~/azure/otel$ python3 shop_trace.py
trace 14c02459  span b2a632cc  parent 2d0299a3  CLIENT  INSERT orders     UNSET    20 ms
trace 14c02459  span a90226f9  parent 2d0299a3  CLIENT  POST /v1/charges  UNSET    10 ms
trace 14c02459  span 2d0299a3  parent -         SERVER  POST /checkout    UNSET    31 ms
trace 6a846832  span 292d70e8  parent 4a03e700  CLIENT  INSERT orders     ERROR   302 ms
trace 6a846832  span 4a03e700  parent -         SERVER  POST /checkout    ERROR   302 ms
```

Os seus ids e durações vão ser outros; eles são aleatórios e medidos a cada execução. Leia as linhas pela estrutura. **Os
spans são impressos quando terminam**, então os filhos vêm antes do pai. Os três primeiros dividem um id de trace, e os
dois spans `CLIENT` nomeiam o span `SERVER` como pai: um trace, uma requisição, duas chamadas. Os dois últimos são o
checkout lento: o `INSERT orders` dele terminou em `ERROR` depois de 300 ms, não há span de pagamento porque o código não
chegou lá, e o span `SERVER` também é `ERROR`. É o primeiro checkout que falhou na lição 11, contado pela própria
aplicação.

O `SimpleSpanProcessor` exporta cada span no momento em que ele termina, o que serve a uma demonstração. Um serviço real usa
o `BatchSpanProcessor`, que enfileira spans e os manda em lotes de uma thread em segundo plano, para um exportador lento
nunca atrasar uma requisição.
