---
title: What an event is, and what it is not
version: 1
---

**An event is a record that something happened.** It is written in the past tense because it is
about the past: a book was sold, a delivery was received, a stock count was taken. Nobody can
refuse it, because it has already happened, and nobody edits it later, because what happened does
not change. Everything else in this lesson rests on those two properties.

The common wrong picture is that an event is a message telling another system to do something.
That is a different thing with a different name, and it is worth keeping the three shapes apart,
because systems that mix them up are hard to change.

| | example | who it is for | can it be refused? |
|---|---|---|---|
| **command** | *reserve one copy of bk-03 for this customer* | one system, the one that must act | yes, and the sender has to find out |
| **event** | *one copy of bk-03 was sold in Recife at 09:00:41* | whoever wants to know, including readers that do not exist yet | no, it already happened |
| **state** | *Recife has 6 copies of bk-03* | whoever asks, now | no, but it is overwritten the moment it changes |

A **command** is addressed: whoever sends it knows who must carry it out and waits to hear whether
it worked. An **event** is not addressed at all. The till that rings up a sale does not know, and
should not know, whether the stock system, the loyalty scheme or the warehouse will read it. A
**state** is a snapshot: it answers *how many now* and forgets *how we got here*. The rest of this
lesson shows that state can always be rebuilt from the events, and the events can never be rebuilt
from the state.

## What goes inside one

This is a sale as the tills from lesson 1 send it:

```json
{"sale": "nat-000002", "shop": "natal", "book": "bk-08", "qty": 2, "cents": 17980, "at": "2026-03-02T09:00:09-03:00"}
```

Four kinds of field turn up in almost every well-made event, and this one has three of them:

- **An identity.** `sale` names this event and no other. When the same event arrives twice, and
  lesson 7 shows that it will, the id is how a reader recognises the second copy.
- **The time it happened.** `at` is the moment the till rang up the sale, written by the till.
  It is not when the event was sent, stored or read; lesson 9 is about keeping those apart.
- **What it is about.** `shop` says whose sale it is, and it is also the **key** Kafka uses to
  decide where the event is stored. Choosing the key is choosing which events keep their order,
  which is this lesson's last idea.
- **A version.** This one is missing. When the shape of a sale changes, a reader needs to know
  which shape it is holding, and lesson 6 adds one with a schema.

## Thin and fat

The sale above is **fat**: it carries the book, the quantity and the price, so a reader can do its
job without asking anybody anything. A **thin** event would carry only `{"sale": "nat-000002"}`
and expect the reader to look the rest up in the shop's database.

Thin looks tidier and costs more than it seems. Every reader now calls back to the source, so the
source has to stay up and answer for them; and by the time a reader asks, the row may have changed.
A reader handling a two-hour-old sale would see the price as it is now, not as it was charged.
Fat events cost bytes and make the event's shape a promise to every reader, which is why lesson 6
puts that shape under a schema. **This course's events are fat**, because a stream processor reads
millions of them and cannot afford a database call per event.
