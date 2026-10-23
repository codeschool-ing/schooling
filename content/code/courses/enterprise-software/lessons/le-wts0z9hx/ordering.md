---
title: Ordering, and how much of it you need
version: 1
---

"A queue is first in, first out, so messages are processed in order." The first half is true of the
queue and the second half is false of almost every system built on one. **A queue hands messages out
in order; it does not finish them in order.** As soon as there are two consumers, a retry, or a
replay from a dead-letter queue, the order in which messages take effect can differ from the order
in which they were published. The good news is that the business rarely needs order across
everything. It needs order per thing: per product, per order, per farm.

## How two consumers reverse a price

SAP publishes a message whenever a material's price changes, and the portal applies it to the
price a bakery sees. On a Tuesday morning the pricing team corrected the price of butter 200 g
twice in a minute:

1. at 09:14:05, "price of butter 200 g is now R$ 10,00";
2. at 09:14:40, "price of butter 200 g is now R$ 12,00", the correction of the correction.

Both messages went to the queue in that order. Two instances of the portal's consumer read it.
Instance A took the first message and stalled for a few seconds on a slow database write; instance B
took the second, applied R$ 12,00, and committed. Then A finished and applied R$ 10,00. **The portal
showed R$ 10,00 while SAP said R$ 12,00**, and until the next price change every bakery that ordered
butter was quoted one price and invoiced another.

Nothing was lost and nothing was duplicated. Both messages were delivered once and processed
correctly, one at a time. The fault was only in the order, and order is the one thing the
previous sections did not protect.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l10-ordering\" aria-label=\"Two panels with the same arrivals, read from top to bottom. In both, instance B applies R$ 12,00, version 42, first, and instance A applies R$ 10,00, version 41, after it, because A was slow. Left, with no version check, the later write wins and the portal shows R$ 10,00 while SAP says R$ 12,00. Right, with a version check, A finds that 41 is older than the 42 already stored, changes no row, and the portal shows R$ 12,00.\"><defs><marker id=\"l10-ordering-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"178.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">no version check</text><rect x=\"28.0\" y=\"43.0\" width=\"300.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">queue: v41 R$ 10,00, then v42 R$ 12,00</text><path d=\"M178.0 74.0 L178.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-ordering-es-ah-paper-dim)\"></path><rect x=\"28.0\" y=\"109.0\" width=\"300.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">B: sets R$ 12,00 (v42)</text><path d=\"M178.0 140.0 L178.0 166.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-ordering-es-ah-paper-dim)\"></path><rect x=\"28.0\" y=\"175.0\" width=\"300.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">A: sets R$ 10,00 (v41)</text><path d=\"M178.0 206.0 L178.0 232.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-ordering-es-ah-paper-dim)\"></path><rect x=\"28.0\" y=\"240.0\" width=\"300.0\" height=\"32.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">portal R$ 10,00, SAP R$ 12,00</text><text x=\"542.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">with a version check</text><rect x=\"392.0\" y=\"43.0\" width=\"300.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"542.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">queue: v41 R$ 10,00, then v42 R$ 12,00</text><path d=\"M542.0 74.0 L542.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-ordering-es-ah-paper-dim)\"></path><rect x=\"392.0\" y=\"109.0\" width=\"300.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"542.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">B: sets R$ 12,00 (v42)</text><path d=\"M542.0 140.0 L542.0 166.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-ordering-es-ah-paper-dim)\"></path><rect x=\"392.0\" y=\"175.0\" width=\"300.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"542.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">A: 41 &lt; 42, no row changed</text><path d=\"M542.0 206.0 L542.0 232.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-ordering-es-ah-paper-dim)\"></path><rect x=\"392.0\" y=\"240.0\" width=\"300.0\" height=\"32.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"542.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">portal R$ 12,00, SAP R$ 12,00</text><path d=\"M360.0 30.0 L360.0 285.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path></svg>", "caption": "Two consumers finish the butter's two prices in the wrong order. Without a version the older price overwrites the newer; with one, the older price changes nothing."}
```

The same reversal has other causes that need no second consumer:

- **A retry.** The first message fails on a lock timeout and waits 4 seconds for its retry; the
  second arrives in the meantime and succeeds. The retried one then succeeds too, on top of it.
- **A replay.** A price message from three weeks ago sits in the dead-letter queue. Somebody fixes
  the cause and replays it, and the portal applies a price that was superseded twenty times since.
- **Two paths.** One message travels through a flow with an extra step and another through a
  shorter one. Neither queue is out of order; their outputs meet out of order.

## Three answers

**One consumer.** Order is kept if one consumer reads the queue, one message at a time, with no
retries that skip ahead. RabbitMQ calls this a *single active consumer*: several instances wait, and
only one reads. It is correct and it throws away the reason for having several consumers: the
throughput is that of one instance, and a poison message at the head stops the whole queue.

**Order per key.** Most order that matters is order *within* one entity. The butter's two prices
must be applied in order; the butter's price and the yoghurt's price need not. So route every
message about one key to the same consumer, and let different keys proceed in parallel:

- in Kafka, the producer gives each message a key, all messages with one key go to the same
  partition, and each partition is read by one member of the consumer group, in order;
- in Amazon SQS FIFO queues, the message group id does the same job;
- in Azure Service Bus, sessions do; in ActiveMQ, message groups, through the `JMSXGroupID`
  property.

The parallelism is now set by the number of keys and partitions rather than by the number of
consumers. A Kafka topic with 12 partitions keeps at most 12 members of a group busy, however many
are started; a 13th waits. And one key with a poison message blocks only its own partition, which is
better than blocking everything and still worse than blocking nothing.

**Versions, and a consumer that checks them.** Routing by key keeps order in transit. It does not
help with a replay from a dead-letter queue weeks later, and it does not help when two systems feed
the same consumer. For that the message itself must say where it belongs in the sequence: the
publisher stamps every message about one entity with an increasing **version**, and the consumer
stores the last version it applied for each entity.

## Discard or hold

What the consumer does with a message that arrives late depends on what the message says, which is
the distinction the idempotent-consumer section drew.

**A message that states a value can be discarded when it is old.** "Butter is now R$ 10,00, version
41" arriving after version 42 carries nothing the consumer needs, because version 42 already
contains everything that matters. The check is one SQL statement, with no read beforehand and no
race:

```sql
UPDATE price
   SET cents = :cents, version = :version
 WHERE material = :material
   AND version < :version;
```

If no row changed, the message was older than what the table holds, and the consumer acknowledges
it and moves on. The replay from three weeks ago does nothing, which is exactly right.

**A message that states a change cannot be discarded.** "Add 300 litres to farm 10233's
collection, version 7" arriving before version 6 is still needed; dropping it loses milk somebody
will be paid for. Additions happen to give the same total in any order, so for them the `processed`
table is enough. Many changes do not commute. "Order 4711: line 3 removed, version 7" arriving
before "line 3 added, version 6" removes nothing, and then the late addition puts back a line the
bakery took out. **The consumer has to hold version 7 until version 6 arrives, then apply both in
order.** Hohpe and Woolf (2003) call a component that does this a *resequencer*, and lesson 11
places it among the routing patterns. Holding has a hard question attached: how long to wait for a
version that may never come, and what to do when the wait runs out. Somebody has to answer it for
every such flow.

That is the practical argument for the advice in the idempotent-consumer section. **Design messages
that state the new value whenever you can.** They are idempotent, and with a version they are
safe in any order; a message that states a change needs a `processed` table, and a resequencer
as well when the changes do not commute.

## What the business actually needs

Joana went through the flows on her map with one question for each: in what order must these take
effect, and per what?

| flow | order needed | key |
|---|---|---|
| `invoice.paid` to the ledger | none: the total of the payments is the same in any order | none |
| prices from SAP to the portal | per material, latest wins | material, with SAP's change number as the version |
| order status from SAP to Salesforce | per order: created, delivered, invoiced | order number |
| farm collection volumes | per farm and day | farm and date |
| all messages in a topic, globally | nothing on the map | — |

**Not one flow needed global order.** Several needed none at all, and the rest needed it per
entity. That matters because global order costs the most: one partition, one consumer, and every
message waiting behind the slowest. When somebody asks for messages "in order", the useful reply is
the question Joana asked: in order per what?

The portal's price consumer now carries SAP's change number as a version and uses the conditional
update above. The butter incident can still happen in transit, and it no longer reaches a bakery:
the older price arrives, changes no row, and is acknowledged.
