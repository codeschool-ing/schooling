---
title: Spans dentro de spans, e o span corrente
version: 1
---

Um span por requisição diz quanto a requisição levou. **Spans dentro dele dizem para onde foi o
tempo**, e na aula 1 essa foi a resposta inteira. O `nested.py` calcula o preço de uma cesta com
dois produtos, com um span para a cesta e um por consulta, e imprime cada span terminado numa
linha:

```schooling-example
{
  "language": "python",
  "file": "nested.py",
  "parts": [
    {
      "code": "import time\n\nfrom opentelemetry import trace\nfrom opentelemetry.sdk.trace import TracerProvider\nfrom opentelemetry.sdk.trace.export import ConsoleSpanExporter, SimpleSpanProcessor\n\n\ndef one_line(span):\n    parent = format(span.parent.span_id, \"016x\") if span.parent else \"none\"\n    took = (span.end_time - span.start_time) / 1e6\n    return f\"{span.name:<16} span {span.context.span_id:016x}  parent {parent:<16}  {took:5.1f} ms\\n\"\n\n\nprovider = TracerProvider()\nprovider.add_span_processor(SimpleSpanProcessor(ConsoleSpanExporter(formatter=one_line)))\ntrace.set_tracer_provider(provider)\ntracer = trace.get_tracer(\"nested\")\n\nPRICES = {\"tea-500g\": 3450, \"kettle\": 18990}\n\n\n",
      "note": "Um formatador para o console imprimir uma linha por span: o nome, o id, o id do pai e quanto levou. Os tempos são guardados em nanossegundos, daí a divisão por um milhão."
    },
    {
      "code": "def price(sku):\n    with tracer.start_as_current_span(\"look up price\") as span:\n        span.set_attribute(\"shop.sku\", sku)\n        time.sleep(0.01)\n        return PRICES[sku]\n\n\n",
      "note": "**Nada aqui nomeia um pai.** O `start_as_current_span` faz do novo span um filho de qualquer que seja o span corrente, e quem chama decide qual é."
    },
    {
      "code": "with tracer.start_as_current_span(\"price basket\"):\n    total = price(\"tea-500g\") + price(\"kettle\")\nprint(\"total:\", total)",
      "note": "As duas chamadas acontecem enquanto `price basket` é o corrente, então as duas consultas viram filhas dele."
    }
  ]
}
```

```
ana@obs:~/shop$ docker compose run --rm sandbox python nested.py
 Container shop-otel-collector-1 Running 
 Container shop-sandbox-run-829101598f1e Creating 
 Container shop-sandbox-run-829101598f1e Created 
look up price    span 643cd2d47d78e040  parent e087853aa9ca2388   10.2 ms
look up price    span ae91b9a9c550a10e  parent e087853aa9ca2388   10.2 ms
price basket     span e087853aa9ca2388  parent none               20.7 ms
total: 22440
```

As duas consultas trazem **o id do span da cesta como pai**, e a cesta não tem pai: ela é a raiz. A
forma de um rastro é só isso, ids apontando para ids, e um backend reconstrói a árvore a partir
deles em qualquer ordem em que os spans cheguem. Aqui chegaram os filhos primeiro, porque um span é
exportado quando termina e a cesta só podia terminar depois das duas consultas. Os tempos também
se aninham: 20,7 milissegundos para a cesta, em volta de duas consultas de 10,2.

**O pai nunca foi passado.** O `price()` não tem argumento para ele. O OpenTelemetry mantém um
*span corrente*, aquele em cujo bloco `with` o código está. O `start_as_current_span` tanto o lê
para escolher o pai quanto o substitui durante o seu próprio bloco. Em Python o span corrente vive
numa variável de `contextvars`, então ele acompanha naturalmente uma chamada de função, e uma tarefa
`asyncio` leva uma cópia quando é criada. **Uma thread nova não leva**: ela começa sem span
corrente, o que é um dos jeitos mais comuns de perder um pai dentro de um único serviço.

Essa conveniência tem um limite, e ele fica exatamente onde um serviço encontra outro. O span
corrente vive na memória deste processo. Uma requisição a outro serviço, uma mensagem numa fila ou
uma tarefa iniciada por um temporizador não levam nada disso, a menos que algo escreva os ids na
própria requisição. A aula 4 trata desse algo, e o rastro da aula 1 já o mostrou funcionando: o
storefront, o orders, o payments e o mailer são quatro processos, e um rastro.
