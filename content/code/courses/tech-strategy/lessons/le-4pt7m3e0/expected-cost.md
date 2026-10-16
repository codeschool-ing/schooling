---
title: Expected cost: probability times switching cost
version: 1
---

A switching cost is what leaving would cost **if** you leave. Most lock-ins are never tested: the
database keeps working, the vendor stays reasonable, and the switching cost is never paid. So the
number to compare is not the switching cost itself. It is the switching cost weighed by how likely
the switch is:

> expected cost = probability of switching × switching cost

Over the same three years lessons 8 and 9 used, so that the numbers can sit in one sheet.

## Coreto's two probabilities

A probability of switching is a judgement, and a judgement is worth writing down only with the
reasons beside it.

**The document database: 10% in three years.** It works, it needs no operating, the provider is
stable, and nothing on the Catalogue roadmap asks for something it cannot do. The 10% is the
chance that one of those changes: a price rise, a product the provider retires, a need that
appears. Davi asked the Catalogue lead to name what would make them leave, and the answer was "a
price rise we cannot absorb".

**The payment gateway: 35% in three years.** Payments has live reasons to look elsewhere. The
gateway's fees are renegotiated every year and each negotiation ends with the question of whether
to move. And product wants Pix in instalments, which the current gateway does not yet offer; if
it does not offer it in time, Coreto will have to go to one that does. Mateus put it at a little
more than one chance in three, and nobody in the room argued for less.

## The sheet

In your spreadsheet, as set up in lesson 1, add a sheet for the two lock-ins:

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Lock-in | Switching cost | Probability | Expected cost |
| 2 | Managed document database | 210000 | 10% | |
| 3 | Payment gateway | 135000 | 35% | |

In D2 and D3, the expected cost:

```localised
D2   =B2*C2      21000
D3   =B3*C3      47250
```

**Type the probability with its percent sign.** Lesson 1's trouble section made exactly this
product go wrong on purpose: R$ 210,000 multiplied by a cell holding `10` instead of `10%` gave
2,100,000, a hundred times the right answer, with no error on the screen. The defence is the same
one: check one row by hand. R$ 210,000 × 10% is R$ 21,000; if D2 shows anything else, look at C2.

## Reading it

**The ranking turns over.** By switching cost, the database is the bigger lock-in, R$ 210,000
against R$ 135,000. By expected cost, the gateway is more than twice the database: R$ 47,250
against R$ 21,000. A team worried by the bigger switching cost would spend its effort on the wrong
lock-in, because the lock-in most likely to be tested is the gateway.

That is the whole use of the multiplication. A large cost you will probably never pay can matter
less than a smaller one you probably will, and the expected cost puts both on one scale.

## What an expected cost is, and is not

Coreto will never pay R$ 21,000 to leave the database. It will pay either nothing, if it stays, or
about R$ 210,000, if it goes. **The expected cost is a weight for comparing decisions, not a
forecast of a bill.** Over many such lock-ins, judged honestly, the expected costs add up to about
what the switches cost in total; on any single one, the outcome is all or nothing.

Two cautions follow.

**Watch the size of the cost as well as the expected cost.** If a switch would cost more than the
company could find in a year, a small probability does not make it small. Neither of Coreto's two
is that large — R$ 210,000 is less than one engineer-year at R$ 264,000 — but a lock-in that could
sink the company deserves more than a multiplication.

**The probability is the weak number, so say how weak.** Nobody knows the gateway's chance is exactly
35%. The useful question is how far the probability would have to move to
change the decision, and that needs the third number: what it would cost to avoid the lock-in. The
next section adds it.
