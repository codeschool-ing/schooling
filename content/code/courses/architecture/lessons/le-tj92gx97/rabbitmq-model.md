---
title: RabbitMQ: exchanges, queues and bindings
version: 1
---

RabbitMQ implements AMQP 0-9-1, and its model has one surprise for newcomers: **a publisher never sends
to a queue.** It sends to an **exchange**, with a **routing key**, and the exchange decides which queues
get a copy, according to **bindings** that link queues to it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A publisher sends a message with routing key order.placed to the exchange orders. The exchange has two bindings with the pattern order.*, one to the queue email and one to the queue warehouse, so a copy of the message goes to each queue. A third queue, refunds, is bound with order.refunded and receives nothing.\"><defs><marker id=\"l6-exchange-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l6-exchange-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l6-exchange-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"100\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">publisher</text><text x=\"95\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">order.placed</text><rect x=\"240\" y=\"95\" width=\"140\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"310\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">exchange</text><text x=\"310\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders</text><path d=\"M162 125 L238 125\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6-exchange-ah-amber)\"></path><rect x=\"540\" y=\"40\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">email</text><path d=\"M382 125 L538 62\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6-exchange-ah-phosphor)\"></path><text x=\"460\" y=\"82.35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">order.*</text><rect x=\"540\" y=\"110\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">warehouse</text><path d=\"M382 125 L538 132\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6-exchange-ah-phosphor)\"></path><text x=\"460\" y=\"120.85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">order.*</text><rect x=\"540\" y=\"180\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"615\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">refunds</text><path d=\"M382 125 L538 202\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l6-exchange-ah-wire)\"></path><text x=\"460\" y=\"159.35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">order.refunded</text></svg>", "caption": "Publishers send to an exchange, never to a queue. The bindings decide which queues get a copy, and a message no binding matches goes nowhere."}
```

| piece | what it is |
| --- | --- |
| exchange | a named router; it holds no messages |
| queue | where messages wait for a consumer; it is the only place that stores them |
| binding | a rule linking a queue to an exchange, with a pattern for the routing key |
| routing key | a short string the publisher puts on each message, such as `order.placed` |

The exchange's **type** says how bindings are matched:

| type | delivers to every queue bound with | Quitanda example |
| --- | --- | --- |
| direct | exactly the message's routing key | `payment.declined` to the queue that handles declines |
| topic | a pattern, where `*` is one word and `#` is any number of words | `order.*` gets `order.placed` and `order.refunded` |
| fanout | every bound queue, whatever the key | a price change that every cache must hear |
| headers | a match on message headers instead of the key | rarely needed |

## Why the indirection

The publisher of `OrderPlaced` knows the exchange `orders` and nothing else. **Each interested service
creates its own queue and binds it**: the e-mail service a queue `email`, the warehouse a queue
`warehouse`. Adding a third service is one more queue and one more binding, and the publisher is not
touched, which is lesson 5's point about events, built into the broker.

Within one queue, the consumers compete; across queues, each queue gets its own copy. So "every
service gets every order" and "the warehouse's three workers share the orders" are both arrangements
of the same pieces: a queue per service, and several consumers on a queue.

## The case that loses messages

The flip side of the indirection is a silent loss. **A message that matches no binding is dropped by the
exchange**, and by default the publisher is not told. If the e-mail service's queue has not been
declared yet when the first orders are published, those orders never reach it. The next section shows
it happen, and lesson 7 shows the two settings that make a publisher find out: publisher confirms, and
the `mandatory` flag.
