---
title: Copying only what changed
version: 1
---

**Once a table is too big to copy whole on every run, each run copies only what changed since the
last one — and "since the last one" is a value the pipeline has to remember.** That value is the
**watermark**: the newest change the previous run saw. Copying everything every time is a **full
load**; copying from the watermark onwards is an **incremental load**.

The usual watermark is a column the source already keeps, `updated_at`, set to the current time
whenever a row is written. An incremental run asks for every row with `updated_at` above the
watermark, copies them, and moves the watermark to the newest one it read. That catches new rows and
changed ones alike, provided the source really does set `updated_at` on every write. Lesson 4's
questions to a source's owner include exactly that one.

## A source, and a copy

The source is a small SQLite database standing in for the app's. `morning` writes forty rides ending
between 08:02 and 09:59. `after` writes what happens after the 10:00 copy: a new ride, a refund, and a
ride whose row says 09:57. That last one is the case this section is about. One of the app's servers
stamped it at 09:57, when the ride ended, but its transaction was slow and only **committed** at 10:01,
so no copy taken at 10:00 could have seen it. Save this as `collect/app.py`:

```python
# collect/app.py
import sqlite3
import sys
from datetime import datetime, timedelta

db = sqlite3.connect("app.db")
db.execute("CREATE TABLE IF NOT EXISTS rides "
           "(ride_id TEXT PRIMARY KEY, station TEXT, status TEXT, updated_at TEXT)")


def write(ride_id, station, status, at):
    db.execute("INSERT OR REPLACE INTO rides VALUES (?, ?, ?, ?)",
               (ride_id, station, status, at))


if sys.argv[1] == "morning":
    # forty rides end between 08:02 and 09:59
    for i in range(1, 41):
        at = datetime(2025, 9, 15, 8, 0) + timedelta(minutes=3 * i - 1)
        write(f"R{i:06d}", f"ST{i % 12 + 1:02d}", "ended", str(at))
elif sys.argv[1] == "after":
    # after the 10:00 copy: one new ride, one refund, and one ride stamped
    # 09:57 by a slow server whose transaction committed at 10:01
    write("R000042", "ST02", "ended", "2025-09-15 10:04:00")
    write("R000010", "ST11", "refunded", "2025-09-15 10:02:00")
    write("R000041", "ST05", "ended", "2025-09-15 09:57:00")
db.commit()
n, last = db.execute("SELECT count(*), max(updated_at) FROM rides").fetchone()
print(f"app.db: {n} rides, latest updated_at {last}")
```

The copy is the program below. It takes one number, the **overlap**: how many minutes before the
watermark to start reading. Each overlap keeps its own watermark and its own copy, so two of them can
be compared on the same source.

```schooling-example
{"language": "python", "file": "collect/incremental.py", "parts": [
{"code": "# collect/incremental.py\nimport sqlite3\nimport sys\nfrom datetime import datetime, timedelta\n\noverlap = int(sys.argv[1])                 # minutes to read again\nmark_file = f\"watermark-{overlap}.txt\"\ntry:\n    mark = open(mark_file).read()\n    since = str(datetime.fromisoformat(mark) - timedelta(minutes=overlap))\nexcept FileNotFoundError:\n    mark = since = \"\"                      # the first run copies everything\n\n", "note": "The overlap comes from the command line. The watermark lives in a file of its own, because it has to outlive the run that wrote it. `since` is where this run starts reading: the watermark, moved back by the overlap. With no file there is no watermark yet, and an empty `since` is below every time."},
{"code": "rows = sqlite3.connect(\"app.db\").execute(\n    \"SELECT * FROM rides WHERE updated_at > ?\", (since,)).fetchall()\n\n", "note": "The whole question to the source: every row changed after `since`. A run reads only these rows, however big the table grows."},
{"code": "copy = sqlite3.connect(f\"copy-{overlap}.db\")\ncopy.execute(\"CREATE TABLE IF NOT EXISTS rides \"\n             \"(ride_id TEXT PRIMARY KEY, station TEXT, status TEXT, updated_at TEXT)\")\nbefore = copy.execute(\"SELECT count(*) FROM rides\").fetchone()[0]\ncopy.executemany(\"INSERT OR REPLACE INTO rides VALUES (?, ?, ?, ?)\", rows)\ncopy.commit()\nafter = copy.execute(\"SELECT count(*) FROM rides\").fetchone()[0]\n\n", "note": "The copy is keyed on `ride_id`, and `INSERT OR REPLACE` writes each row over any older version of it. That is what makes reading a row twice harmless, and it is how the refund replaces the ride it refunds."},
{"code": "mark = max([mark] + [r[3] for r in rows])\nopen(mark_file, \"w\").write(mark)\nprint(f\"overlap {overlap:2} min: read {len(rows):2} rows since {since[11:16] or 'the start'},\"\n      f\" {after - before:2} new, watermark now {mark[11:16]}\")\n", "note": "The new watermark is the newest `updated_at` read, and never moves backwards. It is saved only after the copy is committed: a run that dies halfway leaves the old watermark, and the next run reads the same rows again."}
]}
```

Make the morning, and take the 10:00 copy twice, once with no overlap and once with ten minutes:

```
ana@lab:~/roda/collect$ python app.py morning
app.db: 40 rides, latest updated_at 2025-09-15 09:59:00
ana@lab:~/roda/collect$ python incremental.py 0
overlap  0 min: read 40 rows since the start, 40 new, watermark now 09:59
ana@lab:~/roda/collect$ python incremental.py 10
overlap 10 min: read 40 rows since the start, 40 new, watermark now 09:59
```

The first run of each has no watermark, so it copies everything. Now the three changes arrive, and
both copies run again:

```
ana@lab:~/roda/collect$ python app.py after
app.db: 42 rides, latest updated_at 2025-09-15 10:04:00
ana@lab:~/roda/collect$ python incremental.py 0
overlap  0 min: read  2 rows since 09:59,  1 new, watermark now 10:04
ana@lab:~/roda/collect$ python incremental.py 10
overlap 10 min: read  7 rows since 09:49,  2 new, watermark now 10:04
```

The run with no overlap asked for everything after 09:59. It found the new ride at 10:04 and the
refund at 10:02, and moved its watermark to 10:04. The ride stamped 09:57 was not above 09:59, so it
was not asked for — and it never will be, because every later run starts above 10:04. The run with ten
minutes of overlap started at 09:49, read seven rows, found two of them new, and has the late ride. A
third program compares each copy with the source, row by row:

```python
# collect/compare.py
import sqlite3


def rides(path):
    return {r[0]: r for r in sqlite3.connect(path).execute("SELECT * FROM rides")}


source = rides("app.db")
for overlap in (0, 10):
    copy = rides(f"copy-{overlap}.db")
    missing = sorted(set(source) - set(copy))
    stale = sorted(k for k in copy if copy[k] != source.get(k))
    print(f"overlap {overlap:2} min: source {len(source)}, copy {len(copy)},"
          f" missing {missing or 'none'}, stale {stale or 'none'}")
```

```
ana@lab:~/roda/collect$ python compare.py
overlap  0 min: source 42, copy 41, missing ['R000041'], stale none
overlap 10 min: source 42, copy 42, missing none, stale none
```

**Nothing failed, nothing printed a warning, and one copy is missing a ride for good.** Both caught the
refund, because a change to an old row moves its `updated_at` forward. What the plain watermark cannot
catch is a row that arrives carrying a time in the past.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 232\" role=\"img\" aria-label=\"A time line from 09:40 to 10:10. Rides written up to 09:59 were copied at 10:00, which set the watermark to 09:59. Ride R000041 is stamped 09:57 but committed at 10:01. The next run with no overlap reads only above 09:59 and misses it; with a ten-minute overlap it reads above 09:49 and finds it, with the rides at 10:02 and 10:04.\" data-fig=\"watermark\"><defs><marker id=\"watermark-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"70\" y1=\"120\" x2=\"696\" y2=\"120\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#watermark-ah)\"></line><text x=\"80\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">09:40</text><text x=\"280\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">09:50</text><text x=\"480\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10:00</text><text x=\"680\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10:10</text><line x1=\"460\" y1=\"50\" x2=\"460\" y2=\"214\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></line><text x=\"454\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\" font-weight=\"600\">watermark 09:59</text><line x1=\"480\" y1=\"64\" x2=\"480\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"2 3\"></line><text x=\"486\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the copy at 10:00</text><circle cx=\"100\" cy=\"120\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></circle><circle cx=\"160\" cy=\"120\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></circle><circle cx=\"220\" cy=\"120\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></circle><circle cx=\"280\" cy=\"120\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></circle><circle cx=\"340\" cy=\"120\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></circle><circle cx=\"400\" cy=\"120\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></circle><circle cx=\"460\" cy=\"120\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></circle><circle cx=\"520\" cy=\"120\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><circle cx=\"560\" cy=\"120\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><circle cx=\"420\" cy=\"120\" r=\"6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"420\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">R000041</text><text x=\"428\" y=\"82\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">stamped 09:57, committed 10:01</text><rect x=\"460\" y=\"162\" width=\"220\" height=\"20\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">no overlap: above 09:59</text><rect x=\"260\" y=\"192\" width=\"420\" height=\"20\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"470.0\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ten-minute overlap: above 09:49</text><text x=\"150\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the run after 10:00 reads</text></svg>", "caption": "A row carries the time it was written and becomes visible when it commits. Reading a few minutes before the watermark is what catches the one that committed late."}
```

## The price of the overlap

The overlap re-reads the last ten minutes on every run: seven rows read for two new ones. Two things
make that safe. The write is keyed on `ride_id`, so a row read twice replaces itself instead of
appearing twice; lesson 3 calls that idempotent. And the window is wider than the slowest commit the
source is expected to have. **No window is wide enough for every case**: a server whose clock is a day
slow defeats a ten-minute overlap, and a row deleted in the source never has an `updated_at` to be
found by. Lesson 4 showed the delete going missing, and reading the database's own log of changes
instead. Extraction in depth, with its lookbacks and late rows, is `pipelines-etl`.
