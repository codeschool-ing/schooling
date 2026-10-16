---
title: Exchanges, and who gets a copy
version: 1
---

**The exchange decides who gets a message; the queue decides who does the work.** A message
published to an exchange is copied into every queue whose binding matches it, and into none if
nothing matches — in which case it is dropped, silently, unless the publisher asked to be told.
Each queue then hands its copy to one of its own consumers. Three exchange types cover almost every
use:

| type | a queue gets the message when | Ponto Final would use it for |
|---|---|---|
| **direct** | its binding key equals the message's routing key | orders for the Recife warehouse, and only those |
| **topic** | its binding pattern matches the routing key, word by word | every sale, or everything about Recife |
| **fanout** | always: the routing key is ignored | the same event to the audit log and the archive |

In a topic exchange the routing key is words separated by dots, `sale.recife`, and a binding's
pattern may use `*` for exactly one word and `#` for zero or more. This program declares one
exchange of each type, binds five queues, publishes six messages and then empties every queue to
see what landed where. Save it as `~/work/rabbit_routes.py`:

```schooling-example
{
  "file": "rabbit_routes.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"rabbit_routes.py: one message per shop event, three exchange types, and who got what.\"\"\"\nimport pika\n\nconn = pika.BlockingConnection(pika.ConnectionParameters(\"localhost\"))\nch = conn.channel()\n\nROUTES = {\n    \"direct\": [(\"recife-only\", \"recife\")],\n    \"topic\": [(\"all-sales\", \"sale.*\"), (\"all-recife\", \"*.recife\")],\n    \"fanout\": [(\"audit\", \"\"), (\"archive\", \"\")],\n}",
      "note": "Which queue is bound to which exchange, and with what. **The empty key on the fanout bindings is there because the call needs one**; a fanout exchange never reads it."
    },
    {
      "code": "for kind, queues in ROUTES.items():\n    ch.exchange_declare(exchange=f\"pf.{kind}\", exchange_type=kind)\n    for queue, key in queues:\n        ch.queue_declare(queue=queue)\n        ch.queue_purge(queue=queue)\n        ch.queue_bind(queue=queue, exchange=f\"pf.{kind}\", routing_key=key)",
      "note": "Declare the exchanges and queues, empty the queues of anything an earlier run left, and bind each one. All of these are idempotent: running the program twice gives the same layout."
    },
    {
      "code": "for key in [\"recife\", \"natal\"]:\n    ch.basic_publish(exchange=\"pf.direct\", routing_key=key, body=key)\nfor key in [\"sale.recife\", \"sale.natal\", \"refund.recife\"]:\n    ch.basic_publish(exchange=\"pf.topic\", routing_key=key, body=key)\nch.basic_publish(exchange=\"pf.fanout\", routing_key=\"ignored\", body=\"one event\")",
      "note": "Two messages to the direct exchange, three to the topic exchange, one to the fanout. **The body is the routing key**, so the output shows which key reached which queue."
    },
    {
      "code": "for kind, queues in ROUTES.items():\n    for queue, key in queues:\n        got = []\n        while (m := ch.basic_get(queue=queue, auto_ack=True))[0]:\n            got.append(m[2].decode())\n        print(f\"pf.{kind:7} {queue:12} bound with {key!r:10} got {got}\")\nconn.close()",
      "note": "`basic_get` pulls one message, or nothing, instead of waiting; a loop of them empties a queue. Handy for a demonstration, wasteful for a consumer, which should use `basic_consume`."
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
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Three messages published to the topic exchange pf.topic, and where they went. sale.recife matches both bindings, sale.* and *.recife, so the queues all-sales and all-recife each get a copy. sale.natal matches only sale.* and goes to all-sales. refund.recife matches only *.recife and goes to all-recife.\" data-fig=\"l15-topic-routing\"><defs><marker id=\"l15-topic-routing-ah-83\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l15-topic-routing-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"90\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">routing keys</text><text x=\"330\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">exchange</text><text x=\"630\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">queues and their bindings</text><rect x=\"30\" y=\"46\" width=\"120\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sale.recife</text><rect x=\"30\" y=\"106\" width=\"120\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sale.natal</text><rect x=\"30\" y=\"166\" width=\"120\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">refund.recife</text><rect x=\"280\" y=\"90\" width=\"100\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pf.topic</text><path d=\"M 150 60 L 278 120\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-topic-routing-ah-83)\"></path><path d=\"M 150 120 L 278 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-topic-routing-ah-8343)\"></path><path d=\"M 150 180 L 278 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-topic-routing-ah-8343)\"></path><rect x=\"560\" y=\"50\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">all-sales</text><text x=\"630\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">sale.*</text><text x=\"630\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sale.recife, sale.natal</text><path d=\"M 380 120 L 558 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-topic-routing-ah-8343)\"></path><rect x=\"560\" y=\"145\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">all-recife</text><text x=\"630\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">*.recife</text><text x=\"630\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sale.recife, refund.recife</text><path d=\"M 380 120 L 558 165\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-topic-routing-ah-8343)\"></path></svg>", "caption": "A topic exchange copies a message into every queue whose pattern matches its routing key, so one message can become two copies, and each copy is somebody's work."}
```

Read it by message rather than by queue:

- **`natal` on the direct exchange reached nobody.** No binding says `natal`, so the exchange had
  nowhere to put it, and it is gone. `basic_publish` reported nothing, because by default a
  publisher is not told; `mandatory=True` on the publish asks the server to return such a message,
  and publisher confirms tell it a message was safely taken. A producer that cares about loss uses
  both.
- **`sale.recife` reached two queues.** It matches `sale.*` and `*.recife`, and each queue got its
  own copy. The work, too, is now done twice, once by whoever consumes each queue, and that is the
  point: these are two different jobs.
- **`refund.recife` reached `all-recife` only**, because its first word is not `sale`.
- **The fanout copied one event into both of its queues**, and its routing key `ignored` was, as
  promised, ignored.

## This is how a queue fakes a log's many readers

The fanout exchange is the repair from this lesson's first section. With one queue per reader bound
to one fanout exchange, the stock, the loyalty points and the warehouse each get every sale, and
each consumes its own copy at its own pace. **What it does not repair is replay**: a queue bound
today receives what is published from today, and a reader whose queue was deleted, or never
existed, cannot ask for last week. That is still the log's, and the reason Ponto Final's sales go
to Kafka while its packing orders go to RabbitMQ.
