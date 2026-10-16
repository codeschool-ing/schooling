---
title: Order per key is enough, and it is what scales
version: 1
---

**Only events about the same thing need to stay in order with each other.** Recife's count has to
come before Recife's sales. Whether Recife's count comes before or after Olinda's sale changes
nothing, because no event about Olinda ever touches Recife's row. The thing an event is about is
its **key**, and keeping order *per key* is a much weaker promise than keeping it for the whole
log.

Test it. Rearrange `stock.log` so that every Olinda event comes first and every other event after,
each group still in its own order. That moves seven of the eight lines and changes the order between
the shops completely:

```
ubuntu@stream:~/work$ (grep olinda stock.log; grep -v olinda stock.log) > by-shop.log
ubuntu@stream:~/work$ python balance.py by-shop.log
olinda  bk-03    3
recife  bk-03    6
```

The same answer as the original, 3 and 6. The total order of the log was destroyed and the result
did not move, because **the order inside each key was kept**. Compare the last section, where a
single line moved, within one key, and the answer went wrong.

## What a total order costs

A single order for every event means a single place where events are put in order: one file, one
process, one machine that every writer has to go through. That is what `minilog.py` is, and it has
a ceiling: the log can take only as many events per second as that one place can append. Adding a
second machine does not help unless the two can agree, for every event, which one came first,
and that agreement is a round trip between them for each write.

Order per key removes the ceiling. If every event about Recife goes to one log and every event about
Olinda to another, each log only has to keep its own order, and the two logs can live on two
machines that never talk to each other. Five shops can use five logs; five hundred shops can share
fifty, as long as **one shop never uses more than one**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Left: one log holding every event in one total order, recife and olinda interleaved, with one writer in front of it. Right: the same events split by key into two logs. A hash of the key picks the log, so every recife event goes to log 0 and every olinda event to log 1. Each log keeps its own order, and nothing orders log 0 against log 1.\" data-fig=\"l2-per-key\"><text x=\"175\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">one log: total order</text><rect x=\"20\" y=\"110\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"37\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rec0</text><rect x=\"60\" y=\"110\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"77\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">oli1</text><rect x=\"100\" y=\"110\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"117\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rec2</text><rect x=\"140\" y=\"110\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"157\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">oli3</text><rect x=\"180\" y=\"110\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"197\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rec4</text><rect x=\"220\" y=\"110\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"237\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rec5</text><rect x=\"260\" y=\"110\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"277\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">oli6</text><rect x=\"300\" y=\"110\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"317\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rec7</text><text x=\"175\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">every write goes through one place</text><line x1=\"360\" y1=\"20\" x2=\"360\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\"></line><text x=\"545\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">by key: order per key</text><text x=\"545\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hash(key) % 2</text><text x=\"400\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">log 0</text><text x=\"400\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">log 1</text><rect x=\"425\" y=\"85\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"442\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rec0</text><rect x=\"465\" y=\"85\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"482\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rec2</text><rect x=\"505\" y=\"85\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"522\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rec4</text><rect x=\"545\" y=\"85\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"562\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rec5</text><rect x=\"585\" y=\"85\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"602\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rec7</text><rect x=\"425\" y=\"155\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"442\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">oli1</text><rect x=\"465\" y=\"155\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"482\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">oli3</text><rect x=\"505\" y=\"155\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"522\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">oli6</text><text x=\"545\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no order between the two logs</text></svg>", "caption": "A total order needs one place every event goes through; order per key needs one place per key."}
```

## Hashing a key to a place

The rule that sends each key to one log has to give the same answer every time, on every machine,
with no table to look up. The usual rule is a hash: compute a number from the key's bytes and take
it modulo the number of logs. `recife` always hashes to the same number, so it always lands in the
same log, and so does every other key, each in its own log or sharing one with others.

Kafka calls these logs **partitions**. A topic is a set of partitions, the producer hashes each
message's key to choose one, and Kafka's promise about order is exactly this section's: **within a
partition, in the order written; across partitions, nothing**. Lesson 3 shows the hash at work, and
one surprise in it: two Kafka clients can hash the same key to different partitions.

## The key is a decision

Choosing the key is choosing which events keep their order with each other, and there is no key that
keeps every order somebody might want:

| key | kept in order | not in order with each other |
|---|---|---|
| shop | all of one shop's events, whatever the book | two shops selling the same book |
| book | every sale of one book, across shops | a shop's sales of different books |
| nothing (no key) | nothing at all | everything; the producer spreads messages over partitions |

The tills use the shop, which suits a stock kept per shop. The hard case is an event about **two**
keys: a transfer of five copies from Recife to Olinda takes from one row and adds to another, and
with the shop as key it can only be in order with one of them. The usual answer is two events, one
per shop, each keyed by its own shop, and lesson 8 makes that safe when one of the two arrives
twice.
