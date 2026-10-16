---
title: The rows that duplicated
version: 1
---

**When a key appears more than once on the other side, each row is paired with every match, and the
result has more rows than either table.** pandas raises no error, because sometimes that is exactly
what you want. When it is not, the numbers built on the result are wrong, and they look fine.

The trips with their start station's name, the obvious way:

```python
named = trips.merge(stations, left_on="start_station", right_on="station_id")
len(trips), len(named)
```

```
(33337, 35973)
```

**2,636 more rows than trips.** Nothing was added to the data; some trips now appear twice. Which
ones:

```python
named.groupby("start_station").size().loc[["S06", "S07", "S08"]]
```

```
start_station
S06     789
S07    5272
S08    1871
dtype: int64
```

`S07` has twice its trips, because `stations.csv` has two rows for `S07`: the station was renamed in
July, and lesson 9 saw both rows. Every trip from `S07` matched both, and came out once under each
name. A count of trips per station is now wrong for one station; a sum of minutes is wrong; a share
of electric bikes is still right, because both copies have the same bike, which is how a duplicated
join hides.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Three trips, two from S07 and one from S05, merged with a station table that has two rows for S07. Each S07 trip matches both S07 rows, so the result has five rows: each S07 trip appears twice, once as Rua da Hora and once as Espinheiro.\" data-fig=\"fanout\"><defs><marker id=\"fanout-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"90\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">trips</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">stations</text><text x=\"615\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">result</text><rect x=\"20\" y=\"44\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1  S07</text><rect x=\"20\" y=\"94\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2  S07</text><rect x=\"20\" y=\"144\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3  S05</text><rect x=\"265\" y=\"44\" width=\"190\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S07  Rua da Hora</text><rect x=\"265\" y=\"94\" width=\"190\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S07  Espinheiro</text><rect x=\"265\" y=\"144\" width=\"190\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S05  Praça do Derby</text><line x1=\"164\" y1=\"60\" x2=\"261\" y2=\"60\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#fanout-ah)\"></line><line x1=\"164\" y1=\"60\" x2=\"261\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#fanout-ah)\"></line><line x1=\"164\" y1=\"110\" x2=\"261\" y2=\"60\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#fanout-ah)\"></line><line x1=\"164\" y1=\"110\" x2=\"261\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#fanout-ah)\"></line><line x1=\"164\" y1=\"160\" x2=\"261\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#fanout-ah)\"></line><rect x=\"520\" y=\"40\" width=\"190\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1  Rua da Hora</text><rect x=\"520\" y=\"78\" width=\"190\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1  Espinheiro</text><rect x=\"520\" y=\"116\" width=\"190\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"131.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2  Rua da Hora</text><rect x=\"520\" y=\"154\" width=\"190\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2  Espinheiro</text><rect x=\"520\" y=\"192\" width=\"190\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3  Praça do Derby</text><text x=\"360\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">3 trips in, 5 rows out</text><line x1=\"459\" y1=\"110\" x2=\"516\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#fanout-ah)\"></line></svg>", "caption": "Two rows for one key on the right: every trip with that key comes out twice."}
```

## The relationship, written down

Between trips and stations the relationship should be **many to one**: many trips per station, one
station per code. `validate` checks it:

```python
trips.merge(stations, left_on="start_station", right_on="station_id", validate="many_to_one")
```

```
MergeError: Merge keys are not unique in right dataset; not a many-to-one merge

Duplicates in right:
 station_id
       S07 ...
```

The merge fails, and the message names the duplicated key, `S07`. That is the whole value of the argument: it turns a
table with a silent surplus into an error with an address. The four values are `"one_to_one"`,
`"one_to_many"`, `"many_to_one"` and `"many_to_many"`, the last one checking nothing.

The other check is cheaper still, and it works after any join:

```python
len(named) == len(trips)
```

```
False
```

**Count the rows before and after every merge.** A left join on a key that is unique on the right
side keeps the row count exactly; any other number is a question to answer before going on.

What to do about `S07` depends on what the two rows mean. They are not a mistake to delete: they say
the name changed on a date. The next section joins each trip to the row that was true when it
happened.
