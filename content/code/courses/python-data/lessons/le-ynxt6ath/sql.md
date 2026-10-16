---
title: SQL, and letting the database do the work
version: 1
---

**pandas reads the result of a SQL query into a DataFrame**, and that changes the question from "how
do I load this table" to "which rows and columns do I actually need". The `sql-databases` course
teaches SQL; here it is enough to see the hand-over.

SQLite is a database in a single file, and Python ships the `sqlite3` module to use it, so nothing
needs installing. Put the trips into one:

```python
con = sqlite3.connect("bikes.db")
trips.to_sql("trips", con, index=False, if_exists="replace")
```

```
33337
```

`to_sql` creates the table, inserts every row, and returns the number of rows it wrote.
`if_exists="replace"` makes the cell safe to run again. Now ask the database a question:

```python
pd.read_sql("SELECT plan, bike, COUNT(*) AS trips FROM trips GROUP BY plan, bike", con)
```

```
     plan      bike  trips
0  annual   classic  15226
1  annual  electric   8212
2     day   classic   6456
3     day  electric   3443
```

Four rows came back instead of 33,337. **The counting happened in the database**, and only the
answer crossed into Python. On a database with a hundred million trips, that is the difference
between a query that returns in a second and a notebook that runs out of memory; lesson 20 comes back
to it.

## Parameters, never string formatting

A query that depends on a value takes the value as a parameter, with a `?` in the SQL:

```python
pd.read_sql("SELECT trip_id, started_at FROM trips WHERE start_station = ? LIMIT 3", con, params=["S07"])
```

```
   trip_id           started_at
0        1  2025-01-01 12:22:38
1       32  2025-01-01 15:00:50
2       42  2025-01-01 12:17:37
```

The driver puts the value in safely. **Building the SQL by pasting a value into the string**, with an
f-string, works until the value contains a quote, and on a value that came from a user it lets that
user rewrite the query. `params` costs nothing and closes both.

```python
pd.read_sql("SELECT * FROM trips LIMIT 1", con).dtypes["started_at"]
```

```
<StringDtype(na_value=nan)>
```

SQLite has no datetime type of its own, so the times came back as text, as from a CSV. A database
with real types, PostgreSQL for instance, hands back datetimes, and `read_sql` has a `parse_dates`
argument for when it does not.

```python
con.close()
```
