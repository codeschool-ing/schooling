---
title: Boolean masks, which select by condition
version: 1
---

**A boolean mask is an array of `True` and `False` the same shape as the data, and indexing with it
keeps the elements where it is `True`.** It is how NumPy says "where": the days with heavy rain,
the hot Sundays, the readings that are not missing. Lesson 5 built masks and counted them; here they
select.

```python
heavy = rain > 20
heavy.shape, heavy.sum(), rain[heavy]
```

```
((365,),
 np.int64(20),
 array([25.2, 25. , 45.9, 28.3, 28.9, 29. , 20.8, 37.4, 25.4, 30.8, 29.4,
        41. , 21. , 41.4, 21.7, 23.9, 29.3, 21. , 40.9, 28.6]))
```

`rain[heavy]` is a new, one-dimensional array of the 20 values where the mask is `True`, in their
original order.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Top row: the first eight rain readings, 0.0, 6.8, 7.9, 15.7, 0.0, 0.0, 1.3, 0.0. Middle row: the mask rain &gt; 5, True under 6.8, 7.9 and 15.7 and False elsewhere. Bottom: indexing with the mask gives a new, shorter array, 6.8, 7.9, 15.7, which is a copy.\" data-fig=\"masking\"><defs><marker id=\"masking-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rain[:8]</text><text x=\"20\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rain[:8] &gt; 5</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rain[:8][mask]</text><rect x=\"150\" y=\"24\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"179.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0.0</text><rect x=\"150\" y=\"74\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"179.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">False</text><rect x=\"214\" y=\"24\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"243.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6.8</text><rect x=\"214\" y=\"74\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"243.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">True</text><rect x=\"278\" y=\"24\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"307.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7.9</text><rect x=\"278\" y=\"74\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"307.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">True</text><rect x=\"342\" y=\"24\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"371.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">15.7</text><rect x=\"342\" y=\"74\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"371.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">True</text><rect x=\"406\" y=\"24\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"435.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0.0</text><rect x=\"406\" y=\"74\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"435.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">False</text><rect x=\"470\" y=\"24\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"499.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0.0</text><rect x=\"470\" y=\"74\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"499.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">False</text><rect x=\"534\" y=\"24\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"563.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1.3</text><rect x=\"534\" y=\"74\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"563.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">False</text><rect x=\"598\" y=\"24\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"627.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0.0</text><rect x=\"598\" y=\"74\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"627.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">False</text><rect x=\"150\" y=\"174\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"179.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6.8</text><line x1=\"243.0\" y1=\"110\" x2=\"179.0\" y2=\"170\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#masking-ah)\"></line><rect x=\"214\" y=\"174\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"243.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7.9</text><line x1=\"307.0\" y1=\"110\" x2=\"243.0\" y2=\"170\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#masking-ah)\"></line><rect x=\"278\" y=\"174\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"307.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">15.7</text><line x1=\"371.0\" y1=\"110\" x2=\"307.0\" y2=\"170\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#masking-ah)\"></line><text x=\"352\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a new array, three long: a copy</text></svg>", "caption": "A mask keeps the elements under True, in order, in a new array."}
```

The same mask, applied to another array of the same length, selects the matching
elements of that one, **which is how two arrays are kept in step**:

```python
dates[heavy][:5], temp[heavy].mean().round(2), temp[~heavy].mean().round(2)
```

```
(array(['2025-01-09', '2025-03-20', '2025-03-22', '2025-04-15',
        '2025-04-17'], dtype='<U10'),
 np.float64(29.49),
 np.float64(29.97))
```

The dates of the first five heavy-rain days, and the mean temperature on heavy-rain days against the
rest. `~` inverts a mask, so `temp[~heavy]` is every day that was not heavy rain, which here includes
the six days with no reading, because `nan > 20` is `False`.

## A mask keeps no shape

On a table, a mask of the same shape selects elements, and the result is flat, because the selected
elements do not form rows any more:

```python
hot = weeks > 31.5
weeks[hot].shape, weeks[hot][:4]
```

```
((18,), array([31.7, 32.1, 31.6, 31.9]))
```

To keep whole rows, mask one axis with a mask of that axis's length. The weeks in which at least one
day was above 31.5:

```python
any_hot = hot.any(axis=1)
any_hot.shape, weeks[any_hot].shape
```

```
((52,), (16, 7))
```

`any(axis=1)` asks each row whether any of its elements is `True`; `all(axis=1)` would ask whether
all are. The resulting `(52,)` mask selects rows, and the rows keep their seven days.

## The missing values, selected out

The one mask you will write in nearly every notebook:

```python
known = ~np.isnan(rain)
known.sum(), rain[known].mean().round(3), np.nanmean(rain).round(3)
```

```
(np.int64(359), np.float64(4.771), np.float64(4.771))
```

The mean of the known values, two ways. `rain[known]` is explicit about what was dropped and lets
you count it; `np.nanmean` does the same thing quietly. When you report the number, the explicit
version is the one that reminds you to say "of 359 days".
