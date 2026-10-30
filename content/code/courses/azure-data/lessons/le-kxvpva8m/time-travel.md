---
title: Time travel, and the vacuum that ends it
version: 1
---

**Every version of a Delta table stays readable for as long as its files stay on disk.** The log
says which files each version had; the files are still there because no commit ever deletes one.
That makes the past of a table free to ask about, and it is what the previous two sections paid for
in disk: a deleted order, a month of small files, each still taking space after the table stopped
using it.

## Reading the past

The `hourly` table has 528 versions, 0 to 527, one per commit:

```
ana@laptop:~/azure$ python table.py lake/hourly history | sed -n 1,3p
   0 WRITE     {'num_added_files': 1, 'num_added_rows': 187}
   1 WRITE     {'num_added_files': 1, 'num_added_rows': 168}
   2 WRITE     {'num_added_files': 1, 'num_added_rows': 171}
ana@laptop:~/azure$ python table.py lake/hourly history | tail -2
 526 WRITE     {'num_added_files': 1, 'num_added_rows': 172}
 527 OPTIMIZE  {'numFilesAdded': 31, 'numFilesRemoved': 527, 'numBatches': 527}
ana@laptop:~/azure$ ls lake/hourly/_delta_log | grep -v json
00000000000000000099.checkpoint.parquet
00000000000000000199.checkpoint.parquet
00000000000000000299.checkpoint.parquet
00000000000000000399.checkpoint.parquet
00000000000000000499.checkpoint.parquet
_last_checkpoint
```

**A reader does not replay 528 JSON files to find the newest version.** Every hundred commits the
library wrote a checkpoint, the whole state of the table at that version in one Parquet file, and
`_last_checkpoint` says which is the newest. A reader starts there and replays only the commits
after it, 28 here. Spark's Delta writes them on the same principle, at an interval of its own.

Version 100 is the table after its first 101 hourly loads, a little over the first five days:

```
ana@laptop:~/azure$ python table.py lake/hourly@100 files
version 100: 101 files, 576,494 bytes, 18,577 rows in the log
ana@laptop:~/azure$ python table.py lake/hourly@100 read
version 100: 18,577 rows read from 101 files
```

**That is time travel**: Spark writes it `SELECT * FROM orders VERSION AS OF 100`, or `TIMESTAMP AS
OF` a moment, and so do Fabric's Spark and Databricks. It is how a team answers "what
did the dashboard show on Tuesday?", and how it undoes a bad load: `restore` makes a new commit
whose files are those of an older version, and nothing is copied back, because nothing was ever
lost.

## Vacuum

**Vacuum is the only operation that deletes data files**, and it deletes those that no version
younger than a retention period still names. The library's default retention is seven days, 168
hours, which is also the default of Spark's Delta; it refuses less unless told twice:

```
ana@laptop:~/azure$ python table.py lake/hourly vacuum 0 2>&1 | tail -1
_internal.DeltaError: Generic error: Invalid retention period, minimum retention for vacuum is configured to be greater than 168 hours, got 0 hours
ana@laptop:~/azure$ python table.py lake/hourly vacuum 0 force
527 files deleted from disk
```

**The refusal is the library protecting readers**: a query that started a minute ago may still be
reading files of the version before the compaction, and a vacuum with no retention deletes them under
it. Here nothing else reads the table, so `force` is safe; on a shared lake it is how a job fails
for somebody else in the middle of the night. The 527 small files are gone, and so is everything
that needed them:

```
ana@laptop:~/azure$ python table.py lake/hourly@100 files
version 100: 101 files, 576,494 bytes, 18,577 rows in the log
ana@laptop:~/azure$ python table.py lake/hourly@100 read
version 100 cannot be read: IO Error: No files found that match the pattern "/home/ana/azure/lake/hourly/dt=2026-10-06/part-00000-5b535c4e-7087-411a-82bc-aa5ce85e36de-c000.snappy.parquet"
ana@laptop:~/azure$ python table.py lake/hourly read
version 529: 98,727 rows read from 31 files
ana@laptop:~/azure$ python table.py lake/hourly history | tail -2
 528 VACUUM START {'numFilesToDelete': 527}
 529 VACUUM END {'numDeletedFiles': 527}
```

**Version 100 is still in the log and no longer in the lake.** `files` reads only the log, so it
still describes 101 files and 18,577 rows; `read` opens them and finds the first one missing. The
newest version is untouched, because vacuum keeps every file the current version names. And vacuum
recorded itself as two commits, 528 and 529, so the history says when the past was given up and how
much of it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Paired bars for the hourly table at three moments. After 527 hourly loads, version 526: 527 files in the table and 527 on disk. After compaction, version 527: 31 files in the table and 558 on disk. After vacuum, version 529: 31 in the table and 31 on disk.\" data-fig=\"l18-vacuum\"><rect x=\"240\" y=\"14\" width=\"12\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"/><text x=\"258\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">files in the table</text><rect x=\"420\" y=\"14\" width=\"12\" height=\"10\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"/><text x=\"438\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Parquet files on disk</text><text x=\"218\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">after 527 hourly loads</text><text x=\"218\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">version 526</text><rect x=\"230\" y=\"44\" width=\"415.55555555555554\" height=\"16\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"/><text x=\"651.5555555555555\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">527</text><rect x=\"230\" y=\"64\" width=\"415.55555555555554\" height=\"16\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"/><text x=\"651.5555555555555\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">527</text><text x=\"218\" y=\"114\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">after compaction</text><text x=\"218\" y=\"132\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">version 527</text><rect x=\"230\" y=\"106\" width=\"24.444444444444443\" height=\"16\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"/><text x=\"260.44444444444446\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">31</text><rect x=\"230\" y=\"126\" width=\"440.0\" height=\"16\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"/><text x=\"676.0\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">558</text><text x=\"218\" y=\"176\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">after vacuum</text><text x=\"218\" y=\"194\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">version 529</text><rect x=\"230\" y=\"168\" width=\"24.444444444444443\" height=\"16\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"/><text x=\"260.44444444444446\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">31</text><rect x=\"230\" y=\"188\" width=\"24.444444444444443\" height=\"16\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"/><text x=\"260.44444444444446\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">31</text><line x1=\"230\" y1=\"36\" x2=\"230\" y2=\"226\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/></svg>", "caption": "What the table names and what the disk holds are two different counts. Compaction shrinks the first and grows the second; only vacuum brings them together, and it takes the old versions with it."}
```

## The two retentions

**Time travel needs two things to still exist: the log entry and the files**, and each has its own
retention. Vacuum's, seven days by default, decides the files. The log's own, which Spark's Delta sets
at thirty days by default, decides how long old commits are kept before checkpoints replace them.
Asking for a version older than either fails. A team that wants a year of history keeps a year of
files, and pays for every byte rewritten during that year, which for a table compacted every night
can be many times the table's own size. Deciding the retention is deciding that bill, and the next
section puts numbers on it.
