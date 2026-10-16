---
title: pivot_table, a groupby laid out as a grid
version: 1
---

**`pivot_table` groups by two keys, aggregates, and lays the answer out with one key down the side
and the other across the top.** It is `groupby(...).agg(...).unstack()` in one call, with arguments
for the things a report needs: what to do with empty cells, and totals.

Trips by weekday and hour of the day:

```python
grid = trips.pivot_table(index="weekday", columns="hour", values="trip_id",
                         aggfunc="count", fill_value=0)
grid.shape
```

```
(7, 24)
```

Seven rows, twenty-four columns: every hour of every weekday. `aggfunc="count"` counts the non-missing
`trip_id`s in each cell, which is the number of trips, and `fill_value=0` writes 0 in any cell no
trip reached rather than `NaN`. A few hours, in the order of the week:

```python
grid.loc[order, [7, 8, 12, 17, 18]]
```

```
hour        7    8    12   17   18
weekday                           
Monday     606  426  268  566  419
Tuesday    623  422  260  521  444
Wednesday  634  423  262  591  389
Thursday   601  477  252  565  385
Friday     597  440  258  585  389
Saturday   143  205  227  183  181
Sunday     192  210  251  196  200
```

The week has two shapes. From Monday to Friday the busiest hours are 7 and 17, going to work and
coming back; on Saturday and Sunday the morning peak is gone and the hours are flat. `idxmax` names
the busiest hour of each row:

```python
grid.loc[order].idxmax(axis=1)
```

```
weekday
Monday        7
Tuesday       7
Wednesday     7
Thursday      7
Friday        7
Saturday     16
Sunday        9
dtype: int32
```

## Any aggregation, and the totals

`aggfunc` takes the names `groupby` takes. The median trip by plan and bike, with `margins=True`
adding a row and a column of totals:

```python
trips.pivot_table(index="plan", columns="bike", values="minutes",
                  aggfunc="median", margins=True).round(1)
```

```
bike    classic  electric   All
plan                           
annual     13.4      10.8  12.4
day        21.4      17.2  19.9
All        15.3      12.3  14.2
```

Electric bikes make shorter trips on both plans, and day passes longer ones on both bikes. **The
`All` row and column are the median of all the trips in that row or column, not the median of the
cells**: 14.2 is the median of every trip, where the median of the four cells is 15.3. For a sum
the two agree; for a median, or a mean of groups of unequal size, they do not, and reading `All` as a
summary of the cells is a mistake worth not making.
