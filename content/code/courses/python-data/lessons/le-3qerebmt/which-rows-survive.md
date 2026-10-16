---
title: Which rows survive, and the argument that decides
version: 1
---

**`how` decides what happens to a row whose key has no partner on the other side.** Two small tables
show the four answers better than thirty thousand trips:

```python
left = pd.DataFrame({"station_id": ["S01", "S02", "S03"], "trips": [10, 20, 30]})
right = pd.DataFrame({"station_id": ["S02", "S03", "S04"], "docks": [20, 20, 14]})
left.merge(right, on="station_id", how="inner")
```

```
  station_id  trips  docks
0        S02     20     20
1        S03     30     20
```

`S01` has no docks and `S04` has no trips, so the **inner** join keeps only the two keys present on
both sides. It is `merge`'s default, which is worth remembering: a merge with no `how` drops every
unmatched row without a word.

```python
left.merge(right, on="station_id", how="left")
```

```
  station_id  trips  docks
0        S01     10    NaN
1        S02     20   20.0
2        S03     30   20.0
```

A **left** join keeps every row of the left table and fills the missing side with `NaN`. A **right**
join is the mirror image. An **outer** join keeps everything, and `indicator=True` adds a column
saying where each row came from:

```python
left.merge(right, on="station_id", how="outer", indicator=True)
```

```
  station_id  trips  docks      _merge
0        S01   10.0    NaN   left_only
1        S02   20.0   20.0        both
2        S03   30.0   20.0        both
3        S04    NaN   14.0  right_only
```

`_merge` is a categorical column with three values, `left_only`, `right_only` and `both`, and its
counts are the quickest audit a join has.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The keys each kind of join keeps. Left has S01, S02 and S03; right has S02, S03 and S04. Inner keeps S02 and S03. Left keeps S01, S02 and S03. Right keeps S02, S03 and S04. Outer keeps all four.\" data-fig=\"how\"><text x=\"310.0\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">S01</text><text x=\"410.0\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">S02</text><text x=\"510.0\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">S03</text><text x=\"610.0\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">S04</text><text x=\"130\" y=\"34\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in left</text><text x=\"130\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in right</text><text x=\"310.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">yes</text><text x=\"310.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no</text><text x=\"410.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">yes</text><text x=\"410.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">yes</text><text x=\"510.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">yes</text><text x=\"510.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">yes</text><text x=\"610.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no</text><text x=\"610.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">yes</text><line x1=\"150\" y1=\"80\" x2=\"690\" y2=\"80\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"130\" y=\"106\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">how=&quot;inner&quot;</text><rect x=\"270\" y=\"92\" width=\"80\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><rect x=\"370\" y=\"92\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"410.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S02</text><rect x=\"470\" y=\"92\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"510.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S03</text><rect x=\"570\" y=\"92\" width=\"80\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"130\" y=\"144\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">how=&quot;left&quot;</text><rect x=\"270\" y=\"130\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S01</text><rect x=\"370\" y=\"130\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"410.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S02</text><rect x=\"470\" y=\"130\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"510.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S03</text><rect x=\"570\" y=\"130\" width=\"80\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"130\" y=\"182\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">how=&quot;right&quot;</text><rect x=\"270\" y=\"168\" width=\"80\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><rect x=\"370\" y=\"168\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"410.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S02</text><rect x=\"470\" y=\"168\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"510.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S03</text><rect x=\"570\" y=\"168\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"610.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S04</text><text x=\"130\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">how=&quot;outer&quot;</text><rect x=\"270\" y=\"206\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S01</text><rect x=\"370\" y=\"206\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"410.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S02</text><rect x=\"470\" y=\"206\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"510.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S03</text><rect x=\"570\" y=\"206\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"610.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S04</text></svg>", "caption": "Which keys survive each how. A dashed cell is a key the join dropped."}
```

## The rows the default drops

Now the real tables. The end station of each trip, against the list of stations:

```python
ids = stations[["station_id"]].drop_duplicates()
ends = trips.merge(ids, left_on="end_station", right_on="station_id", how="left", indicator=True)
ends["_merge"].value_counts()
```

```
_merge
both          33191
left_only       146
right_only        0
Name: count, dtype: int64
```

**146 trips found no station**: the lost bikes, whose `end_station` is missing, while the list of
stations has no missing code to pair them with. With the default `how="inner"` those trips would have
left the table, and every count built on it would be 146 short, the same loss lesson 13 found in
`groupby`. `right_only` is 0, so every station has trips ending at it.

A missing key on **both** sides is another matter. Unlike SQL, pandas pairs them:

```python
a = pd.DataFrame({"k": ["S01", np.nan]})
b = pd.DataFrame({"k": [np.nan, "S01"], "v": [1, 2]})
a.merge(b, on="k")
```

```
     k  v
0  S01  2
1  NaN  1
```

The two gaps matched as though missing were a station. **Decide what a missing key means before the
join**: drop those rows, or keep them on purpose with a left join from the table you care about.

**Choose `how` on purpose, and look at `_merge` the first time.** A left join keeps the table you
care about whole; the indicator tells you how much of it found a partner.
