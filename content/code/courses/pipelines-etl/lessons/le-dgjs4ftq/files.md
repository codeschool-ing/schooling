---
title: A file, and how you know it is finished
version: 1
---

A file is the oldest interface between two companies and still the commonest. The distributor
writes one stock file a day and drops it in Ana's inbox:

```
ana@vm:~/etl$ sudo bash ~/lab/lab.sh day 2026-03-05
ana@vm:~/etl$ ls -l inbox
total 248
-rw-r--r-- 1 ana ana 51310 Oct  7 00:07 stock_2026-03-01.csv
-rw-r--r-- 1 ana ana 51319 Oct  7 00:07 stock_2026-03-02.csv
-rw-r--r-- 1 ana ana 51320 Oct  7 00:07 stock_2026-03-03.csv
-rw-r--r-- 1 ana ana 51322 Oct  7 00:07 stock_2026-03-04.csv
-rw-r--r-- 1 ana ana 40527 Oct  7 00:07 stock_2026-03-05.csv
ana@vm:~/etl$ head -3 inbox/stock_2026-03-04.csv
isbn,available,as_of
9786557083932,8,2026-03-04T06:00:00-03:00
9786543217853,20,2026-03-04T06:00:00-03:00
ana@vm:~/etl$ head -3 inbox/stock_2026-03-05.csv | cat -v
isbn;disponM-mvel;data
9786557083932;11;05/03/2026 06:00
9786543217853;21;05/03/2026 06:00
ana@vm:~/etl$ file inbox/stock_2026-03-0*.csv
inbox/stock_2026-03-01.csv: CSV ASCII text
inbox/stock_2026-03-02.csv: CSV ASCII text
inbox/stock_2026-03-03.csv: CSV ASCII text
inbox/stock_2026-03-04.csv: CSV ASCII text
inbox/stock_2026-03-05.csv: ISO-8859 text
```

Two things in that transcript are this section and the next one. The file for 5 March is smaller
than the others, and `file` calls it `ISO-8859 text` where the rest are `ASCII`. Look at its first
lines and the header has changed language, separator and date format at once: the distributor
moved to a new system that day and nobody told Ponto Final. The next section is about that.

This section is about the quieter question: **how does a pipeline know a file is complete?**

## The file that loads perfectly

Ana's loader reads a stock file, checks its header and inserts its rows into `raw.stock`:

```
"""Load one day of the distributor's stock file into the warehouse's raw layer."""
import csv
import sys

import psycopg

EXPECTED = ["isbn", "available", "as_of"]
path = sys.argv[1]
with open(path, newline="", encoding="utf-8") as f:
    reader = csv.reader(f)
    header = next(reader)
    if header != EXPECTED:
        sys.exit(f"{path}: header is {header}, expected {EXPECTED}; nothing loaded")
    rows = list(reader)
with psycopg.connect("dbname=wh") as wh:
    wh.execute("CREATE SCHEMA IF NOT EXISTS raw")
    wh.execute("""CREATE TABLE IF NOT EXISTS raw.stock (
                    isbn text, available integer, as_of timestamptz, file text)""")
    wh.execute("DELETE FROM raw.stock WHERE file = %s", (path,))
    with wh.cursor() as cur:
        cur.executemany("INSERT INTO raw.stock VALUES (%s, %s, %s, %s)",
                        [(*row, path) for row in rows])
print(f"{path}: {len(rows)} rows loaded")
```

Now give it a file whose transfer stopped at line 600 — a connection that dropped, a disk that
filled, a supplier's job that died:

```
ana@vm:~/etl$ python load_stock.py /tmp/stock_2026-03-04.csv
/tmp/stock_2026-03-04.csv: 599 rows loaded
ana@vm:~/etl$ tail -2 /tmp/stock_2026-03-04.csv
9786558559689,23,2026-03-04T06:00:00-03:00
9786529909567,15,2026-03-04T06:00:00-03:00
```

**599 rows, loaded, no complaint.** The file stopped between two lines, so every line in it is
well-formed, and nothing about a CSV says how long it should be. Half the catalogue now has no stock
figure, and tomorrow's report says those books are not in stock.

## Ways to know

A file cannot say it is finished, so something around it has to:

- **Write somewhere else, then rename.** The supplier writes `stock_2026-03-04.csv.tmp` and renames
  it when it is done. On one filesystem a rename is atomic: the pipeline sees either no file or the
  whole file. This is the cheapest fix, and it needs the supplier's cooperation.
- **A marker file.** The supplier drops `stock_2026-03-04.done` after the data file. The pipeline
  waits for the marker, not the data — lesson 9's sensors are built for exactly this wait.
- **A count in a trailer or a manifest.** The last line says `TOTAL,1200`, or a small JSON beside
  the file says how many rows and what checksum. The pipeline compares before it loads.
- **An expectation of your own.** Ponto Final has 1,200 books, and a stock file with 599 rows is
  wrong whatever its format says. Lesson 16 turns that kind of expectation into a check.

The first three need an agreement with whoever writes the file. **Ask for one before the first
load**, while asking is still cheap.
