---
title: Choosing the style of a conversation
version: 1
---

The choice is made per conversation, not per system. Quitanda's checkout will reasonably use both:
it asks pricing for the total and waits, because it cannot show the customer a basket without one,
and it announces `OrderPlaced` and moves on, because the e-mail, the loyalty points and the warehouse
can each catch up in their own time.

**The question that decides it is whether the caller needs the outcome before it can go on.**

| situation at Quitanda | style | why |
| --- | --- | --- |
| show the price of the basket | synchronous query | the page cannot be drawn without it |
| authorise the card at checkout | synchronous command | the customer is waiting for yes or no, and a no changes what happens next |
| send the confirmation e-mail | asynchronous event | nobody is waiting, and the e-mail service being down must not stop an order |
| tell the warehouse to pick the order | asynchronous command, on a queue | the warehouse works in its own rhythm, and a burst at lunch should wait in line |
| build the monthly report | asynchronous request-reply | too slow to hold a connection, and somebody does want the result |
| update a search index with a new product | asynchronous event | a few seconds of delay before it is searchable cost nothing |

## Three questions before going asynchronous

1. **What does the sender tell its own caller?** "Accepted" is the honest answer, and the screen has
   to be designed for it. "Your order is being processed" is a different promise from "your order is
   confirmed".
2. **What happens if the message is delivered twice, or not at all?** Lesson 7. If the answer is "the
   card is charged twice", the receiver needs to be idempotent before anything else.
3. **How long can the two sides disagree?** Seconds, for an e-mail. For stock that customers are
   buying, lesson 9 shows the disagreement on screen, and lesson 8 explains why it cannot be wished
   away.

**Synchronous is not the naive choice and asynchronous is not the advanced one.** Each is the right
shape for a different kind of conversation, and most of the trouble in distributed systems comes from
using one where the conversation has the shape of the other.
