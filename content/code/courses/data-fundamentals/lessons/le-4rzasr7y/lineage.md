---
title: Lineage: walking a number back to where it was born
version: 1
---

**Lineage is the answer to "where did this number come from?", given as a path that can be walked
backwards, one stage at a time, down to the rows in the source.** It is the lifecycle read in the
other direction.

Marta reads the morning report and stops at Rua XV. The station supervisor told her the docks there
unlocked more bicycles than that on Monday. One of them is wrong, and before anybody argues, the
number in the report has to be traced.

## Tracing it by hand

Because each stage writes its output to its own directory, the trace is a matter of counting the
same thing at each layer. This program does the counting for one station and one day, and lists any
ride that raw has and clean does not:

```python
# lifecycle/trace.py
import csv
import json
import sqlite3
import sys

station, day = sys.argv[1], sys.argv[2]


def starting_here(path):
    with open(path, encoding="utf-8") as f:
        return [r for r in map(json.loads, f) if r["start_station"] == station]


with open(f"curated/date={day}/rides_per_station.csv", encoding="utf-8") as f:
    curated = next(r for r in csv.DictReader(f) if r["station_id"] == station)
clean = starting_here(f"clean/date={day}/rides.jsonl")
raw = starting_here(f"raw/date={day}/rides.jsonl")
app = sqlite3.connect("file:app.db?mode=ro", uri=True)
source = app.execute("SELECT count(*) FROM rides WHERE start_station = ? AND started_at LIKE ?",
                     (station, day + "%")).fetchone()[0]

print(f"curated {curated['rides']:>4}  curated/date={day}/rides_per_station.csv")
print(f"clean   {len(clean):>4}  clean/date={day}/rides.jsonl")
print(f"raw     {len(raw):>4}  raw/date={day}/rides.jsonl")
print(f"app.db  {source:>4}  table rides")
kept = {r["ride_id"] for r in clean}
for r in raw:
    if r["ride_id"] not in kept:
        print("dropped", r["ride_id"], r["started_at"], r["minutes"], "min")
```

Ask it about Rua XV on Monday:

```
ana@lab:~/roda/lifecycle$ python trace.py ST02 2025-09-15
curated   29  curated/date=2025-09-15/rides_per_station.csv
clean     29  clean/date=2025-09-15/rides.jsonl
raw       31  raw/date=2025-09-15/rides.jsonl
app.db    31  table rides
dropped R000183 2025-09-15 06:33 1 min
dropped R000342 2025-09-15 19:51 0 min
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 352\" role=\"img\" aria-label=\"Five layers, from the top: the report says Rua XV 29; the curated row says ST02, Rua XV, 29; the clean zone has 29 rides from ST02; the raw zone has 31; the app database has 31. Ingestion copied all 31; the transformation dropped 2 false starts, R000183 and R000342; the 29 left were counted into one row and read by the report.\" data-fig=\"lineage\"><defs><marker id=\"lineage-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"134\" y=\"33.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">the report</text><rect x=\"148\" y=\"14\" width=\"240\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"268.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST02 Rua XV  29</text><text x=\"134\" y=\"101.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">curated</text><rect x=\"148\" y=\"82\" width=\"240\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"268.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST02,Rua XV,29,610</text><text x=\"134\" y=\"169.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">clean</text><rect x=\"148\" y=\"150\" width=\"240\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"268.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">29 rides from ST02</text><text x=\"134\" y=\"237.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">raw</text><rect x=\"148\" y=\"218\" width=\"240\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"268.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">31 rides from ST02</text><text x=\"134\" y=\"305.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">the app</text><rect x=\"148\" y=\"286\" width=\"240\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"268.0\" y=\"305.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">31 rides from ST02</text><line x1=\"268\" y1=\"82\" x2=\"268\" y2=\"54\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lineage-ah)\"></line><text x=\"408\" y=\"67.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">read by the report</text><line x1=\"268\" y1=\"150\" x2=\"268\" y2=\"122\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lineage-ah)\"></line><text x=\"408\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">counted: one row per station</text><line x1=\"268\" y1=\"218\" x2=\"268\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lineage-ah)\"></line><text x=\"408\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the transformation drops 2 false starts</text><text x=\"408\" y=\"211.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">R000183 1 min, R000342 0 min</text><line x1=\"268\" y1=\"286\" x2=\"268\" y2=\"258\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lineage-ah)\"></line><text x=\"408\" y=\"271.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ingestion copies all of them</text></svg>", "caption": "The 29 rides from Rua XV in the report, walked back to the app. Every difference between two layers is one rule in one program."}
```

Read from the bottom up, that is the whole history of one number. The app has 31 rides from
Rua XV that day; ingestion copied all 31, which is what ingestion is for; the transformation
dropped 2 of them as false starts, and the 29 that remain are the 29 in
the report. **Every difference between two layers is explained by one rule in one program**, and the
two rides it names can be looked up and argued about. The supervisor's count was right, and so was
the report: they count different things, and now both sides can see which.

## Why it matters beyond one argument

- Trust: a number that can be traced is a number somebody can defend in a meeting. A number that
  cannot is an opinion with decimals.
- Impact: read forwards, the same path answers a different question: if the app team renames
  `start_station`, which tables and which reports break? Without lineage, the answer is found the
  morning after.
- Erasure: when a customer asks Roda Livre to delete their data, as the LGPD allows, somebody has
  to know every zone their rows reached. Lineage is that list.

## Lineage at the size of a company

Here the path was four directories and a program that knows where they are. At a company there are
thousands of tables, and nobody traces them by hand. Tools record lineage as the pipelines run,
noting which job read which table and wrote which other, and draw it as a graph. The most thorough
go down to single columns, and OpenLineage is an open standard for describing it. The tools change the
scale and not the idea: **every number in a report is the end of a path, and somebody has to be able
to walk it back.**
