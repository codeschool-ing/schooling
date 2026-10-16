---
title: JSON, and the types read_json decides on its own
version: 1
---

**JSON is how web services hand over data: objects with named fields, which pandas turns into rows
and columns.** It is text, like CSV, and about twice as large, because every row repeats every
field's name. The usual table shape is one object per line, called **JSON Lines**:

```python
trips.to_json("trips.jsonl", orient="records", lines=True)
with open("trips.jsonl") as f:
    print(f.readline())
```

```
{"trip_id":1,"started_at":"2025-01-01 12:22:38","ended_at":"2025-01-01 12:57:03","start_station":"S07","end_station":"S05","plan":"day","bike":"electric"}

```

`orient="records"` writes each row as an object, and `lines=True` puts one per line, which lets a
program read a huge file a line at a time. Read it back:

```python
back = pd.read_json("trips.jsonl", lines=True)
back.dtypes
```

```
trip_id                   int64
started_at       datetime64[us]
ended_at         datetime64[us]
start_station               str
end_station                 str
plan                        str
bike                        str
dtype: object
```

**Two columns changed type on the way back.** `started_at` and `ended_at` went out as text and came
back as datetimes, while `start_station` did not. `read_json` converts columns to dates on its own
when their names look like dates to it: ending in `_at` or `_time`, starting with `timestamp`, or
called `date` or `modified`, among others. That helped here. On a column called `created_at` that
holds something that only looks like a date, it is a surprise. `convert_dates=False` turns it off,
and naming the columns to convert, `convert_dates=["started_at"]`, makes it explicit.

## Nested JSON

An API answer is often nested: an object inside a field. `pd.json_normalize` flattens it into
columns with dotted names:

```python
answer = [{"station": "S01", "status": {"bikes": 9, "docks_free": 5}},
          {"station": "S02", "status": {"bikes": 3, "docks_free": 17}}]
pd.json_normalize(answer)
```

```
  station  status.bikes  status.docks_free
0     S01             9                  5
1     S02             3                 17
```

Each nested field became a column, `status.bikes` and `status.docks_free`, which is what a table
needs. A list inside a field, a station's last ten trips, say, does not flatten into columns, and
`json_normalize` has a `record_path` argument for turning such a list into rows.
