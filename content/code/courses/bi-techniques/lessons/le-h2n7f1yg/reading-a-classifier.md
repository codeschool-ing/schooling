---
title: Reading a classifier
version: 1
---

**Accuracy, the share predicted correctly, is 89.4 per cent, and it is the least informative number
the model produced.** A model that predicts "stays" for every customer, without looking at anything,
is right 83.5 per cent of the time, because most customers stay. The model's real contribution is the
gap between the two, and accuracy hides it. Whenever one category is rare, accuracy flatters.

Two other numbers describe what the model does for the people who will use it.

- **Precision**, 78.8 per cent: of the customers the model flags, how many really churn. It is what a
  retention team experiences: of every hundred customers they call, seventy-nine were really leaving
  and twenty-one were fine.
- **Recall**, 48.5 per cent: of the customers who churn, how many the model flags. It is what the
  business experiences: of every hundred customers who leave, the model warned about forty-eight.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 230\" role=\"img\" data-fig=\"l17-confusion\" aria-label=\"The confusion matrix of the churn model at a threshold of 0.5, as four boxes. Churned and flagged: 204. Churned and not flagged: 217. Stayed and flagged: 55. Stayed and not flagged: 2082. Precision reads along the flagged column, recall along the churned row.\"><text x=\"200.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">flagged</text><text x=\"360.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">not flagged</text><text x=\"108.0\" y=\"75.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">churned</text><rect x=\"120.0\" y=\"40.0\" width=\"160.0\" height=\"70.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">204</text><text x=\"200.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">caught</text><rect x=\"280.0\" y=\"40.0\" width=\"160.0\" height=\"70.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">217</text><text x=\"360.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">missed</text><text x=\"108.0\" y=\"145.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">stayed</text><rect x=\"120.0\" y=\"110.0\" width=\"160.0\" height=\"70.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">55</text><text x=\"200.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">false alarms</text><rect x=\"280.0\" y=\"110.0\" width=\"160.0\" height=\"70.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">2082</text><text x=\"360.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">left alone</text><path d=\"M121 41 h158 v68 h-158 Z\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\" fill=\"none\"></path><text x=\"200.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">precision: caught ÷ flagged</text><text x=\"452.0\" y=\"75.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">recall: caught ÷ churned</text></svg>", "caption": "The same four counts give every measure. Precision is what the retention team sees; recall is what the business sees."}
```

They pull against each other. Flag more customers and recall rises, because more of the leavers are
caught, and precision falls, because more of the flagged were never leaving. **There is no setting
that maximises both**, which is why the next section chooses one from what the mistakes cost.

## The two mistakes are not the same

A **false alarm** costs whatever is done to the flagged customer: a phone call, a discount given to
somebody who would have paid full price. A **missed churner** costs the customer, everything they
would have spent. At Panela the second is far more expensive than the first, so the business should
accept many false alarms to catch more leavers, which means a lower threshold than the default of 0.5.

That default has no meaning of its own. It is the point where the model thinks churning is as likely as
not, and nothing about the business says that is where action should start.
