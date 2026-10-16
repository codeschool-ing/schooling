---
title: Inside a Parquet file
version: 1
---

**A Parquet file is a sequence of row groups, each a slice of the table's rows stored column by
column, followed by a footer that describes them.** Lesson 6 promised to open one, and the tool for
that is `pyarrow`, the Python library of the Apache Arrow project, which reads Parquet without
Spark. Install it in an environment of its own, as lesson 3 did for S3:

```sh
python3 -m venv ~/pq-env
~/pq-env/bin/pip install pyarrow==26.0.0
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l10-file\" aria-label=\"The anatomy of a Parquet file. The file is a sequence of row groups, each holding a few thousand to millions of rows. Inside a row group, each column is a column chunk, and each chunk is a sequence of pages, the unit that is compressed and encoded. The footer at the end holds the schema, and for every column chunk its position, size, encodings and the minimum and maximum value.\"><text x=\"20.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">one Parquet file</text><rect x=\"14.0\" y=\"32.0\" width=\"692.0\" height=\"196.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"26.0\" y=\"44.0\" width=\"224.0\" height=\"172.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"138.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">row group 0</text><rect x=\"36.0\" y=\"72.0\" width=\"204.0\" height=\"38.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42.0\" y=\"83.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">column chunk: ts</text><rect x=\"42.0\" y=\"92.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"91.0\" y=\"92.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"140.0\" y=\"92.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"189.0\" y=\"92.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"36.0\" y=\"118.0\" width=\"204.0\" height=\"38.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42.0\" y=\"129.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">column chunk: visitor_id</text><rect x=\"42.0\" y=\"138.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"91.0\" y=\"138.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"140.0\" y=\"138.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"189.0\" y=\"138.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"36.0\" y=\"164.0\" width=\"204.0\" height=\"38.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42.0\" y=\"175.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">column chunk: kind</text><rect x=\"42.0\" y=\"184.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"91.0\" y=\"184.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"140.0\" y=\"184.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"189.0\" y=\"184.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"138.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pages ▸</text><rect x=\"262.0\" y=\"44.0\" width=\"224.0\" height=\"172.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"374.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">row group 1</text><rect x=\"272.0\" y=\"72.0\" width=\"204.0\" height=\"38.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"278.0\" y=\"83.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">column chunk: ts</text><rect x=\"278.0\" y=\"92.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"327.0\" y=\"92.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"376.0\" y=\"92.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"425.0\" y=\"92.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"272.0\" y=\"118.0\" width=\"204.0\" height=\"38.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"278.0\" y=\"129.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">column chunk: visitor_id</text><rect x=\"278.0\" y=\"138.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"327.0\" y=\"138.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"376.0\" y=\"138.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"425.0\" y=\"138.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"272.0\" y=\"164.0\" width=\"204.0\" height=\"38.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"278.0\" y=\"175.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">column chunk: kind</text><rect x=\"278.0\" y=\"184.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"327.0\" y=\"184.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"376.0\" y=\"184.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"425.0\" y=\"184.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"374.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pages ▸</text><text x=\"508.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" fill=\"var(--paper-dim)\">· · ·</text><rect x=\"540.0\" y=\"44.0\" width=\"154.0\" height=\"172.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"617.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">footer</text><text x=\"617.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">schema, sizes,</text><text x=\"617.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">min and max per chunk</text></svg>", "caption": "A reader opens the footer first, and from it decides which row groups and which column chunks to read at all."}
```

Each **row group** holds a slice of the rows, by default up to 128 MB of them. Inside it, each
column's values form a **column chunk**, and each chunk is cut into **pages** of about 1 MB, the
unit that is encoded and compressed. The **footer** at the end of the file records the schema and,
for every column chunk, where it starts, its size, its encodings and the smallest and largest value
in it. A reader opens the footer first and decides from it what else to read.

This program reads only the footer of a day's file. Save it as `~/big/footer.py`:

```schooling-example
{
  "language": "python",
  "file": "footer.py",
  "parts": [
    {
      "code": "\"\"\"The footer of the first Parquet file in a directory: its row groups, and what each column costs.\"\"\"\nimport glob\nimport sys\n\nimport pyarrow.parquet as pq\n\n"
    },
    {
      "code": "path = sorted(glob.glob(f\"{sys.argv[1]}/*.parquet\"))[0]\nmeta = pq.ParquetFile(path).metadata\nprint(f\"{meta.num_rows:,} rows in {meta.num_row_groups} row group(s), {meta.serialized_size:,} bytes\"\n      f\" of footer, written by {meta.created_by}\")\n\n",
      "note": "**Only the footer is read.** A Parquet file ends with its metadata: the schema, every row group, and for each column chunk its size, its encodings and the smallest and largest value it holds. `metadata` reads that and nothing else."
    },
    {
      "code": "print(\"column       on disk  decompressed  codec   encodings\")\nprint(\"                KiB           KiB\")\nfor i in range(meta.num_columns):\n    chunks = [meta.row_group(g).column(i) for g in range(meta.num_row_groups)]\n    first = chunks[0]\n    print(f\"{first.path_in_schema:10} {sum(c.total_compressed_size for c in chunks) / 1024:9.1f}\"\n          f\" {sum(c.total_uncompressed_size for c in chunks) / 1024:13.1f}  {first.compression:7}\"\n          f\" {', '.join(first.encodings)}\")\n\n",
      "note": "**One line per column**, its chunks added up over the row groups: the bytes on disk, the bytes once decompressed, the codec and the encodings."
    },
    {
      "code": "if len(sys.argv) > 2:\n    i = meta.schema.names.index(sys.argv[2])\n    for g in range(meta.num_row_groups):\n        s = meta.row_group(g).column(i).statistics\n        print(f\"row group {g:2}: {meta.row_group(g).num_rows:7,} rows,\"\n              f\" {sys.argv[2]} from {s.min} to {s.max}\")\n",
      "note": "**The statistics of one column in every row group**, if a second argument names it: the range a reader compares a filter with before deciding to read the row group at all."
    }
  ]
}
```

Run it with the environment's Python, on the silver layer's 1 January:

```
ana@lab:~/big$ ~/pq-env/bin/python footer.py data/silver/clicks/day=2025-01-01
65,754 rows in 1 row group(s), 1,328 bytes of footer, written by parquet-mr version 1.16.0 (build 402c3810c372d29603e181771acebfecc71bef61)
column       on disk  decompressed  codec   encodings
                KiB           KiB
event_id       257.9         513.8  SNAPPY  BIT_PACKED, RLE, PLAIN
ts             532.3         897.6  SNAPPY  BIT_PACKED, RLE, PLAIN_DICTIONARY
visitor_id     156.6         233.4  SNAPPY  BIT_PACKED, RLE, PLAIN_DICTIONARY
kind            16.2          16.3  SNAPPY  BIT_PACKED, RLE, PLAIN_DICTIONARY
book_id        108.4         109.7  SNAPPY  BIT_PACKED, RLE, PLAIN_DICTIONARY
device          16.4          16.4  SNAPPY  BIT_PACKED, RLE, PLAIN_DICTIONARY
```

**One row group of 65,754 rows**: a day's file is 1.1 MB, far below the 128 MB a row group may hold,
so the whole file is one. The footer itself is 1,328 bytes.

**The six columns cost very different amounts.** `kind` and `device` take 16 KiB each, because they
have a handful of values and dictionary encoding turns each into a small number. `ts` takes 532 KiB,
the most of any column, and `event_id` 258. Those two are different in every row, so a dictionary
cannot help them, and what is left to do falls to the compression codec, `SNAPPY` here. The next
section is about why that is not much.
