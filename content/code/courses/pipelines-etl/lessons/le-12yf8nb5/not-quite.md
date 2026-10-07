---
title: What is never the same twice
version: 1
---

Some steps cannot be idempotent as written, because what they record is the act of running. Ana's
first idea for knowing when the fact table was last filled:

```
-- One row per load, so that somebody can ask when the fact table was last filled.
CREATE TABLE IF NOT EXISTS marts.load_log (loaded_day date, loaded_at timestamptz, lines bigint);
INSERT INTO marts.load_log
SELECT :'day', now(), count(*) FROM marts.fact_sales WHERE order_date = :'day';
```

```
ana@vm:~/etl$ sh twice.sh 'psql -q -d wh -v day=2026-03-16 -f load/load_log.sql' 'SELECT count(*) FROM marts.load_log'
psql:load/load_log.sql:2: NOTICE:  relation "load_log" already exists, skipping
after one run:  1
after two runs: 2
NOT idempotent
ana@vm:~/etl$ psql -d wh -c "TABLE marts.load_log"
 loaded_day |           loaded_at           | lines 
------------+-------------------------------+-------
 2026-03-16 | 2026-10-07 03:56:20.940378-03 |   448
 2026-03-16 | 2026-10-07 03:56:20.958687-03 |   448
(2 rows)
```

**Not idempotent, and correctly so.** Two loads happened, and a log of loads should say two. The
`now()` makes every row different from the last even if the counts were the same. A log is the one
kind of table where appending is the point.

Every table is one kind or the other, and the two have to be kept apart:

- **A table of facts about the world** — sales, customers, prices — must come out the same however
  many times it is loaded. Nothing in it may depend on when, or how often, the pipeline ran:
  no `now()`, no `random()`, no identity number handed out in arrival order and used as a key
  elsewhere.
- **A table of facts about the pipeline** — loads, runs, alerts — is append-only by nature, and is
  never what a report about the shop reads.

A column like `loaded_at` on a fact table is the usual way the two get mixed. It is useful, and it
makes every run's fingerprint different. The fix is not to drop it but to know it is there: the
fingerprint of an idempotent table leaves out the columns that record the run.

The same is true outside the warehouse. An e-mail, a file uploaded to a partner, a charge on a card:
each is an act, and running it twice acts twice. Lesson 14 said those belong at the end; here is why.
**They need a guard written on purpose** — a record that the e-mail for the 16th was sent, checked
before sending — because idempotency there is not a shape a load can take.
