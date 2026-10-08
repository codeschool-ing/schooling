---
title: Putting numbers on it
version: 1
---

**The arithmetic of a risk should fit on a few lines, and every number in it should have a source
the reader can ask about.** Here is Lívia's, for the Friday problem, as it went into the proposal in
February. Each line says where its number comes from, because Caio will ask.

## The chronic loss

| | value | source |
|---|---|---|
| checkouts attempted, Friday 18:00 to 21:00 | 9,000 | order logs, average of the last eight Fridays |
| share that fail with a timeout | 2% | checkout error logs, same Fridays |
| failed checkouts per Friday | **180** | 9,000 × 2% |
| share of those customers who do not retry successfully | 40% | matching failed sessions to later orders |
| orders lost per Friday | **72** | 180 × 40% |
| average basket | R$ 150 | finance's monthly report |
| **revenue lost per Friday** | **R$ 10,800** | 72 × R$ 150 |
| revenue lost per year | R$ 561,600 | × 52 Fridays |

Two details in that table matter more than the arithmetic.

**The 40% is the number most likely to be challenged**, and it is the one that most needed
measuring rather than assuming. Lívia's first draft assumed every failed checkout was a lost order,
which would have claimed R$ 27,000 a Friday. Bruna's team matched failed sessions to orders placed
later by the same customers and found that 60% came back. The honest number is two and a half
times smaller, and **it is the one that makes the rest believable**.

**Revenue is not profit.** Caio thinks in margin. Marola's gross margin is about 25%, so the
R$ 561,600 of lost revenue is about R$ 140,400 of lost margin a year. Lívia's proposal gives both,
labelled. A director who discovers that "R$ 560,000 a year" was revenue presented as if it were
money in the bank stops trusting the document.

## The tail risk

| | value | reasoning |
|---|---|---|
| checkouts per minute at peak | 50 | 9,000 over 180 minutes |
| minutes until somebody intervenes | about 30 | the time from page to diagnosis in past incidents |
| checkouts affected | about 1,500 | 50 × 30 |
| orders lost, at the same 40% | about 600 | 1,500 × 40% |
| revenue lost per event | about R$ 90,000 | 600 × R$ 150 |
| events per year, at current growth | 2 to 4 | a judgement: connections peaked within 5% of the limit on three Fridays since November |
| **expected revenue loss per year** | **R$ 180,000 to R$ 360,000** | the two lines above multiplied |

The likelihood is a range and says it is a judgement, with the evidence it rests on. It is the
weakest number in the document and it is labelled as such.

Then, on Friday 6 March, the event happened: checkout failed for 32 minutes, and 1,350 checkouts
failed. The tail risk had become a measurement. The estimate of 1,500 checkouts affected for about
thirty minutes turned out close, which is the best thing that can happen to an estimate after the
fact, and it made the next proposal easier to believe.

## One line for the top of the page

All of it compresses into the sentence that goes into the one-pager and the board report:

> The Friday database limit costs about R$ 560,000 a year in lost revenue (about R$ 140,000 in
> margin) and carries a risk of checkout stopping entirely, which we estimate at two to four times
> a year at about R$ 90,000 in revenue each time.

**The tables are the evidence; this sentence is what gets read.** Without the tables, the sentence is
an assertion. Without the sentence, the tables are homework for the reader.
