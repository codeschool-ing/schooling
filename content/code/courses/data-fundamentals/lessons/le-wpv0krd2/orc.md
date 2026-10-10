---
title: "ORC: stripes, indexes and a Hive accent"
version: 1
---

**ORC is Parquet's close relative: columnar, typed, compressed and carrying statistics, but grown
up inside Apache Hive.** The name is short for Optimized Row Columnar. It was created in 2013 for
Hive, the system that put SQL on top of Hadoop, and that is still where it is met most often.

The vocabulary is different and the ideas are nearly the same:

| ORC | the nearest thing in Parquet |
|---|---|
| **stripe**: a slice of the rows, stored column by column | row group |
| **row index**: minimum and maximum for each run of rows inside a stripe, 10,000 by default | page statistics |
| **file footer**: the schema, where each stripe is, statistics per column | footer |
| **postscript**: the footer's length and the compression, at the very end | the footer's length and `PAR1` |

With the row index, a reader looking for one day can skip not only the stripes that cannot hold it
but most of the stripe that does. pyarrow's writer records an entry every 10,000 rows unless told
otherwise. ORC can also store a **bloom filter** for a column, a small structure that
answers "is this value certainly absent from this stripe?", which helps when looking up one id among
millions.

## Writing one

pyarrow writes ORC as well as Parquet. Save this as `formats/as_orc.py`:

```python
# formats/as_orc.py
import pyarrow as pa
import pyarrow.orc as orc
from rides import make

table = pa.Table.from_pylist(make(50_000))
orc.write_table(table, "rides.orc", stripe_size=64 * 1024, compression="zstd")

f = orc.ORCFile("rides.orc")
print(f.nrows, "rows in", f.nstripes, "stripes, compression", f.compression)
for i in range(f.nstripes):
    print(f"  stripe {i}: {f.read_stripe(i).num_rows} rows")
print("started_at is stored as", f.schema.field("started_at").type)
```

A stripe is normally far bigger than this month of rides: pyarrow's default is 64 MiB. The program
asks for 64 KiB so that the file has more than one, and for `zstd` compression, because pyarrow's ORC
writer compresses nothing by default.

```
ana@lab:~/roda/formats$ python as_orc.py
50000 rows in 2 stripes, compression ZSTD
  stripe 0: 33792 rows
  stripe 1: 16208 rows
started_at is stored as timestamp[ns, tz=UTC]
```

The stripes are not round numbers, unlike Parquet's row groups. A stripe is cut by size, when the
writer's estimate of the encoded data reaches the limit, and not by a count of rows. The last line
is the same lesson Avro taught: the timestamps went in with Curitiba's zone and are stored as UTC
instants. The moment survives; the zone it was written in does not.

## Parquet or ORC

Measured on the same data, the two land close together, as section "the-same-data-five-ways" shows.
The difference that decides most choices is who else reads the file. Delta Lake stores its tables
only as Parquet; Apache Iceberg can use Parquet, ORC or Avro, and uses Parquet unless told
otherwise. Hive's transactional tables, the ones that accept updates and deletes, require ORC. So
ORC is the right answer where the estate is already Hive's, and Parquet is the one most new
platforms start from.
