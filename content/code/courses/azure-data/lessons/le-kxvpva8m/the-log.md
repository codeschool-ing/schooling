---
title: The log, and what a delete really writes
version: 1
---

**A Delta table never changes a file it has written.** Every change, an insert, a delete, an update,
a compaction, writes new Parquet files and a new commit in `_delta_log` that adds them and removes
the old ones from the table. The old files stay on disk. That one rule explains time travel, it
explains why a table can be read while it is written, and it explains most of what a Delta table
costs. Lesson 17 showed the first commit; this section makes a second and watches what it does.

**Everything in this lesson runs on your computer, on the local disk**, with the same `deltalake`
library lesson 17 used and no emulator at all. A Delta table is the same folder on a disk, in a blob
container or in OneLake, and on a disk you can `ls` it. No Azure service is involved, and none is
imitated.

The terminal is the one from lesson 1, in `~/azure`, with the virtual environment active and
`orders.py` from lesson 17 saved there. One more program looks after a table from the command line:

`table.py`:

```schooling-example
{"language": "python", "file": "table.py", "parts": [
{"code": "\"\"\"table.py: look after a Delta table from the command line.\n\n    python table.py PATH[@VERSION] files | history | read | compact | delete PREDICATE | vacuum HOURS [force]\n\"\"\"\nimport sys\n\nimport duckdb\nimport pyarrow as pa\nimport pyarrow.compute as pc\nfrom deltalake import DeltaTable\n\n\ndef open_table(arg):\n    path, _, version = arg.partition(\"@\")\n    return DeltaTable(path, version=int(version) if version else None)\n\n\n", "note": "**`lake/flat@3` opens the table as it was at version 3.** With no `@`, it opens the newest version. Every action below takes the table opened this way."},
{"code": "def files(t):\n    adds = pa.table(t.get_add_actions(flatten=True))\n    size = pc.sum(adds[\"size_bytes\"]).as_py()\n    print(f\"version {t.version()}: {adds.num_rows} files, {size:,} bytes, {t.count():,} rows in the log\")\n\n\n", "note": "**`files` reads only the log**: the `add` actions of the version, their sizes, and the row counts their statistics carry. It opens no Parquet file, which matters at the end of the lesson."},
{"code": "def history(t):\n    for h in reversed(t.history()):\n        counts = {k: v for k, v in (h.get(\"operationMetrics\") or {}).items()\n                  if k.startswith(\"num\") and v}\n        print(f\"{h['version']:>4} {h['operation']:<9} {counts}\")\n\n\n", "note": "One line per commit, oldest first, with the counts the writer recorded in `commitInfo`. Timings are recorded too and left out, because they differ on every run."},
{"code": "def read(t):\n    paths = t.file_uris()\n    try:\n        rows = duckdb.execute(\"SELECT count(*) FROM read_parquet(?)\", [paths]).fetchone()[0]\n        print(f\"version {t.version()}: {rows:,} rows read from {len(paths)} files\")\n    except duckdb.IOException as e:\n        print(f\"version {t.version()} cannot be read: {str(e).splitlines()[0]}\")\n\n\n", "note": "**`read` opens every Parquet file the version names**, through DuckDB, and counts the rows in them, which is the difference from `files`. A file the log names and the disk no longer has is reported in one line."},
{"code": "def compact(t):\n    m = t.optimize.compact()\n    print(f\"{m['numFilesRemoved']} files removed, {m['numFilesAdded']} added; now version {t.version()}\")\n\n\n", "note": "Compaction rewrites many small files of a partition into few large ones, as one new commit."},
{"code": "def delete(t, predicate):\n    m = t.delete(predicate)\n    print(f\"{m['num_deleted_rows']} deleted, {m['num_copied_rows']:,} copied into \"\n          f\"{m['num_added_files']} new file(s); now version {t.version()}\")\n\n\n", "note": "A delete takes a SQL condition. Its metrics say how many rows went, and **how many had to be copied** to make that happen."},
{"code": "def vacuum(t, hours, force=None):\n    gone = t.vacuum(retention_hours=int(hours), dry_run=False, enforce_retention_duration=force != \"force\")\n    print(f\"{len(gone)} files deleted from disk\")\n\n\n", "note": "**Vacuum deletes from disk the files no recent version needs.** `HOURS` is how far back a version must stay readable, and the library refuses anything under its default unless `force` is given."},
{"code": "if __name__ == \"__main__\":\n    table, action, *rest = sys.argv[1:]\n    {\"files\": files, \"history\": history, \"read\": read, \"compact\": compact,\n     \"delete\": delete, \"vacuum\": vacuum}[action](open_table(table), *rest)\n"}
]}
```

Write the month as one table, look at what is on disk, and delete one order:

```
ana@laptop:~/azure$ python -c "from deltalake import write_deltalake; from orders import october; write_deltalake('lake/flat', october())"
ana@laptop:~/azure$ find lake/flat -type f | sort
lake/flat/_delta_log/00000000000000000000.json
lake/flat/part-00000-ad802eef-bf0b-4c1c-85de-5affc3f3578f-c000.snappy.parquet
ana@laptop:~/azure$ python table.py lake/flat files
version 0: 1 files, 1,205,188 bytes, 98,727 rows in the log
ana@laptop:~/azure$ python table.py lake/flat delete "order_id = '1015-00042'"
1 deleted, 98,726 copied into 1 new file(s); now version 1
ana@laptop:~/azure$ python table.py lake/flat files
version 1: 1 files, 710,217 bytes, 98,726 rows in the log
```

**One order deleted, 98,726 copied.** Parquet files cannot be edited in place, so removing a row
means writing a new file with every other row of the old one. The table had one file, so the whole
month was rewritten to delete one order. The new file is smaller, 710,217 bytes against 1,205,188,
for a reason that has nothing to do with the delete: the library compressed the rewrite with zstd,
where the first write used Snappy. The codec is chosen by whoever writes a file, every time.

The commit says exactly that, and nothing else:

```
ana@laptop:~/azure$ jq -c 'if .add then {add: .add.path} elif .remove then {remove: .remove.path, dataChange: .remove.dataChange} else empty end' lake/flat/_delta_log/00000000000000000001.json
{"add":"part-00000-28ae7e46-8a47-4264-a4f0-38d5831e40e9-c000.zstd.parquet"}
{"remove":"part-00000-ad802eef-bf0b-4c1c-85de-5affc3f3578f-c000.snappy.parquet","dataChange":true}
ana@laptop:~/azure$ ls lake/flat/*.parquet | wc -l
2
```

**`remove` takes the old file out of the table and leaves it on the disk.** Version 1 is the new
file alone; version 0 is still the old file alone, and both are readable, because both files are
there. The cost is that the folder now holds two months of orders, and anything that reads the
folder rather than the log counts both:

```
ana@laptop:~/azure$ python table.py lake/flat read
version 1: 98,726 rows read from 1 files
ana@laptop:~/azure$ python -c "import duckdb; duckdb.sql(\"SELECT count(*) AS orders FROM 'lake/flat/*.parquet'\").show()"
┌────────┐
│ orders │
│ int64  │
├────────┤
│ 197453 │
└────────┘

```

**197,453 orders: the month twice, less the one that was deleted.** That is the most common mistake made with a
Delta table: pointing a tool that knows only Parquet at the folder. Serverless SQL in Synapse,
lesson 16, can read a folder of Parquet files and can also read the same folder as Delta, and only
the second answer is right. Every engine in the next three lessons reads the log.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two commits in _delta_log beside two Parquet files on disk. Commit 0 adds file A, Snappy, 1,205,188 bytes and 98,727 orders. Commit 1 removes A and adds B, zstd, 710,217 bytes and 98,726 orders. Both files are still on disk. A reader of the log sees version 1 as B alone, 98,726 orders; a reader of the folder sees A and B together, 197,453 orders.\" data-fig=\"l18-log\"><defs><marker id=\"l18-ah\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"/></marker></defs><text x=\"180\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">_delta_log/</text><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">on disk</text><rect x=\"20\" y=\"36\" width=\"320\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"32\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">00000000000000000000.json</text><text x=\"32\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">add A</text><text x=\"328\" y=\"72\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">version 0</text><rect x=\"20\" y=\"100\" width=\"320\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"32\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">00000000000000000001.json</text><text x=\"32\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">remove A, add B</text><text x=\"328\" y=\"136\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">version 1</text><rect x=\"400\" y=\"36\" width=\"300\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"412\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">A  …-c000.snappy.parquet</text><text x=\"412\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1,205,188 bytes, 98,727 orders</text><rect x=\"400\" y=\"100\" width=\"300\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"412\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">B  …-c000.zstd.parquet</text><text x=\"412\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">710,217 bytes, 98,726 orders</text><line x1=\"340\" y1=\"62\" x2=\"397\" y2=\"62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\" marker-end=\"url(#l18-ah)\"/><line x1=\"340\" y1=\"126\" x2=\"397\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l18-ah)\"/><rect x=\"20\" y=\"176\" width=\"330\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"185\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a reader of the log</text><text x=\"185\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">version 1 is B alone: 98,726 orders</text><rect x=\"370\" y=\"176\" width=\"330\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"535\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a reader of the folder</text><text x=\"535\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">A and B together: 197,453 orders</text></svg>", "caption": "The delete of one order as the log records it. Nothing on disk was changed or removed: a new file was added, and the log stopped naming the old one."}
```

## Why this is safe to read while it changes

**A commit is one file, and a file either exists or does not.** A writer writes its Parquet files
first, where no reader looks, and then creates the next numbered JSON file in `_delta_log`. A reader
lists the log, takes the highest number it finds, and reads exactly the files that version names.
A reader that started before the commit reads version 0 to the end; one that starts after reads
version 1. Neither ever sees half a delete.

**Two writers racing for the same number is the one hard case**, and the storage settles it: the
commit file is created only if no file of that name exists, and the loser reads what the winner did
and tries again with the next number. On a local disk and on Azure Blob Storage that "create only if
absent" is an operation the store provides, which is why `deltalake` could write to Azurite in lesson
17 with no lock service beside it.
