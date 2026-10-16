---
title: melt, from wide back to long
version: 1
---

**`melt` turns columns into rows: each value of a wide table becomes a row of its own, with a
column saying which column it came from.** It is the opposite of `pivot`, and it is what you reach
for when a table arrives wide and the next step wants it long.

`wide` from the first section, melted back:

```python
back = wide.reset_index().melt(id_vars="month", var_name="plan", value_name="trips")
back.head(3)
```

```
   month    plan  trips
0      1  annual   2016
1      2  annual   1902
2      3  annual   1983
```

```python
back.shape
```

```
(24, 3)
```

`id_vars` names the columns that stay as they are and are repeated on every row; every other column
is melted. `var_name` and `value_name` name the two new columns; without them they are called
`variable` and `value`, which says nothing. `reset_index` came first because `melt` works on columns,
and in `wide` the month was the index.

The rows come out grouped by the old column, all the annual months and then all the day months,
where `long` had them by month. The content is the same; sort if the order matters.

## Measurements kept side by side

Many files arrive wide because people type them that way. `weather.csv` has one row per day and one
column per measurement:

```python
weather = pd.read_csv("weather.csv")
weather["date"] = pd.to_datetime(weather["date"], format="%Y-%m-%d")
measured = weather.melt(id_vars="date", var_name="measure", value_name="value")
measured.shape, measured["measure"].unique().tolist()
```

```
((730, 3), ['rain_mm', 'temp_max'])
```

Two measurements of 365 days are 730 rows. That shape looks worse to a person and is exactly what
lesson 19's seaborn wants for "one line per measure": the measure is a column, so it can be the
colour of a line, where in the wide shape it was part of the column names, out of reach.

**Melting mixes units.** Rain in millimetres and temperature in degrees now share the column
`value`, and a `mean` of that column would be a number about nothing. Long is the right shape for
grouping and drawing by `measure`; it is the wrong shape for arithmetic across measures, which is
what wide is for.
