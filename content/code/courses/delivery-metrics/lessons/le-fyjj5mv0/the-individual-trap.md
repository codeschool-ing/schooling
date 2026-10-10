---
title: The trap of measuring one person
version: 1
---

Every team that starts measuring flow eventually gets asked the same question by somebody above it: **"which of your developers is the most productive?"** The numbers seem to be right there. Each item has an assignee, each commit an author, each review a reviewer. Summing them per person takes minutes. It is the most damaging thing you can do with delivery data, and the reasons are specific.

## What per-person numbers measure

Lines of code per person measure who writes the most lines, which rewards verbose code and punishes deleting it. Commits per person measure who commits most often. Story points per person measure who estimates highest, or who takes the items whose estimates were most generous. Items finished per person measure who takes small items. **Each one measures a habit of the individual, not a contribution to the team**, and each one rewards a habit that makes the team worse.

## What per-person numbers cannot see

The work that makes a team fast is mostly invisible at the level of one person:

- **Reviewing.** After 3 August, the Billing team's developers reviewed before starting anything new. That rule is why its cycle time fell by three quarters. It also lowered every developer's count of items finished in the weeks they spent reviewing.
- **Unblocking.** Whoever finally gets `BIL-189` moving, by persuading another team to make its change, will have done the most valuable work on the board that week and closed no item of their own.
- **Pairing and teaching.** Two people on one item finish it sooner and count once.
- **Incidents and on-call.** The person who restored service at two in the morning has an empty commit history for the next day.

A per-person ranking punishes exactly these, and people respond to what is measured, as lesson 7 showed. **Rank developers by items finished and they will stop reviewing each other's work**, and the queue lessons 2 and 3 found in front of Bia will come back in front of everybody.

## The 2023 argument

The question returned to public debate in 2023, when the consultancy McKinsey published an article arguing that developer productivity could be measured, including at the level of individuals, and proposing metrics to do so. The response from practitioners was sharp; one of the most widely read was a two-part reply by Kent Beck and Gergely Orosz, which argued that measuring effort and output per person changes behaviour in ways that harm outcomes, and that measurement should focus on the impact a team delivers.

You do not need to settle that argument to act on this lesson. The SPACE paper itself warns against using its dimensions to rank individuals, and DORA's metrics are defined for teams and systems. **The research the course rests on measures teams.** Using it to measure people is using it for something it was not built to support.

## The question behind the question

When somebody asks which developer is most productive, they usually want to know something legitimate: whether anybody is struggling, whether the team has the people it needs, whether a promotion is deserved. Each of those has a better instrument than a ranking, and the next sections name them.
