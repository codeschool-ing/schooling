---
title: Smaller types for the same values
version: 1
---

**The right type for a column is usually also the smallest one.** Lesson 12 chose types for
correctness: a datetime that can be subtracted, a category with known values. The same choices cost
less memory, and a third one, a smaller integer, costs nothing but a check.

The same table, with every column given the type it should have had:

```python
fmt = "%Y-%m-%d %H:%M:%S"
typed = trips.assign(
    started_at=pd.to_datetime(trips["started_at"], format=fmt),
    ended_at=pd.to_datetime(trips["ended_at"], format=fmt),
    start_station=trips["start_station"].astype("category"),
    end_station=trips["end_station"].astype("category"),
    plan=trips["plan"].astype("category"),
    bike=trips["bike"].astype("category"),
    trip_id=pd.to_numeric(trips["trip_id"], downcast="integer"),
)
typed.memory_usage(deep=True)
```

```
Index               132
trip_id          133348
started_at       266696
ended_at         266696
start_station     33560
end_station       33560
plan              33363
bike              33369
dtype: int64
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Memory per column, in kilobytes, before and after choosing types. The two time columns fall from about 900 to 266, the four text columns of codes and words from 366 to 512 down to about 33 each as categories, and trip_id from 266 to 133 as int32.\" data-fig=\"memory\"><text x=\"550\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">as read</text><rect x=\"530\" y=\"16\" width=\"12\" height=\"12\" rx=\"0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"550\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">typed</text><rect x=\"530\" y=\"36\" width=\"12\" height=\"12\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"140\" y=\"76\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">trip_id</text><rect x=\"150\" y=\"64\" width=\"145.9809684210526\" height=\"12\" rx=\"0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"301.9809684210526\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">266</text><rect x=\"150\" y=\"78\" width=\"72.9904842105263\" height=\"12\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"228.9904842105263\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">133</text><text x=\"140\" y=\"112\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">started_at</text><rect x=\"150\" y=\"100\" width=\"492.6857684210526\" height=\"12\" rx=\"0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"648.6857684210527\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">900</text><rect x=\"150\" y=\"114\" width=\"145.9809684210526\" height=\"12\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"301.9809684210526\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">266</text><text x=\"140\" y=\"148\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ended_at</text><rect x=\"150\" y=\"136\" width=\"493.4488\" height=\"12\" rx=\"0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"649.4488\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">901</text><rect x=\"150\" y=\"150\" width=\"145.9809684210526\" height=\"12\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"301.9809684210526\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">266</text><text x=\"140\" y=\"184\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">start_station</text><rect x=\"150\" y=\"172\" width=\"200.72383157894737\" height=\"12\" rx=\"0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"356.7238315789474\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">366</text><rect x=\"150\" y=\"186\" width=\"18.369684210526316\" height=\"12\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"174.36968421052632\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">33</text><text x=\"140\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">end_station</text><rect x=\"150\" y=\"208\" width=\"202.76551578947368\" height=\"12\" rx=\"0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"358.7655157894737\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">370</text><rect x=\"150\" y=\"222\" width=\"18.369684210526316\" height=\"12\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"174.36968421052632\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">33</text><text x=\"140\" y=\"256\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">plan</text><rect x=\"150\" y=\"244\" width=\"239.2114947368421\" height=\"12\" rx=\"0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"395.2114947368421\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">437</text><rect x=\"150\" y=\"258\" width=\"18.26185263157895\" height=\"12\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"174.26185263157896\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">33</text><text x=\"140\" y=\"292\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">bike</text><rect x=\"150\" y=\"280\" width=\"280.0938947368421\" height=\"12\" rx=\"0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"436.0938947368421\" y=\"286\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">511</text><rect x=\"150\" y=\"294\" width=\"18.265136842105264\" height=\"12\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"174.26513684210528\" y=\"300\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">33</text><line x1=\"150\" y1=\"56\" x2=\"150\" y2=\"318\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"410.0\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">kilobytes</text></svg>", "caption": "The same values in each row; only the types changed."}
```

Each change, and why it is smaller:

| column | was | now | why |
|---|---|---|---|
| `started_at`, `ended_at` | text, about 27 bytes a row | `datetime64`, 8 | a moment is one number, not nineteen characters |
| stations, `plan`, `bike` | text | `category`, 1 byte a row | a small code per row and each word stored once |
| `trip_id` | `int64`, 8 bytes | `int32`, 4 | `downcast` picks the smallest integer that holds every value |

The whole table:

```python
round(typed.memory_usage(deep=True).sum() / trips.memory_usage(deep=True).sum(), 2)
```

```
np.float64(0.21)
```

About a fifth of the memory, with the same information in it and better types besides. A
category earns its place when a column has **few distinct values repeated many times**: twenty
stations over 33,337 rows. A column where nearly every value is different, like a name or an address,
is cheaper as text, because a category would store every value once and a code beside it.

**Downcasting has one trap.** `int32` holds numbers up to about 2.1 billion. A trip id that will grow
past that, or a column that later gets added to, overflows silently in NumPy arithmetic, as lesson 4
showed with `int8`. Downcast columns you only read, like an id, and leave the ones you compute with at
the default.

These types can be asked for at reading time, so the large version is never built:

```python
small = pd.read_csv(
    "trips.csv",
    dtype={"start_station": "category", "end_station": "category", "plan": "category", "bike": "category"},
    parse_dates=["started_at", "ended_at"], date_format=fmt,
)
small.memory_usage(deep=True).sum()
```

```
np.int64(935400)
```

On a file that does not fit in memory as text, that is the difference between reading it and not.
