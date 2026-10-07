---
title: When pairing pays, and what it costs
version: 1
---

**Pairing costs more person-hours per task and buys fewer defects, faster learning and a second
person who understands the code.** Whether that is a good trade depends on the task, and the error in
both directions is common: teams that never pair because it "halves productivity", and teams that
pair on everything and wonder why they are tired.

## What the evidence says

The most cited early study, by Alistair Cockburn and Laurie Williams in 2000, compared students
working alone and in pairs. The pairs spent about 15% more total effort on the same programs and
produced code with about 15% fewer defects. Later studies, including a meta-analysis by Jo Hannay and
colleagues in 2009, found the effects real but modest and dependent on the task: pairing helped most
on complex tasks and with less experienced programmers, and helped least, or cost the most, on simple
tasks done by experts.

**So the answer to "does pairing pay?" is "for which task, and which pair?"**, and the next part is a
way to answer it.

## Pair when

- **The task is hard or risky.** A change to how checkout reserves stock (lesson 8's flash deals) is
  where a second person catching a mistake is worth an hour of their time.
- **Knowledge needs to spread.** Only one person understands the outbox reader; pairing the next change
  to it with somebody else takes the bus factor from one to two in a week.
- **Somebody is new**, to the team, the codebase or the language. Pairing is the fastest onboarding
  there is; lesson 10's stretch assignment went faster because Diego paired on the first part.
- **Two people disagree about a design.** Writing the first version together often settles it faster
  than the argument would have.

## Do not pair when

- **The task is simple and well understood.** A configuration change, a copy fix, an upgrade the
  tooling does for you.
- **The work is exploratory reading.** Reading a large codebase to understand it is done alone, and
  then discussed.
- **One of the two is exhausted**, or has been pairing all day.

## The cost people forget

The 15% extra effort is visible on the day. What is not visible is the cost of **not** pairing on the
right tasks: the outbox reader that only one person understands goes down while that person is on
holiday, and the team spends two days learning it under pressure. Pairing moves that cost earlier and
makes it smaller. **Whether the trade is worth it is a question about risk and knowledge, not about
typing speed.**
