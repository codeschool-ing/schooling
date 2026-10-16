---
title: Copy-on-Write, pandas 3's answer
version: 1
---

**In pandas 3, every selection behaves as a copy of what it selected, and changing it never changes
the table it came from.** The library calls this Copy-on-Write: the copy is not actually made until
one side is written to, so selecting stays cheap, but the result is the same as if it had been.

Take the day-pass trips as a table of their own and add a column to it:

```python
day = trips[trips["plan"] == "day"]
day["note"] = "day pass"
"note" in day.columns, "note" in trips.columns
```

```
(True, False)
```

`day` has the new column and `trips` does not. That is what almost everybody expects, and pandas 3
does it without a warning. Changing a value in a selected Series is the same:

```python
plan = trips["plan"]
plan.iloc[0] = "changed"
plan.iloc[0], trips.loc[0, "plan"]
```

```
('changed', 'day')
```

`plan` changed; the table did not. The Series is no longer a window onto the table's column.

## Chained assignment never works

The one pattern that breaks is two selections in a row with an assignment at the end, the pandas
version of lesson 7's vanishing write:

```python
trips["bike"][trips["bike"] == "electric"] = "e-bike"
(trips["bike"] == "e-bike").sum()
```

```
/tmp/ipykernel_2374/3907501872.py:1: ChainedAssignmentError: A value is being set on a copy of a DataFrame or Series through chained assignment.
Such chained assignment never works to update the original DataFrame or Series, because the intermediate object on which we are setting values always behaves as a copy (due to Copy-on-Write).

Try using '.loc[row_indexer, col_indexer] = value' instead, to perform the assignment in a single step.

See the documentation for a more detailed explanation: https://pandas.pydata.org/pandas-docs/stable/user_guide/copy_on_write.html#chained-assignment
  trips["bike"][trips["bike"] == "electric"] = "e-bike"
np.int64(0)
```

`trips["bike"]` is selected first, as its own object; the mask and the assignment then act on that
object, which is thrown away. **Nothing in `trips` changed, and pandas 3 says so**, with a
`ChainedAssignmentError` warning that names the line and the fix.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Top: trips[&quot;bike&quot;][mask] = &quot;e-bike&quot;. The first brackets make a separate object from the bike column; the assignment lands in that object, which is thrown away, and trips is unchanged. Bottom: trips.loc[mask, &quot;bike&quot;] = &quot;e-bike&quot;. One step, and the assignment lands in trips.\" data-fig=\"chained\"><defs><marker id=\"chained-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">trips[&quot;bike&quot;][mask] = &quot;e-bike&quot;</text><rect x=\"20\" y=\"40\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">trips</text><text x=\"95.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">unchanged</text><rect x=\"285\" y=\"40\" width=\"170\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"370.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">trips[&quot;bike&quot;]</text><text x=\"370.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a separate object</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">= &quot;e-bike&quot;</text><text x=\"630.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lands here, then lost</text><line x1=\"174\" y1=\"70\" x2=\"281\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#chained-ah)\"></line><line x1=\"459\" y1=\"70\" x2=\"556\" y2=\"70\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#chained-ah)\"></line><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">trips.loc[mask, &quot;bike&quot;] = &quot;e-bike&quot;</text><rect x=\"20\" y=\"158\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">trips</text><text x=\"95.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">changed in place</text><rect x=\"285\" y=\"158\" width=\"170\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"370.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">one step</text><text x=\"370.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rows and column together</text><line x1=\"281\" y1=\"188\" x2=\"174\" y2=\"188\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#chained-ah)\"></line></svg>", "caption": "Two selections then an assignment write into the middle object. One loc writes into the table."}
```

The fix is the one-step form:

```python
trips.loc[trips["bike"] == "electric", "bike"] = "e-bike"
(trips["bike"] == "e-bike").sum()
```

```
np.int64(11655)
```

## What this replaced

Before pandas 3, whether a selection was a view or a copy depended on how it was made, much as in
NumPy, and the rules were too intricate to remember. Writing to a selection sometimes changed the
original and sometimes did not, and pandas could not always tell which, so it warned whenever it
might be either: the `SettingWithCopyWarning`. The next section shows that warning and that
behaviour, because the code you will read was written for it.
