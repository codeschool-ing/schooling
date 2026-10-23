---
title: Three options on one sheet
version: 1
---

With every line counted for every option, the comparison is short to write and long to argue about.
**The totals rank the options; the shape over time, the dates and the sensitivity of the ranking to
its weakest assumptions decide whether the ranking means anything.** This section lays out all four,
for Serra Alta's three options.

## The assumptions behind B and C

A's sheet is in section 03 of this lesson. B and C are built the same way, from these assumptions,
all of them Serra Alta's invented estimates:

- *B, extend SAP.* It cannot go live before S/4HANA does, and Serra Alta's conversion is planned to
  go live in January 2028, month 13. Functional consultants design and configure it from month 1 to
  month 16, R$ 62,500 a month. Of the 46 rules, 30 become standard SAP purchasing price conditions; the
  other 16, and the collection app on the truck handhelds, are custom development from month 4 to
  month 16 at R$ 120,000 a month. Additional SAP licences and the platform the handheld app runs on
  cost R$ 15,000 a month. One person from Edson's team works on it throughout. The first farm payment
  is in May 2028, month 17, and Coleta is switched off after month 19.
- *C, build.* Seven people for twelve months build it on the same stack as Rota, Kotlin and
  PostgreSQL. Parallel running is months 13 to 15, the first farm payment is in April 2028, month 16,
  and Coleta is switched off after month 18. Maintenance from month 13 follows the 20% assumption of
  section 04 of this lesson: R$ 35,000 a month.

## The sheet

All figures in reais, over the 36 months:

| line | A: buy | B: extend SAP | C: build |
|---|---|---|---|
| licence or subscription | 1,825,200 | 540,000 | 0 |
| implementation | 360,000 | 1,000,000 | 2,100,000 |
| data migration | 150,000 | 150,000 | 150,000 |
| integration | 240,000 | 150,000 | 300,000 |
| customisation | 150,000 | 1,560,000 | 0 |
| infrastructure | 90,000 | 96,000 | 252,000 |
| operation and support | 108,000 | 160,000 | 320,000 |
| internal team | 562,500 | 900,000 | 840,000 |
| training | 80,000 | 80,000 | 80,000 |
| upgrades | 90,000 | 150,000 | 60,000 |
| Coleta kept running | 180,000 | 285,000 | 270,000 |
| **spending** | **3,835,700** | **5,071,000** | **4,372,000** |
| exit | 397,800 | 190,000 | 307,000 |
| **TCO** | **4,233,500** | **5,261,000** | **4,679,000** |

**A is cheapest by R$ 445,500 over C and by R$ 1,027,500 over B.** Two zeros in C's column were
typed on purpose: a build has no licence to pay and nothing to customise, because everything is
written to fit, and the cost of fitting is in its implementation line. Data migration and training
are the same in every column, because the farms, the history and the drivers are the same whichever
system they move to. A line that is identical in every option changes no ranking, and it stays on the
sheet anyway, because it is still money somebody has to find.

## The shape over time

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l15-cumulative\" aria-label=\"Cumulative spending of the three options over 36 months, from January 2027, in millions of reais. All three start together. C, the build, climbs fastest in year 1 and reaches R$ 2.71 million at month 12; B, the SAP extension, overtakes it and reaches R$ 3.97 million by month 18; A, the SaaS product, flattens after month 9. At month 36 A has spent R$ 3.84 million, C R$ 4.37 million and B R$ 5.07 million. A dot on each line marks the first farm payment from the new system: A at month 10, C at month 16, B at month 17. A dashed vertical line at month 18 marks Sebastião's retirement. Exit costs are not drawn.\"><path d=\"M80.0 300.0 L590.0 300.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"72.0\" y=\"300.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M80.0 250.9 L590.0 250.9\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"72.0\" y=\"250.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.00 M</text><path d=\"M80.0 201.8 L590.0 201.8\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"72.0\" y=\"201.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2.00 M</text><path d=\"M80.0 152.7 L590.0 152.7\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"72.0\" y=\"152.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3.00 M</text><path d=\"M80.0 103.6 L590.0 103.6\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"72.0\" y=\"103.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4.00 M</text><path d=\"M80.0 54.5 L590.0 54.5\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"72.0\" y=\"54.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5.00 M</text><text x=\"80.0\" y=\"315.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"165.0\" y=\"315.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><text x=\"250.0\" y=\"315.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12</text><text x=\"335.0\" y=\"315.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18</text><text x=\"420.0\" y=\"315.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">24</text><text x=\"505.0\" y=\"315.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30</text><text x=\"590.0\" y=\"315.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">36</text><text x=\"335.0\" y=\"334.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">months from January 2027</text><path d=\"M335.0 30.0 L335.0 300.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"341.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Sebastião retires</text><path d=\"M80.0 300.0 L94.2 293.6 L108.3 285.8 L122.5 276.7 L136.7 266.4 L150.8 256.1 L165.0 245.8 L179.2 234.1 L193.3 222.5 L207.5 212.1 L221.7 208.1 L235.8 204.1 L250.0 199.6 L264.2 196.2 L278.3 192.9 L292.5 189.0 L306.7 185.6 L320.8 182.2 L335.0 178.3 L349.2 174.9 L363.3 171.6 L377.5 167.7 L391.7 164.3 L405.8 160.9 L420.0 157.0 L434.2 153.4 L448.3 149.8 L462.5 145.7 L476.7 142.1 L490.8 138.5 L505.0 134.4 L519.2 130.7 L533.3 127.1 L547.5 123.0 L561.7 119.4 L575.8 115.8 L590.0 111.7\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"221.7\" cy=\"208.1\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M80.0 300.0 L94.2 294.2 L108.3 288.5 L122.5 282.7 L136.7 271.0 L150.8 259.4 L165.0 247.7 L179.2 236.1 L193.3 223.2 L207.5 210.3 L221.7 197.4 L235.8 184.5 L250.0 170.2 L264.2 155.6 L278.3 141.0 L292.5 126.3 L306.7 111.7 L320.8 108.4 L335.0 105.1 L349.2 101.8 L363.3 99.3 L377.5 96.7 L391.7 94.2 L405.8 91.6 L420.0 89.1 L434.2 86.5 L448.3 84.0 L462.5 81.4 L476.7 78.8 L490.8 76.3 L505.0 66.4 L519.2 63.8 L533.3 61.3 L547.5 58.7 L561.7 56.2 L575.8 53.6 L590.0 51.1\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"320.8\" cy=\"108.4\" r=\"4\" fill=\"var(--amber)\"></circle><path d=\"M80.0 300.0 L94.2 290.5 L108.3 281.1 L122.5 271.6 L136.7 262.1 L150.8 250.8 L165.0 239.5 L179.2 228.2 L193.3 216.8 L207.5 205.5 L221.7 192.7 L235.8 179.9 L250.0 167.2 L264.2 161.0 L278.3 154.8 L292.5 150.1 L306.7 146.7 L320.8 143.4 L335.0 140.0 L349.2 137.3 L363.3 134.7 L377.5 132.0 L391.7 129.4 L405.8 126.7 L420.0 122.1 L434.2 119.4 L448.3 116.8 L462.5 114.1 L476.7 111.5 L490.8 108.8 L505.0 103.2 L519.2 100.6 L533.3 97.9 L547.5 95.3 L561.7 92.6 L575.8 90.0 L590.0 85.4\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 3\"></path><circle cx=\"306.7\" cy=\"146.7\" r=\"4\" fill=\"var(--paper)\"></circle><text x=\"600.0\" y=\"110.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">A: buy</text><text x=\"600.0\" y=\"124.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3.84 M</text><text x=\"600.0\" y=\"44.1\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">B: extend SAP</text><text x=\"600.0\" y=\"58.1\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5.07 M</text><text x=\"600.0\" y=\"78.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">C: build</text><text x=\"600.0\" y=\"92.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4.37 M</text><circle cx=\"90.0\" cy=\"348.0\" r=\"4\" fill=\"var(--paper-dim)\"></circle><text x=\"100.0\" y=\"348.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">first farm payment from the new system</text></svg>", "caption": "Cumulative spending, in millions of reais, before any exit cost. The build spends first and the extension spends most; the purchase is the only one paying farms before 2028."}
```

The curves say what the totals cannot:

- **B is the cheapest option for the first eight months.** It spends on consultants and licences,
  not on a team of seven or a subscription for 1,900 farms. Anybody who compared spending at month 6
  — R$ 1,065,000 for B, R$ 1,105,000 for A and R$ 1,233,000 for C — would have ranked it first. It
  passes C in month 13, when the custom development is at full speed, and ends highest;
- **C spends first.** By month 12 it has spent R$ 2,706,000 and paid nobody. Every month of delay in
  that year is R$ 175,000 of a team that has not finished;
- **A flattens.** Once the one-off costs end in month 9, A's curve rises at roughly R$ 70,000 to
  R$ 90,000 a month, and the dot at month 10 shows it is the only option paying farms in 2027.

## What money does not measure

| | A: buy | B: extend SAP | C: build |
|---|---|---|---|
| first farm payment | October 2027, month 10 | May 2028, month 17 | April 2028, month 16 |
| Coleta switched off | after month 12 | after month 19 | after month 18 |
| against Sebastião's retirement, end of June 2028 | six months before | one month after | the same month |
| how the 46 rules fit | 41 configured, 5 extended beside | 30 as price conditions, 16 custom | all 46 written by Serra Alta |
| what it depends on | a vendor keeping its product and its price | S/4HANA live in January 2028 | hiring seven people and keeping them |

**The deadline row is the one Marcos read twice.** Sebastião is the only person who can explain what
Coleta does when its answer and the new system's differ, and lesson 13's parallel run is the period
in which such differences appear. A finishes the parallel run and switches Coleta off with six months
of Sebastião still in the building. C switches Coleta off the month he leaves. B needs Coleta, and
therefore him, for a month after he has gone, and it starts only when another programme — S/4HANA —
finishes on time.

## Sensitivity: does the ranking survive its weakest assumptions?

A ranking is only as strong as the assumption it is most sensitive to. Two are obviously soft.

**What if the build takes 50% longer?** Eighteen months instead of twelve is not pessimism; it is an
ordinary software project. The six extra months of the team add R$ 1,050,000 (6 × R$ 175,000). Some
lines fall, because the system starts running later: maintenance starts in month 19 instead of 13,
R$ 210,000 less; operation, R$ 60,000 less; infrastructure, R$ 36,000 less (six more months of the
development environment at R$ 3,000, six fewer of production at R$ 9,000). Coleta runs six months
longer, R$ 90,000 more. The net change is:

> R$ 1,050,000 − 210,000 − 60,000 − 36,000 + 90,000 = **R$ 834,000**

C becomes R$ 5,513,000 — **more expensive than B**, so the order of the two behind A changes. The
dates change more: the first farm payment moves to October 2028, and Coleta runs until December,
six months after Sebastião has gone.

**What if the SaaS price rises 15% at renewal instead of 4%?** Year 3's price becomes R$ 28.75 per
farm, and two numbers move. Year 3's subscription goes from R$ 655,200 to R$ 724,500 (2,100 × 28.75 ×
12), R$ 69,300 more. The three overlap months in the exit go from R$ 163,800 to R$ 181,125, R$ 17,325
more. A becomes R$ 4,320,125, still cheapest, by R$ 358,875.

How large would the rise have to be for A to lose? The renewal price applies to 15 months of 2,100
farms — twelve in year 3 and three of overlap — 31,500 farm-months. A matches C when those cost
R$ 445,500 more than they do at R$ 26:

> R$ 445,500 ÷ 31,500 = R$ 14.14, so a price of **R$ 40.14** per farm per month

That is 61% above today's R$ 25. **A conclusion that survives a 61% price rise is robust on price**,
and saying so in the decision record tells the reader exactly how much room there is.

## The horizon chooses too

Three years favours buying, and year 3 on its own shows why. A spends R$ 923,200 in it (section 03
of this lesson). C spends R$ 748,000: R$ 108,000 of infrastructure, R$ 160,000 of operation with one
penetration test, R$ 420,000 of maintenance and R$ 60,000 of upgrades. Once built, C is R$ 175,200 a
year cheaper to run. At month 36 C has spent R$ 536,300 more than A. If year 3's costs simply
repeated, C would catch up in R$ 536,300 ÷ R$ 175,200 = 3.06 more years — **during its seventh year**.

That is not a reason to choose C. Seven years is a long time to assume nothing changes: farms keep
being added, which raises A's bill, and the maintenance assumption has to hold for every one of those
years, which is the one most likely to be wrong. But it is a reason to say, in the record, that the
choice is a three-year choice, and to name the day it should be looked at again.
