---
title: The idempotent consumer
version: 1
---

An operation is **idempotent** when doing it twice has the same effect as doing it once. Setting a
price to 3,290 is idempotent; adding 3,290 to a balance is not; charging a card is not, unless the
charge carries something that lets the second attempt be recognised.

The common fix is to make duplicates impossible upstream. That cannot be done, as the first section
showed, so **the consumer is made to recognise a message it has already handled**, using the id the
message carries.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The idempotent consumer. A message with id q-2 arrives. In one database transaction the consumer inserts q-2 into the processed table and inserts the charge. The first delivery commits both. A second delivery of q-2 fails on the processed table&#x27;s primary key, the transaction rolls back, and the consumer acknowledges the message without charging again.\"><defs><marker id=\"l7-dedup-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l7-dedup-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"90\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">message</text><text x=\"90\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">id q-2</text><rect x=\"200\" y=\"40\" width=\"300\" height=\"150\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"6 4\"></rect><text x=\"214\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">one transaction</text><rect x=\"220\" y=\"72\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">INSERT INTO processed ('q-2')</text><rect x=\"220\" y=\"128\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">INSERT INTO charges …</text><path d=\"M152 115 L198 115\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7-dedup-ah-amber)\"></path><rect x=\"550\" y=\"50\" width=\"150\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">first delivery</text><text x=\"625\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">both committed</text><rect x=\"550\" y=\"130\" width=\"150\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">second delivery</text><text x=\"625\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">key exists: skip</text><path d=\"M502 92 L548 77\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7-dedup-ah-phosphor)\"></path><path d=\"M502 148 L548 157\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7-dedup-ah-amber)\"></path><text x=\"350\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">then acknowledge, in both cases</text></svg>", "caption": "The record of having handled a message and the effect of handling it are written in one transaction, so they can never disagree."}
```

`pay.py` without `--naive` does exactly that: in the same transaction as the charge, it inserts the
message id into `processed`, whose primary key refuses a second insert of the same id. Ask for
payment `q-2` and crash after charging once more:

```
ana@vm:~/lab/delivery$ $R publish.py q-2 2450
confirmed by the broker: q-2
ana@vm:~/lab/delivery$ $R pay.py --crash-after-charge
charged q-2: 2450 cents (redelivered: False)
crashing before the acknowledgement
```

The same crash as before, and the message is again unacknowledged. Run the consumer normally:

```
ana@vm:~/lab/delivery$ $R pay.py
skipped q-2: already charged (redelivered: True)
ana@vm:~/lab/delivery$ $R pay.py --list
charged q-1 3290
charged q-1 3290
charged q-2 2450
```

The message came back, `redelivered: True`, and this time the insert into `processed` failed on the
primary key, the transaction rolled back, and the consumer acknowledged the message **without
charging**. The list shows `q-2` once, beside the two charges of `q-1` the naive consumer left behind.

## Why the same transaction matters

The record of having handled the message and the effect of handling it **must commit together**. If
the consumer wrote `processed` first, committed, and then charged, a crash between the two would leave
the message marked as done and the customer never charged, which is at most once again, just moved.
If it charged first and recorded afterwards, a crash between them is the duplicate this section exists
to prevent. One transaction makes the two a single fact.

When the effect is not in the consumer's own database, a call to a real card processor for instance,
there is no shared transaction to use. The consumer then passes the message id on as an
**idempotency key**, and relies on the other side to recognise it, which is the next section.

## How long to remember

`processed` grows by one row per message, for ever. A real consumer keeps ids for longer than the
longest a duplicate could arrive late, which is bounded by the broker's redelivery and by how far back
anybody might replay, and deletes older rows. The bound is a decision; leaving it unmade is a table that
fills a disk in a year.
