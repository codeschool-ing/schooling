---
title: Ranges, not points
version: 1
---

An estimate is a statement about what you do not know yet. **Written as one number, it hides the
only part a decision needs: how wide the not-knowing is.** This section is about saying the width
out loud, with a method that takes a few minutes per piece of work, and about what an architect
estimates that a team does not.

## The question in the corridor

Helena Prado, Carreto's product director, stopped Renata after a planning meeting. Drivers have
been asking to be paid the moment a delivery is proved, instead of waiting for the next payout run,
and a competitor has started offering exactly that. "Instant payout by Pix. Roughly how long?"

The tempting answer is a number. Renata had a feel for one, about three months, and it would have
been on a slide for the board by Friday. **A number said in a corridor becomes a commitment the
moment somebody writes it down**, and nobody who reads it afterwards knows it came from thirty
seconds of thought.

Three words get confused at this point, and Steve McConnell's *Software Estimation* (2006) keeps
them apart:

- an **estimate** is a prediction of how long something will take, with its uncertainty;
- a **target** is a date the business wants, for reasons of its own;
- a **commitment** is a promise to deliver by a date, made by people who know both.

Helena's question asks for an estimate. What she will be asked upstairs is a commitment, and the
board may already have a target in mind. Keeping the three apart is most of the job, and it starts
with not answering the first question with the third.

So Renata said: "Today, somewhere between a month and a year. Give me a week with Bruno's team and
I'll give you a range you can plan with." It sounds evasive. It is the honest answer, and there is a
picture that shows why.

## The cone of uncertainty

Barry Boehm measured, in 1981, how far estimates made at different stages of a project landed from
the effort really spent. Steve McConnell later redrew the result as the **cone of uncertainty**.
At the stage of an initial idea, the real effort lands anywhere from a quarter to four times the
estimate. Once the product is defined, half to double. With the requirements settled, about two
thirds to one and a half. By the detailed design, within about ten per cent either way.

```schooling-figure
@@FIG:cone@@
```

Applied to Renata's twelve weeks, the cone says the corridor answer really meant **3 to 48
weeks**, and "between a month and a year" is the same statement in words. A week later, with the
work broken down and the requirements agreed with Helena, the same twelve weeks means **8 to 18**.

**The cone narrows because decisions are made, not because time passes.** A month spent without
deciding what a payout does when the bank is down leaves the range exactly as wide as it was.
`process-management` lesson 1 goes through the cone and the evidence behind it. What matters here
is the consequence for an architect: an early estimate is a range, and the most useful early work
is whatever removes the widest uncertainty first. This lesson's section on alternatives comes back
to that as a spike.

## Three numbers for each piece

To narrow the range, Renata sat with Bruno Farias, the tech lead of Payments, and two of his
engineers for an hour. They split instant payout into four pieces of work, and for each one they
gave three numbers instead of one:

- **O**, the optimistic duration: the things that can go well do;
- **M**, the most likely duration: the number they would bet on;
- **P**, the pessimistic duration: the things that usually go wrong do. A bad month, not a
  disaster.

**PERT**, a technique built for the US Navy's Polaris programme in 1958, turns the three numbers
into a mean and a spread:

```localised
mean               = (O + 4M + P) / 6
standard deviation = (P − O) / 6
```

The mean gives the most likely value four times the weight of either extreme. The standard
deviation is a sixth of the whole range, a rule of thumb that treats O and P as roughly the edges.
Here is the table, in weeks of the Payments team:

| piece of work | O | M | P | PERT mean | standard deviation |
|---|---|---|---|---|---|
| integrate the bank's Pix payout API | 2 | 3 | 8 | 3.67 | 1.00 |
| ledger entries and reconciliation | 2 | 4 | 7 | 4.17 | 0.83 |
| a payout status API for the Driver app | 1 | 2 | 3 | 2.00 | 0.33 |
| checks on the proof of delivery | 1 | 3 | 9 | 3.67 | 1.33 |
| **total** | 6 | 12 | 27 | **13.50** | |

Three things in it are worth more than the formula.

**The sum of the most likely values is 12 weeks**, and that is the number Bruno's team would have
given if asked for one. The sum of the means is 13.5, a week and a half more, and none of it is
padding. It comes from the shape almost every piece of software work has: a little room to finish
faster than expected and a lot of room to finish slower, so P sits further from M than O does, and
each mean sits above its most likely value. A plan built from most likely values is built from
numbers that are each more optimistic than the average outcome.

**The spread of the total is not the sum of the spreads.** If the pieces vary independently, their
variances add, and the standard deviation of the total is the square root of the sum: about 1.89
weeks here. Planning at roughly the 85th percentile gives 13.5 + 1.04 × 1.89, or **about 15.5
weeks**. `process-management` lesson 9 works through that arithmetic and the assumption that breaks
it, so this lesson only uses the result. What Renata took back to Helena was three numbers: 12
weeks if nearly everything goes to plan, 13.5 as the expected value, 15.5 to plan against.

**The widest row is the most interesting one.** The proof-of-delivery checks run from 1 to 9 weeks,
a spread of 1.33, because nobody at the table knew what Tracking records at the moment a load is
delivered. The other three pieces are uncertain for ordinary reasons; that one is uncertain because
of a question somebody could answer. Questions like that are cheap to answer, and this lesson's section
on alternatives buys the answer.

## What the architect estimates, and what the team does

Renata did not fill in the table. **The people who will do the work estimate it**, because they know
the code, and because a team held to somebody else's number has a reason to miss it. What she did
was ask questions: "What would make this take nine weeks?" "Which of these would you do first?"
"Does the 3 assume the bank's sandbox works?" The answers to the first question are the raw material
of the next section, which turns them into risks.

An architect's own estimates are for a different decision. A team estimates to plan delivery: which
sprint, which date. An architect estimates to **choose between options before anybody is committed
to one** — whether instant payout is built on the bank's API or bought from a provider, whether it
fits this quarter at all, whether the structural cost of a feature (lesson 10) is a week or a
season. Those estimates are made earlier, so they sit further left in the cone and are wider, and
that is fine as long as they are given as ranges.

Two habits make those ranges useful to whoever reads them:

- **Write the assumptions beside the numbers.** "Assumes the bank's payout API is the one in their
  current documentation; assumes Tracking keeps the delivery photo." When an assumption breaks, the
  reader knows the estimate broke with it, instead of discovering it at the deadline.
- **Use the unit the decision is made in.** Helena plans in weeks of a team, Sílvio Matos, the
  finance director, in reais. Hours of an individual are the wrong grain for a choice between two
  architectures, and they suggest a precision nobody has.

The question a student usually asks here is whether all this is worth it for a three-month
project. The table took an hour. The alternative was a number from the corridor, on a slide to the
board, that was really "3 to 48 weeks" and was read as "12".
