---
title: As of a moment, and never after
version: 1
---

**The point-in-time join asks the store a question with a date in it**: for this member, at this
moment, what was known? It takes the newest snapshot on or before the moment, and nothing after it,
however much newer data the store holds. Save this as `asof.py`:

```python
"""asof.py: one member, asked about on three different days."""
import pandas as pd

from featurestore import historical

ask = pd.DataFrame({"member_id": [2, 2, 2], "at": ["2025-11-27", "2025-11-30", "2026-02-28"]})
print(historical(ask)[["member_id", "at", "as_of", "recency_days", "visits_180d"]]
      .to_string(index=False))
```

```
ana@dev:~/ml$ python asof.py
 member_id         at      as_of  recency_days  visits_180d
         2 2025-11-27 2025-11-23          15.0            3
         2 2025-11-30 2025-11-30           0.0            4
         2 2026-02-28 2026-02-28           3.0            4
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l06-asof\" aria-label=\"A timeline of snapshots for member 2: Sundays 16, 23 and 30 November 2025, and Saturday 28 February 2026. A question on Thursday 27 November is answered by the 23 November snapshot; one on 30 November by that day's; one on 28 February by that night's. No answer comes from a snapshot after its question.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><path d=\"M40.0 150.0 L46.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M114.0 150.0 L196.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M264.0 150.0 L346.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M414.0 150.0 L606.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M674.0 150.0 L690.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"510.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" fill=\"var(--paper-dim)\">…</text><text x=\"40.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">snapshots</text><rect x=\"46.0\" y=\"138.0\" width=\"68.0\" height=\"24.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">16 Nov</text><rect x=\"196.0\" y=\"138.0\" width=\"68.0\" height=\"24.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">23 Nov</text><rect x=\"346.0\" y=\"138.0\" width=\"68.0\" height=\"24.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">30 Nov</text><rect x=\"606.0\" y=\"138.0\" width=\"68.0\" height=\"24.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">28 Feb</text><circle cx=\"330.0\" cy=\"40.0\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"322.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">asked 27 Nov</text><path d=\"M330 45 L230 136\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#st-ah-amber)\"></path><circle cx=\"390.0\" cy=\"84.0\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"398.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">asked 30 Nov</text><path d=\"M390 89 L380 136\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#st-ah-amber)\"></path><circle cx=\"640.0\" cy=\"60.0\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"632.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">asked 28 Feb</text><path d=\"M640 65 L640 136\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#st-ah-amber)\"></path></svg>", "caption": "Each question is answered by the newest snapshot on or before it. Newer rows exist in the store the whole time, and the join never reaches them."}
```

Three questions about the same member:

- **Thursday 27 November** falls between snapshots, so the answer is Sunday 23 November's: 15 days
  since the last visit, 3 visits. Four days stale, and within the seven-day time to live, so it is
  served;
- **Sunday 30 November** has a snapshot of its own: recency 0, because member 2 bought something that
  very day, and 4 visits;
- **Saturday 28 February** is tonight's snapshot: 3 days, 4 visits.

**The store held all three rows the whole time.** What it did not do is hand back February's row to
a question about November, which is exactly what the summary table did. The staleness on the
Thursday is the price of weekly snapshots, and it is a known, bounded price: at most six days,
written down as `MAX_AGE`. A leak has no bound and no name.
