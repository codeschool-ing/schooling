---
title: What most companies call a strategy
version: 1
---

Ask an engineering organisation for its technical strategy and you will usually be sent a list. It
has five to ten lines, each of them a goal, and every line is something nobody would argue against.
**That agreement is the problem.** A document nobody can disagree with has not chosen anything, and
choosing is the only work a strategy does.

This course follows one company the whole way through. **Coreto** is invented: a São Paulo company
that sells a ticketing platform to theatres, concert halls and festivals, and earns a fee on every
ticket. It has 52 engineers in seven teams, and most of what they run is `coreto-core`, a Rails
application nine years old. In January the CTO, Helena Prates, asked Davi Moreira, a staff engineer,
to write the company's first technical strategy. Davi collected what each team lead wanted and
came back with this:

> **Coreto technical strategy, first draft**
>
> 1. Be the most reliable ticketing platform in Brazil.
> 2. Reach 99.99% availability on checkout.
> 3. Migrate from the monolith to microservices.
> 4. Cut the cloud bill by 20%.
> 5. Adopt a modern front-end framework.
> 6. Pay down technical debt.

Every line is defensible. Read it again and try to answer three questions from it: **what is wrong
at Coreto, which of these matters most, and what will the company stop doing to get it.** The draft
answers none of them, and that is the test this lesson is built around.

## Four ways a strategy goes bad

Richard Rumelt, in *Good Strategy Bad Strategy* (2011), named the hallmarks of what he called bad
strategy. They are not the absence of a strategy; they are documents that look like one. All four
are in Davi's draft.

**Fluff** is language that sounds like insight and carries none. "Be the most reliable ticketing
platform in Brazil" is a superlative with no mechanism. It would read the same at any company in
the market, which is how you know it says nothing about this one.

**Failure to face the challenge** is the commonest and the most expensive. A strategy is a response
to a difficulty, and if the difficulty is not named, nobody can judge whether the response fits.
The draft never says what is going wrong. Line 6 gestures at it — "pay down technical debt" — and
stops short of saying which debt, or why now.

**Mistaking goals for strategy** is what the whole list does. "Reach 99.99% availability" is a
target; it says where to arrive and nothing about how. A team handed it does what teams do with a
target and no approach: each picks the work it already wanted to do and labels it with the goal.

**Bad strategic objectives** are goals that are too many, unconnected, or impossible to act on with
the resources available. Six goals for 52 engineers, several pulling against each other —
microservices and a framework migration both cost years of engineering time, and so does the cut
to the cloud bill — is a list where something will be dropped. The draft does not say which, so the
teams will decide one by one, and the company will not notice it decided.

## Why the list is so common

**A list is politically cheap.** Davi asked six team leads what they wanted and every one of them
found their wish in the result. Nobody lost an argument, because no argument happened. A real
strategy produces losers on paper: somebody's project waits a year, and they read that in the
document before they hear it in a meeting.

A list also survives any outcome. At the end of the year, something on it will have improved, and
the list can claim it. A strategy that named one challenge and one approach can be shown to have
been wrong, which is uncomfortable and is also the only way a company learns whether its strategy
works.

The next section gives the alternative its structure: three parts that a list does not have.
