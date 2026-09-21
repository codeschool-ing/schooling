---
title: Two pages of JSON into a DataFrame
version: 1
---

```python
rows = []
url = "https://api.example.tld/orders"
while url:
    r = session.get(url, timeout=10)
    r.raise_for_status()
    page = r.json()
    rows += page["results"]
    url = page["next"]

df = pd.DataFrame(rows)
```

```sh
   id country  cents
0   1      US   1137
1   2      PT   1274
2   3      BR   1411
```

**A list of dictionaries is a DataFrame.** Nothing was parsed, nothing was converted, and the
columns are typed from the values. This is the shape of most data work there is: fetch, collect,
tabulate, ask.

## Nested JSON

```python
[{"id": 1, "cents": 12990, "customer": {"name": "ana", "country": "BR"}}]
```

```sh
>>> pd.DataFrame(nested)
   id  cents                          customer
0   1  12990  {'name': 'ana', 'country': 'BR'}
```

The whole dictionary lands in one cell, which is almost never useful.

```sh
>>> pd.json_normalize(nested)
   id  cents customer.name customer.country
0   1  12990           ana               BR
```

`json_normalize` flattens the nesting into dotted column names. It also takes `record_path` for
the case where the rows are a list inside each object, and `meta` for the fields outside it that
should be repeated onto each row.

## Then the ordinary five minutes

```python
df.info()
df.describe()
df["country"].value_counts(dropna=False)
```

An API is not cleaner than a CSV. A field that is `null` for some rows arrives as `NaN`, a number
sent as a string arrives as text, and an id that is all digits becomes an integer — all three are
the same problems as the reading section, in a different wrapper.

```python
df["cents"] = pd.to_numeric(df["cents"], errors="coerce")
df["paid_at"] = pd.to_datetime(df["paid_at"], errors="coerce")
```

`errors="coerce"` turns whatever will not convert into `NaN` rather than raising, and then
`isna().sum()` tells you how many there were. That pair — coerce, then count — is how you find
out what the feed is actually sending.

## Going back out

```python
df.to_csv("orders.csv", index=False)
df.to_parquet("orders.parquet")
df.to_json("orders.json", orient="records")
```

**`index=False`** on `to_csv`, or the file gets a first column of row numbers that whoever opens
it next has to work out the meaning of.

## And the whole thing

```python
rows = fetch_all(url, session)
df = pd.json_normalize(rows)
df["cents"] = pd.to_numeric(df["cents"], errors="coerce")
print(df.groupby("country")["cents"].agg(["count", "sum"]))
```

Four lines between an endpoint and an answer. Everything in this lesson is in there, and there is
no loop over rows anywhere in it.
