---
title: `groupby`, which is `uniq -c` with arithmetic
version: 2
---

```python
df.groupby("country")["cents"].sum()
```

```sh
country
BR    23990.0
PT     9000.0
US    38000.0
```

**Split by a column, apply a function to each group, combine the results.** That is the whole
model, and it is the same one as `sort | uniq -c` from the terminal course with the counting
replaced by any arithmetic you like.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 268\" role=\"img\" aria-label=\"Grouping splits the rows by the value of a column, applies a function to each group, and combines the answers into one small table with one row per group.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"360\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">df.groupby(&quot;country&quot;)[&quot;cents&quot;].sum()</text> <text x=\"130\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">split</text> <text x=\"400\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">apply</text> <text x=\"620\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">combine</text> <rect x=\"20\" y=\"66\" width=\"74\" height=\"68\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"57\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">BR</text> <rect x=\"110\" y=\"66\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"185\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">12990</text> <rect x=\"110\" y=\"102\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"185\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">11000</text> <path d=\"M266 82 L320 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"326\" y=\"66\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"401\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sum()</text> <path d=\"M482 82 L536 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"542\" y=\"66\" width=\"158\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"621\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">BR  23990.0</text> <rect x=\"20\" y=\"154\" width=\"74\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"57\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">PT</text> <rect x=\"110\" y=\"154\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"185\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">9000</text> <path d=\"M266 170 L320 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"326\" y=\"154\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"401\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sum()</text> <path d=\"M482 170 L536 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"542\" y=\"154\" width=\"158\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"621\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PT  9000.0</text> <rect x=\"20\" y=\"206\" width=\"74\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"57\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">US</text> <rect x=\"110\" y=\"206\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"185\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">38000</text> <path d=\"M266 222 L320 222\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"326\" y=\"206\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"401\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sum()</text> <path d=\"M482 222 L536 222\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"542\" y=\"206\" width=\"158\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"621\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">US  38000.0</text> <text x=\"360\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">it is sort | uniq -c from the terminal course, with the counting replaced by arithmetic</text> </svg>", "caption": "Split by a column, apply a function to each group, combine the results. That is the whole model."}
```

## Several aggregations at once

```python
df.groupby("country").agg(
    orders=("id", "count"),
    total=("cents", "sum"),
    avg=("cents", "mean"),
)
```

```sh
         orders    total           avg
country
BR            4  23990.0   7996.666667
PT            2   9000.0   4500.000000
US            2  38000.0  19000.000000
```

The keyword form — `name=("column", "function")` — is the one to learn. It names the output
columns, which the older list form does not, and it reads like the table it produces.

## `count` counts what is present

`orders` above is `count` of `id`, which has no gaps. Had it been `count` of `cents`, BR would
say 3 rather than 4 — because one of its orders has no amount.

**That is a feature.** A `count` of the column you are summing tells you how much of each group
the sum is actually made of, and it is free.

## Grouping by more than one

```python
df.groupby(["country", "customer"])["cents"].sum()
```

The result has a two-level index. `.reset_index()` flattens it back into ordinary columns, which
is almost always what you want before writing it out or plotting it.

## `transform`, when the answer belongs beside each row

```python
df["country_total"] = df.groupby("country")["cents"].transform("sum")
```

`agg` gives you one row per group; `transform` gives you one row per **original row**, with the
group's answer repeated. That is how you compute "this order as a share of its country" without a
join.

## And the loop you are not writing

```python
totals = {}
for row in rows:
    totals.setdefault(row["country"], 0)
    totals[row["country"]] += row["cents"]
```

That is lesson 20's `defaultdict(int)`, and it is exactly right in plain Python. `groupby` is the
same idea when the data is already a table — and it gets you `count`, `mean`, `min`, `max` and
the rest without writing any of them.
