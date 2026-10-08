---
title: Full or incremental, table by table
version: 1
---

**The choice is made per table, not per pipeline.** Ponto Final's nightly extraction ends up with
both kinds side by side, because its tables are not alike:

| table | size and growth | deletes? | extraction |
|---|---|---|---|
| `shops` | 7 rows, fixed | no | full |
| `books` | 1,200 rows, slow | no | full |
| `customers` | 5,000 rows, +20 a day | yes, erasures | full |
| `orders` | 17,000 rows, +300 a day | no | incremental, with a lookback |
| `order_lines` | 26,000 rows, +450 a day | no | incremental, by its order's `updated_at` |
| `payments` | 17,000 rows, +300 a day | no | incremental |

`order_lines` has no `updated_at` of its own. A line is never changed after it is written, so the
extraction takes the lines of every order that changed, and a refund re-reads that order's lines
too — a few extra rows, which the latest-version view collapses.

Three questions decide each row of a table like that:

1. **Is it small, and will it stay small?** Then reload it whole and stop thinking about it.
2. **Can the source say what changed?** A trustworthy `updated_at`, indexed, set by every write. If
   not, a full load or the database's log.
3. **Does the source delete rows, and does it matter?** If it does, an incremental load needs
   something beside it — a full load of the keys, or the log.

**And write the answer down next to the table**, with the reason. The next person to look at a
nightly job that reloads `customers` whole will want to make it incremental, and the reason it is
not — the erasures — is not visible in the code.
