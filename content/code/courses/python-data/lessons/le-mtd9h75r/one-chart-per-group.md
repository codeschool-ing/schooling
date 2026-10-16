---
title: One chart per group, in one call
version: 1
---

**seaborn has two kinds of function: those that draw on one axes, and those that make a whole figure
of them.** `histplot`, `boxplot`, `scatterplot` and `barplot` draw on an axes, the one you pass or
the current one. `displot`, `catplot` and `relplot` build a new figure with **one axes per group**,
the small multiples of lesson 18, from a single argument.

The histogram of the first section, one panel per plan instead of two colours on one:

```python
g = sns.displot(data=trips, x="minutes", col="plan", binwidth=2, height=3, aspect=1.3)
g.set(xlim=(0, 80))
type(g).__name__, g.axes.shape
```

```
('FacetGrid', (1, 2))
```

`col="plan"` made one column of panels per value of `plan`, with the same vertical scale on both, the
`sharey` of lesson 18 by default. `height` is each panel's height in inches and `aspect` its width as a
multiple of that. What comes back is not an `Axes` but a **`FacetGrid`**, which holds the figure and
the array of axes, one per panel.

That difference is the usual surprise. A `FacetGrid` has no `set_title` or `set_xlim`; it has `set`,
which applies to every panel, and `set_titles`, which titles them from the group values. For anything
else, `g.axes` is the array of matplotlib axes, and `g.figure` the figure:

```python
g.set_titles("{col_name} plan")
g.set_axis_labels("minutes", "trips")
g.figure.suptitle("Trip lengths by plan", y=1.03)
g.savefig("lengths.png")
[ax.get_title() for ax in g.axes.flat]
```

```
['day plan', 'annual plan']
```

`{col_name}` is filled with each panel's value of `col`. `g.savefig` saves the whole grid, with
`bbox_inches="tight"` already applied, so the labels of lesson 18 are not cut off. `row=` adds a second
dimension of panels, `col="plan", row="bike"` making a grid of four, and `relplot` and `catplot` take
the same arguments for scatters and categories.

**Which to use is a question about the comparison.** Colours on one axes compare the groups at the
same place, which works for two or three groups that do not overlap much. Panels compare the shape of
each group on its own, which works for more groups, or groups that would hide each other on one axes.
