---
title: Exchanges, e quem recebe uma cópia
version: 1
---

**A exchange decide quem recebe uma mensagem; a fila decide quem faz o trabalho.** Uma mensagem
publicada numa exchange é copiada para toda fila cujo binding combina com ela, e para nenhuma se
nada combina — e nesse caso ela é descartada, em silêncio, a menos que o publicador tenha pedido
para ser avisado. Cada fila então entrega a sua cópia a um dos próprios consumidores. Três tipos de
exchange cobrem quase todo uso:

| tipo | uma fila recebe a mensagem quando | a Ponto Final usaria para |
|---|---|---|
| **direct** | a chave do binding é igual à routing key da mensagem | pedidos do depósito do Recife, e só esses |
| **topic** | o padrão do binding casa com a routing key, palavra por palavra | toda venda, ou tudo sobre o Recife |
| **fanout** | sempre: a routing key é ignorada | o mesmo evento para o log de auditoria e para o arquivo |

Numa exchange topic a routing key são palavras separadas por pontos, `sale.recife`, e o padrão de um
binding pode usar `*` para exatamente uma palavra e `#` para zero ou mais. Este programa declara
uma exchange de cada tipo, liga cinco filas, publica seis mensagens e depois esvazia cada fila para
ver o que caiu onde. Salve-o como `~/work/rabbit_routes.py`:

```schooling-example
{
  "language": "python",
  "file": "rabbit_routes.py",
  "parts": [
    {
      "code": "\"\"\"rabbit_routes.py: one message per shop event, three exchange types, and who got what.\"\"\"\nimport pika\n\nconn = pika.BlockingConnection(pika.ConnectionParameters(\"localhost\"))\nch = conn.channel()\n\nROUTES = {\n    \"direct\": [(\"recife-only\", \"recife\")],\n    \"topic\": [(\"all-sales\", \"sale.*\"), (\"all-recife\", \"*.recife\")],\n    \"fanout\": [(\"audit\", \"\"), (\"archive\", \"\")],\n}",
      "note": "Qual fila está ligada a qual exchange, e com o quê. **A chave vazia nos bindings do fanout está lá porque a chamada exige uma**; uma exchange fanout nunca a lê."
    },
    {
      "code": "for kind, queues in ROUTES.items():\n    ch.exchange_declare(exchange=f\"pf.{kind}\", exchange_type=kind)\n    for queue, key in queues:\n        ch.queue_declare(queue=queue)\n        ch.queue_purge(queue=queue)\n        ch.queue_bind(queue=queue, exchange=f\"pf.{kind}\", routing_key=key)",
      "note": "Declara as exchanges e as filas, esvazia as filas do que uma execução anterior deixou, e liga cada uma. Tudo isso é idempotente: rodar o programa duas vezes dá o mesmo arranjo."
    },
    {
      "code": "for key in [\"recife\", \"natal\"]:\n    ch.basic_publish(exchange=\"pf.direct\", routing_key=key, body=key)\nfor key in [\"sale.recife\", \"sale.natal\", \"refund.recife\"]:\n    ch.basic_publish(exchange=\"pf.topic\", routing_key=key, body=key)\nch.basic_publish(exchange=\"pf.fanout\", routing_key=\"ignored\", body=\"one event\")",
      "note": "Duas mensagens para a exchange direct, três para a topic, uma para a fanout. **O corpo é a própria routing key**, então a saída mostra qual chave chegou a qual fila."
    },
    {
      "code": "for kind, queues in ROUTES.items():\n    for queue, key in queues:\n        got = []\n        while (m := ch.basic_get(queue=queue, auto_ack=True))[0]:\n            got.append(m[2].decode())\n        print(f\"pf.{kind:7} {queue:12} bound with {key!r:10} got {got}\")\nconn.close()",
      "note": "`basic_get` puxa uma mensagem, ou nada, em vez de esperar; um laço deles esvazia uma fila. Prático numa demonstração, desperdício num consumidor, que deve usar `basic_consume`."
    }
  ]
}
```

```
ubuntu@stream:~/work$ python rabbit_routes.py
pf.direct  recife-only  bound with 'recife'   got ['recife']
pf.topic   all-sales    bound with 'sale.*'   got ['sale.recife', 'sale.natal']
pf.topic   all-recife   bound with '*.recife' got ['sale.recife', 'refund.recife']
pf.fanout  audit        bound with ''         got ['one event']
pf.fanout  archive      bound with ''         got ['one event']
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Três mensagens publicadas na exchange topic pf.topic, e para onde foram. sale.recife casa com os dois bindings, sale.* e *.recife, então as filas all-sales e all-recife recebem uma cópia cada. sale.natal casa só com sale.* e vai para all-sales. refund.recife casa só com *.recife e vai para all-recife.\" data-fig=\"l15-topic-routing\"><defs><marker id=\"l15-topic-routing-ah-83\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l15-topic-routing-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"90\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">routing keys</text><text x=\"330\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">exchange</text><text x=\"630\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">filas e seus bindings</text><rect x=\"30\" y=\"46\" width=\"120\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sale.recife</text><rect x=\"30\" y=\"106\" width=\"120\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sale.natal</text><rect x=\"30\" y=\"166\" width=\"120\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">refund.recife</text><rect x=\"280\" y=\"90\" width=\"100\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pf.topic</text><path d=\"M 150 60 L 278 120\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-topic-routing-ah-83)\"></path><path d=\"M 150 120 L 278 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-topic-routing-ah-8343)\"></path><path d=\"M 150 180 L 278 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-topic-routing-ah-8343)\"></path><rect x=\"560\" y=\"50\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">all-sales</text><text x=\"630\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">sale.*</text><text x=\"630\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sale.recife, sale.natal</text><path d=\"M 380 120 L 558 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-topic-routing-ah-8343)\"></path><rect x=\"560\" y=\"145\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">all-recife</text><text x=\"630\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">*.recife</text><text x=\"630\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sale.recife, refund.recife</text><path d=\"M 380 120 L 558 165\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-topic-routing-ah-8343)\"></path></svg>", "caption": "Uma exchange topic copia a mensagem para toda fila cujo padrão casa com a routing key dela, então uma mensagem pode virar duas cópias, e cada cópia é trabalho de alguém.", "same": ["routing keys", "exchange"]}
```

Leia por mensagem, não por fila:

- **`natal` na exchange direct não chegou a ninguém.** Nenhum binding diz `natal`, então a exchange
  não tinha onde pô-la, e ela sumiu. O `basic_publish` não avisou nada, porque por padrão o
  publicador não é avisado; `mandatory=True` no publish pede ao servidor que devolva uma mensagem
  assim, e os publisher confirms dizem que uma mensagem foi aceita com segurança. Um produtor que se
  importa com perda usa os dois.
- **`sale.recife` chegou a duas filas.** Ela casa com `sale.*` e com `*.recife`, e cada fila recebeu
  a sua cópia. O trabalho, também, agora é feito duas vezes, uma por quem consome cada fila, e é
  esse o ponto: são dois trabalhos diferentes.
- **`refund.recife` chegou só à `all-recife`**, porque a primeira palavra dela não é `sale`.
- **O fanout copiou um evento para as duas filas dele**, e a routing key `ignored` foi, como
  prometido, ignorada.

## É assim que uma fila imita os muitos leitores de um log

A exchange fanout é o remendo da primeira seção desta lição. Com uma fila por leitor ligada a uma
exchange fanout, o estoque, os pontos de fidelidade e o warehouse recebem cada um toda venda, e cada
um consome a própria cópia no próprio ritmo. **O que ela não remenda é o replay**: uma fila ligada
hoje recebe o que for publicado a partir de hoje, e um leitor cuja fila foi apagada, ou nunca
existiu, não pode pedir a semana passada. Isso continua sendo do log, e é o motivo de as vendas da
Ponto Final irem para o Kafka enquanto os pedidos de embalagem vão para o RabbitMQ.
