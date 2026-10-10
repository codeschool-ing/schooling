---
title: Adding a field without breaking last month
version: 1
---

**Every format meets the day a field is added; what differs is whether the old files and the old
readers notice, and whether they say so.** The app team at Roda Livre is about to start renting
electric bicycles, and from October every ride will carry a `kind`. September's files were written
without it, and nobody is going to rewrite them.

The phrase for this is **schema evolution**, and it has two directions worth naming. A new reader
that can still read old files is **backward compatible**. An old reader that can still read new
files is **forward compatible**. A field added carefully gives both.

## Avro: two schemas, resolved by name

An Avro reader always has two schemas in hand: the **writer's schema**, which is in the file's
header, and the **reader's schema**, the one the program asks for. Avro matches their fields by
name, not by position, and has a rule for each difference. A field the writer had and the reader
does not is skipped. A field the reader wants and the writer never wrote is filled from the
reader's **default**, and if the reader's schema has no default, the read fails.

This program writes two September rides with the old schema, then reads them back twice with a
schema that adds `kind`: once with a default, once without. Save it as `formats/evolve.py`:

```python
# formats/evolve.py
from fastavro import reader, writer

OLD = {"type": "record", "name": "Ride", "fields": [
    {"name": "ride_id", "type": "string"},
    {"name": "minutes", "type": "int"},
]}
WITH_DEFAULT = {"type": "record", "name": "Ride", "fields": [
    {"name": "ride_id", "type": "string"},
    {"name": "minutes", "type": "int"},
    {"name": "kind", "type": "string", "default": "classic"},
]}
WITHOUT_DEFAULT = {"type": "record", "name": "Ride", "fields": [
    {"name": "ride_id", "type": "string"},
    {"name": "minutes", "type": "int"},
    {"name": "kind", "type": "string"},
]}

with open("september.avro", "wb") as f:
    writer(f, OLD, [{"ride_id": "R000001", "minutes": 5},
                    {"ride_id": "R000002", "minutes": 23}])

for label, schema in [("with a default", WITH_DEFAULT),
                      ("without one", WITHOUT_DEFAULT)]:
    with open("september.avro", "rb") as f:
        try:
            print(label + ":", list(reader(f, reader_schema=schema)))
        except Exception as e:
            print(label + ":", type(e).__name__ + ":", e)
```

```
ana@lab:~/roda/formats$ python evolve.py
with a default: [{'ride_id': 'R000001', 'minutes': 5, 'kind': 'classic'}, {'ride_id': 'R000002', 'minutes': 23, 'kind': 'classic'}]
without one: SchemaResolutionError: No default value for field kind in Ride
```

With a default, September reads perfectly under October's schema: every old ride is a `classic`,
which happens to be true, because there were no electric bicycles before October. Without one, the
reader refuses and names the field. **Both outcomes are good ones.** The first is correct and the
second is loud, and neither produces a wrong number. A schema registry, met in section 06, can run this
same check before it accepts a new version of a schema, so a change that would break readers is
refused on the day it is proposed rather than on the morning it is read.

## CSV: by position, and silently

CSV has no schema to resolve, only a header that most readers skip and a position that most code
trusts. This program averages the minutes of September's export and October's, reading the third
column of each, which is where `minutes` has always been. October's export added a `battery` column
for the electric bicycles, and put it third. Save it as `formats/shifted.py`:

```python
# formats/shifted.py
import csv
import io

SEPTEMBER = "ride_id,station,minutes\nR000001,ST08,5\nR000002,ST12,23\n"
OCTOBER = "ride_id,station,battery,minutes\nR000003,ST04,81,58\nR000004,ST02,64,12\n"


def average_minutes(text):
    rows = list(csv.reader(io.StringIO(text)))[1:]
    return sum(int(row[2]) for row in rows) / len(rows)  # minutes: third column


print("September:", average_minutes(SEPTEMBER))
print("October:  ", average_minutes(OCTOBER))
```

```
ana@lab:~/roda/formats$ python shifted.py
September: 14.0
October:   72.5
```

October's real average is 35 minutes, from 58 and 12. The program printed 72.5, the average battery
charge, and nothing complained: a battery percentage is a perfectly good integer. This is the quiet
failure lesson 1 warned about, caused by nothing more than a column inserted in the middle. Reading
by header name, with `csv.DictReader`, would have survived this insertion and failed loudly with a
`KeyError` on a rename, which is the better of the two failures.

## Parquet and ORC

Both keep the schema in each file's footer, so a reader that is handed September's files and
October's can match their columns by name and fill `kind` with nulls for the rows that never had
it. What neither does is decide what a missing value should mean; a null is not `classic`. Table
formats such as Apache Iceberg and Delta Lake go one step further and keep the history of a table's
schema above its files; this course names them and leaves them there.
