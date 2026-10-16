---
title: Who decides, written down before anybody needs to know
version: 1
---

Autonomy is usually discussed as a feeling: the team feels trusted or it does not. **It is more
useful as a list of decisions, each with an owner.** A team has as much autonomy as the decisions
it can make without asking, and it knows how much it has only if the list exists. Lesson 2 wrote
such a list between two leads. This section writes it between a team and everybody above and
around it.

## Doors that open both ways

Amazon's 2015 letter to shareholders contains a distinction that has spread through software
companies because it is so easy to apply. Some decisions are **one-way doors**: consequential and
hard or impossible to reverse, so they deserve care and the judgement of more people. Most are
**two-way doors**: if the decision turns out wrong, you walk back through and try something else.
The letter's warning is that organisations tend to treat every decision as a one-way door, which
makes everything slow.

The distinction gives a first answer to "who decides". **Two-way doors belong as close to the work
as possible**, because the cost of a wrong decision is small and the cost of waiting is not. One-way
doors go up, or out, to whoever has to live with the consequences.

| decision on Agenda | which door | who decides |
|---|---|---|
| the order of work inside the quarter's goal | two-way | the team, with Helena |
| the wording of a reminder | two-way, within the text legal approved | the team |
| a new public API that clinics' systems will call | one-way: clinics build on it | Diego, after a design review with the platform team |
| dropping a feature a clinic paid for | one-way: a commercial promise | Otávio, with sales |
| changing the database engine | one-way, and expensive | a design review across teams |
| who on the team works on what | two-way | Renata, consulting Diego |

Two caveats keep the idea honest. Plenty of decisions look like two-way doors and are not, because
something else gets built on them before anybody notices: a field name in an API is easy to change
on the day it ships and very hard six months later. And a two-way door taken repeatedly in the
wrong direction is expensive in aggregate, even if each trip back is cheap.

## Decisions that fall between chairs

The list catches a kind of problem that is otherwise invisible: decisions everybody assumes
belong to somebody else. On Agenda, nobody had decided who could turn off a feature flag in
production during the night. The on-call engineer assumed it needed Diego; Diego assumed on-call
could do it. The question came up at three in the morning, during an incident, and was answered by
a twenty-minute wait for Diego to wake up.

**The decisions that matter most to write down are the ones that will be needed in a hurry.** A
team can work out the owner of a design question over a week. It cannot work out the owner of a
rollback while customers are failing to book.

## The decisions page, extended

Lesson 1 started a decisions page in your notebook with four columns: the date, what was decided,
why, and what you expect to see if you were right. Add two:

- **Who decided.** A name, or a group with a rule ("the team, by agreement in planning").
- **Which door.** One-way or two-way, as judged at the time.

The first makes it possible to see, months later, whether decisions are being made at the right
level. If every line on Renata's page says "Renata", the team has less autonomy than she thinks it
has. The second makes it possible to check the judgement afterwards: a decision logged as two-way
that turned out to be hard to reverse is worth a sentence about why.

## Your task

For a team you know, list ten decisions it makes in a typical month. For each, write which door it
is and who decides it today. Then check:

- At least half the two-way doors are decided by the people doing the work.
- Every one-way door has a named owner, not "management".
- At least one decision would be needed in a hurry, during an incident or outside working hours,
  and its owner is somebody who would be awake.
- If one name appears on most lines, you have found where the team's autonomy is going.
