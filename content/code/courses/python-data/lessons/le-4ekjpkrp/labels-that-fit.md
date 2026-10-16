---
title: Labels that fit
version: 1
---

**matplotlib lays out a figure for short labels, and a long one is cut off at the edge of the
picture.** Nothing warns you: the chart looks finished in the notebook, and the file you send is
missing the start of every name.

Trips by start station, with the stations' names. Each code gets its **current** name, the last row
for each code in `stations.csv`, because the chart is about the station and lesson 14 already showed
how to name each trip by the name of its day:

```python
current = stations.drop_duplicates("station_id", keep="last").set_index("station_id")["name"]
per_station = trips["start_station"].map(current).value_counts().sort_values()
per_station.tail(3)
```

```
start_station
Espinheiro        2636
Rua da Aurora     2728
Praça do Derby    4154
Name: count, dtype: int64
```

Horizontal bars suit long names, because the names are read along a line rather than tilted under a
bar:

```python
fig, ax = plt.subplots(figsize=(6, 6))
ax.barh(per_station.index, per_station.to_numpy())
ax.set_title("Trips by start station, 2025")
fig.savefig("stations.png")
```

Open `stations.png` from JupyterLab's file browser, and the names on the left read `do Derby`,
`da Aurora`, `ruzilhada`: the figure is six inches wide, the axes take a fixed share of it, and the
names that do not fit in the margin left of the axes are drawn outside the picture. The figure can say
so itself. `get_tightbbox` measures everything that was drawn, in inches from the figure's lower
left corner:

```python
box = fig.get_tightbbox()
round(box.x0, 2), round(box.x1, 2)
```

```
(np.float64(-0.87), np.float64(5.4))
```

The drawing starts left of zero, outside the six inches the file holds. Under the cell the names
looked whole, because the notebook shows each chart saved with `bbox_inches="tight"`, its default
for charts in a cell, and that default is exactly what hides the problem until the file is opened
somewhere else.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two versions of the station chart. Left: the saved file, whose edge cuts the long names, so they read do Derby, da Aurora and spinheiro. Right: the same chart with layout constrained, the axes moved right inside the figure and every name whole.\" data-fig=\"clipped\"><rect x=\"20\" y=\"40\" width=\"320\" height=\"190\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">stations.png, as saved</text><line x1=\"82\" y1=\"60\" x2=\"82\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><rect x=\"82\" y=\"70\" width=\"238.0\" height=\"24\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"78\" y=\"82\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">do Derby</text><rect x=\"82\" y=\"106\" width=\"156.29850746268656\" height=\"24\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"78\" y=\"118\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">da Aurora</text><rect x=\"82\" y=\"142\" width=\"151.02744342802117\" height=\"24\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"78\" y=\"154\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">spinheiro</text><rect x=\"82\" y=\"178\" width=\"148.79297063071738\" height=\"24\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"78\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Madalena</text><rect x=\"380\" y=\"40\" width=\"320\" height=\"190\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">layout=&quot;constrained&quot;</text><line x1=\"520\" y1=\"60\" x2=\"520\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><rect x=\"520\" y=\"70\" width=\"160.0\" height=\"24\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"516\" y=\"82\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Praça do Derby</text><rect x=\"520\" y=\"106\" width=\"105.07462686567165\" height=\"24\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"516\" y=\"118\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Rua da Aurora</text><rect x=\"520\" y=\"142\" width=\"101.53105440539238\" height=\"24\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"516\" y=\"154\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Espinheiro</text><rect x=\"520\" y=\"178\" width=\"100.02888781896968\" height=\"24\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"516\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Madalena</text><text x=\"30\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the names begin outside the picture</text></svg>", "caption": "The four busiest stations of the chart, as the file was saved and as it should be."}
```

## Two fixes

`bbox_inches="tight"` when saving measures what was drawn and grows the saved picture to hold it:

```python
fig.savefig("stations.png", bbox_inches="tight")
```

The other fix is at the start: `layout="constrained"` asks matplotlib to fit the axes inside the
figure **around** its labels, so the figure is right on screen and in every file:

```python
fig, ax = plt.subplots(figsize=(6, 6), layout="constrained")
ax.barh(per_station.index, per_station.to_numpy())
ax.set_title("Trips by start station, 2025")
fig.savefig("stations.png")
```

The second is the better habit. A chart laid out properly does not depend on how it is saved, and
`constrained` also stops the titles of several axes in one figure from running into each other, which
the next section needs. **Open the file you saved**, not only the notebook, before sending it.

The chart makes one point at a glance: `Praça do Derby`, `S05`, is far ahead of every other station,
and the next three are close together. Sorting by value, `sort_values()` above, is what makes that
visible; in alphabetical order the same bars would be a list to search.
