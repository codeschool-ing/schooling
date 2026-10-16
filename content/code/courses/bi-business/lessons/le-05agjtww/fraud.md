---
title: Fraud: hunting something rare
version: 1
---

Every card payment Ipê authorises passes through rules that decide, in a fraction of a second, whether
it looks like fraud. A payment that does is blocked until the customer confirms it. BI does not write
those rules: it **measures what they cost**, in fraud let through and in good customers stopped. This
section is written from that side, the side of detection and measurement.

## The base rate

In December 2025, Ipê's card processed 400,000 payments. Over the following weeks, as customers
disputed charges they did not make, 400 of them turned out to be fraud: **0.1%, one payment in a
thousand**. That number, how common the thing is before any rule looks for it, is the base rate, and
almost every surprise in fraud measurement comes from forgetting it.

Ipê's main rule, rule A, flagged 300 of the 400 frauds, three in four. It also flagged 2% of the good
payments. Two per cent sounds small. Of 399,600 good payments it is 7,992.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A tree of December's 400,000 card payments. 400 are fraud and 399,600 are good. Of the 400 fraud, rule A flags 300 and misses 100. Of the 399,600 good, it flags 7,992 and lets 391,608 through. Among the 8,292 flagged, 300 are fraud: a precision of 3.6%.\" data-fig=\"l17-fraud\"><rect x=\"250.0\" y=\"14.0\" width=\"220.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"35.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">card payments in December</text><text x=\"360.0\" y=\"55.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">400,000</text><rect x=\"100.0\" y=\"110.0\" width=\"180.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"190.0\" y=\"131.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">fraud</text><text x=\"190.0\" y=\"151.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">400</text><rect x=\"440.0\" y=\"110.0\" width=\"180.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"530.0\" y=\"131.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">good</text><text x=\"530.0\" y=\"151.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">399,600</text><rect x=\"20.0\" y=\"206.0\" width=\"150.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"227.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">fraud flagged</text><text x=\"95.0\" y=\"247.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">300</text><rect x=\"195.0\" y=\"206.0\" width=\"150.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270.0\" y=\"227.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">fraud missed</text><text x=\"270.0\" y=\"247.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">100</text><rect x=\"375.0\" y=\"206.0\" width=\"150.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"227.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">good flagged</text><text x=\"450.0\" y=\"247.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">7,992</text><rect x=\"550.0\" y=\"206.0\" width=\"150.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"625.0\" y=\"227.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">good let through</text><text x=\"625.0\" y=\"247.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">391,608</text><path d=\"M360.0 66.0 L360.0 88.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M190.0 88.0 L530.0 88.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M190.0 88.0 L190.0 108.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M530.0 88.0 L530.0 108.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M190.0 162.0 L190.0 184.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M95.0 184.0 L270.0 184.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M95.0 184.0 L95.0 204.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M270.0 184.0 L270.0 204.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M530.0 162.0 L530.0 184.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M450.0 184.0 L625.0 184.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M450.0 184.0 L450.0 204.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M625.0 184.0 L625.0 204.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"360.0\" y=\"292.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">flagged by rule A: 8,292, of which 300 are fraud</text><text x=\"360.0\" y=\"314.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">precision 3.6%: about 27 good customers blocked for each fraud caught</text></svg>", "caption": "Rule A catches three frauds in four, and still most of what it flags is good customers, because good payments outnumber fraud a thousand to one."}
```

## Precision: how many of the alerts are right

Rule A raised 8,292 alerts in the month, and 300 were fraud. **Its precision, the share of its alerts
that were right, is 3.6%.** For every fraud it caught, about 27 good customers had a payment blocked at
a till, rang the call centre or gave up. A rule that catches three frauds in four and is wrong about
96 alerts in 100 is not a contradiction; it is what any rule looks like when the thing it hunts is a
thousand times rarer than the thing it must not touch.

Type the two rules Ipê was choosing between into a new sheet from A1. B is the frauds each caught, of
the month's 400; C the good payments each blocked:

| | A | B | C |
|---|---|---|---|
| 1 | Rule | Caught | Good blocked |
| 2 | Rule A | 300 | 7992 |
| 3 | Rule B | 240 | 3996 |

Rule B is stricter: it flags 1% of good payments instead of 2%, and catches 60% of the fraud instead of
75%. In D1 type `Precision %`, and in D2:

```localised
=ROUND(B2/(B2+C2)*100,1)      3.6
```

Copy it to D3: rule B's precision is **5.7%**. Better, and still mostly wrong alerts.

## The two costs

Precision alone does not choose between the rules, because the two mistakes cost different amounts. A
fraud let through costs Ipê, on average, R$ 1,100. A good payment blocked costs about R$ 15 to handle,
in the call centre's time; what it costs in customers who stop using the card is real and harder to
price, and Ipê leaves it out of this sum on purpose and says so. In E1 type `Missed`, and in E2 the
frauds the rule let through:

```localised
=400-B2      100
```

In F1 `Cost`, and in F2 the month's cost of both mistakes, in reais:

```localised
=E2*1100+C2*15      229880
```

Copy E2:F2 to row 3. **Rule A costs R$ 229,880 a month and rule B R$ 235,940**: the stricter rule saves
R$ 59,940 in blocked good payments and loses R$ 66,000 more in fraud let through. With no rule at all,
the 400 frauds would have cost R$ 440,000.

The two rules are close, and the answer would flip if a blocked customer cost a few reais more. That is
the honest result: **the threshold of a fraud rule is a business decision about the price of each
mistake**, made by people who own both prices, which is `machine-learning` lesson 11's argument about
any model's threshold and lesson 14's about Marcos's alerts.

## What makes fraud data odd

Two habits of the data change every number above.

- **The labels arrive late.** A payment is known to be fraud only when somebody disputes it, often weeks
  later. A report on yesterday's fraud counts only what has been disputed so far and always looks
  better than the month will. It is the young-book problem of the last section, in another form.
- **A blocked fraud leaves no outcome.** When rule A stops a payment and the customer never confirms
  it, Ipê assumes it was fraud, and some were good customers who gave up. The rule's own decisions shape
  the data it is later measured on.

How a model is built to find fraud, and why accuracy is the wrong measure when one case in a thousand is
positive, is `machine-learning` lessons 10 and 13. The BI analyst's part is the one in this section:
the base rate, the precision, the two costs, and a report that says how much of last month's fraud has
not been discovered yet.
