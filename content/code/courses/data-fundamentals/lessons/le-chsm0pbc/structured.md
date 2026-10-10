---
title: Structured data, and a table that says no
version: 1
---

**Structured data has a schema declared before any of it arrived, and every value is checked
against it as it is written.** A table in a relational database is the familiar case: rows
and columns, one type per column, the same columns in every row. The jargon for it is **schema on
write**. The check runs once, at the moment of writing, and every reader afterwards can trust the
shape without looking.

That trust is the whole point. A query that adds up `minutes` never has to ask whether one of them
is the text `9 min`, because a value like that could not have got in.

## A table that refuses

pyarrow, the library you installed in lesson 1, builds tables in memory with a declared schema, which
makes it a small way to see schema on write happen without installing a database. This lesson works
in a directory of its own:

```sh
mkdir -p ~/roda/shapes && cd ~/roda/shapes
```

Save this as `structured.py` there:

```schooling-example
{"language": "python", "file": "shapes/structured.py", "parts": [{"code": "# shapes/structured.py\nfrom datetime import datetime\nfrom zoneinfo import ZoneInfo\n\nimport pyarrow as pa\n\n", "note": "The first line names the file and the directory to save it in. `zoneinfo` is in the standard library; `pyarrow` is the one you installed."}, {"code": "SP = ZoneInfo('America/Sao_Paulo')\nSCHEMA = pa.schema([\n    ('ride_id', pa.string()),\n    ('station', pa.string()),\n    ('started_at', pa.timestamp('s', tz='America/Sao_Paulo')),\n    ('minutes', pa.int32()),\n])\n\n", "note": "The schema, declared before a single ride exists: four columns, each with a name and a type. `int32` is a whole number; the timestamp carries Curitiba's time zone."}, {"code": "rides = [\n    {'ride_id': 'R000001', 'station': 'ST02',\n     'started_at': datetime(2025, 9, 14, 7, 52, tzinfo=SP), 'minutes': 12},\n    {'ride_id': 'R000002', 'station': 'ST05',\n     'started_at': datetime(2025, 9, 14, 8, 3, tzinfo=SP), 'minutes': 25},\n]\ntable = pa.Table.from_pylist(rides, schema=SCHEMA)\nprint(table.schema)\nprint(table.num_rows, 'rows accepted')\n\n", "note": "Two rides that fit. `from_pylist` builds a table from a list of dictionaries and checks every value against `SCHEMA` as it goes."}, {"code": "rides.append({'ride_id': 'R000003', 'station': 'ST06',\n              'started_at': datetime(2025, 9, 14, 8, 31, tzinfo=SP), 'minutes': '9 min'})\ntry:\n    pa.Table.from_pylist(rides, schema=SCHEMA)\nexcept (pa.ArrowInvalid, pa.ArrowTypeError) as err:\n    print('refused:', err)\n", "note": "A third ride whose `minutes` arrived as text, the way a careless export writes it. The same call is tried again, and the error it raises is printed rather than left to stop the program."}]}
```

Run it:

```
ana@lab:~/roda/shapes$ python structured.py
ride_id: string
station: string
started_at: timestamp[s, tz=America/Sao_Paulo]
minutes: int32
2 rows accepted
refused: Could not convert '9 min' with type str: tried to convert to int32
```

The two good rides went in. The third was stopped at the door, with a message naming the value and
the type it failed to become. **Nothing was written**: `from_pylist` builds the whole table or none of
it, so there is no half-loaded state to clean up afterwards.

Notice the column `started_at`. It is not a string that happens to look like a time. It is a
timestamp with a time zone, so sorting, subtracting and grouping by hour all work on it directly,
and no reader ever has to parse it.

## The same rows without a schema

A CSV file has column names in its first line and nothing else: no types, no rule that a value must
be there. Save this as `loose.py`:

```python
# shapes/loose.py
import csv

rows = [
    ['ride_id', 'station', 'started_at', 'minutes'],
    ['R000001', 'ST02', '2025-09-14 07:52', '12'],
    ['R000002', 'ST05', '2025-09-14 08:03', '25'],
    ['R000003', 'ST06', '2025-09-14 08:31', '9 min'],
]
with open('rides.csv', 'w', newline='') as f:
    csv.writer(f).writerows(rows)
print('wrote', len(rows) - 1, 'rides')

with open('rides.csv', newline='') as f:
    rides = list(csv.DictReader(f))
print(rides[2])
total = sum(int(r['minutes']) for r in rides)
print('total minutes:', total)
```

```
ana@lab:~/roda/shapes$ python loose.py
wrote 3 rides
{'ride_id': 'R000003', 'station': 'ST06', 'started_at': '2025-09-14 08:31', 'minutes': '9 min'}
Traceback (most recent call last):
  File "/home/ana/roda/shapes/loose.py", line 17, in <module>
    total = sum(int(r['minutes']) for r in rides)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/roda/shapes/loose.py", line 17, in <genexpr>
    total = sum(int(r['minutes']) for r in rides)
                ^^^^^^^^^^^^^^^^^
ValueError: invalid literal for int() with base 10: '9 min'
```

The writer accepted all three rows. The reader got every value back as a string, which is all a CSV
can hold, and the program only failed at line 17, when it tried to add the minutes up. **The
error was the same; it surfaced at a different person.** In `structured.py` it stopped whoever was
writing the bad row. Here it stops whoever reads the file, possibly a week later, possibly Caio in the
middle of something else, and the file that caused it is already stored and copied.

That is the trade structured data makes. Somebody has to declare the schema first, and changing it
later is a deliberate act: a migration, a new column, a conversation with whoever reads the table. In
return, every mistake of type is caught at the cheapest moment there is, before it has been stored.
