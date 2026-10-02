---
title: O que um rastreador de erros registra
version: 1
---

Um rastreador de erros é a ideia mais antiga desses produtos e a mais estreita. **Ele registra exceções,
não requisições**, e registra cada uma com muito mais em volta do que uma linha de log ou um span leva.
O SDK do Sentry é o exemplo aqui porque é de código aberto e se instala como qualquer biblioteca; o
script relata uma exceção do jeito que um serviço faria, só que o transport dele escreve o evento num
arquivo em vez de enviá-lo:

```schooling-example
{
  "language": "python",
  "file": "scratch/tracked.py",
  "parts": [
    {
      "code": "\"\"\"An error reported the way an error tracker's SDK reports it.\n\nThe DSN names a project and points nowhere; the transport writes each event\nto event.json instead of sending it.\n\"\"\"\nimport json\nimport logging\n\nimport sentry_sdk\nfrom sentry_sdk.transport import Transport\n\n\n"
    },
    {
      "code": "class ToFile(Transport):\n    def capture_envelope(self, envelope):\n        for item in envelope.items:\n            if item.type == \"event\":\n                with open(\"event.json\", \"w\") as f:\n                    json.dump(item.payload.json, f, indent=1)\n\n\n",
      "note": "Um **transport** é a parte do SDK que envia. Este escreve cada evento num arquivo, para a aula poder ler exatamente o que teria atravessado a rede."
    },
    {
      "code": "sentry_sdk.init(\n    dsn=\"https://key@errors.example.invalid/1\",\n    transport=ToFile,\n    release=\"shop@1.4.0\",\n    environment=\"lab\",\n)\n",
      "note": "O **DSN** nomeia o projeto a que um evento pertence e leva a chave dele; este aponta para um domínio que não pode existir. `release` e `environment` viajam com todo evento, e é isso que permite ao produto dizer *este erro começou na 1.4.0*."
    },
    {
      "code": "logging.basicConfig(level=logging.INFO)\nlog = logging.getLogger(\"checkout\")\n\n",
      "note": "O SDK se pendura no `logging` sozinho: todo registro de `INFO` para cima vira uma **breadcrumb**, guardada em memória e enviada só se um erro vier depois."
    },
    {
      "code": "COUPONS = {\"WELCOME10\": 10, \"FRIEND15\": 15}\n\n\ndef apply_coupon(total_cents, coupon):\n    return total_cents * (100 - COUPONS[coupon]) // 100\n\n\ndef checkout(sku, qty, card, coupon):\n    sentry_sdk.set_tag(\"sku\", sku)\n    log.info(\"pricing %s x %d\", sku, qty)\n    total_cents = 4900 * qty\n    log.info(\"applying coupon %s\", coupon)\n    return apply_coupon(total_cents, coupon)\n\n\n",
      "note": "Um bug comum: um cupom que ninguém definiu levanta `KeyError`. O `set_tag` acrescenta um campo indexado ao evento, buscável no produto como um label."
    },
    {
      "code": "try:\n    checkout(\"kettle\", 2, \"4111 1111 1111 1111\", \"WELCOME20\")\nexcept KeyError:\n    sentry_sdk.capture_exception()\nsentry_sdk.flush()\n",
      "note": "O `capture_exception` relata a exceção sendo tratada; uma não tratada é relatada sem ele. O `flush` espera o transport antes de o script terminar."
    }
  ]
}
```

```
ana@obs:~/shop$ docker compose run --rm sandbox python tracked.py
 Container shop-otel-collector-1 Running 
 Container shop-sandbox-run-19321cd586d2 Creating 
 Container shop-sandbox-run-19321cd586d2 Created 
INFO:checkout:pricing kettle x 2
INFO:checkout:applying coupon WELCOME20
```

As duas linhas `INFO` são o logging que o script faz. O evento que o SDK montou está em `event.json`, e
as partes que vale ler:

```
ana@obs:~/shop$ jq '{level, release, environment, tags, exception: [.exception.values[] | {type, value, frames: [.stacktrace.frames[] | select(.function != "<module>") | {function, lineno, vars}]}], breadcrumbs: [.breadcrumbs.values[] | .message]}' scratch/event.json
{
  "level": "error",
  "release": "shop@1.4.0",
  "environment": "lab",
  "tags": {
    "sku": "kettle"
  },
  "exception": [
    {
      "type": "KeyError",
      "value": "'WELCOME20'",
      "frames": [
        {
          "function": "checkout",
          "lineno": 42,
          "vars": {
            "sku": "'kettle'",
            "qty": "2",
            "card": "'4111 1111 1111 1111'",
            "coupon": "'WELCOME20'",
            "total_cents": "9800"
          }
        },
        {
          "function": "apply_coupon",
          "lineno": 34,
          "vars": {
            "total_cents": "9800",
            "coupon": "'WELCOME20'"
          }
        }
      ]
    }
  ],
  "breadcrumbs": [
    "pricing kettle x 2",
    "applying coupon WELCOME20"
  ]
}
```

Quatro coisas nele que nenhum sinal deste curso carregou até aqui:

- **A pilha, com as variáveis locais de cada frame.** O `apply_coupon` foi chamado com `'WELCOME20'`,
  um cupom que o `COUPONS` não tem, e o frame acima diz de onde. Uma linha de log teria dito
  `KeyError: 'WELCOME20'` e deixado o resto para ser reproduzido.
- **Breadcrumbs.** As linhas de log que vieram antes do erro, guardadas em memória e enviadas só agora.
  Elas não custam nada nos milhares de requisições que não falham.
- **A versão.** Todo evento nomeia a versão de onde veio, então o produto pode dizer quando um erro
  apareceu pela primeira vez e se a versão que dizia corrigi-lo corrigiu.
- **Um nível e tags**, que o tornam buscável como uma issue, e não como texto.

O que o evento não mostra é a coisa mais útil que o produto faz com ele. **O servidor agrupa eventos em
issues** pela pilha, então dez mil deste erro são uma linha numa tela, com uma contagem, a primeira e
a última vez em que foi visto e as versões em que apareceu. Agrupar pela pilha é o motivo de um
rastreador de erros ser mais quieto que uma busca em logs, e também de ele errar de um jeito
reconhecível: um bug levantado de dois lugares vira duas issues, e dois bugs levantados de uma função
auxiliar viram uma.

E há uma linha na saída que não devia estar lá. A próxima seção é sobre ela.
