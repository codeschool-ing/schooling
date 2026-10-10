---
title: Labels that are not finished
version: 1
---

The label is computed by `features.py`: *no purchase in the 90 days after the cutoff*. For a cutoff
less than 90 days before the last day in the database, part of those 90 days has not happened, and
**a member who simply has not had time to come back is labelled lapsed.** No error, no warning,
just a label that is wrong in one direction.

How wrong is one program away. Save it as `maturity.py`:

```python
"""maturity.py: the share of members labelled lapsed, cutoff by cutoff."""
import features

for cutoff in ["2025-10-31", "2025-11-15", "2025-11-30", "2025-12-15", "2025-12-31",
               "2026-01-15", "2026-01-31", "2026-02-15"]:
    rows = features.build(cutoff)
    print(f"{cutoff}  {len(rows):5} active  {rows['lapsed'].mean():6.1%} lapsed")
```

```
ana@dev:~/ml$ python maturity.py
2025-10-31   3038 active   17.1% lapsed
2025-11-15   3094 active   17.0% lapsed
2025-11-30   3130 active   16.9% lapsed
2025-12-15   3165 active   19.2% lapsed
2025-12-31   3208 active   23.2% lapsed
2026-01-15   3244 active   30.1% lapsed
2026-01-31   3291 active   43.1% lapsed
2026-02-15   3316 active   65.5% lapsed
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l03-maturity\" aria-label=\"Share of active members labelled lapsed, by cutoff: 17.1% at 31 October, 17.0% at 15 November, 16.9% at 30 November, then 19.2%, 23.2%, 30.1%, 43.1% and 65.5% at 15 February, as the 90-day window runs past the last day of data.\"><path d=\"M70.0 40.0 L70.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 220.0 L70.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><path d=\"M70.0 168.6 L690.0 168.6\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 168.6 L70.0 168.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"168.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20%</text><path d=\"M70.0 117.1 L690.0 117.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 117.1 L70.0 117.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"117.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40%</text><path d=\"M70.0 65.7 L690.0 65.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 65.7 L70.0 65.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"65.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60%</text><text x=\"70.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">labelled lapsed</text><path d=\"M70.0 220.0 L690.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M93.4 220.0 L93.4 176.0 L137.4 176.0 L137.4 220.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"115.4\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">17.1%</text><text x=\"115.4\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">25-10-31</text><path d=\"M169.0 220.0 L169.0 176.3 L213.0 176.3 L213.0 220.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"191.0\" y=\"167.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">17.0%</text><text x=\"191.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">25-11-15</text><path d=\"M244.6 220.0 L244.6 176.5 L288.6 176.5 L288.6 220.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"266.6\" y=\"167.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">16.9%</text><text x=\"266.6\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">25-11-30</text><path d=\"M320.2 220.0 L320.2 170.6 L364.2 170.6 L364.2 220.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"342.2\" y=\"161.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">19.2%</text><text x=\"342.2\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">25-12-15</text><path d=\"M395.8 220.0 L395.8 160.3 L439.8 160.3 L439.8 220.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"417.8\" y=\"151.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">23.2%</text><text x=\"417.8\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">25-12-31</text><path d=\"M471.4 220.0 L471.4 142.6 L515.4 142.6 L515.4 220.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"493.4\" y=\"133.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">30.1%</text><text x=\"493.4\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">26-01-15</text><path d=\"M547.0 220.0 L547.0 109.2 L591.0 109.2 L591.0 220.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"569.0\" y=\"100.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">43.1%</text><text x=\"569.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">26-01-31</text><path d=\"M622.6 220.0 L622.6 51.6 L666.6 51.6 L666.6 220.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"644.6\" y=\"42.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">65.5%</text><text x=\"644.6\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">26-02-15</text><text x=\"191.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">window closed</text><text x=\"531.2\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">window still open</text></svg>", "caption": "The label is honest until its window reaches past the data. After that, every member who has not yet come back is counted as gone."}
```

Up to 30 November the share sits at 17%, because those cutoffs' 90 days ended by 28 February. From
15 December it climbs, because their windows reach past the end of the data: 23.2% at the end of
December, 43.1% at the end of January, and **65.5% two weeks before the database's last day**, when
almost nobody has had time to visit again.

A model trained on those rows learns that lapsing is three or four times as common as it is, and it
learns it most from the newest rows, the ones a nightly retrain would weigh as the most relevant.
**The cure is to never compute a label whose window is open**, which in SQL is one more condition:
the cutoff plus 90 days must be on or before the last day the data is complete. It belongs in the
pipeline that builds the training set, not in the modeller's notebook, because it is a property of
when the data landed.

The same shape turns up wherever an outcome takes time: a loan that defaults within a year, a
purchase returned within thirty days, a fraud reported by a chargeback weeks later. **Every label
has a maturity, and a training set has to know it.**
