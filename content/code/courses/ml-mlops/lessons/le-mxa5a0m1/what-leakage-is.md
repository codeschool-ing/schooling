---
title: What leakage is
version: 1
---

**Leakage is information in the training or test rows that will not exist at the moment the model
is used.** A model trained with it learns to use it, and a test set that also contains it rewards
the model for using it. Both scores look excellent. The model then goes to production, where the
information is not there, and it does something nobody measured.

The definition turns on one moment: **the moment of prediction.** For the lapse model that is the
cutoff, the night the scores are computed. Everything known by then may be a feature. Everything
learned after it, including whether the member came back, may only be the label.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l03-moment\" aria-label=\"A timeline around the cutoff, 30 November 2025. To its left, the 180 days the features are computed from. To its right, the 90 days the label is computed from. Anything from the right-hand side that reaches a feature is leakage.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"40.0\" y=\"88.0\" width=\"400.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">features: 180 days before</text><rect x=\"440.0\" y=\"88.0\" width=\"240.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"560.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">label: 90 days after</text><path d=\"M440.0 40.0 L440.0 160.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"440.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">the cutoff: the moment of prediction</text><text x=\"40.0\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4 Jun 2025</text><text x=\"440.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30 Nov 2025</text><text x=\"680.0\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">28 Feb 2026</text><path d=\"M560.0 134 C 560.0 190, 300.0 190, 300.0 134\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#st-ah-amber)\"></path><text x=\"400.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">any of this in a feature is leakage</text></svg>", "caption": "One date divides every example. What is to its left may describe the member; what is to its right may only be the answer."}
```

Written down, it sounds impossible to get wrong. In practice it arrives through the platform, not
through the model, in four shapes this lesson measures one at a time:

1. **a column read from a table as it is today**, not as it was at the cutoff (section 05);
2. **the same member on both sides of a split**, so the test rows are partly rows the model has
   already seen (section 06);
3. **labels that are not finished**, because the window after the cutoff has not closed (section
   08);
4. **a preprocessing step fitted on every row**, test rows included, before the split (section 09).

**The first one is the one a data engineer causes most often**, because the tables a warehouse
keeps are built for reporting the present, and a model's features need the past as it looked at
the time.
