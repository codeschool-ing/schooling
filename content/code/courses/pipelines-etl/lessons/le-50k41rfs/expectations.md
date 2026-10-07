---
title: Expectations: what usually happens
version: 1
---

Some problems break no rule. A day with a fifth of its events has no null, no duplicate, no wrong
type; every row in it is a perfectly good event. What is wrong is **how many** there are, and the
only way to see that is to compare with what usually happens. That is an **expectation**: not a rule
the data must obey, but a range it is expected to fall in, where falling outside is worth a person's
look.

Ana adds the website's events to the dbt project — a source, and a staging model that is lesson 6's
`staging/events.sql` with `source` in it — and an expectation on their daily volume:

```
version: 2

sources:
  - name: raw                   # what load_raw.py copies in: dbt reads it, never writes it
    schema: raw
    tables:
      - name: orders
      - name: order_lines
      - name: books
      - name: events
```

```
-- One row per website event, however many times the collector delivered it,
-- dated by when it happened in São Paulo.
select event_id, occurred_at, event_date, session, type, book_id
  from (select doc->>'event_id'                   as event_id,
               (doc->>'occurred_at')::timestamptz as occurred_at,
               ((doc->>'occurred_at')::timestamptz
                  at time zone 'America/Sao_Paulo')::date as event_date,
               doc->>'session'                    as session,
               doc->>'type'                       as type,
               (doc->>'book_id')::integer         as book_id,
               row_number() over (partition by doc->>'event_id' order by file) as copy
          from {{ source('raw', 'events') }}) as delivered
 where copy = 1
```

```
-- An expectation, not a rule: each day of March has between half and twice the
-- events of the seven days before it, on average. A day outside that range is
-- not impossible, but it is worth a person's look before anything is built on it.
with daily as (
    select event_date, count(*) as events
      from {{ ref('stg_events') }}
     group by 1
), compared as (
    select event_date, events,
           avg(events) over (order by event_date rows between 7 preceding and 1 preceding)
             as usual
      from daily
)
select event_date, events, round(usual) as usual
  from compared
 where event_date >= date '2026-03-01'
   and (events < usual / 2 or events > usual * 2)
```

Each day is compared with the average of the seven before it, and any day below half or above
double is returned. On the month so far, nothing is:

```
ana@vm:~/etl/shop$ dbt build -s stg_events+ 2>&1 | grep -E " OK | PASS | FAIL |Done"
07:03:50  1 of 2 OK created sql view model dbt_staging.stg_events ........................ [CREATE VIEW in 0.13s]
07:03:50  2 of 2 PASS event_volume_is_plausible .......................................... [PASS in 0.18s]
07:03:50  Done. PASS=2 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=2
```

Then an incident, staged and said so: the collector delivers only the first part of the 20th's file,
four hundred lines where a day has two and a half thousand, and stops. Nothing errors. The file is
valid JSON, every event in it is real, and the load and the view both succeed:

```
ana@vm:~/etl$ wc -l landing/events/2026-03-19.jsonl landing/events/2026-03-20.jsonl
  2589 landing/events/2026-03-19.jsonl
   400 landing/events/2026-03-20.jsonl
  2989 total
ana@vm:~/etl$ python load_raw.py >/dev/null
ana@vm:~/etl/shop$ dbt build -s stg_events+ 2>&1 | grep -E " OK | PASS | FAIL |Done"
07:03:54  1 of 2 OK created sql view model dbt_staging.stg_events ........................ [CREATE VIEW in 0.10s]
07:03:54  2 of 2 FAIL 1 event_volume_is_plausible ........................................ [FAIL 1 in 0.16s]
07:03:54  Done. PASS=1 WARN=0 ERROR=1 SKIP=0 NO-OP=0 REUSED=0 TOTAL=2
ana@vm:~/etl$ psql -d wh -f shop/target/compiled/shop/tests/event_volume_is_plausible.sql
 event_date | events | usual 
------------+--------+-------
 2026-03-20 |    399 |  2476
(1 row)

done
```

**The expectation caught what nothing else could**: 399 events on the 20th where about 2,476 is
usual. Running the compiled test in `psql` shows the day and both numbers, which is what Ana sends to
whoever runs the collector. Without it, the 20th would have gone into every report as the quietest
day of the month on the website.

Expectations need care in a way rules do not. Real days vary — a holiday, a sale, a newsletter — and
an expectation tight enough to catch every incident will also fire on good news. **Half to double**
is loose on purpose. A failure here is a question, as lesson 12 said of every failure: sometimes the
answer is *it was Black Friday*. Libraries such as Great Expectations and Soda exist to write many
checks like this one with less SQL; none is installed in the lab, and the lesson does not run one.
