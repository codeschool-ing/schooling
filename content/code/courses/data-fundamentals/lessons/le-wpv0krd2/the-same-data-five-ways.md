---
title: The same rides, five ways
version: 1
---

**Written with no compression at all, the same month of rides takes anywhere from about one megabyte
to more than eight, and the whole difference is layout and encoding.** This section measures it, and
then asks the question the measurement is really for: how much of a file does one question have to
read?

## Writing them all

`five.py` writes the 50,000 rides of `rides.py` once in each format, into a directory `five/`, and
prints the size of each file. It borrows the Avro schema from `as_avro.py`, which is why that program
keeps its writing under `if __name__ == "__main__":`. Save it as `formats/five.py`:

```python
# formats/five.py
import csv
import json
import os
import pyarrow as pa
import pyarrow.orc as orc
import pyarrow.parquet as pq
from fastavro import writer
from as_avro import SCHEMA
from rides import COLUMNS, make

rides = make(50_000)
os.makedirs("five", exist_ok=True)

with open("five/rides.csv", "w", newline="") as f:
    out = csv.DictWriter(f, fieldnames=COLUMNS, lineterminator="\n")
    out.writeheader()
    out.writerows(rides)

with open("five/rides.jsonl", "w") as f:
    for ride in rides:
        f.write(json.dumps(ride, default=str) + "\n")

with open("five/rides.avro", "wb") as f:
    writer(f, SCHEMA, rides)

table = pa.Table.from_pylist(rides)
pq.write_table(table, "five/rides.parquet", compression="none")
orc.write_table(table, "five/rides.orc")

for name in sorted(os.listdir("five")):
    print(f"{name:14} {os.path.getsize('five/' + name):>9,} bytes")
```

fastavro and pyarrow's ORC writer compress nothing unless asked, and pyarrow's Parquet writer does,
so the program tells Parquet not to. What is left to differ is how each format lays the rides out.

```
ana@lab:~/roda/formats$ python five.py
rides.avro     1,552,466 bytes
rides.csv      2,858,966 bytes
rides.jsonl    8,208,898 bytes
rides.orc      1,061,077 bytes
rides.parquet  1,287,381 bytes
```

From the largest:

- **JSON Lines, 8,208,898 bytes.** Every ride carries its seven field names, and every value is
  text: `started_at` alone is 25 characters a ride.
- **CSV, 2,858,966 bytes.** The names are written once, in the header, and the values are still text.
- **Avro, 1,552,466 bytes.** Binary values with no names, about 31 bytes a ride; still one ride after
  another.
- **Parquet, 1,287,381 bytes, and ORC, 1,061,077 bytes.** Columns, where alike values sit together:
  Parquet keeps a dictionary for the stations and the bicycles, and both store each column's
  numbers and times in encodings built for runs of similar values.

The two columnar files are the smallest, and they are close to each other. Which of them wins is a
property of this data and these two writers; a different table can reverse it.

## One column out of seven

Marta asks how long the average ride was in September. The answer needs one column. This program
works out how many bytes each file makes a reader go through to get it, and then computes the
average from both, to show they agree. Save it as `formats/one_column.py`:

```python
# formats/one_column.py
import csv
import os
import pyarrow.parquet as pq

meta = pq.ParquetFile("five/rides.parquet").metadata
col = meta.schema.names.index("minutes")
need = sum(meta.row_group(i).column(col).total_compressed_size
           for i in range(meta.num_row_groups))
print(f"Parquet: {need:,} of {os.path.getsize('five/rides.parquet'):,} bytes")
print(f"CSV:     {os.path.getsize('five/rides.csv'):,} of"
      f" {os.path.getsize('five/rides.csv'):,} bytes")

minutes = pq.read_table("five/rides.parquet", columns=["minutes"])["minutes"]
print("average from Parquet:", round(sum(minutes.to_pylist()) / len(minutes), 2))
with open("five/rides.csv", newline="") as f:
    values = [int(row["minutes"]) for row in csv.DictReader(f)]
print("average from CSV:    ", round(sum(values) / len(values), 2))
```

```
ana@lab:~/roda/formats$ python one_column.py
Parquet: 38,312 of 1,287,381 bytes
CSV:     2,858,966 of 2,858,966 bytes
average from Parquet: 31.54
average from CSV:     31.54
```

**To answer the same question, the Parquet reader goes through 38,312 bytes of its file, and the
CSV reader through all 2,858,966 of its own**, plus the footer in Parquet's case, which is small.
That is about 3% of one file against all of the other, for an identical answer, 31.54 minutes.
`columns=["minutes"]` is what tells pyarrow to fetch that one column chunk and leave the others where
they are.

This lesson counts bytes rather than seconds on purpose. A timing depends on the machine, the disk
and what else was running, and it would be different on yours. Bytes are the same everywhere, and
they are what a disk reads, a network carries and a cloud bill charges for. The share does not
shrink as the table grows: on a million times as many rides, one column is still a few per cent of
the file, and the CSV reader still reads all of it.
