---
title: Deduplicating: one row per thing that happened
version: 1
---

Lesson 3 counted the events delivered twice in one day's file. Across the week the raw layer holds
every delivery, and the staging table keeps one row per event:

```
-- One row per event, however many times the collector delivered it, dated by
-- when it happened rather than by the file it landed in.
DROP TABLE IF EXISTS staging.events CASCADE;
CREATE TABLE staging.events AS
SELECT event_id, occurred_at, event_date, session, type, book_id
  FROM (SELECT doc->>'event_id'                     AS event_id,
               (doc->>'occurred_at')::timestamptz   AS occurred_at,
               ((doc->>'occurred_at')::timestamptz
                  AT TIME ZONE 'America/Sao_Paulo')::date AS event_date,
               doc->>'session'                      AS session,
               doc->>'type'                         AS type,
               (doc->>'book_id')::integer           AS book_id,
               row_number() OVER (PARTITION BY doc->>'event_id' ORDER BY file) AS copy
          FROM raw.events) AS delivered
 WHERE copy = 1;
```

The inner query numbers the copies of each `event_id` with `row_number()`, ordered by the file they
came in, and the outer one keeps copy number one. It also works out the date from `occurred_at`,
the moment the event happened — lesson 3's *event time* — rather than from the file it landed in.

```
ana@vm:~/etl$ psql -q -d wh -f sql/staging/events.sql
psql:sql/staging/events.sql:3: NOTICE:  table "events" does not exist, skipping
ana@vm:~/etl$ psql -d wh -c "SELECT (SELECT count(*) FROM raw.events) AS delivered, (SELECT count(*) FROM staging.events) AS events"
 delivered | events 
-----------+--------
     18308 |  18230
(1 row)
```

**Seventy-eight deliveries were second copies.** A count of views straight from `raw.events` would
have been 78 too high, and the error would have grown every day the pipeline ran.

## What makes two rows the same

Deduplicating needs a definition of *the same*, and that definition is the hard part:

- an identifier the producer assigned — `event_id` here. The best case: two rows with the same
  id are the same event by definition;
- every column equal — `SELECT DISTINCT`. Dangerous: two customers who really did buy the same
  book at the same second become one;
- a business key — the same ISBN from the same publisher at the same `updated_at`. Workable when
  there is no id, and it needs somebody who knows the business to say which columns make the key.

**Which copy to keep** is the second decision. For events the copies are identical, so the first
file is as good as any. For two versions of a row that differ — lesson 4's refunded order — the
rule is "the newest", and the `ORDER BY` inside `row_number()` is where that rule is written.
