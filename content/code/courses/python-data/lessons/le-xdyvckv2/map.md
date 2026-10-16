---
title: map, a lookup per value
version: 1
---

**`Series.map` replaces each value with what a dictionary, or a Series used as one, says for it.** It is
the right tool for a lookup, a code turned into a name, and it has one behaviour worth knowing before
you rely on it: a value the dictionary does not mention becomes `NaN`, without a word.

Station codes to names, with one name per code:

```python
names = stations.drop_duplicates("station_id").set_index("station_id")["name"]
trips["start_station"].map(names).head(3)
```

```
0    Rua da Hora
1       Afogados
2        Setúbal
Name: start_station, dtype: str
```

A Series indexed by code is a dictionary pandas can search fast. The `drop_duplicates` keeps the
first row of `S07`, which is fine for a demonstration and wrong for a report of the second half of the
year, for the reason lesson 14 gave; when the lookup depends on time, it is a `merge_asof`, not a
`map`.

## The value nobody mapped

A dictionary that forgets a key:

```python
labels = {"annual": "subscriber"}
trips["plan"].map(labels).value_counts(dropna=False)
```

```
plan
subscriber    23438
NaN            9899
Name: count, dtype: int64
```

The day passes did not fail; they became `NaN`, and a `value_counts` without `dropna=False` would not
even show them. **After a `map`, count the `NaN`s it made**, because each one is a key your dictionary
did not cover or a value that was missing to begin with:

```python
trips["end_station"].map(names).isna().sum()
```

```
np.int64(146)
```

146, the lost bikes, whose end station was already missing. Here the gaps are expected; on another
column they would be a spelling the dictionary did not have, as lesson 14 found with `"s02"`.

`replace` is the other choice. It changes the values it knows and **leaves the rest as they were**:

```python
trips["plan"].replace(labels).value_counts()
```

```
plan
subscriber    23438
day            9899
Name: count, dtype: int64
```

Which is right depends on what an unknown value means. A translation of every category wants `map`,
so that a category you did not expect shows up as a gap; a correction of a few known misspellings
wants `replace`, so that everything else passes through.

## map with a function

`map` also takes a function, and then it is a loop: the function is called once per value, in
Python. For text, the `.str` methods do the same work in one call:

```python
loop = %timeit -o -q trips["start_station"].map(lambda s: s.lower())
vec = %timeit -o -q trips["start_station"].str.lower()
round(loop.average * 1000, 1), round(vec.average * 1000, 1)
```

```
(5.4, 0.3)
```

The gap is smaller than on rows, because each call is cheaper than building a row, and it is still
large. **A dictionary or a Series in `map` is a lookup; a function in `map` is a loop.**
