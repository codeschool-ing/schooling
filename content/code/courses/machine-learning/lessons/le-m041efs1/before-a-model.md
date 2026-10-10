---
title: Whether a model is the answer at all
version: 1
---

**Not every question that mentions data needs a model.** Some of the most useful work a data
scientist does is the afternoon spent showing that a rule, a report or a phone call answers the
question better than anything that could be trained. A model costs something to build, more to
keep honest, and the most to explain when it is wrong. It earns that cost only under certain
conditions, and they can be checked before anything is fitted.

## Five conditions, and what fails without each

**A decision that changes because of the answer.** If the retention team will send the credit to
the same people whatever the model says, because the budget is fixed and the list is chosen by
hand, the model changes nothing and is worth nothing. Ask what would be done differently with a
perfect prediction. If the answer is "nothing", stop.

**A label that exists, and means what you think.** To learn who cancels, the data has to say who
cancelled. At Feira em Casa it does, in `churned`. Many companies discover at this step that a
cancellation is recorded only when somebody phones, and a subscriber whose card simply stops
working appears in no list at all. A model trained on that label learns to predict phone calls.

**Inputs known at the moment of the decision.** Section 06 of this lesson named the moment: the
first of the month. A model that needs next week's complaints to predict this month's
cancellations cannot run at the moment the credit is sent.

**A pattern that a rule cannot already capture.** If everybody who skips three boxes in a row
cancels, and nobody else does, write that sentence into the system and go home. A model is worth
building when the signal is spread across many columns in ways no one person would write down,
and lesson 2 is the test: a rule of thumb, scored the same way the model will be.

**Enough examples of the thing that matters.** 248 cancellations in December, 3,685 across the
file. That is enough to learn from. A company with forty cancellations a year has a different
problem, which is reading each of them.

## A one-page frame

Before any code, Ana writes this down and sends it to the people who asked. It takes ten minutes
and it is the most reusable thing in the project:

| | Feira em Casa, churn |
|---|---|
| the decision | send a R$ 40 credit, or not, at the start of each month |
| one row | a subscriber on the first day of a month |
| the moment | the first of the month, before the credit is sent |
| the target | cancels during that month: `churned` = 1 |
| what a mistake costs | a false positive R$ 40, a false negative R$ 104 not gained |
| what it must beat | the best simple rule, and sending nobody (lesson 2) |
| how it will be tested | on months later than the ones it learned from (lesson 3) |

**The frame is a contract more than a document.** When somebody asks, three months later, why the
model is "only 30% precise", the answer is already written: precision was never the goal, the net
value in the last section was, and here is what was agreed.

## What changes for a regression

The same four questions apply when the target is a quantity. Feira em Casa's logistics team wants
to tell each customer when their box will arrive: one row is one delivery, the moment is when the
route is planned, the target is `minutes`, and the cost of an error depends on its direction. A
box promised in 40 minutes that arrives in 30 bothers nobody; one that arrives in 50 produces a
complaint. Lesson 12 measures error in ways that can tell those two apart, and lesson 5 fits the
first model to `deliveries.csv`.
