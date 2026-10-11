---
title: Stop starting, start finishing
version: 1
---

The slogan is old and it is exactly right: **stop starting, start finishing**. It sounds like a statement about effort and it is a statement about attention. A limit only changes anything at the moment somebody reaches it, and what they do at that moment decides whether the limit helps or just makes people wait.

## What to do when you cannot start

When a developer finishes an item and the limit says they may not start another, the board, read right to left, tells them what to do instead:

1. **Is anything waiting for review?** Review it. That was the Billing team's rule, and it emptied the queue lessons 2 and 3 found.
2. **Is anything blocked?** Help unblock it: chase the other team, find a workaround, split off the part that can ship.
3. **Is anything old?** Pair with whoever has it. Two people on the oldest item usually finish it sooner than one person on it and one on something new.
4. **Is there nothing at all?** Then the limit may be too low, or the work genuinely is flowing; improve a test, a tool or the documentation, and say so at the next standup so the limit can be reconsidered.

Working together on the oldest items is called **swarming**. It feels inefficient to people who measure how busy everybody is. It is efficient by the measure that matters to whoever is waiting for the work.

## Pull, not push

Underneath the slogan is a change in who decides when work starts. On the Billing team in June, items were **pushed**: whoever had capacity took the next item from the backlog, whatever was already waiting downstream. After 3 August they were **pulled**: an item was started only when the item ahead of it had moved on. In a pull system the downstream steps set the pace, and a queue cannot form in front of review because nothing is started faster than review can take it.

That is the same idea as Toyota's kanban cards, which `process-management` described: a card travelling back upstream as a request for more. The software version is simpler and the principle is identical. **Nothing is started until something has finished.**

## What changes for the tech lead

A limit moves the tech lead's attention from people to items. The question at a standup stops being "is everybody busy?" and becomes "what is stuck, and who is unsticking it?", which is lesson 3's walk of the board. It also changes the conversation upwards: a stakeholder asking for something to be started this week is asking for something else to wait, and the limit makes that trade visible instead of letting it happen silently in everybody's open items. Lesson 11 comes back to that conversation.
