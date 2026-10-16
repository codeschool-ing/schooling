---
title: Run it twice, and get the same answer
version: 1
---

**Every pipeline will run twice over the same day sooner or later.** A scheduler retries a job that
timed out after it had in fact finished; somebody re-runs Monday by hand after a failure; a fix is
deployed and the week is rebuilt. That it will happen is certain; what matters is whether the second
run changes the answer.

A step that gives the same result however many times it runs is **idempotent**. The word is long
and the test is short: run it twice, and compare.

## The ingestion from the previous section, run again

Nothing is wrong with the pipeline as it stands, so far as one run can tell. Run the ingestion for
Monday a second time, as a retry would, and then the rest of the pipeline after it:

```
ana@lab:~/roda/lifecycle$ python ingest.py 2025-09-15
 187 rides    -> raw/date=2025-09-15/rides.jsonl
  12 stations -> raw/date=2025-09-15/stations.jsonl
ana@lab:~/roda/lifecycle$ wc -l raw/date=2025-09-15/*.jsonl
  374 raw/date=2025-09-15/rides.jsonl
   24 raw/date=2025-09-15/stations.jsonl
  398 total
ana@lab:~/roda/lifecycle$ python transform.py 2025-09-15
374 raw, 352 kept, 22 under 2 minutes dropped
ana@lab:~/roda/lifecycle$ python report.py 2025-09-15
Roda Livre, rides on 2025-09-15: 352
Busiest stations:
  ST02 Rua XV             58
  ST01 Praça Tiradentes   42
  ST08 Parque Barigui     32
```

**Every number in the report doubled, and nothing complained.** No error, no warning, a report that
looks exactly as trustworthy as the one before. That is lesson 1's `twice.py` again, at the scale of a
pipeline, and it is the failure Marta would never find on her own: a busy Monday looks like a busy
Monday.

The cause is one character in `ingest.py`. It opens each file with `"a"`, which appends: the second
run added Monday's rides to the end of the file that already held them. The transformation did its
own job correctly. It overwrote `clean/` and `curated/` and faithfully counted what raw said, and raw
said every ride twice.

The station names survived only by luck. `stations.jsonl` holds 24 lines now, but the transformation
puts them in a dictionary, which keeps one name per id. A join that kept every match would have
paired each doubled ride with two copies of its station and counted it four times.

## Replace the day, instead of adding to it

The repair is to make the unit of ingestion the **day**, and to replace it whole. This is the same
program with two changes:

```schooling-example
{"language": "python", "file": "lifecycle/ingest_replace.py", "parts": [
{"code": "# lifecycle/ingest_replace.py\nimport json\nimport os\nimport shutil\nimport sqlite3\nimport sys\n\n", "note": "The same imports as `ingest.py`, and one more: `shutil`, to remove a directory with everything in it."},
{"code": "day = sys.argv[1]\napp = sqlite3.connect(\"file:app.db?mode=ro\", uri=True)\napp.row_factory = sqlite3.Row\nrides = app.execute(\"SELECT * FROM rides WHERE started_at LIKE ?\", (day + \"%\",)).fetchall()\nstations = app.execute(\"SELECT * FROM stations\").fetchall()\n\n", "note": "Unchanged: the same read-only connection and the same two queries."},
{"code": "part = f\"raw/date={day}\"\nif os.path.exists(part):\n    shutil.rmtree(part)\nos.makedirs(part)\n", "note": "The first change. If the day's directory exists, it is removed whole, and created again empty. Whatever an earlier run left there is gone before anything is written."},
{"code": "for name, rows in ((\"rides\", rides), (\"stations\", stations)):\n    with open(f\"{part}/{name}.jsonl\", \"w\", encoding=\"utf-8\") as f:\n        for row in rows:\n            f.write(json.dumps(dict(row), ensure_ascii=False) + \"\\n\")\n    print(f\"{len(rows):4} {name:8} -> {part}/{name}.jsonl\")\n", "note": "The second: `\"w\"` instead of `\"a\"`. Either change alone would fix these two files; together they make the day the unit, so a file an older version left behind cannot survive either."}
]}
```

Run it twice in a row, and the rest of the pipeline after it:

```
ana@lab:~/roda/lifecycle$ python ingest_replace.py 2025-09-15
 187 rides    -> raw/date=2025-09-15/rides.jsonl
  12 stations -> raw/date=2025-09-15/stations.jsonl
ana@lab:~/roda/lifecycle$ python ingest_replace.py 2025-09-15
 187 rides    -> raw/date=2025-09-15/rides.jsonl
  12 stations -> raw/date=2025-09-15/stations.jsonl
ana@lab:~/roda/lifecycle$ wc -l raw/date=2025-09-15/*.jsonl
  187 raw/date=2025-09-15/rides.jsonl
   12 raw/date=2025-09-15/stations.jsonl
  199 total
ana@lab:~/roda/lifecycle$ python transform.py 2025-09-15
187 raw, 176 kept, 11 under 2 minutes dropped
ana@lab:~/roda/lifecycle$ python report.py 2025-09-15
Roda Livre, rides on 2025-09-15: 176
Busiest stations:
  ST02 Rua XV             29
  ST01 Praça Tiradentes   21
  ST08 Parque Barigui     16
```

The second run left the files exactly as the first did, and the report is back to the numbers in the
previous section. **Now a retry is harmless, and re-running a day is the ordinary way to repair it**
rather than a risk.

## What this does not cover

Replacing a partition is the simplest of several ways to be idempotent, and it fits a batch that
copies a whole day at a time. Two others are worth recognising by name:

- **a unique key**: every row carries an id, and a second copy of `R000174` replaces the first instead
  of sitting beside it. A database does this with a primary key, and `sql-databases` shows how;
- **a write and a rename**: the new day is written to a temporary directory and renamed into place
  only when it is complete, so a reader never sees half a day. Lesson 4 meets the same idea from the
  reading side, in a file that is still being written.

Lesson 8 returns to the subject for streams, where a crash between doing the work and recording that
it was done is the ordinary case rather than the exception.
