---
title: Two problems with one cause
version: 1
---

Two lessons ended on the same kind of failure, and neither raised an error.

**Lesson 3:** a model trained with `recency_days` read from a summary table as it stood on the last
night, not as it stood on each cutoff. Its test score was 0.994, and in production it flagged 2,450
members of 3,130.

**Lesson 5:** the same saved model, fed features the website computed in its own code, with money in
reais instead of cents. 160 members' probabilities moved by more than 0.1.

**Both are a feature computed in more than one place, or for the wrong moment.** The first needs
every training row's features as they stood on that row's own date. The second needs the service to
get its features from the same code training used. A **feature store** is the piece of a platform
built to give both: features computed once, kept with the day they were true, and served to training
and to production from the same place.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l06-between\" aria-label=\"The feature store between the code that computes features and the two readers. features.py, run as of each day, writes snapshots into the offline store. The online store is built from the offline store. Training and batch scoring read the offline store with a point-in-time join; a service reads one member from the online store.\"><defs><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"115.0\" width=\"160.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">features.py</text><text x=\"100.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">as of each day</text><rect x=\"230.0\" y=\"20.0\" width=\"260.0\" height=\"250.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"700\" fill=\"var(--amber)\">the feature store</text><rect x=\"255.0\" y=\"62.0\" width=\"210.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">offline store</text><text x=\"360.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every value, with its day</text><rect x=\"255.0\" y=\"180.0\" width=\"210.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">online store</text><text x=\"360.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the latest value per member</text><path d=\"M180.0 130.0 L253.0 100.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M360.0 132.0 L360.0 178.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"540.0\" y=\"62.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">training</text><text x=\"620.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">as of each row</text><rect x=\"540.0\" y=\"180.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">a service</text><text x=\"620.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one member, now</text><path d=\"M467.0 97.0 L538.0 97.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M467.0 215.0 L538.0 215.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path></svg>", "caption": "One computation, two faces. Training asks about the past and a service asks about now, and both get values computed by the same code."}
```

It sits between the pipelines that produce features and the two kinds of reader, and it has **two
faces because the two readers ask different questions**:

| | the **offline store** | the **online store** |
| --- | --- | --- |
| who asks | training and batch scoring | a service answering one request |
| the question | what did these members look like on these days? | what does this member look like now? |
| answers | many rows at once, in seconds | one row, in milliseconds |
| keeps | every value, with the day it was true | the latest value per member |

**A feature store does not compute features.** The computation is still `features.py`; the store
decides when it runs, keeps what it produced, and makes sure nobody reads it from the wrong day. The
rest of this lesson builds one small enough to read whole.
