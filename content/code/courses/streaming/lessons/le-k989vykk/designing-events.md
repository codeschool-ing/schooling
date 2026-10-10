---
title: Designing an event that will still make sense next year
version: 1
---

**An event outlives the code that wrote it.** The till program is replaced, the stock system is
rewritten, and the log still holds sales from three years ago that somebody will replay. So an
event is designed the way a database table is, for readers nobody has met, and the decisions below
are cheap on the first day and expensive on any later one.

## Name what happened, in the past tense

`book-sold`, `stock-received`, `stock-counted`. A name in the past tense keeps the event a fact. The
names that cause trouble are the ones that are not:

- **A command in disguise**: `update-stock`, `send-receipt`. It tells a reader what to do, so it
  has one intended reader, and a second reader does not know whether it is meant to do it too.
- **A change with no meaning**: `sale-updated` with the whole new row. A reader can see that
  something changed and has to compare two rows to guess what. Was the sale refunded, or was a typo
  in the quantity corrected? Those are two different facts, `sale-refunded` and `sale-corrected`,
  and the stock system treats them differently.

## Give it an id that is unique for good

Every event carries an id that no other event has, written by whoever created the event. The tills
write `nat-000002`. **Duplicates are not an accident to be prevented; they are part of how streams
work**: a producer that did not hear back sends again, and a reader that crashed reads again. Lesson
7 shows both happening, and lesson 8 uses the id to make a second copy harmless. An event with no
id cannot be told apart from a different event with the same content, such as two customers buying
the same book in the same shop in the same second.

## Put the time it happened inside

`at` is the moment of the sale, from the till's own clock. The log will also record when it
received the event, and the reader knows when it read it, and both of those are different numbers
for a sale that was stuck on a till with no connection. **The time inside the event is the only one
that describes the sale**; lesson 9 shows the other two giving wrong answers.

## Choose the key on purpose

The key decides what stays in order. Key by the thing whose state the event changes: the shop, for
a stock kept per shop; the customer, for loyalty points. An event with no key loses its order with
everything, which is fine for a click counted in a total and wrong for anything folded into state.

## Say which shape it is

Sooner or later a field is added, renamed or split. A reader holding an event from before the
change needs to know which shape it has, and a reader written before the change needs to survive
events from after it. A version number in every event is the least that answers the first; a
**schema**, kept in a registry that writers and readers both consult, answers both, and lesson 6 is
about it.

## The tills, checked

| rule | the tills' sale | verdict |
|---|---|---|
| past tense | no type field; the topic `sales` names it | fine while the topic holds only sales |
| unique id | `sale`: `nat-000002` | yes |
| time inside | `at`, from the till | yes |
| key on purpose | the shop | yes, for stock per shop |
| shape declared | nothing | missing; lesson 6 adds it |

One event per topic, named by the topic, is a common design and a good one while it lasts. The day
a refund has to go in the same topic, because it must stay in order with the sale it refunds, every
event needs a `type`, as `stock.log` has. **Decide that on the day you create the topic, not the day
you need it**, because the events already written will not grow a field.
