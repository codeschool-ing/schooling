---
title: Categories, and the bars that are means
version: 1
---

**`sns.barplot` does not draw counts. It draws the mean of a column for each category, with an error
bar, and the error bar comes from random resampling.** Both facts surprise people who expected the
chart they would have drawn by hand, and the second one changes the chart every time it runs.

The mean trip length per plan:

```python
fig, ax = plt.subplots(figsize=(6, 3.5), layout="constrained")
sns.barplot(data=trips, x="plan", y="minutes", ax=ax)
[round(bar.get_height(), 2) for bar in ax.patches]
```

```
[np.float64(22.64), np.float64(14.12)]
```

The bars are the means, 22.64 minutes for day passes and 14.12 for subscribers, in the order the
plans first appear in the table. The black line on each bar is a **95% confidence interval** for that
mean: a range built so that, if the trips were collected again and again, 95 such ranges in 100 would
contain the true mean.

seaborn estimates it by **bootstrapping**: it draws a thousand random samples from each group, with
replacement, takes the mean of each, and reports the range of the middle 95%. Random samples mean the
ends of the line move a little on every run:

```python
ends = []
for _ in range(2):
    fig, ax = plt.subplots()
    sns.barplot(data=trips, x="plan", y="minutes", ax=ax)
    ends.append([round(line.get_ydata()[0], 3) for line in ax.lines])
    plt.close(fig)
ends[0] == ends[1]
```

```
False
```

Two runs of the same code drew different error bars. The difference is small, a hundredth of a minute or
so, and it is exactly the kind of difference lesson 8 was about: a notebook that gives a
different picture each time it runs cannot be checked against itself. `seed=` fixes it:

```python
ends = []
for _ in range(2):
    fig, ax = plt.subplots()
    sns.barplot(data=trips, x="plan", y="minutes", seed=8, ax=ax)
    ends.append([round(line.get_ydata()[0], 3) for line in ax.lines])
    plt.close(fig)
ends[0] == ends[1], ends[0]
```

```
(True, [np.float64(22.419), np.float64(14.024)])
```

## When you meant counts

To draw how many trips each plan had, `countplot` counts the rows:

```python
fig, ax = plt.subplots(figsize=(6, 3.5), layout="constrained")
sns.countplot(data=trips, x="plan", ax=ax)
[int(bar.get_height()) for bar in ax.patches]
```

```
[9899, 23438]
```

9,899 and 23,438, the counts of lesson 13. **A bar chart answers "how many" or "how much on average",
and the two look the same**; the axis label is the only thing that tells a reader which, so set it.
And when the error bar is not part of the point, `errorbar=None` leaves it out rather than leaving a
reader to guess what it means.
