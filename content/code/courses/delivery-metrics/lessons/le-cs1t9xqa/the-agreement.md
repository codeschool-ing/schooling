---
title: Writing the agreement down
version: 1
---

A team cannot protect its numbers by being careful. The protection has to be written down, agreed with the people who might misuse them, and kept somewhere everybody can find it. The Billing team wrote theirs in October, with Bia, the engineering director and the head of product, after the quarterly review. It fits on one page, and every line of it comes from a lesson.

## The Billing team's agreement on its numbers

| we measure | we use it for | we never use it for |
|---|---|---|
| cycle time, work in progress, throughput | improving how we work; forecasts | targets; comparing people or teams |
| the four DORA metrics | seeing whether our delivery system is getting better | comparing teams; bonuses |
| forecasts | telling stakeholders what is likely, with a probability | commitments the team did not make |
| incidents and postmortems | learning how the system failed | deciding who to blame |
| the error budget | deciding when reliability comes before features | judging the people on call |
| on-call load per person | spreading the load fairly | performance reviews |
| the share of pages worth answering | deciding which alerts survive | a target for the on-call engineer |

And under it, five sentences:

1. **No number in this table is ever reported per person outside the team.** Inside the team, on-call load per person is reported because its purpose is to protect the person.
2. **The team presents its own numbers.** Dashboards are open to anybody who asks, and conclusions are drawn with the team in the room.
3. **We report measures and agree practices.** Anybody may ask what a number is and why it moved; nobody sets a target on one.
4. **A forecast is a probability until the team says it is a commitment**, and the team says so in writing when it does.
5. **This agreement is reviewed every quarter**, at the review of lesson 19, and changed only with the team.

## Why it is signed by the people above the team

An agreement written by the team alone is a wish. The director and the head of product signed it because **they are the ones who would otherwise make the requests it forbids**, with good intentions, in a hurry, on a day when a number would settle an argument. With the agreement on the table, the request "can I have cycle time per developer" is not a confrontation between a tech lead and her director; it is a question about whether the agreement still holds, which is a much easier conversation to have.

## Why it lists uses as well as limits

The middle column matters as much as the last one. An agreement that only forbids things reads as a team hiding its numbers, and people who cannot get information legitimately start getting it some other way. **Saying clearly what the numbers are for**, and offering them for those uses, is what makes the limits acceptable to the people who accept them.

## When it is broken

It will be, sooner or later, by somebody new who never read it or by somebody under pressure. The Billing team's answer is not outrage but the agreement itself: point to the line, say what the misuse would do to the numbers, and offer the legitimate version of what was asked. Most requests to misuse a metric are questions that have a better answer, and the next section is what those answers sound like.
