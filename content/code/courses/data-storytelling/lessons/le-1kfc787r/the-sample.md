---
title: The sample: who is in it, and who is not
version: 1
---

Every number describes a group. **Questioning the sample means asking how that group was chosen, and who
the choice left out**, because the people left out are rarely a random slice of everybody.

## Faro's exit survey

When a subscriber cancels, Faro asks why. Of the 1,320 who cancelled within ninety days in the first half
of 2025, **304 answered**, 23%. Their reasons:

| reason | answers | share |
|---|---|---|
| price | 116 | 38.2% |
| the pet refused the food | 58 | 19.1% |
| delivery | 52 | 17.1% |
| moved to a shop | 43 | 14.1% |
| other | 35 | 11.5% |

Read naively, the survey contradicts Marina: customers say they leave because of price, and delivery comes
third. Paulo asked exactly this in the premortem of lesson 10.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 300\" role=\"img\" data-fig=\"l12-survey\" aria-label=\"A bar of all 1,320 early cancellers: 304 answered the exit survey, 23%, and 1,016 did not. Below, the answers of the 304: price 116, the pet refused the food 58, delivery 52, moved to a shop 43, other 35. The people who did not answer are the larger part, and nothing is known about their reasons.\"><text x=\"30.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">everyone who cancelled within 90 days, 1,320</text><path d=\"M30.0 32.0 L172.8 32.0 L172.8 62.0 L30.0 62.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M172.8 32.0 L650.0 32.0 L650.0 62.0 L172.8 62.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><text x=\"101.4\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">answered, 304</text><text x=\"411.4\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">did not answer, 1,016</text><text x=\"30.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">what the 304 said</text><text x=\"220.0\" y=\"131.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">price</text><path d=\"M230.0 120.0 L560.0 120.0 L560.0 142.0 L230.0 142.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--panel)\"></path><text x=\"566.0\" y=\"131.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">116  (38.2%)</text><text x=\"220.0\" y=\"163.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the pet refused the food</text><path d=\"M230.0 152.0 L395.0 152.0 L395.0 174.0 L230.0 174.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--panel)\"></path><text x=\"401.0\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">58  (19.1%)</text><text x=\"220.0\" y=\"195.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">delivery</text><path d=\"M230.0 184.0 L377.9 184.0 L377.9 206.0 L230.0 206.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"var(--scan)\"></path><text x=\"383.9\" y=\"195.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">52  (17.1%)</text><text x=\"220.0\" y=\"227.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">moved to a shop</text><path d=\"M230.0 216.0 L352.3 216.0 L352.3 238.0 L230.0 238.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--panel)\"></path><text x=\"358.3\" y=\"227.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">43  (14.1%)</text><text x=\"220.0\" y=\"259.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">other</text><path d=\"M230.0 248.0 L329.6 248.0 L329.6 270.0 L230.0 270.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--panel)\"></path><text x=\"335.6\" y=\"259.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">35  (11.5%)</text></svg>", "caption": "The survey describes the 23% who chose to answer. The cancellation rates describe all 6,113 subscribers, which is why behaviour outweighs what the survey says."}
```

## Why the survey and the behaviour disagree

- **Who answered.** 304 people chose to answer and 1,016 did not. People who answer exit surveys differ from
  people who do not, in ways nobody measured. If customers who left after a bad first delivery were less
  willing to spend another minute on Faro, they are under-represented among the answers.
- **What is easy to say.** "Too expensive" is a complete, polite reason that needs no story. A first box
  that arrived three days late, weeks before cancelling, may not be what a customer remembers as the reason,
  even if it is when they started looking elsewhere.
- **What was asked.** The survey offers five boxes and the first is price. The list shapes the answers.

The cancellation rates in Marina's analysis are **behaviour, measured on everybody**: all 6,113 subscribers,
not the 23% who chose to talk. Where stated reasons and behaviour disagree, behaviour measured on the whole
group is usually the stronger evidence, and the survey still earns its place as a clue to other causes.

## Survivorship

A second kind of sample problem is subtler: **the data includes only those who survived to be counted**. If
Faro had analysed only customers still subscribed after a year, it would have found that first deliveries
barely matter, because the customers they drove away were no longer in the data. Marina's analysis avoids
this by starting from everybody who joined and following them forward, which is why it is built on cohorts.
