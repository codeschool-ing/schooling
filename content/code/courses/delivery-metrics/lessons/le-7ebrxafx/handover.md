---
title: The handover
version: 1
---

A week on call ends with a small transfer of knowledge that most teams do badly or not at all. The outgoing primary knows things the incoming one does not: which alert fired four times and was noise, which release is still being watched, why the provider's status page has been yellow since Tuesday. **If that knowledge stays in one head, the next person meets the same problems as if for the first time.**

## A handover note

The Billing team writes a short note at the end of each shift, in the team's channel, and the incoming primary reads it before the shift starts:

| heading | what goes under it |
|---|---|
| **open** | incidents not yet resolved, and anything somebody promised to check |
| **pages this week** | each page, one line: what fired, what was done, and whether it needed a person |
| **changed** | releases and configuration changes that are still settling |
| **coming** | what the next week holds that could break things: the month-end, a provider's maintenance window, a big customer's launch |
| **noise** | alerts that fired and needed nothing, so somebody can fix or remove them |

Five headings and a dozen lines. The note is for the person starting, not a report for managers, and it takes ten minutes to write while the week is still fresh.

## The fifteen-minute overlap

The note is followed by **a short call**, fifteen minutes, where the incoming primary asks questions. The call is where "the provider has been slow" becomes "the provider has been slow in the afternoons, and it got worse on Friday", which is the sentence the note left out. On the morning of Wednesday 30 September, Inês handed the pager to Rafa, and her note under **coming** said "month-end today". The call was skipped that week; it is where somebody would have asked what month-end meant for card charges, with a release planned for the afternoon.

## The pages line is a measurement

The **pages this week** heading does a second job. Every line says whether the page needed a person, and a team that keeps its handover notes has, without trying, a record of how many of its alerts are worth waking somebody for. Lesson 18 turns that record into a number, and it is the number that decides which alerts survive.

## Handing over in the middle of an incident

A shift can end while an incident is open. The rule from lesson 14 applies: the outgoing person does not just leave. They brief the incoming one, who says out loud that they have it, and only then does the outgoing person go to bed. An incident has an owner at every moment, and that includes the moment the rota turns over.
