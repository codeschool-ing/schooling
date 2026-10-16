---
title: rolling, a window that slides along
version: 1
---

**`rolling(n)` computes a statistic over a window of the last `n` rows, at every row.** A rolling mean
of seven days replaces each day with the average of the week ending on it, which smooths the
weekly rhythm out and leaves the trend.

```python
week_mean = daily.rolling(7).mean()
week_mean.head(8).round(1)
```

```
started_at
2025-01-01     NaN
2025-01-02     NaN
2025-01-03     NaN
2025-01-04     NaN
2025-01-05     NaN
2025-01-06     NaN
2025-01-07    92.3
2025-01-08    91.4
Freq: D, dtype: float64
```

The first six days are `NaN`: a window of seven needs seven values, and on 6 January only six days
exist. From 7 January each value is the mean of that day and the six before it. **The window ends on
the row it is labelled with**, which is what "trailing" means, and what you want when the question is
"how have the last seven days been".

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Ten days in a row, 1 to 10 January. A trailing window of seven days covers 1 to 7 January and its mean is written on 7 January. A centred window covers the same seven days and its mean is written on 4 January, the middle, so three of its days lie after the day it is written on.\" data-fig=\"window\"><defs><marker id=\"window-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"44\" y=\"100\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"72.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1 Jan</text><rect x=\"108\" y=\"100\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"136.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2 Jan</text><rect x=\"172\" y=\"100\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"200.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3 Jan</text><rect x=\"236\" y=\"100\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"264.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4 Jan</text><rect x=\"300\" y=\"100\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"328.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5 Jan</text><rect x=\"364\" y=\"100\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"392.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6 Jan</text><rect x=\"428\" y=\"100\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"456.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7 Jan</text><rect x=\"492\" y=\"100\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"520.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">8 Jan</text><rect x=\"556\" y=\"100\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"584.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">9 Jan</text><rect x=\"620\" y=\"100\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"648.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10 Jan</text><path d=\"M44 94 L44 84 L484 84 L484 94\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><text x=\"264.0\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rolling(7)</text><line x1=\"456.0\" y1=\"46\" x2=\"456.0\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#window-ah)\"></line><text x=\"456.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">written on the 7th</text><path d=\"M44 146 L44 156 L484 156 L484 146\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><text x=\"379.2\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rolling(7, center=True)</text><line x1=\"264.0\" y1=\"200\" x2=\"264.0\" y2=\"144\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#window-ah)\"></line><text x=\"264.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">written on the 4th: the 5th, 6th and 7th are its future</text></svg>", "caption": "The same seven days, written on the last of them or on the middle one."}
```

`min_periods` lets a window with fewer values give an answer:

```python
daily.rolling(7, min_periods=1).mean().head(3).round(1)
```

```
started_at
2025-01-01    106.0
2025-01-02    107.0
2025-01-03    109.7
Freq: D, dtype: float64
```

The first value is the mean of one day, the second of two. It fills the start of the series, and it
also means the first values are noisier than the rest while looking the same. Use it when a short
window is still an honest answer, and say so on any chart that shows it.

## Centred, and the future

`center=True` puts the window around the row instead of before it:

```python
daily.rolling(7, center=True).mean().head(5).round(1)
```

```
started_at
2025-01-01     NaN
2025-01-02     NaN
2025-01-03     NaN
2025-01-04    92.3
2025-01-05    91.4
Freq: D, dtype: float64
```

4 January now carries the mean of 1 to 7 January, three days of which are in its future. **A centred
window looks ahead.** That is fine for describing a year that is over, where the curve lines up with
the days it describes. It is wrong for anything that will be used on a day when the future is not yet
known, a forecast or an alert, because the number used in testing contains information the real day
will not have.

## What the smoothing shows

The quietest single day was 17 May, with 28 trips. The quietest week is something else:

```python
week_mean.idxmin(), round(week_mean.min(), 1)
```

```
(Timestamp('2025-06-22 00:00:00'), np.float64(69.4))
```

The week ending 22 June averaged 69.4 trips a day. A single wet Saturday makes a low day; a low week
says something lasted. Any aggregation `groupby` knows works in a window too, `sum`, `median`,
`max`, `std`, and `rolling(7).sum()` is the weekly total on every day.
