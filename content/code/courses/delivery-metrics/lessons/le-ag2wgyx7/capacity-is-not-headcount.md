---
title: Capacity is not headcount
version: 1
---

"We have five developers" is a statement about payroll, not about capacity. The time those five people can put into planned work is much less than five people's working weeks, and a plan that does not know by how much is a plan for a team that does not exist.

## Where the time goes

Here is a plausible week for the Billing team's five developers, set out as a calculation. The proportions are illustrative, written for the course, and each line is a thing a real team can measure.

| | days per week |
|---|---|
| five people, five days | 25.0 |
| holidays, illness and training, averaged over the year (about 10%) | −2.5 |
| meetings: standups, planning, retrospective, one-to-ones | −2.5 |
| reviewing each other's work | −2.5 |
| on-call and incident work, lesson 17 | −2.0 |
| support questions and other teams' requests | −1.5 |
| **left for planned items** | **14.0** |

**Fourteen days out of twenty-five**, a little more than half. None of the deductions is waste. Reviews are why the team's cycle time fell; on-call is why the shops can use the product at night; support is part of the job. They are simply not the planned items, and a plan that assigns 25 days of items to this team has planned for eleven days that will not be there.

## Measure the split

The numbers in the table are a guess for an invented team. Yours can be measured, roughly and cheaply:

- **Tag unplanned work when it arrives.** A label on items that were not in the plan, an expedite lane, lesson 4, or a count of incidents and support requests per week.
- **Compare what was planned with what was done.** Over a quarter, the share of finished items that were unplanned is the number to plan around next quarter.
- **Count the interruptions, not only the work.** A support question that takes ten minutes costs more than ten minutes: the developer it interrupted has to get back into what they were doing.

A team that knows that a third of its capacity goes to unplanned work can plan the other two thirds honestly, and can have a factual conversation about whether the unplanned third is the right size.

## Throughput already knows

There is a shortcut that makes most of this arithmetic unnecessary for forecasting. **Throughput is measured after all the deductions.** The Billing team's history of about one item a day already contains the meetings, the reviews, the incidents and the holidays of those weeks. That is the deepest reason lesson 10 forecasts from throughput instead of from headcount: the history has already done the subtraction.
