---
title: Inject na saída, extract na entrada
version: 1
---

Duas operações fazem tudo, e têm o mesmo nome em toda linguagem que o OpenTelemetry suporta.
**Inject** escreve o contexto corrente no que quer que leve a requisição. **Extract** o lê de volta
do outro lado e entrega um contexto em que começar spans. O objeto que conhece o formato do
cabeçalho é um **propagador**, e o `opentelemetry.propagate` usa os que o `OTEL_PROPAGATORS` nomeou.

A vitrine, instrumentada à mão, faz o inject antes de chamar o `orders`:

```schooling-example
{
  "language": "python",
  "file": "storefront/app.py",
  "parts": [
    {
      "code": "        headers = {}\n        propagate.inject(headers)\n",
      "note": "**Inject**: o propagador escreve o contexto do span corrente num dicionário, como o cabeçalho `traceparent`. O span corrente aqui é o `POST /checkout`."
    },
    {
      "code": "        try:\n            answer = requests.post(\n                f\"{ORDERS}/orders\",\n                json={\"sku\": sku, \"qty\": qty, \"total_cents\": total, \"card\": body[\"card\"]},\n                headers=headers,\n                timeout=5,\n            )",
      "note": "O dicionário viaja como cabeçalhos HTTP. Nada mais na requisição precisa saber de rastreamento."
    }
  ]
}
```

E o payments faz o extract quando uma cobrança chega:

```schooling-example
{
  "language": "python",
  "file": "payments/app.py",
  "parts": [
    {
      "code": "@app.post(\"/charge\")\ndef charge():\n    ctx = propagate.extract(request.headers)\n",
      "note": "**Extract**: o propagador lê `traceparent` dos cabeçalhos que chegaram e devolve um contexto com o span de quem chamou como pai remoto. Se o cabeçalho faltar, o contexto vem vazio."
    },
    {
      "code": "    with tracer.start_as_current_span(\"POST /charge\", context=ctx, kind=SpanKind.SERVER) as span:",
      "note": "`context=ctx` é o que faz do novo span um filho de quem chamou em vez de uma raiz. É o único argumento que a próxima seção apaga."
    }
  ]
}
```

**O `orders` não faz nenhum dos dois, e mesmo assim os dois acontecem.** A instrumentação do Flask
extrai o cabeçalho que chega antes de o tratador rodar, e é por isso que o `POST /orders` saiu como
filho da vitrine na seção anterior. A instrumentação do `requests` injeta em toda chamada que sai, e
é assim que o payments recebe um `traceparent` de um serviço cujo código nunca menciona um. A
instrumentação automática é mais útil exatamente aqui: propagar são as mesmas poucas linhas em toda
chamada, e esquecê-las uma vez quebra o rastro.

Então a regra para um serviço é simples de dizer: **todo jeito pelo qual uma requisição sai precisa
fazer inject, e todo jeito pelo qual uma chega precisa fazer extract.** O HTTP é coberto pelas
instrumentações. O que não é coberto é todo outro portador: uma mensagem numa fila, uma linha que uma
tarefa vai ler depois, um arquivo deixado para outro programa. Cada um desses é um lugar onde alguém
tem de escrever as duas chamadas à mão ou instalar a instrumentação que as faz.
