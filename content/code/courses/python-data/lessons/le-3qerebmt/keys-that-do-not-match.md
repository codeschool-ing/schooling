---
title: Keys that look equal and are not
version: 1
---

**A key matches only when it is equal byte for byte**: same case, same spaces, same type. Two keys a
person reads as the same can be two different strings, and the merge treats them as strangers.

A table typed by hand, one contact per station, the way such tables arrive:

```python
contacts = pd.DataFrame({
    "station": ["S01", "s02", "S03 ", "S04"],
    "contact": ["Bia", "Caio", "Davi", "Elis"],
})
ids = stations[["station_id"]].drop_duplicates()
ids.merge(contacts, left_on="station_id", right_on="station", how="left").head(4)
```

```
  station_id station contact
0        S01     S01     Bia
1        S02     NaN     NaN
2        S03     NaN     NaN
3        S04     S04    Elis
```

`S02` and `S03` have no contact, though the table has one for each: `s02` is in lower case and
`S03 ` ends in a space. Nothing failed. On a table of twenty rows you might notice; on a table of
twenty thousand you would report the gaps as real.

The indicator counts them for you:

```python
check = ids.merge(contacts, left_on="station_id", right_on="station", how="outer", indicator=True)
check["_merge"].value_counts()
```

```
_merge
left_only     18
right_only     2
both           2
Name: count, dtype: int64
```

Two `right_only` rows are the two keys that matched nothing. **A `right_only` you did not expect is
almost always a spelling.** Normalise the key the way lesson 12 did, and the join finds them:

```python
contacts["station"] = contacts["station"].str.strip().str.upper()
ids.merge(contacts, left_on="station_id", right_on="station", how="left").head(4)
```

```
  station_id station contact
0        S01     S01     Bia
1        S02     S02    Caio
2        S03     S03    Davi
3        S04     S04    Elis
```

## Numbers that are text

The type matters as much as the spelling. A key that is a number in one file and text in another
does not match at all, and pandas says so:

```python
codes = pd.DataFrame({"code": [1, 2, 3]})
labels = pd.DataFrame({"code": ["1", "2", "3"], "label": ["one", "two", "three"]})
codes.merge(labels, on="code")
```

```
ValueError: You are trying to merge on int64 and str columns for key 'code'. If you wish to proceed you should use pd.concat
```

The message is the one the dates gave, and so is the fix: convert one side before the merge, with
`astype` or `pd.to_numeric`, and decide which type the key really is. A code with leading zeros,
such as a Brazilian CEP, is text, and turning it into a number loses the zeros.
