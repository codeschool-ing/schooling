---
title: The loss exceedance curve
version: 1
---

A table of percentiles answers questions somebody already thought of. A **loss exceedance curve**
answers all of them at once: for every amount of money, **the chance that one year's total loss is
larger**. It is the single most useful picture FAIR produces, and the one to put in front of the
person who decides how much risk the business carries.

`fair.py` prints four points of it:

```
chance that one year's total loss is more than
  R$   100,000   46.4%
  R$   250,000   28.1%
  R$   500,000   14.1%
  R$ 1,000,000    4.8%
```

And the whole curve, drawn from the same ten thousand years:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l10-exceedance\" aria-label=\"The loss exceedance curve from the simulation: for each amount on a logarithmic axis from 10,000 to 3,000,000 reais, the chance that one year’s total loss is larger. The curve falls from almost 100% at 10,000 through 46.4% at 100,000, 28.1% at 250,000 and 14.1% at 500,000 to 4.8% at 1,000,000. A dashed line marks daniel’s tolerance: no more than a 10% chance of losing more than 500,000 in a year. The curve passes above that point.\"><path d=\"M80.0 270.0 L690.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 25.0 L80.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M76.0 270.0 L80.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"72.0\" y=\"270.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><path d=\"M76.0 208.8 L80.0 208.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 208.8 L690.0 208.8\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"72.0\" y=\"208.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">25%</text><path d=\"M76.0 147.5 L80.0 147.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 147.5 L690.0 147.5\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"72.0\" y=\"147.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50%</text><path d=\"M76.0 86.2 L80.0 86.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 86.2 L690.0 86.2\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"72.0\" y=\"86.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">75%</text><path d=\"M76.0 25.0 L80.0 25.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 25.0 L690.0 25.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"72.0\" y=\"25.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100%</text><path d=\"M80.0 270.0 L80.0 274.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80.0\" y=\"285.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10,000</text><path d=\"M326.3 270.0 L326.3 274.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"326.3\" y=\"285.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100,000</text><path d=\"M572.5 270.0 L572.5 274.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"572.5\" y=\"285.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1,000,000</text><path d=\"M80.0 31.8 L85.1 32.7 L90.2 33.7 L95.3 34.8 L100.3 35.8 L105.4 37.0 L110.5 38.3 L115.6 39.6 L120.7 41.3 L125.7 43.3 L130.8 45.2 L135.9 46.9 L141.0 48.5 L146.1 51.0 L151.2 53.2 L156.2 55.4 L161.3 58.1 L166.4 61.4 L171.5 64.5 L176.6 67.5 L181.7 70.3 L186.8 73.2 L191.8 77.1 L196.9 80.8 L202.0 84.4 L207.1 88.1 L212.2 91.3 L217.2 95.1 L222.3 99.0 L227.4 102.5 L232.5 106.0 L237.6 109.8 L242.7 113.6 L247.8 116.9 L252.8 120.2 L257.9 123.2 L263.0 126.4 L268.1 129.3 L273.2 131.7 L278.2 134.6 L283.3 137.2 L288.4 139.4 L293.5 141.9 L298.6 144.2 L303.7 146.3 L308.8 148.4 L313.8 151.0 L318.9 153.3 L324.0 155.6 L329.1 158.1 L334.2 160.2 L339.3 162.5 L344.3 165.0 L349.4 167.3 L354.5 169.4 L359.6 171.7 L364.7 173.7 L369.7 175.7 L374.8 178.2 L379.9 181.1 L385.0 183.7 L390.1 185.8 L395.2 188.4 L400.2 190.3 L405.3 192.5 L410.4 194.5 L415.5 197.0 L420.6 199.4 L425.7 201.9 L430.7 204.5 L435.8 207.3 L440.9 209.5 L446.0 212.1 L451.1 214.4 L456.2 216.8 L461.2 219.1 L466.3 221.4 L471.4 223.7 L476.5 225.7 L481.6 228.0 L486.7 230.0 L491.8 232.9 L496.8 234.8 L501.9 236.9 L507.0 239.0 L512.1 240.7 L517.2 242.5 L522.2 244.2 L527.3 246.0 L532.4 247.8 L537.5 249.0 L542.6 250.5 L547.7 251.9 L552.8 252.8 L557.8 254.5 L562.9 256.0 L568.0 257.2 L573.1 258.4 L578.2 259.4 L583.2 260.2 L588.3 261.4 L593.4 262.3 L598.5 263.3 L603.6 263.9 L608.7 264.7 L613.8 265.2 L618.8 265.9 L623.9 266.2 L629.0 266.5 L634.1 267.1 L639.2 267.4 L644.3 267.9 L649.3 268.2 L654.4 268.5 L659.5 268.7 L664.6 268.9 L669.7 268.9 L674.8 269.2 L679.8 269.4 L684.9 269.5 L690.0 269.6\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><circle cx=\"326.3\" cy=\"156.4\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"334.3\" y=\"146.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">46.4%</text><circle cx=\"424.2\" cy=\"201.3\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"432.2\" y=\"191.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">28.1%</text><circle cx=\"498.4\" cy=\"235.4\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"506.4\" y=\"225.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">14.1%</text><circle cx=\"572.5\" cy=\"258.2\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"580.5\" y=\"248.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">4.8%</text><path d=\"M498.4 245.5 L690.0 245.5\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M498.4 245.5 L498.4 270.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><circle cx=\"498.4\" cy=\"245.5\" r=\"4.5\" fill=\"var(--amber)\"></circle><text x=\"490.4\" y=\"259.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">daniel’s tolerance: 10% at R$ 500,000</text><text x=\"385.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">total loss in one year, R$ (log scale)</text><text x=\"80.0\" y=\"14.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">chance of losing more</text></svg>", "caption": "One curve for the whole portfolio. Where it runs above the tolerance point, the business is carrying more risk than it said it would."}
```

### Risk appetite, as a point on the picture

A curve makes a question answerable that a list of risks never could: **how much risk is the
business willing to carry?** daniel's answer, after looking at the curve for a while, was a single
point: *no more than a 10% chance of losing more than half a million reais in a year.* That
sentence is the clinics' **risk appetite**, or its tolerance, written in units anybody can check.

The curve passes **above** that point: the chance of losing more than R$ 500,000 is 14.1%. The
business is carrying more risk than its owner says it wants, and that, not a colour on a chart, is
the reason to spend money on controls. Lesson 11 asks which controls bring the curve below the point
for the least money.

### Two cautions

**The curve's far right is the least certain part.** The chance of losing more than R$ 1,000,000
depends almost entirely on the tails of the widest ranges, which are the estimates the team was
least sure of. Read 4.8% as "a few percent", not as a measurement.

**The appetite is a decision, not a calculation.** No formula produces daniel's point. It depends on
what Vereda can absorb, what the owners are willing to lose, what insurance would cost, and what the
patients would accept. The analysis's job is to show daniel the curve in reais; the decision is
daniel's, and lesson 12 is about writing it down.
