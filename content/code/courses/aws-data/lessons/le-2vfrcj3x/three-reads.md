---
title: One question, four bills
version: 1
---

**The same SQL costs what the layout of the files lets it skip.** The previous section asked for
October's sales by payment and read 40,641,097 bytes. Nothing about the question needs most of
those bytes: it uses two columns of seven, and every day of the month. Ask it of the Parquet layer,
then for one day, and the answer stays right while the read falls by two orders of magnitude.

## The columns it names

```
ana@laptop:~/aws$ python3 ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬─────────────┐
│   payment    │ orders │    reais    │
│   varchar    │ int64  │   double    │
├──────────────┼────────┼─────────────┤
│ pix          │ 348030 │ 41382125.37 │
│ credit       │ 249543 │ 29611096.91 │
│ debit        │  97614 │ 11585221.55 │
│ meal-voucher │  60324 │  7158978.69 │
└──────────────┴────────┴─────────────┘

read from S3: 5,102,048 bytes in 62 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

**The same four rows, from 5,102,048 bytes instead of 40,641,097.** In a Parquet file each column
is stored in a block of its own, and the file says where each block starts, so the engine read the
blocks for `payment` and `total_cents` and nothing of the other five. That is eight times less, and
the true ratio is larger, because part of those five megabytes is not column data at all.

## The days it names

```
ana@laptop:~/aws$ python3 ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders WHERE dt = '2026-10-15' GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬────────────┐
│   payment    │ orders │   reais    │
│   varchar    │ int64  │   double   │
├──────────────┼────────┼────────────┤
│ pix          │  10885 │ 1292365.89 │
│ credit       │   7756 │  939193.96 │
│ debit        │   3188 │  370995.75 │
│ meal-voucher │   1952 │  230061.29 │
└──────────────┴────────┴────────────┘

read from S3: 163,234 bytes in 2 GET requests to 1 object
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

**163,234 bytes from one object.** The filter on `dt` was settled before anything was read: `dt` is
in the key, so the 30 days that are not 15 October were never opened. This is what partitioning is
for, and it works on any format, the CSV included:

```
ana@laptop:~/aws$ python3 ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders_csv WHERE dt = '2026-10-15' GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬────────────┐
│   payment    │ orders │   reais    │
│   varchar    │ int64  │   double   │
├──────────────┼────────┼────────────┤
│ pix          │  10885 │ 1292365.89 │
│ credit       │   7756 │  939193.96 │
│ debit        │   3188 │  370995.75 │
│ meal-voucher │   1952 │  230061.29 │
└──────────────┴────────┴────────────┘

read from S3: 1,279,794 bytes in 3 GET requests to 1 object
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

The CSV read 1,279,794 bytes, the whole of one day's file, and the Parquet read an eighth of that.
**The two decisions are independent and they multiply**: the format decides how much of each file a
question reads, the partitioning decides how many files it opens.

## Where the rest of the bytes went

A question that needs almost nothing shows what every Parquet read pays before it reads a column:

```
ana@laptop:~/aws$ python3 ask.py "SELECT hour, count(*) AS orders FROM orders WHERE hour >= 21 GROUP BY hour ORDER BY hour"
┌──────┬────────┐
│ hour │ orders │
│ int8 │ int64  │
├──────┼────────┤
│   21 │  74339 │
│   22 │  42695 │
│   23 │  21388 │
└──────┴────────┘

read from S3: 2,039,661 bytes in 62 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

`hour` is the smallest column in the lake, and the query read 2,039,661 bytes for it. **31 objects,
and 31 × 65,536 is 2,031,616 of those bytes.** Before PyArrow can read any column it reads the end of
the file, where Parquet keeps its footer, the map of where every column block is, and it reads that
end 64 KiB at a time. What is left, 8,045 bytes, is the hour column of 31 days. The footer itself is
small, and this program prints it for one day:

`footer.py`:

```python
import sys

import pyarrow.parquet as pq

from lake import filesystem

meta = pq.ParquetFile(sys.argv[1].removeprefix('s3://'), filesystem=filesystem()).metadata
groups = meta.num_row_groups
print(f'{meta.num_rows:,} rows in {groups} row group{"s" * (groups != 1)}, '
      f'footer {meta.serialized_size:,} bytes')
for g in range(meta.num_row_groups):
    group = meta.row_group(g)
    for c in (group.column(j) for j in range(group.num_columns)):
        s = c.statistics
        print(f'  {g}  {c.path_in_schema:<14}{c.total_compressed_size:>10,} bytes'
              f'  {s.min!s:>12} .. {s.max!s}')
```

```
ana@laptop:~/aws$ python3 footer.py s3://quitanda-curated-prod/orders/dt=2026-10-15/orders.parquet
23,781 rows in 1 row group, footer 1,576 bytes
  0  order_id         162,148 bytes  o-1015-00001 .. o-1015-23781
  0  customer_id      109,646 bytes           c-1 .. c-9998
  0  hour                 259 bytes             7 .. 23
  0  items             18,196 bytes             1 .. 40
  0  total_cents       91,537 bytes          1380 .. 87990
  0  payment            6,161 bytes        credit .. pix
  0  neighbourhood     12,268 bytes    Bela Vista .. Vila Mariana
```

**The day's footer is 1,576 bytes, and 163,234 is that day's read to the byte**: 65,536 for the
footer, 91,537 for `total_cents` and 6,161 for `payment`. Every number `ask.py` printed for Parquet
is footers plus the blocks the question named. Athena's engine reads the footer with requests of its
own size, so the per-object part of its bill differs from this one; the per-column part is the same
blocks of the same file. Lesson 19 returns to `footer.py` for the last two columns it prints, the
smallest and largest value of each block.

## The four bills side by side

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Four grids, each with seven rows for the seven columns and thirty-one cells for the days of October. CSV over the whole month reads every cell, 40,641,097 bytes. Parquet over the whole month reads only the rows payment and total_cents, all 31 days, 5,102,048 bytes. CSV for 15 October reads all seven rows of that one day, 1,279,794 bytes. Parquet for 15 October reads two cells, payment and total_cents of that day, 163,234 bytes.\" data-fig=\"l15-reads\"><text x=\"112\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CSV, the whole month</text><text x=\"104\" y=\"39.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">order_id</text><rect x=\"112\" y=\"34\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"112\" y=\"34\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"51.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">customer_id</text><rect x=\"112\" y=\"46\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"112\" y=\"46\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"63.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">hour</text><rect x=\"112\" y=\"58\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"112\" y=\"58\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"75.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">items</text><rect x=\"112\" y=\"70\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"112\" y=\"70\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"87.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">total_cents</text><rect x=\"112\" y=\"82\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"112\" y=\"82\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"99.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">payment</text><rect x=\"112\" y=\"94\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"112\" y=\"94\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"111.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">neighbourhood</text><rect x=\"112\" y=\"106\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"112\" y=\"106\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><line x1=\"120.5\" y1=\"34\" x2=\"120.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"129.5\" y1=\"34\" x2=\"129.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"138.5\" y1=\"34\" x2=\"138.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"147.5\" y1=\"34\" x2=\"147.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"156.5\" y1=\"34\" x2=\"156.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"165.5\" y1=\"34\" x2=\"165.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"174.5\" y1=\"34\" x2=\"174.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"183.5\" y1=\"34\" x2=\"183.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"192.5\" y1=\"34\" x2=\"192.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"201.5\" y1=\"34\" x2=\"201.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"210.5\" y1=\"34\" x2=\"210.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"219.5\" y1=\"34\" x2=\"219.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"228.5\" y1=\"34\" x2=\"228.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"237.5\" y1=\"34\" x2=\"237.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"246.5\" y1=\"34\" x2=\"246.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"255.5\" y1=\"34\" x2=\"255.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"264.5\" y1=\"34\" x2=\"264.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"273.5\" y1=\"34\" x2=\"273.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"282.5\" y1=\"34\" x2=\"282.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"291.5\" y1=\"34\" x2=\"291.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"300.5\" y1=\"34\" x2=\"300.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"309.5\" y1=\"34\" x2=\"309.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"318.5\" y1=\"34\" x2=\"318.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"327.5\" y1=\"34\" x2=\"327.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"336.5\" y1=\"34\" x2=\"336.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"345.5\" y1=\"34\" x2=\"345.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"354.5\" y1=\"34\" x2=\"354.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"363.5\" y1=\"34\" x2=\"363.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"372.5\" y1=\"34\" x2=\"372.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"381.5\" y1=\"34\" x2=\"381.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><text x=\"112\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">40,641,097 bytes</text><text x=\"425\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Parquet, the whole month</text><rect x=\"425\" y=\"34\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"425\" y=\"46\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"425\" y=\"58\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"425\" y=\"70\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"425\" y=\"82\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"425\" y=\"82\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"425\" y=\"94\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"425\" y=\"94\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"425\" y=\"106\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><line x1=\"433.5\" y1=\"34\" x2=\"433.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"442.5\" y1=\"34\" x2=\"442.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"451.5\" y1=\"34\" x2=\"451.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"460.5\" y1=\"34\" x2=\"460.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"469.5\" y1=\"34\" x2=\"469.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"478.5\" y1=\"34\" x2=\"478.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"487.5\" y1=\"34\" x2=\"487.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"496.5\" y1=\"34\" x2=\"496.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"505.5\" y1=\"34\" x2=\"505.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"514.5\" y1=\"34\" x2=\"514.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"523.5\" y1=\"34\" x2=\"523.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"532.5\" y1=\"34\" x2=\"532.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"541.5\" y1=\"34\" x2=\"541.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"550.5\" y1=\"34\" x2=\"550.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"559.5\" y1=\"34\" x2=\"559.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"568.5\" y1=\"34\" x2=\"568.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"577.5\" y1=\"34\" x2=\"577.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"586.5\" y1=\"34\" x2=\"586.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"595.5\" y1=\"34\" x2=\"595.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"604.5\" y1=\"34\" x2=\"604.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"613.5\" y1=\"34\" x2=\"613.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"622.5\" y1=\"34\" x2=\"622.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"631.5\" y1=\"34\" x2=\"631.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"640.5\" y1=\"34\" x2=\"640.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"649.5\" y1=\"34\" x2=\"649.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"658.5\" y1=\"34\" x2=\"658.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"667.5\" y1=\"34\" x2=\"667.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"676.5\" y1=\"34\" x2=\"676.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"685.5\" y1=\"34\" x2=\"685.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"694.5\" y1=\"34\" x2=\"694.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><text x=\"425\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">5,102,048 bytes</text><text x=\"112\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CSV, 15 October</text><text x=\"104\" y=\"187.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">order_id</text><rect x=\"112\" y=\"182\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"238\" y=\"182\" width=\"8\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"199.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">customer_id</text><rect x=\"112\" y=\"194\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"238\" y=\"194\" width=\"8\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"211.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">hour</text><rect x=\"112\" y=\"206\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"238\" y=\"206\" width=\"8\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"223.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">items</text><rect x=\"112\" y=\"218\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"238\" y=\"218\" width=\"8\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"235.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">total_cents</text><rect x=\"112\" y=\"230\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"238\" y=\"230\" width=\"8\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"247.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">payment</text><rect x=\"112\" y=\"242\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"238\" y=\"242\" width=\"8\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"259.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">neighbourhood</text><rect x=\"112\" y=\"254\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"238\" y=\"254\" width=\"8\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><line x1=\"120.5\" y1=\"182\" x2=\"120.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"129.5\" y1=\"182\" x2=\"129.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"138.5\" y1=\"182\" x2=\"138.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"147.5\" y1=\"182\" x2=\"147.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"156.5\" y1=\"182\" x2=\"156.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"165.5\" y1=\"182\" x2=\"165.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"174.5\" y1=\"182\" x2=\"174.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"183.5\" y1=\"182\" x2=\"183.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"192.5\" y1=\"182\" x2=\"192.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"201.5\" y1=\"182\" x2=\"201.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"210.5\" y1=\"182\" x2=\"210.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"219.5\" y1=\"182\" x2=\"219.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"228.5\" y1=\"182\" x2=\"228.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"237.5\" y1=\"182\" x2=\"237.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"246.5\" y1=\"182\" x2=\"246.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"255.5\" y1=\"182\" x2=\"255.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"264.5\" y1=\"182\" x2=\"264.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"273.5\" y1=\"182\" x2=\"273.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"282.5\" y1=\"182\" x2=\"282.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"291.5\" y1=\"182\" x2=\"291.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"300.5\" y1=\"182\" x2=\"300.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"309.5\" y1=\"182\" x2=\"309.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"318.5\" y1=\"182\" x2=\"318.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"327.5\" y1=\"182\" x2=\"327.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"336.5\" y1=\"182\" x2=\"336.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"345.5\" y1=\"182\" x2=\"345.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"354.5\" y1=\"182\" x2=\"354.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"363.5\" y1=\"182\" x2=\"363.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"372.5\" y1=\"182\" x2=\"372.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"381.5\" y1=\"182\" x2=\"381.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><text x=\"112\" y=\"280\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">1,279,794 bytes</text><text x=\"425\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Parquet, 15 October</text><rect x=\"425\" y=\"182\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"425\" y=\"194\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"425\" y=\"206\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"425\" y=\"218\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"425\" y=\"230\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"551\" y=\"230\" width=\"8\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"425\" y=\"242\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"551\" y=\"242\" width=\"8\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"425\" y=\"254\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><line x1=\"433.5\" y1=\"182\" x2=\"433.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"442.5\" y1=\"182\" x2=\"442.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"451.5\" y1=\"182\" x2=\"451.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"460.5\" y1=\"182\" x2=\"460.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"469.5\" y1=\"182\" x2=\"469.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"478.5\" y1=\"182\" x2=\"478.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"487.5\" y1=\"182\" x2=\"487.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"496.5\" y1=\"182\" x2=\"496.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"505.5\" y1=\"182\" x2=\"505.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"514.5\" y1=\"182\" x2=\"514.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"523.5\" y1=\"182\" x2=\"523.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"532.5\" y1=\"182\" x2=\"532.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"541.5\" y1=\"182\" x2=\"541.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"550.5\" y1=\"182\" x2=\"550.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"559.5\" y1=\"182\" x2=\"559.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"568.5\" y1=\"182\" x2=\"568.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"577.5\" y1=\"182\" x2=\"577.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"586.5\" y1=\"182\" x2=\"586.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"595.5\" y1=\"182\" x2=\"595.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"604.5\" y1=\"182\" x2=\"604.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"613.5\" y1=\"182\" x2=\"613.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"622.5\" y1=\"182\" x2=\"622.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"631.5\" y1=\"182\" x2=\"631.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"640.5\" y1=\"182\" x2=\"640.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"649.5\" y1=\"182\" x2=\"649.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"658.5\" y1=\"182\" x2=\"658.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"667.5\" y1=\"182\" x2=\"667.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"676.5\" y1=\"182\" x2=\"676.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"685.5\" y1=\"182\" x2=\"685.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"694.5\" y1=\"182\" x2=\"694.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><text x=\"425\" y=\"280\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">163,234 bytes</text><text x=\"112\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one cell per day, 1 to 31 October</text><rect x=\"425\" y=\"299\" width=\"10\" height=\"10\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"441\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">read</text><rect x=\"495\" y=\"299\" width=\"10\" height=\"10\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><text x=\"511\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">not read</text></svg>", "caption": "The same question asked four ways. Each grid is the lake: a row per column, a cell per day. The format decides how many rows a question reads; the partition decides how many cells across."}
```

| question | read | Athena would bill | USD |
|---|---:|---:|---:|
| CSV, whole month | 40,641,097 bytes | 39 MB | 0.000335 |
| Parquet, whole month | 5,102,048 bytes | 10 MB | 0.000086 |
| CSV, one day | 1,279,794 bytes | 10 MB | 0.000086 |
| Parquet, one day | 163,234 bytes | 10 MB | 0.000086 |

**Three of the four meet the 10 MB minimum**, so the bill flattens what the read did not. That is
the minimum doing its job, and it is a property of this small lake, not of the formats. Multiply
both month reads by a thousand, for a lake of a few years and more stores, and the minimum stops mattering. The CSV is then 38,759 MB a query and the Parquet 4,866 MB, which is 0.333 dollars against 0.042 in the program's units. A dashboard that asks every ten minutes asks 4,464 times in
October. **That is 1,485 dollars a month against 186, for the same four rows**, and the Parquet
figure still pays for its footers, which grow with the number of files rather than with their size.
