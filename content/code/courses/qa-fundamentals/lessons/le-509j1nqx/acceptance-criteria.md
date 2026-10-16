---
title: Writing acceptance criteria a tester can use
version: 1
---

**Acceptance criteria are the conditions a story has to meet to be accepted by the product owner.** They
are usually written by the product owner, often with the team, and they are the closest thing a Scrum team
has to lesson 9's test basis: the source of the expected results.

They vary enormously in quality, and the difference matters to a tester more than to anyone, because a
criterion that cannot be checked is a criterion nobody can say was met.

## Three versions of the same criterion

Here is one criterion for the story *older customers pay half*, written three ways:

| version | the criterion | can a tester use it? |
|---|---|---|
| vague | "the discount for older customers works correctly" | no: correct according to what? |
| a rule | "customers over 60 pay half price" | partly: it is exactly the sentence that hid the defect |
| examples | "a customer of 59 pays R$ 36,00; of 60 pays R$ 18,00; of 61 pays R$ 18,00, at an evening session" | yes: three checks, with their expected results |

The third version is longer, and every word is useful. It names the boundary on both sides, it gives the
expected price, it fixes the session so the price is unambiguous. **Writing a criterion as examples forces
every ambiguity into the open**: Joana cannot write *60 pays R$ 18,00* without deciding whether sixty counts.

## A shape that helps

Many teams write criteria in a fixed shape, borrowed from behaviour-driven development:

> **Given** a customer aged 60 at an evening session on a Thursday,
> **when** they buy one ticket,
> **then** they pay R$ 18,00.

The *given* sets the situation, the *when* is the action, the *then* is the expected result. The shape is
not magic, but it makes one thing hard to leave out: the *then*, which is the part a tester needs most.
Lesson 16 is about this shape in depth, and about running such criteria as tests automatically.

## What a tester adds to the criteria

When a product owner writes acceptance criteria, the tester's contribution is the cases the product owner did
not think of, chosen with the habits of the previous lessons:

- **both sides of every line** in the rule, from lesson 6: 59 and 60, 11 and 12, 16:59 and 17:00;
- **the combinations**, also from lesson 6: older customers on a Wednesday;
- **inputs nobody mentioned**: an age typed as a word, a time written with one digit;
- **what happens after**, from lesson 8: is the reduction recorded with the order, so the accountant's report
  can show it?

Not every suggestion becomes a criterion. Some become questions Joana answers differently from what Lia
expected; some are judged not worth a criterion and left to exploration. The point is that the decision is
made before the code is written, in a conversation, rather than discovered afterwards in a defect report.
That conversation has a name and a format of its own, the three amigos, and lesson 17 is about it.
