---
title: "Commitments: a discount for a promise"
version: 1
---

On-demand is the price for keeping every option open: you can stop any machine at any hour and owe
nothing more. **A commitment is the same machine sold cheaper in exchange for a promise to pay for it
whether you use it or not**, usually for one or three years. Every large provider sells one. AWS has
Reserved Instances, which name a machine type in a region, and Savings Plans, which promise an amount
of spend per hour across many types. Google Cloud has committed use discounts, and Azure has
reservations and its own savings plan.

## What the sheet says it is worth

The sheet's second block is the 1-year reserved price with no upfront payment, beside the on-demand
price in its first block. Two lines from the `sa-east-1` column:

| machine | on demand, per hour | 1-year reserved, per hour | discount |
| --- | --- | --- | --- |
| `m7i.large` | 0.16065 | 0.09956 | 38.0% |
| `t3.medium` | 0.06720 | 0.03860 | 42.6% |

The discount is one minus the ratio: 1 − 0.09956 / 0.16065 = 0.380, and 1 − 0.03860 / 0.06720 = 0.426.
In money, an `m7i.large` saves 0.06109 an hour, which over a 730-hour month is **44.60 USD per machine**.
A `t3.medium` saves 0.02860 an hour, 20.88 a month; the estimate's two machines would cost 56.36 a month
instead of 98.11.

## What the promise costs

"No upfront" sounds like no obligation, and it is not one. It means the payment is spread over the
year instead of made on the first day. **A 1-year reservation for a `t3.medium` is a debt of
0.03860 × 8,760 = 338.14 USD**, owed in hourly instalments whether any machine runs or not. If the
application is rewritten for functions in month four, the remaining eight months are still billed.

That gives a simple test. The reservation costs 0.03860 for every hour; on demand costs 0.06720, but
only for the hours the machine actually runs. The two are equal when the machine runs
0.03860 / 0.06720 = **57.4% of the hours**. A machine that runs more than that is cheaper reserved; a
machine that runs less, such as a test environment switched off at night and at weekends, is cheaper on
demand, however large the advertised discount.

## Commit to the floor

The usage of a real application moves. Lesson 4's autoscaling group runs two machines at night and six
at the busiest hour of the busiest month, and the rest of the year somewhere between.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Machines running over one year of an invented application. The count never falls below 2, rises through the year and peaks at 6 once, near the end. The band from 0 to 2 is the committed floor, reserved and used every hour. The line above it is on-demand capacity that comes and goes. A dashed line at 6 marks the peak, where a commitment would pay for idle hours.\"><defs><marker id=\"flr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"60\" y=\"186\" width=\"560\" height=\"64\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"72\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">committed floor: reserved, used every hour</text><path d=\"M60.0 186.0 L65.4 147.5 L70.9 162.1 L76.3 186.0 L81.7 158.3 L87.2 157.6 L92.6 153.2 L98.1 148.3 L103.5 139.3 L108.9 156.3 L114.4 147.8 L119.8 166.8 L125.2 134.4 L130.7 157.3 L136.1 135.4 L141.6 160.4 L147.0 144.0 L152.4 144.2 L157.9 136.5 L163.3 137.5 L168.7 151.6 L174.2 142.2 L179.6 151.3 L185.0 127.2 L190.5 156.1 L195.9 135.2 L201.4 162.2 L206.8 132.5 L212.2 141.6 L217.7 132.1 L223.1 142.7 L228.5 150.7 L234.0 136.3 L239.4 142.6 L244.9 128.0 L250.3 155.7 L255.7 141.6 L261.2 160.3 L266.6 128.2 L272.0 146.7 L277.5 186.0 L282.9 154.3 L288.3 143.2 L293.8 137.1 L299.2 141.1 L304.7 136.1 L310.1 160.9 L315.5 140.0 L321.0 158.9 L326.4 130.4 L331.8 157.8 L337.3 143.7 L342.7 159.5 L348.2 139.8 L353.6 142.8 L359.0 144.5 L364.5 148.3 L369.9 161.4 L375.3 139.9 L380.8 156.5 L386.2 136.3 L391.7 171.1 L397.1 149.2 L402.5 161.0 L408.0 138.0 L413.4 150.3 L418.8 148.8 L424.3 159.0 L429.7 153.4 L435.1 139.7 L440.6 153.9 L446.0 141.9 L451.5 175.1 L456.9 142.2 L462.3 160.4 L467.8 135.1 L473.2 156.1 L478.6 150.3 L484.1 152.7 L489.5 142.2 L495.0 137.3 L500.4 148.7 L505.8 144.2 L511.3 160.3 L516.7 131.2 L522.1 155.6 L527.6 129.5 L533.0 157.8 L538.4 137.9 L543.9 141.7 L549.3 127.6 L554.8 132.0 L560.2 139.7 L565.6 135.8 L571.1 138.7 L576.5 117.2 L581.9 140.1 L587.4 121.1 L592.8 58.0 L598.3 116.6 L603.7 128.1 L609.1 111.6 L614.6 124.9 L620.0 127.8\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M60 58 L620 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"628\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the peak</text><text x=\"628\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">the floor</text><text x=\"210\" y=\"93.19999999999999\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">above the floor: on demand, comes and goes</text><path d=\"M60 250 L620 250\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60 250 L60 45.19999999999999\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"50\" y=\"250\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"50\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"50\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"50\" y=\"58\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><text x=\"50\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">machines running</text><text x=\"60\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">January</text><text x=\"620\" y=\"270\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">December</text></svg>", "caption": "An invented year, not a measurement. The two machines that run every hour are what a commitment is for. Committing to six would pay, every hour of the year, for four machines that were needed on a few days."}
```

**Commit to the floor of your usage, not to the peak.** The machines that run every hour of the year are
the ones a commitment is for: they are always used, so every hour of the promise is worth its discount.
The machines above the floor come and go, and paying on demand for them is what buys the freedom to
remove them. Commit to the peak and the hours between the peak and the real usage are paid for and wasted. At a 42.6% discount, a reserved `t3.medium` that sits idle for more than 42.6% of its hours
has cost more than paying on demand would have.

Two more rules follow from the same idea. Commit to what you have measured over months, not to the
estimate, because the estimate has never been tested against a real month. And when you are unsure, prefer the commitment
that is easier to reuse. A Savings Plan that follows your spend to another machine type gives a smaller
discount than a reservation for one type, and is worth much more the day you change type.
