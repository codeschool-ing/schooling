---
title: Which time to use
version: 1
---

**Use event time whenever the answer is about the world, and processing time only when the answer
is about the pipeline.** That one sentence settles most cases, and the rest of this section is
the cases where it needs a second look.

The usual mistake is not choosing processing time on purpose. It is never choosing at all: a
framework's default, a `now()` in a function, or a consumer that counts what it read "in the last
minute". Each of those is processing time, silently, and the result looks right on every day that
nothing went wrong.

| the question | the clock | why |
|---|---|---|
| sales per hour for the manager's report | event time | the hour belongs to the sale; a late till must not move it |
| is the card used in two cities ten minutes apart | event time | the ten minutes are between two purchases, not two arrivals |
| how many sales is the pipeline handling a second | processing time | that is a question about the pipeline itself |
| how far behind is the consumer | both | lag in time is processing time minus event time; lesson 16 measures it |
| a timeout: no answer from the payment service in 30 seconds | processing time | the wait is happening now, to a program |
| stock left on the shelf | neither, really | stock is state, folded from every sale in order per book; lesson 2 |
| which version of a price was in force for a sale | event time | the sale happened under one price, whenever it arrived |

Two rows deserve a sentence each. **Lag is the one place both clocks are the point**: the distance
between them is the measurement. And **stock is not a time question at all**, which is easy to
forget while reading a lesson about time. It needs every sale for a book, in an order that respects
the book's key, and lesson 2's fold gives it that.

## What event time costs

Event time is not free, and the costs are worth naming before choosing it everywhere:

- **Results wait.** An hour by event time is not finished at the end of the hour; it is finished
  when the processor decides nothing else will arrive for it. Lesson 11 is that decision.
- **State is kept.** While an hour is open, its running count has to be kept somewhere, for every
  key. A per-shop count by event time with a two-hour wait keeps two hours of open counts for five
  shops; per customer, for a million.
- **Every event needs a trustworthy time inside it.** The last section showed what that means for
  a device you do not run.

## Ingestion time, the compromise

`LogAppendTime` sits between the two. It is stamped by a clock you run, it is the same in every
replay, and in a well-behaved stream it is within seconds of event time. It is a reasonable choice
when the source has **no** time of its own worth trusting, such as events from devices whose
clocks you cannot fix. What it cannot do is put Natal's sales back in the morning: they were
appended at 14:00, and ingestion time says 14:00 for ever.

**Whatever you choose, write it down beside the result.** A table headed "sales per hour" is
ambiguous in exactly the way this lesson has spent five sections on. "Sales per hour, by the time
of sale, sales more than two hours late not included" is a number somebody can check.
