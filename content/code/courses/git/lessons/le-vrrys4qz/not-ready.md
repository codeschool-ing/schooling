---
title: The ticket that was not ready
version: 1
---

The bakery's team has grown. Carla joined as a developer and Diego tests every change before it is released,
so there are four people on the board now. On Monday, Ana takes ticket #35 from the top of *to do*:

> **#35 Pay online**

That is the whole ticket. By Wednesday she has discovered, one at a time, the questions it did not answer:

- **Which methods?** Card, Pix, or both? Pix is what most customers ask for, and nobody had said so.
- **With which company?** The bakery has no account with any payment provider. Opening one takes a week,
  and each provider's API is different.
- **What about refunds?** A cancelled order has to be paid back. Today that is a form filled in at the bank.
- **How will anybody know it is finished?** There are no acceptance criteria, so "done" is whatever Ana
  decides.

Three days of work built on guesses, and most of them were wrong. **The ticket was not ready to start**,
and nothing on the board said so.

## Ready is a checklist

Many teams write down what a ticket needs before anybody may take it, a **definition of ready**. It varies,
but most look like this:

1. **The problem is stated**, with who has it and why it matters.
2. **Acceptance criteria say how everybody will know it is done** (lesson 12).
3. **The open questions have answers**, or the ticket says which ones are still open and who will answer.
4. **Dependencies are known**: another team, a supplier, an account that must exist first.
5. **It is small enough** to finish in a few days. If not, it is split first.

#35 fails all five. Its title is a wish, not a ticket.

## When you find out halfway

It happens even on good teams, because some questions only appear once you start. When it does, **stop
guessing and say so**: write the questions on the ticket, tell whoever wrote it or the product owner, and mark
the card blocked, or move it back. The day you lose by asking costs less than the two days you lose by
answering yourself and being wrong.

The worst version is quiet: a developer who guesses, builds, and presents the result at the review, where
the person who asked sees it for the first time and says that is not what they meant. Lesson 19 is about
not being surprised at the end, and it starts here.
