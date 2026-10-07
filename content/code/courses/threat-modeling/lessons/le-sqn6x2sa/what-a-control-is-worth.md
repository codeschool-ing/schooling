---
title: What a control is worth
version: 1
---

Lesson 8 wrote nineteen requirements, and every one of them is a good idea. A small company cannot
build nineteen good ideas this quarter, so the question changes from *is this worth doing?* to
*which first?* The arithmetic that answers it uses lesson 9's numbers and one new one, **the cost of
the control.**

### The value of a control

A control is worth **the expected loss it removes**: the risk before, minus the risk after.

> value per year = expected loss before − expected loss after

For C1, a second factor for staff, judged on T03 alone:

> before: 0.3 a year × R$ 250,000 = R$ 75,000
> after: removes 80% of the frequency, so 0.06 a year × R$ 250,000 = R$ 15,000
> value: R$ 60,000 a year

The 80% is an estimate like any other: the team's judgement of how many of the phishing attempts
that work today would still work with a second factor. It sits in `controls.csv` beside the
control, where somebody can argue with it.

### The cost of a control

**Everything it costs, per year**, so it can be set against a yearly loss:

| | example for C1 |
|---|---|
| licences and hardware | authenticator app licences, two spare keys per clinic |
| building it | two days to wire the second factor into the console's sign-in |
| running it | resetting lost factors, perhaps one a month |
| friction | forty people spending a few seconds more at each sign-in |

A one-off cost is spread over the years the control will last: two days of work, about R$ 4,000,
spread over three years, is about R$ 1,400 a year, which is how C3, the webhook signature check,
gets its number. **Friction is the line people forget**, and it is the one that decides whether a
control survives: a second factor that takes a minute every time gets switched off by somebody in a
hurry, and then it costs nothing and protects nothing.

### Return on security investment

The ratio of the two is sometimes called **return on security investment (ROSI)**, usually written
as (value − cost) ÷ cost. This lesson uses the simpler **saved ÷ cost**: a control that saves R$ 20
for every real spent is plainly better value than one that saves R$ 2, and the two forms put
controls in the same order. Any ratio above 1 means the control saves more than it costs, on
average; below 1 it does not, and the decision has to be made on other grounds, which the section
on beyond the money is about.
