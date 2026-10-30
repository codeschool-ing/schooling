---
title: Reading the files back out of the bucket
version: 1
---

**A query on an external table reads Parquet from Cloud Storage the way any good Parquet reader does:
the footer first, then only the byte ranges of the columns it needs.** BigQuery cannot be run here, but
that much can: fake-gcs-server holds the same files, it answers ranged requests as Cloud Storage does,
and Google's Python client can make them. This section builds a reader that does what an external table
does, counts every request and every byte it fetches, and hands the result to DuckDB.

## The files, in the bucket again

**fake-gcs-server forgets everything when it stops**, so if it has been restarted since lesson 13, put
the files back. In the terminal you type into, with the emulator running in its own:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-curated-prod --location=southamerica-east1
Creating gs://quitanda-curated-prod/...
ana@laptop:~/gcp$ gcloud storage cp --recursive warehouse/orders gs://quitanda-curated-prod/ 2>&1 | tail -1
Average throughput: 6.9MiB/s
ana@laptop:~/gcp$ gcloud storage ls -l 'gs://quitanda-curated-prod/orders/dt=2026-09-2*/*' | tail -4
    598978  2026-10-30T19:08:31Z  gs://quitanda-curated-prod/orders/dt=2026-09-27/part-000.parquet
    465485  2026-10-30T19:08:32Z  gs://quitanda-curated-prod/orders/dt=2026-09-28/part-000.parquet
    435738  2026-10-30T19:08:30Z  gs://quitanda-curated-prod/orders/dt=2026-09-29/part-000.parquet
TOTAL: 10 objects, 5293736 bytes (5.05MiB)
```

**Each day is one object of about half a megabyte.** The wildcard matched the ten days from 20 to 29
September, and the listing shows the last three with their sizes and the moment they were written, and
the total of the ten. These sizes are the ones the program below reads against.

## The reader

Save this as `~/gcp/external.py`:

```schooling-example
{"language": "python", "file": "external.py", "parts": [{"code": "import io\nimport sys\n\nimport duckdb\nimport pyarrow as pa\nimport pyarrow.parquet as pq\nfrom google.cloud import storage\n\nBUCKET, PREFIX = 'quitanda-curated-prod', 'orders/'\nfirst, last, columns = sys.argv[1], sys.argv[2], sys.argv[3].split(',')\n\n\n", "note": "**A query over the bucket, as three arguments**: the first and last day the partition filter keeps, and the columns to read. The bucket and the prefix are where lesson 13 put the files."}, {"code": "class RangeReader(io.RawIOBase):\n    \"\"\"A file that fetches only the byte ranges asked of it, and counts them.\"\"\"\n\n    def __init__(self, blob):\n        self.blob, self.size, self.pos = blob, blob.size, 0\n        self.requests = self.fetched = 0\n\n    def seekable(self):\n        return True\n\n    def readable(self):\n        return True\n\n    def seek(self, offset, whence=io.SEEK_SET):\n        self.pos = {io.SEEK_SET: 0, io.SEEK_CUR: self.pos, io.SEEK_END: self.size}[whence] + offset\n        return self.pos\n\n    def tell(self):\n        return self.pos\n\n    def readinto(self, buffer):\n        end = min(self.pos + len(buffer), self.size)\n        if end <= self.pos:\n            return 0\n        data = self.blob.download_as_bytes(start=self.pos, end=end - 1)\n        buffer[:len(data)] = data\n        self.pos += len(data)\n        self.requests += 1\n        self.fetched += len(data)\n        return len(data)\n\n\n", "note": "**A file that is never downloaded whole.** PyArrow asks a file to seek and read like any other, and every read here becomes one request for exactly that byte range of the object, `download_as_bytes(start=..., end=...)`, which is an HTTP `Range` request. It counts the requests and the bytes, which is the point of it."}, {"code": "client = storage.Client(project='planner-dev')\ntables, listed, requests, fetched, stored = [], 0, 0, 0, 0\nfor blob in client.list_blobs(BUCKET, prefix=PREFIX):\n    listed += 1\n    dt = blob.name.split('dt=')[1].split('/')[0]\n    if not first <= dt <= last:\n        continue\n    reader = RangeReader(blob)\n    table = pq.read_table(reader, columns=columns)\n    tables.append(table.append_column('dt', pa.array([dt] * table.num_rows)))\n    requests, fetched, stored = requests + reader.requests, fetched + reader.fetched, stored + blob.size\n\n", "note": "**Hive partitioning, done by hand.** Every object under the prefix is listed, the date is read out of its name, and an object outside the range is skipped without a byte of it being fetched. For the rest, `read_table` with `columns=` reads the footer, finds where those columns are, and fetches only them. `dt` is added back from the name, as BigQuery adds it from the path. The client finds fake-gcs-server through `STORAGE_EMULATOR_HOST`, which every terminal of this course exports."}, {"code": "orders = pa.concat_tables(tables)\nprint(f'{listed} objects listed, {len(tables)} read: {requests} range requests, '\n      f'{fetched:,} of their {stored:,} bytes fetched')\nduckdb.sql(\"SELECT district, sum(total_cents) AS sales FROM orders GROUP BY district ORDER BY sales DESC\").show()\n", "note": "**The query, on what came back.** DuckDB queries an Arrow table in a Python variable by its name, so `orders` here is the data fetched from the bucket and nothing else."}]}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"One Parquet object in the bucket, drawn as a long bar: a row group holding nine column chunks, order_id to created_at, with district and total_cents highlighted, and at the end of the object the footer. Three numbered requests leave the reader. Request 1 fetches the footer, at the end of the object, which says where every column chunk starts. Requests 2 and 3 fetch only the district and total_cents chunks. The other column chunks are never fetched.\" data-fig=\"l17-ranges\"><defs><marker id=\"l17-ranges-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l17-ranges-ah-1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one object: orders/dt=2026-09-29/part-000.parquet</text><rect x=\"20\" y=\"34\" width=\"82\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"61.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">order_id</text><rect x=\"106\" y=\"34\" width=\"66\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"139.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">customer_id</text><rect x=\"176\" y=\"34\" width=\"58\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">store_id</text><rect x=\"238\" y=\"34\" width=\"68\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"272.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">district</text><rect x=\"310\" y=\"34\" width=\"52\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"336.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">items</text><rect x=\"366\" y=\"34\" width=\"76\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"404.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">total_cents</text><rect x=\"446\" y=\"34\" width=\"56\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"474.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">payment</text><rect x=\"506\" y=\"34\" width=\"70\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"541.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">created_at</text><rect x=\"580\" y=\"34\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">footer</text><rect x=\"300\" y=\"196\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"420\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">external.py, or any Parquet reader</text><polyline points=\"500,196 640.0,82\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l17-ranges-ah-0)\"></polyline><text x=\"560\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">1. the footer, first</text><polyline points=\"360,196 272.0,82\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l17-ranges-ah-1)\"></polyline><polyline points=\"430,196 404.0,82\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l17-ranges-ah-1)\"></polyline><text x=\"20\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">2. and 3. only the two column chunks asked for</text><text x=\"20\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--paper-dim)\">never fetched: order_id, customer_id, store_id,</text><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--paper-dim)\">items, payment, created_at</text></svg>", "caption": "What a columnar reader asks a bucket for: the footer first, then only the column chunks it needs. Drawn for one row group; the files of this lesson have one per day."}
```

## Three queries over the bucket

September's sales per district, which needs two columns of 29 files; one day with every column, which
needs a whole file; and the same two columns across all sixty days:

```
ana@laptop:~/gcp$ python3 external.py 2026-09-01 2026-09-29 district,total_cents
60 objects listed, 29 read: 87 range requests, 4,878,703 of their 15,520,944 bytes fetched
┌──────────────┬────────────┐
│   district   │   sales    │
│   varchar    │   int128   │
├──────────────┼────────────┤
│ Santana      │ 1796352232 │
│ Vila Mariana │ 1794992861 │
│ Tatuapé      │ 1794313101 │
│ Mooca        │ 1787916569 │
│ Pinheiros    │ 1786375693 │
│ Butantã      │ 1778472411 │
│ Lapa         │ 1776954375 │
│ Moema        │ 1773707382 │
└──────────────┴────────────┘

ana@laptop:~/gcp$ python3 external.py 2026-09-29 2026-09-29 order_id,customer_id,store_id,district,items,total_cents,payment,created_at
60 objects listed, 1 read: 2 range requests, 499,423 of their 435,738 bytes fetched
┌──────────────┬──────────┐
│   district   │  sales   │
│   varchar    │  int128  │
├──────────────┼──────────┤
│ Butantã      │ 51441722 │
│ Mooca        │ 50703844 │
│ Tatuapé      │ 49693044 │
│ Santana      │ 48953221 │
│ Pinheiros    │ 48877437 │
│ Vila Mariana │ 48705315 │
│ Moema        │ 47805392 │
│ Lapa         │ 47482131 │
└──────────────┴──────────┘

ana@laptop:~/gcp$ python3 external.py 2026-08-01 2026-09-29 district,total_cents
60 objects listed, 60 read: 180 range requests, 10,152,701 of their 32,451,790 bytes fetched
┌──────────────┬────────────┐
│   district   │   sales    │
│   varchar    │   int128   │
├──────────────┼────────────┤
│ Vila Mariana │ 3758093658 │
│ Santana      │ 3753808833 │
│ Tatuapé      │ 3752619012 │
│ Mooca        │ 3747729248 │
│ Butantã      │ 3736296055 │
│ Lapa         │ 3724394126 │
│ Pinheiros    │ 3720802949 │
│ Moema        │ 3718075370 │
└──────────────┴────────────┘
```

**September's two columns fetched 4,878,703 of the 15,520,944 bytes stored**, in 87 requests, three for
each of the 29 files. Lesson 16 counted the two columns' share of those files at 2,978,159 bytes; the
rest is the footer of each file, which every reader has to fetch before it knows where anything else
is. The other 31 objects were listed and never opened, because their names said they were August.

**One day of every column fetched more than the file holds**: 499,423 bytes for a file of 435,738. The
reader asked for the end of the file first, to find the footer, and then for the whole file, so the
footer's bytes crossed the network twice. For a query that wants everything, a columnar format saves
nothing, and the ranged reads cost a little extra.

**Two columns of all sixty days took 180 requests**, three a file, and fetched 10,152,701 of the
32,451,790 bytes in the bucket: under a third, for the same reason as September. A query on columns
pays for its columns and its footers, never for the rest of the file.

## What this is, and what it is not

**This is what a reader of an external table does, measured on the emulator.** The number of requests,
the footer read and the column ranges are properties of the Parquet format and of the reader, and
BigQuery's reader has to do the same work in some form: list the objects, read each footer, fetch the
column chunks. **It is not BigQuery's reader.** BigQuery's caches metadata (the next section's
subject), reads in parallel across many workers, and fetches in whatever ranges it chooses; how many
requests it makes for a query is not something its documentation promises. And it is not a bill: what
BigQuery would charge for these three queries is lesson 16's arithmetic, on the bytes of the columns,
and what Cloud Storage would charge for the requests is the last section's.
