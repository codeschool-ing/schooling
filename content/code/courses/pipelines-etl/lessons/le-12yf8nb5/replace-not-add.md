---
title: Replace, don't add
version: 1
---

The real `fact_sales.sql`, run twice on the same day:

```
ana@vm:~/etl$ psql -q -d wh -v day=2026-03-16 -f load/fact_sales.sql
psql:load/fact_sales.sql:10: NOTICE:  relation "fact_sales" already exists, skipping
ana@vm:~/etl$ psql -d wh -v day=2026-03-16 -f fingerprint.sql
 lines |           fingerprint            
-------+----------------------------------
   448 | c5aa6b634e10684f652731525f1e420f
(1 row)

ana@vm:~/etl$ psql -q -d wh -v day=2026-03-16 -f load/fact_sales.sql
psql:load/fact_sales.sql:10: NOTICE:  relation "fact_sales" already exists, skipping
ana@vm:~/etl$ psql -d wh -v day=2026-03-16 -f fingerprint.sql
 lines |           fingerprint            
-------+----------------------------------
   448 | c5aa6b634e10684f652731525f1e420f
(1 row)
```

448 lines, the same fingerprint as before the naive load, and the same again after a second run —
the triple-loaded day included, since the first `DELETE` removed all 1,344 lines. (The `NOTICE` is
the `CREATE TABLE IF NOT EXISTS` at the top of the file finding the table there.) The load is
idempotent because of one decision: **it does not add the day, it replaces it**. Delete everything
the load is about to write, then write it, in one transaction.

That is one of three shapes an idempotent load can take, and between them they cover almost every
load in this course:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l15-shapes\" aria-label=\"Three shapes of idempotent load, each run twice. Delete then insert: the slice the run owns is removed and written again, so the second run leaves the same slice. Upsert: each row is written by its key, so the second run updates rows to the values they already have. Rebuild and swap: the whole result is built beside the old one and put in its place, so the second run builds the same result again.\"><rect x=\"20.0\" y=\"20.0\" width=\"216.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"128.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">delete, then insert</text><text x=\"128.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">by the slice the run owns</text><text x=\"128.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">fact_sales.sql · delete+insert</text><text x=\"128.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">second run:</text><text x=\"128.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the same slice again</text><rect x=\"252.0\" y=\"20.0\" width=\"216.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">upsert by key</text><text x=\"360.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">INSERT … ON CONFLICT</text><text x=\"360.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">dim_book</text><text x=\"360.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">second run:</text><text x=\"360.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">every key already there</text><rect x=\"484.0\" y=\"20.0\" width=\"216.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"592.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">rebuild and swap</text><text x=\"592.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">build beside, then rename</text><text x=\"592.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dbt's table</text><text x=\"592.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">second run:</text><text x=\"592.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the same table again</text></svg>", "caption": "Each shape answers the same question: why would a second run write the same rows rather than more?"}
```

- **Delete, then insert**, by a key that names everything the run is responsible for: the day in
  `fact_sales.sql`, the `order_date` in dbt's `delete+insert`. Right when a run owns a whole slice —
  a day, a shop, a file.
- **Upsert**, by the row's own key: `INSERT … ON CONFLICT DO UPDATE`, as `dim_book` does since lesson
  7. Right when rows arrive one by one and each has an identity. A second run finds every key
  already there and updates it to the value it already has.
- **Rebuild and swap**: build the whole result beside the old one, then replace it in one step, as a
  dbt `table` does with its `__dbt_tmp`. Right when the result is small enough to build whole, and
  the simplest of the three to get right.

What all three avoid is the plain `INSERT` of rows that may already be there. The question to ask of
any load is: **if this ran a second time, right now, what would make it write the same rows rather
than more?** If the answer is *nothing*, the load is not idempotent, however carefully it was
written.
