---
title: The transaction log
version: 1
---

Every commit is one JSON file in `_delta_log`, numbered from zero, and each line of it is one **action**.
Here is what each line of the first commit is:

```
ana@lab:~/wh$ ls lake/sales/_delta_log
00000000000000000000.json
00000000000000000001.json
ana@lab:~/wh$ jq -c 'keys[0]' lake/sales/_delta_log/00000000000000000000.json
"commitInfo"
"protocol"
"metaData"
"add"
ana@lab:~/wh$ jq -c 'select(.add) | .add | {partitionValues, size, records: (.stats | fromjson | .numRecords)}' lake/sales/_delta_log/00000000000000000001.json
{"partitionValues":{"year":"2025"},"size":5170360,"records":483410}
```

Commit 0 has four actions:

- **`commitInfo`**: who wrote it, when, with what operation, `WRITE` here, and its parameters.
- **`protocol`**: which version of the Delta protocol a reader needs to understand the table, so an old reader
  refuses a table it cannot read rather than misreading it.
- **`metaData`**: the table's schema, its partition columns and its settings.
- **`add`**: one data file joining the table.

The last command looks inside commit 1's `add` action. Beside the file's path, left out here because it is a random
name, it carries the partition value and the size of the file in bytes. It also carries **statistics**: the number of
records, and the minimum, maximum and count of empty values of each column. 483,410 records, the year 2025.

**To read the table, a reader replays the log**: start with nothing, apply each commit in order, adding and removing
files, and the set left at the end is the current table. A table with thousands of commits writes a **checkpoint**
every so often, a Parquet file holding the state as of that commit, so a reader starts from the latest checkpoint
instead of from zero.

Two consequences matter more than the details:

- **A commit is one file appearing.** Object storage can create a file atomically, and the commit numbers are
  claimed in order; if two writers try to write commit 2 at once, one succeeds and the other finds it taken, rereads,
  and retries. That is how two jobs writing one table stay consistent with no server between them.
- **The log is the table.** Delete `_delta_log` and the folder is once again a pile of Parquet files with nothing to
  say which belong together.
