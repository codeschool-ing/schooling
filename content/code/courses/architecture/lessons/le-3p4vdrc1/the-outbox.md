---
title: The transactional outbox
version: 1
---

The shop saves an order in its database and publishes a message so that payments will charge it.
Those are **two writes to two systems**, and no transaction covers both, lesson 1's lost guarantee
again. Each order of the two has a failure:

| the shop does | and crashes between the two | result |
| --- | --- | --- |
| commit the order, then publish | after the commit | an order nobody will ever charge |
| publish, then commit the order | after the publish | a payment for an order that does not exist |

The common fix people reach for, publishing inside the database transaction, does not help: the
publish is not part of the transaction and is not rolled back with it.

## Write the message where the order is

The **transactional outbox** puts the message in the shop's own database, in an `outbox` table, in the
same transaction as the order. Then the order and the intention to announce it are one fact: both
committed or neither. A separate **relay** reads the unsent rows, publishes each one, waits for the
broker's confirm, and only then marks the row as sent.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"The transactional outbox. The shop writes the order row and an outbox row in one transaction in its own database. A separate relay reads unsent outbox rows, publishes each to the broker, waits for the broker&#x27;s confirmation, then marks the row sent. The broker delivers to the payments consumer.\"><defs><marker id=\"l7-outbox-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l7-outbox-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"40\" width=\"290\" height=\"180\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"6 4\"></rect><text x=\"44\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">the shop's database, one transaction</text><rect x=\"50\" y=\"76\" width=\"250\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"175\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders: o-1, 649</text><rect x=\"50\" y=\"146\" width=\"250\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"175\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">outbox: o-1, sent = 0</text><text x=\"175\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">→ sent = 1 after the confirm</text><rect x=\"360\" y=\"146\" width=\"100\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"410\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">relay</text><rect x=\"500\" y=\"146\" width=\"90\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">broker</text><rect x=\"500\" y=\"50\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">payments consumer</text><path d=\"M302 171 L358 171\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7-outbox-ah-amber)\"></path><path d=\"M462 171 L498 171\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7-outbox-ah-amber)\"></path><path d=\"M545 144 L565 102\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7-outbox-ah-phosphor)\"></path><text x=\"410\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">retried until the broker confirms</text></svg>", "caption": "The order and its message are committed together, in one database. Getting the message to the broker is a separate step that can be retried until it succeeds."}
```

`outbox.py` is both halves. Stop the broker to make the point, and place an order. `--no-deps` stops
Compose from starting the broker again just because the `tools` service depends on it:

```
ana@vm:~/lab/delivery$ docker compose stop rabbitmq
 Container delivery-rabbitmq-1 Stopping 
 Container delivery-rabbitmq-1 Stopped 
ana@vm:~/lab/delivery$ docker compose --progress quiet run --rm --no-deps tools python outbox.py order o-1 649
order o-1 saved, its message waits in the outbox
ana@vm:~/lab/delivery$ docker compose --progress quiet run --rm --no-deps tools python outbox.py relay
broker unreachable; 1 message(s) wait in the outbox
```

**The order is saved, and so is its message**, even though the broker is unreachable; the relay could
not deliver it, said so, and left it in the outbox. Start the broker and run the relay again:

```
ana@vm:~/lab/delivery$ docker compose start rabbitmq
 Container delivery-rabbitmq-1 Starting 
 Container delivery-rabbitmq-1 Started 
ana@vm:~/lab/delivery$ $R outbox.py relay
relayed o-1
ana@vm:~/lab/delivery$ $R pay.py
charged o-1: 649 cents (redelivered: False)
```

The relay published `o-1`, the broker confirmed it, and the payments consumer charged it.

## What the outbox does not remove

The relay can crash after the broker confirms and before it marks the row sent, and the next run will
publish the same message again. **The outbox turns "maybe never" into "at least once"**, which is why
the consumer still has to be idempotent: the message carries the order id, and `processed` catches the
repeat. The two patterns are halves of one design, and neither works without the other.

In production the relay is rarely a script someone runs. It is a loop in the service, or a
change-data-capture tool such as Debezium, which reads the database's own log of committed changes and
publishes the outbox rows from there without polling the table.
