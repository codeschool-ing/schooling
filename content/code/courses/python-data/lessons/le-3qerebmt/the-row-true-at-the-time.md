---
title: The row that was true at the time
version: 1
---

**`pd.merge_asof` pairs each row with the latest row on the other side whose key is not after it.**
It is a join on time: each trip gets the station row whose `valid_from` is the last one on or before
the trip's start. That is what `stations.csv` means, so it is the join that answers its question.

The quick fixes are worth naming first, because both are tempting and both are wrong.
`stations.drop_duplicates("station_id", keep="last")` keeps `Espinheiro` and gives it to the trips
of January, when the station had another name. `keep="first"` does the opposite to the trips of
December. Either one restores the row count and quietly changes the history.

`merge_asof` needs both tables sorted by the time key, and the key to be a datetime on both sides:

```python
history = stations.assign(valid_from=pd.to_datetime(stations["valid_from"], format="%Y-%m-%d"))
named = pd.merge_asof(
    trips.sort_values("started_at"),
    history.sort_values("valid_from"),
    left_on="started_at", right_on="valid_from",
    left_by="start_station", right_by="station_id",
)
len(named)
```

```
33337
```

As many rows as trips. `left_on` and `right_on` are the times compared; `left_by` and `right_by` say
that only rows of the **same station** may be paired, so a trip from `S03` never picks up a renamed
`S07`. Within a station, each trip takes the last row whose `valid_from` is on or before its start.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A timeline of 2025 for station S07. One station row starts on 1 January with the name Rua da Hora, another on 1 July with the name Espinheiro. A trip in March looks back to the January row; a trip in September looks back to the July row.\" data-fig=\"asof\"><defs><marker id=\"asof-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"60\" y1=\"120\" x2=\"680\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"60.0\" y1=\"114\" x2=\"60.0\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"66.0\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Jan</text><line x1=\"215.0\" y1=\"114\" x2=\"215.0\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"221.0\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Apr</text><line x1=\"370.0\" y1=\"114\" x2=\"370.0\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"376.0\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Jul</text><line x1=\"525.0\" y1=\"114\" x2=\"525.0\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"531.0\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Oct</text><rect x=\"50.0\" y=\"40\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"135.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Rua da Hora</text><text x=\"135.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">valid_from 2025-01-01</text><rect x=\"360.0\" y=\"40\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"445.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Espinheiro</text><text x=\"445.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">valid_from 2025-07-01</text><line x1=\"60.0\" y1=\"84\" x2=\"60.0\" y2=\"116\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"370.0\" y1=\"84\" x2=\"370.0\" y2=\"116\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><rect x=\"183.16666666666666\" y=\"164\" width=\"12\" height=\"12\" rx=\"6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"189.16666666666666\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">trip in March</text><path d=\"M181.16666666666666 170 Q124.58333333333333 205 64.0 128\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#asof-ah)\"></path><rect x=\"493.1666666666667\" y=\"164\" width=\"12\" height=\"12\" rx=\"6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"499.1666666666667\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">trip in September</text><path d=\"M491.1666666666667 170 Q434.58333333333337 205 374.0 128\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#asof-ah)\"></path></svg>", "caption": "Each trip takes the last station row whose valid_from is on or before its start."}
```

The trips from `S07` now carry the name of their day:

```python
s07 = named[named["start_station"] == "S07"]
s07.groupby(s07["started_at"].dt.month)["name"].first().loc[[5, 6, 7, 8]]
```

```
started_at
5    Rua da Hora
6    Rua da Hora
7     Espinheiro
8     Espinheiro
Name: name, dtype: str
```

```python
s07["name"].value_counts()
```

```
name
Espinheiro     1374
Rua da Hora    1262
Name: count, dtype: int64
```

June is the last month of `Rua da Hora` and July the first of `Espinheiro`, and the two counts add
up to the 2,636 trips that the plain merge doubled.

One thing `merge_asof` does not keep is the original order: it returns the trips sorted by
`started_at`, which is not quite the order of `trips.csv`. Sort back by the key you care about,
`named.sort_values("trip_id")`, before comparing it row by row with anything else.
