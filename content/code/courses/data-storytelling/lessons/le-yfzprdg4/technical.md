---
title: The technical team: definitions, method, reproducibility
version: 1
---

Sandra has an analyst, Diego, who maintains the delivery reports. **For him the question is not what the
finding means but whether it is right**, and he will answer it by looking for the place where Marina's
numbers and his stop agreeing.

## Lead with the definitions

A technical audience disagrees about definitions long before it disagrees about conclusions. So the
technical version opens with them:

| term | definition in this analysis |
|---|---|
| new subscriber | first paid order between 1 January and 30 June 2025 |
| first delivery | the first box of that subscription |
| late | delivered after the date promised at checkout, by the carrier's delivered scan |
| cancelled within 90 days | cancellation request dated within 90 days of the first delivery |
| region | *capital* is the city of São Paulo; *interior* is the rest of the state |

Every line is a place where Diego's reports might differ. His on-time rate might use the date promised
**by the carrier** rather than at checkout, or count a delivery as on time if it arrived by the end of the
promised day in a different time zone. **Settling those first turns a dispute about the conclusion into a
check of one definition**, which is a much shorter conversation.

## Then the method, and a way to rerun it

After the definitions, the technical audience wants the method in enough detail to repeat it: which
tables, which joins, what was excluded and why, and the counts at each step. **The strongest thing you
can give a technical reviewer is the means to reproduce your number**: the query, the spreadsheet, the
twenty-four-row table from lesson 1. If Diego can rebuild 41.5% himself, he stops being a reviewer and
becomes a witness.

## Every level, and the caveats out loud

This is the one audience that gets every level of the pyramid, including the parts that weaken the case.
The cancellation reasons in the exit survey, for instance, put price first and delivery third, and
only 23% of those who cancelled answered it; lesson 12 deals with why that does not undermine the
finding. Hiding that from Diego would be found out, and **a caveat a technical reviewer finds for
himself costs more trust than one you showed him.**

## Why this audience comes early

The technical review usually happens before the management meeting, not after it. A finding that the
technical team has checked arrives at Paulo's meeting with Sandra's own analyst behind it, and
Sandra's first question, "did you talk to my team?", already has an answer.
