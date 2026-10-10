---
title: Every pair, on purpose
version: 1
---

**The silent `(n, 1)` against `(n,)` from two sections ago is a bug when it happens by accident and
one of the most useful tools in NumPy when it happens on purpose.** A column against a row gives
every combination of the two, without a loop and without writing the combinations down.

The docks at five stations, and the question "how many more docks does each station have than
each other station":

```python
docks = np.array([14, 20, 12, 17, 10])
difference = docks[:, np.newaxis] - docks
difference
```

```
array([[  0,  -6,   2,  -3,   4],
       [  6,   0,   8,   3,  10],
       [ -2,  -8,   0,  -5,   2],
       [  3,  -3,   5,   0,   7],
       [ -4, -10,  -2,  -7,   0]])
```

Row `i`, column `j` holds station `i`'s docks minus station `j`'s. The diagonal is zero, each station
against itself, and the table is antisymmetric: the entry for `(j, i)` is minus the entry for
`(i, j)`. Twenty-five numbers from two lines, and the shape tells you what it is: **`(5, 1)`
against `(5,)` is a 5 × 5 table of pairs.**

## A table of expected counts

Pairs are how a model of "what you would expect if two things were independent" is built. Suppose
trips through the day follow one shape, the share of each hour, and the days differ only in how many
trips they have. The expected count for every day and every hour is one product:

```python
hour_share = np.array([0.02, 0.10, 0.25, 0.30, 0.23, 0.10])
day_totals = np.array([96, 110, 71])
expected = day_totals[:, np.newaxis] * hour_share
expected.shape, expected.round(1)
```

```
((3, 6),
 array([[ 1.9,  9.6, 24. , 28.8, 22.1,  9.6],
        [ 2.2, 11. , 27.5, 33. , 25.3, 11. ],
        [ 1.4,  7.1, 17.8, 21.3, 16.3,  7.1]]))
```

Three days by six periods of the day, every row summing to its day's total. Lesson 15 builds the
real table of trips by day and hour with pandas, and comparing it against a table like this one is
how you find the hours that are busier than their share.

The shapes say which is the row and which is the column. Put `day_totals` second, unexpanded, and
the shapes `(6,)` and `(3,)` do not broadcast at all, which is the rule protecting you; give
`hour_share` the new axis instead, and you get the same numbers transposed, six by three. Decide
which way round you want the table before you write the line.
