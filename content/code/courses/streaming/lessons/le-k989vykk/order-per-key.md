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

@@fig:l2-per-key@@

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
