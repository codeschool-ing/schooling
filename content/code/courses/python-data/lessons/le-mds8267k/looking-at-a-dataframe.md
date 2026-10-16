---
title: Looking at a table before believing it
version: 1
---

**Three calls tell you most of what a new table is: `info`, `describe` and `value_counts`.** They
answer, in order: what is in it, what the numbers look like, and what the categories are. Run them
on every table you load, before any analysis.

```python
trips.info()
```

```
<class 'pandas.DataFrame'>
RangeIndex: 33337 entries, 0 to 33336
Data columns (total 8 columns):
 #   Column         Non-Null Count  Dtype
---  ------         --------------  -----
 0   trip_id        33337 non-null  int64
 1   started_at     33337 non-null  str  
 2   ended_at       33191 non-null  str  
 3   start_station  33337 non-null  str  
 4   end_station    33191 non-null  str  
 5   plan           33337 non-null  str  
 6   bike           33337 non-null  str  
 7   round_trip     33337 non-null  bool 
dtypes: bool(1), int64(1), str(6)
memory usage: 3.6 MB
```

`info` prints rather than returns, so its text is the output. It lists every column with its count
of **non-null** values and its dtype. Two columns have 33,191 values instead of 33,337: `ended_at`
and `end_station` are missing for 146 trips, the bikes lesson 1 said never came back. The count is
how you notice a column with holes without looking for them, and it is the first number to check
in any table.

```python
trips.describe()
```

```
            trip_id
count  33337.000000
mean   16669.000000
std     9623.707298
min        1.000000
25%     8335.000000
50%    16669.000000
75%    25003.000000
max    33337.000000
```

`describe` summarises the numeric columns: count, mean, spread and quartiles. Here there is only one
numeric column, `trip_id`, and its summary is meaningless: an id is a number that is not a quantity.
**`describe` is only as good as the dtypes**; with the times still text, the interesting numbers are
not there yet.

For text columns the question is which values occur, and how often:

```python
trips["plan"].value_counts(), trips["bike"].value_counts(normalize=True).round(3)
```

```
(plan
 annual    23438
 day        9899
 Name: count, dtype: int64,
 bike
 classic     0.65
 electric    0.35
 Name: proportion, dtype: float64)
```

`value_counts` counts each distinct value, most common first; `normalize=True` gives shares instead
of counts. Seven trips in ten were on an annual plan, and about one in three was on an electric bike.

```python
trips["start_station"].nunique(), trips["start_station"].value_counts().head(3)
```

```
(20,
 start_station
 S05    4154
 S03    2728
 S07    2636
 Name: count, dtype: int64)
```

Twenty stations, as `stations.csv` lists, and the three busiest. A station code here that
`stations.csv` did not know would be the first sign of a problem joining the two, which is lesson
14's subject.
