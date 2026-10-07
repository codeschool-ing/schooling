---
title: Ranking risks with money
version: 1
---

A quantitative assessment replaces the words with an expected amount of money lost per year. It
needs more work and more data, and in return it answers the question the matrix cannot: **is this
control worth what it costs?**

Four quantities, defined in this order:

| name | what it is | how it is found |
|---|---|---|
| **AV**, asset value | what the asset is worth to the business | the owner's estimate |
| **EF**, exposure factor | the fraction of that value one incident destroys | from 0 to 1 |
| **SLE**, single loss expectancy | what one incident costs | **SLE = AV × EF** |
| **ARO**, annualised rate of occurrence | how many times a year it is expected | history, or industry data |
| **ALE**, annualised loss expectancy | what this risk costs per year, on average | **ALE = SLE × ARO** |

### Laptops

R3 from the previous section, worked through. A laptop plus the day it takes to set up a
replacement is worth R$ 7,000 to the shop, and a lost laptop is lost entirely, so the exposure
factor is 1. The shop has lost a laptop about once every two years, so the ARO is 0.5:

| | |
|---|---|
| SLE | R$ 7,000 × 1 = R$ 7,000 |
| ALE | R$ 7,000 × 0.5 = **R$ 3,500 a year** |

That does not mean the shop loses R$ 3,500 every year. It means that over many years the average
comes to that, and it is a fair ceiling for what to spend each year to make the problem smaller.

### Ransomware

R2 is rarer and much worse. Restoring the shop's systems from nothing and the sales lost meanwhile
put the value at stake at R$ 80,000. With only a backup on the same server, an attack would
destroy about half of that value, so EF is 0.5. The workshop estimated one such event in ten
years, so the ARO is 0.1:

| | |
|---|---|
| SLE | R$ 80,000 × 0.5 = R$ 40,000 |
| ALE | R$ 40,000 × 0.1 = **R$ 4,000 a year** |

Now a control: an offline backup, kept where the server cannot write to it, costs R$ 1,500 a year.
With it, an attack destroys only the work since the last backup, and the exposure factor drops to
0.05:

| | |
|---|---|
| new SLE | R$ 80,000 × 0.05 = R$ 4,000 |
| new ALE | R$ 4,000 × 0.1 = R$ 400 a year |

The control is worth **the loss it removes minus what it costs**:

> R$ 4,000 − R$ 400 − R$ 1,500 = **R$ 2,100 a year in the shop's favour**

So the shop buys it. If the same backup had cost R$ 5,000 a year, the arithmetic would say the
control costs more than the risk, and the honest answer would be a cheaper control or a decision
to accept.

### Where the numbers come from

**The precision of the result is the precision of the worst input.** An ARO of 0.1 for ransomware
is a guess with a range, not a measurement. Quantitative analysis earns its place by forcing those
guesses into the open, where they can be argued about and improved, and by making the comparison
with the control's cost explicit. It does not make a guess into a fact.

In practice most organisations use both: the matrix to rank everything quickly, and the money for
the handful of risks where a large spending decision is on the table. `threat-modeling` lesson 10
covers FAIR, a more rigorous quantitative method that works with ranges instead of single numbers.
