---
title: query, a condition written as text
version: 1
---

**`DataFrame.query` takes a condition as a string and returns the matching rows.** It says the same
thing as a `loc` with a mask, in fewer brackets, and with column names written bare:

```python
trips.query("plan == 'day' and bike == 'e-bike' and start_station == end_station").shape
```

```
(223, 9)
```

Inside the string, `and`, `or` and `not` work, because `query` parses the text itself rather than
handing it to Python, so lesson 7's error about `and` on arrays does not happen. The same selection
with `loc`:

```python
mask = (trips["plan"] == "day") & (trips["bike"] == "e-bike") & (trips["start_station"] == trips["end_station"])
trips.loc[mask].shape
```

```
(223, 9)
```

A variable from the notebook goes in with `@`:

```python
station = "S07"
trips.query("start_station == @station").shape
```

```
(2636, 9)
```

Which to use is a matter of reading: `query` is shorter for a condition of several parts, and `loc`
is the one that also chooses columns and assigns. Two limits are worth knowing: a column name with a
space needs backticks inside the string, and a typo in a column name fails only when the line runs,
as with `loc`.
