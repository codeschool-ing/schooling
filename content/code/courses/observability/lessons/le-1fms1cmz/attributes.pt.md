---
title: Atributos: o que um span sabe
version: 2
---

Um span com só um nome e uma duração diz que algo levou tempo. **Atributos dizem com o que esse
tempo foi gasto**: pares de chave e valor, definidos enquanto o span está aberto, que um backend
pode buscar e agrupar. Este é o começo do checkout da vitrine, o span com que o rastro da aula 1
começava:

```schooling-example
{
  "language": "python",
  "file": "storefront/app.py",
  "parts": [
    {
      "code": "@app.post(\"/checkout\")\ndef checkout():\n    with tracer.start_as_current_span(\"POST /checkout\", kind=SpanKind.SERVER) as span:\n        body = request.get_json()\n        sku, qty = body[\"sku\"], int(body.get(\"qty\", 1))\n",
      "note": "Um span para a requisição inteira, aberto à mão. `kind=SpanKind.SERVER` diz que este span é a ponta que recebe uma chamada, o que os backends usam para desenhar a fronteira entre serviços."
    },
    {
      "code": "        span.set_attribute(\"http.request.method\", \"POST\")\n        span.set_attribute(\"http.route\", \"/checkout\")\n",
      "note": "Atributos das **convenções semânticas do OpenTelemetry**: nomes com que todo backend e toda biblioteca concordam, para que um painel feito para um serviço sirva para o seguinte."
    },
    {
      "code": "        span.set_attribute(\"shop.sku\", sku)\n        span.set_attribute(\"shop.quantity\", qty)\n",
      "note": "Os atributos próprios da loja, sob um prefixo só dela para nunca colidirem com uma convenção acrescentada depois."
    },
    {
      "code": "        if sku not in PRODUCTS:\n            span.set_attribute(\"http.response.status_code\", 404)\n            log.info(\"unknown product\", extra={\"fields\": {\"sku\": sku}})\n            return {\"error\": f\"no product {sku}\"}, 404\n        total = PRODUCTS[sku] * qty\n        span.set_attribute(\"shop.total_cents\", total)",
      "note": "Um 404 é registrado e **não marcado como erro**: a vitrine fez seu trabalho ao recusar um produto desconhecido. O número do cartão em `body` nunca vira atributo, de propósito."
    }
  ]
}
```

E isto é o que esse span carregava para um checkout de uma chaleira, como o Jaeger o guardou. Para
ver o seu, mande um checkout e peça ao log da vitrine o trace id do último; esse id vai no lugar do
que está no endereço abaixo:

```sh
curl -s -X POST localhost:8080/checkout -H 'Content-Type: application/json' -d @checkout.json
docker compose logs --no-log-prefix storefront | grep 'checkout finished' | tail -1 | jq -r .trace_id
```

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/7649c3dfb988a9ca71e4bec16bfca43f | jq -c '.data[0].spans[] | select(.operationName == "POST /checkout") | .tags[] | {key, value}'
{"key":"otel.scope.name","value":"storefront"}
{"key":"otel.scope.version","value":"1.4.0"}
{"key":"http.request.method","value":"POST"}
{"key":"http.status_code","value":201}
{"key":"http.route","value":"/checkout"}
{"key":"shop.quantity","value":1}
{"key":"shop.sku","value":"kettle"}
{"key":"shop.total_cents","value":18990}
{"key":"span.kind","value":"server"}
```

Três famílias se misturam nessa lista, e distingui-las é a maior parte da habilidade:

- **Atributos das convenções semânticas**, `http.request.method` e `http.route`. O OpenTelemetry
  publica os nomes para as coisas comuns: HTTP, bancos de dados, mensageria, recursos de nuvem. Use
  esses nomes sempre que algum servir, porque todo backend e toda instrumentação automática usam os
  mesmos, e uma consulta por `http.route` acha a rota não importa quem escreveu o span. O código de
  status saiu como `http.response.status_code`, a convenção atual, e o Jaeger o lista sob o nome
  antigo `http.status_code`.
- **Os atributos próprios da loja**, `shop.sku`, `shop.quantity` e `shop.total_cents`. Nada
  automático sabe o que é uma chaleira, e são esses atributos que tornam respondível *"os checkouts
  de um produto estão mais lentos?"*. O prefixo é da loja, então uma convenção acrescentada no ano
  que vem nunca vai significar outra coisa sob o mesmo nome.
- **O que o backend acrescentou**: `otel.scope.name` e `otel.scope.version` são o tracer que fez o
  span, e `span.kind` é o tipo que ele recebeu.

**O que não está na lista importa tanto quanto.** O corpo da requisição levava um número de cartão,
e o código nunca o copia para um atributo. Um rastro é guardado, transmitido entre sistemas,
amostrado, exportado para fornecedores e lido por qualquer pessoa depurando. Um número de cartão,
uma senha, um token ou um documento pessoal nele vaza para todos esses lugares de uma vez. A aula
10 faz o mesmo argumento para logs, com calma.

Um atributo pode ser tão específico quanto a requisição: um id de pedido, o país de um cliente, um
produto. **Essa é a diferença para um label de métrica**, que a aula 6 mostra se multiplicando num
número impagável de séries. Um span é guardado uma vez, digam o que disserem seus atributos, então
alta cardinalidade é exatamente para o que atributos servem. O *nome* de um span é outra história,
e a última seção desta aula trata dele.
