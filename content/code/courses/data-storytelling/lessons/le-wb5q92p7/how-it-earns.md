---
title: How a subscription business earns
version: 1
---

Every finding eventually has to answer a finance question: **what does this do to the money?** Answering
it starts with knowing how the money is made, and a subscription business makes it in a shape worth
learning, because so many companies now sell that way.

## The parts

- **Price.** What a subscriber pays each period. Faro's average box costs R$ 189.90 a month.
- **Gross margin.** What is left of the price after the direct costs of delivering it: the food, the
  packaging, the shipping. Faro keeps 31%, so each box leaves **R$ 58.87**. Margin, not price, is what pays
  for everything else the company does.
- **Churn.** The share of subscribers who leave in a period. Faro's has two phases: high in the first
  ninety days, where this whole course has been looking, and about 4% a month after that.
- **Customer acquisition cost, or CAC.** What the company spends to win one new subscriber: advertising,
  discounts, the first-box promotion. Faro's marketing team puts it at **R$ 152**.
- **Lifetime value, or LTV.** The margin a customer brings over the whole time they stay. It depends on all
  of the above, and the next section computes it.

## The one relationship that matters

A subscriber is profitable once their margin has paid back what it cost to win them. At R$ 58.87 a box
against R$ 152 to acquire, **that takes about 2.6 boxes**. Before that point, the company is still paying
for the customer; after it, the customer is paying for the company.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 280\" role=\"img\" data-fig=\"l11-payback\" aria-label=\"Cumulative margin from one customer, rising by R$ 58.87 with each box, against a flat line at R$ 152, the cost of acquiring them. The rising line crosses the cost line at about 2.6 boxes. A marker at 1.6 boxes, where the average early canceller stops, sits below the cost line at R$ 94.19.\"><path d=\"M70.0 30.0 L70.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 0</text><path d=\"M70.0 167.2 L640.0 167.2\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"167.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 100</text><path d=\"M70.0 114.4 L640.0 114.4\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"114.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 200</text><path d=\"M70.0 61.7 L640.0 61.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"61.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 300</text><text x=\"70.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"165.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"260.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"355.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"450.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"545.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"640.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"355.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">boxes paid</text><path d=\"M70.0 220.0 L640.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70.0 139.8 L640.0 139.8\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\"></path><text x=\"640.0\" y=\"129.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">cost to acquire: R$ 152</text><path d=\"M70.0 220.0 L640.0 33.6\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"573.5\" y=\"43.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">margin so far</text><circle cx=\"222.0\" cy=\"170.3\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M222.0 170.3 L222.0 220.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"232.0\" y=\"196.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">early canceller: 1.6 boxes, R$ 94.19</text><circle cx=\"315.3\" cy=\"139.8\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"305.3\" y=\"125.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">paid back at 2.6 boxes</text></svg>", "caption": "A customer pays back what it cost to win them after about 2.6 boxes. The average early canceller stops at 1.6, so every one of them was bought at a loss."}
```

Now the first box looks different. **A customer who cancels in the first ninety days pays, on average, 1.6
boxes**, which is R$ 94.19 of margin: not enough to recover the R$ 152 Faro paid to win them. Every early
cancellation is a customer bought at a loss. That sentence, more than any percentage, is what makes a
finance director lean forward.

## Why an analyst needs this

Nobody expects an analyst to run the finance department. But **a finding placed in this structure can be
weighed against every other use of the company's money**, and one that is not stays an operational
curiosity. Lesson 4 led the board version with money for exactly this reason; this lesson shows where the
money came from.
