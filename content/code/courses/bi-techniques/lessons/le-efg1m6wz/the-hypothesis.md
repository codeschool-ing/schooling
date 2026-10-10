---
title: The hypothesis
version: 1
---

**A test without a written hypothesis is a fishing trip**: something will turn up, and it will be
mistaken for a finding. The hypothesis is written before the test starts, and it has four parts.

> **If** we change *the checkout page to a single step*,
> **then** *the share of visitors who place a first order* will rise **by at least** *0.6
> percentage points*,
> **because** *the current three-step form loses people on phones at the payment step*.

Each part does work.

- **The change** names exactly what differs between control and treatment. "A new checkout" is
  not a change, it is a project; a test of everything at once can say that something helped and
  never what.
- **The metric** is the one number that will decide. The next section is about choosing it.
- **The size**, "at least 0.6 points", is the smallest effect worth shipping. It is a business
  judgement, not a statistical one: below it, the change is not worth what it costs to build and
  maintain. Lesson 8 turns it into the number of visitors the test needs.
- **The reason** is what makes the result teach something. If the effect appears on desktops and not
  on phones, the reason was wrong, and that is worth knowing even when the metric moved.

## The statistician's version

`statistics` lesson 13 writes the same thing as two hypotheses about the population of visitors:

- the **null hypothesis**, H₀: the treatment's conversion rate equals the control's;
- the **alternative**, H₁: they differ.

The test asks whether the data is surprising if H₀ were true. Two choices are made here, before the
data exists, and both are lesson 10's to use.

**One side or two.** A two-sided alternative says the rates differ in either direction; a one-sided
one says the treatment is better. A one-sided test needs fewer visitors to detect the same
improvement, and it cannot see harm: a page that drives customers away reads as "no improvement"
rather than as a warning. **Two-sided is the safe default**, and it is what this course uses.

**The significance level**, α, the chance of declaring an effect when there is none. Five per cent
is the convention. A business that runs a hundred tests a year at 5 per cent should expect about
five false wins among the tests where nothing worked, which lesson 11 comes back to.
