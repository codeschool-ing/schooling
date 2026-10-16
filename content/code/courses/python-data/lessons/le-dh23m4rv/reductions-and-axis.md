---
title: Reductions, and the axis they run along
version: 1
---

**A reduction turns many values into one: `sum`, `mean`, `min`, `max`, `std`.** On a table, the
question is always *one value per what*, and the `axis` argument answers it.

Take the first 364 days of temperature, exactly 52 weeks, and lay them out one week per row:

```python
weeks = temp[:364].reshape(52, 7)
weeks.shape, weeks.mean()
```

```
((52, 7), np.float64(29.93324175824176))
```

With no `axis`, the reduction runs over every element: one number, the mean of 364 days. With an
axis, it runs **along** that axis and removes it from the shape:

```python
weekly = weeks.mean(axis=1)
by_position = weeks.mean(axis=0)
weekly.shape, weekly[:3].round(2), by_position.round(2)
```

```
((52,),
 array([30.37, 30.61, 30.53]),
 array([30.02, 29.85, 29.96, 29.91, 30.1 , 29.82, 29.87]))
```

`axis=1` runs along each row, across its seven days, and leaves one mean per week: 52 of them.
`axis=0` runs down each column, across the 52 weeks, and leaves one mean per position in the week:
7 of them. The rule that never fails: **the axis you name is the one that disappears.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A table of 52 weeks by 7 days. mean with axis=1 runs along each row and leaves 52 weekly means, one per row. mean with axis=0 runs down each column and leaves 7 means, one per day position. The axis that is named is the one that disappears.\" data-fig=\"axis\"><defs><marker id=\"axis-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"40\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">weeks, shape (52, 7)</text><rect x=\"40\" y=\"40\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"74\" y=\"40\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"108\" y=\"40\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"142\" y=\"40\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"176\" y=\"40\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"40\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"244\" y=\"40\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"40\" y=\"64\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"74\" y=\"64\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"108\" y=\"64\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"142\" y=\"64\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"176\" y=\"64\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"64\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"244\" y=\"64\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"40\" y=\"88\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"74\" y=\"88\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"108\" y=\"88\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"142\" y=\"88\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"176\" y=\"88\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"88\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"244\" y=\"88\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"40\" y=\"112\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"74\" y=\"112\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"108\" y=\"112\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"142\" y=\"112\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"176\" y=\"112\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"112\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"244\" y=\"112\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"40\" y=\"136\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"74\" y=\"136\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"108\" y=\"136\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"142\" y=\"136\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"176\" y=\"136\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"136\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"244\" y=\"136\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"159.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">⋮</text><line x1=\"44\" y1=\"52\" x2=\"274\" y2=\"52\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#axis-ah)\"></line><line x1=\"57\" y1=\"44\" x2=\"57\" y2=\"156\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#axis-ah)\"></line><rect x=\"330\" y=\"30\" width=\"340\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">weeks.mean(axis=1)</text><text x=\"500.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">along each row: 52 values, shape (52,)</text><rect x=\"330\" y=\"140\" width=\"340\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">weeks.mean(axis=0)</text><text x=\"500.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">down each column: 7 values, shape (7,)</text><line x1=\"286\" y1=\"52\" x2=\"326\" y2=\"65\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#axis-ah)\"></line><line x1=\"57\" y1=\"162\" x2=\"326\" y2=\"175\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#axis-ah)\"></line></svg>", "caption": "The axis you name is the one that disappears: (52, 7) becomes (52,) or (7,)."}
```

2025 began on a Wednesday, so position 0 is every Wednesday and position 4 every Sunday. The
seven means are within a few tenths of each other, which is what you expect of weather, since it
does not know what day it is; trips, in lesson 13, will not be so even.

## Missing values in a reduction

The rain column has six `nan`, and a reduction meets all of them:

```python
rain.sum(), np.nansum(rain), np.nanmean(rain), np.nanmax(rain)
```

```
(np.float64(nan),
 np.float64(1712.8),
 np.float64(4.771030640668523),
 np.float64(45.9))
```

`rain.sum()` is `nan`: one unknown day makes the year's total unknown, which is the honest answer
and a useless one. The `nan`-prefixed versions **ignore** the missing values and reduce what is
left. That is a decision, not a fix. The year's total from `nansum` is the total of 359 known days,
and if the six missing ones were rainy, it is too low. Say so wherever you report it.

| plain | ignores `nan` |
|---|---|
| `sum`, `mean`, `max`, `min`, `std` | `np.nansum`, `np.nanmean`, `np.nanmax`, `np.nanmin`, `np.nanstd` |

pandas, from lesson 9, skips missing values in its reductions by default, which is the second
choice made for you; lesson 12 says how to make it the first.
