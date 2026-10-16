---
title: Sort keys and the blocks a query never reads
version: 1
---

**A sort key is the order a table's rows are written in, and its value is the blocks it lets a
query skip.** Redshift has no indexes in the sense PostgreSQL has them. What it has is the zone map
of every block, its minimum and maximum, and a zone map only helps when the rows are sorted: in a
table written in random order, every block holds a little of every day, its range spans the whole
month, and a filter on one day has to read all of them.

The model below measures that with the same ten thousand orders as before, cut into blocks, under
three sort orders. **Like the last one, it is a model of the arithmetic and not Redshift.** Save it
as `~/aws/zonemaps.py`:

```schooling-example
{"language": "python", "file": "zonemaps.py", "parts": [{"code": "import random\n\nROWS_PER_BLOCK = 250\nrng = random.Random(14)\nrows = [(f'2026-10-{rng.randint(1, 31):02d}', f'c-{rng.randint(1, 500):02d}')\n        for _ in range(10_000)]\n\n\n", "note": "Ten thousand orders again, each a date in October 2026 and a customer, in no particular order. A block here holds 250 rows; a real Redshift block is 1 MB of one column and holds far more, and the count of blocks is what matters, not their size."}, {"code": "def blocks(ordered):\n    return [ordered[i:i + ROWS_PER_BLOCK] for i in range(0, len(ordered), ROWS_PER_BLOCK)]\n\n\n", "note": "Cuts a table, in the order given, into blocks of 250 rows."}, {"code": "def read(table, column, value):\n    \"\"\"Blocks whose zone map, the min and max of the column, admits the value.\"\"\"\n    hits = 0\n    for block in table:\n        values = [row[column] for row in block]\n        if min(values) <= value <= max(values):\n            hits += 1\n    return hits\n\n\n", "note": "**The zone map at work.** For each block, the smallest and largest value of the column; a block is read only if the value could be inside that range."}, {"code": "layouts = {\n    'no sort key': rows,\n    'SORTKEY (dt, customer_id)': sorted(rows),\n    'SORTKEY (customer_id, dt)': sorted(rows, key=lambda r: (r[1], r[0])),\n}\n", "note": "The same rows written in three orders: as they came, sorted by date and then customer, and sorted by customer and then date. Python sorts a tuple by its first element first, which is exactly what a compound sort key does."}, {"code": "print(f'{\"\":<27}{\"dt = 2026-10-05\":>21}{\"customer_id = c-17\":>21}')\nfor name, ordered in layouts.items():\n    table = blocks(ordered)\n    by_day, by_customer = read(table, 0, '2026-10-05'), read(table, 1, 'c-17')\n    print(f'{name:<27}{by_day:>8} of {len(table)} blocks{by_customer:>8} of {len(table)} blocks')\n", "note": "For each layout, how many of the 40 blocks a filter on one day reads, and how many a filter on one customer reads."}]}
```

```
ana@laptop:~/aws$ python3 zonemaps.py
                                 dt = 2026-10-05   customer_id = c-17
no sort key                      40 of 40 blocks      40 of 40 blocks
SORTKEY (dt, customer_id)         2 of 40 blocks      36 of 40 blocks
SORTKEY (customer_id, dt)        40 of 40 blocks       1 of 40 blocks
```

**With no sort key, both filters read all 40 blocks.** Sorted by date first, the filter on one day
read 2 blocks, and the filter on one customer still read 36: within a day's blocks the customers are
all mixed again. Sorted by customer first, the two results swap. That is the rule of a **compound
sort key**: it helps a filter on its first column a great deal, on its second column only within
each value of the first, and on its third column hardly at all. So the first column is the one most
queries filter on by range, and at Quitanda that is the date: nearly every report asks about a day,
a week or a month. That is why `orders.sql` says `COMPOUND SORTKEY (dt, customer_id)`.

## Interleaved, and when it is the wrong answer

**An interleaved sort key gives each of its columns equal weight**, so that a filter on any one of
them skips blocks about as well as a filter on any other. It sounds like the better deal and it
usually is not. AWS's documentation lists its costs. Loading is slower, and the table needs a
`VACUUM REINDEX` to stay sorted, which is expensive. And it should not be used on a column whose
values only ever grow, such as a date or an identity column, because new rows all land in the same
corner of the order. Quitanda's orders are exactly that table, and the compound key on `dt` is the
better choice for them. An interleaved key is for a table filtered on several columns with no
favourite and loaded rarely.

## The rows that arrive later

**Rows added after a table is sorted are written to an unsorted region at its end**, and the zone
maps of those blocks span whatever the new rows contain. A nightly load of one day's orders, in
date order, keeps the table nearly sorted by itself. A load that inserts last month's corrections
does not, and Redshift sorts the table again in the background with an automatic `VACUUM`, or when
somebody runs `VACUUM SORT ONLY`. None of this was run; it is the behaviour AWS documents, and the
model above is the reason it matters.
