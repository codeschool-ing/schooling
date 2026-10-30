---
title: Scheduled queries, for what a view cannot hold
version: 1
---

**A scheduled query is a query BigQuery runs on a timetable and writes somewhere.** It is the other way
to keep an answer ready, and the one that has no restrictions on its SQL: a median, a window function, a
join of five tables, anything that would never qualify as an incremental materialised view. The price
of that freedom is that nothing is maintained for you. The schedule runs the query, the query writes
its result, and making each run correct, complete and safe to repeat is the author's job.

Scheduled queries are a feature of the **BigQuery Data Transfer Service**, the same service that loads
data from Google Ads or Amazon S3 on a schedule, and everything here is from its documentation. None of
it was run.

## One, written down

**A scheduled query that keeps a table of median order value per district**, refreshed every night for
the day before. The SQL uses `@run_date`, a parameter the service fills with the date of each run; its companion,
`@run_time`, holds the instant the run was scheduled for:

```sql
MERGE quitanda.daily_median AS t
USING (
  SELECT dt, district,
         APPROX_QUANTILES(total_cents, 2)[OFFSET(1)] AS median_cents
  FROM quitanda.orders
  WHERE dt = DATE_SUB(@run_date, INTERVAL 1 DAY)
  GROUP BY dt, district
) AS s
ON t.dt = s.dt AND t.district = s.district
WHEN MATCHED THEN UPDATE SET median_cents = s.median_cents
WHEN NOT MATCHED THEN INSERT (dt, district, median_cents)
  VALUES (s.dt, s.district, s.median_cents);
```

**A median cannot be maintained incrementally**: the median of yesterday's orders and the median of the
day before cannot be combined into the median of both. So this is a scheduled query and not a view, and
it recomputes one day per run. **`MERGE` makes the run safe to repeat**: run twice for the same date,
it updates the rows the first run inserted rather than inserting them again. That property matters,
because the service retries and backfills, and a scheduled query that appends would count a day twice
the first time it ran twice.

The schedule is created with the `bq` command line, as you would type it and not run here:

```sh
bq mk --transfer_config --data_source=scheduled_query \
  --target_dataset=quitanda --display_name='daily median per district' \
  --schedule='every day 06:00' --location=southamerica-east1 \
  --params='{"query": "MERGE quitanda.daily_median AS t USING ( ... )"}'
```

**The query in `--params` is the `MERGE` above**, abridged here so the command fits. The schedule is
written in the service's own syntax and read in UTC unless the documentation's time-zone options say
otherwise, which is the first thing to check when a report run "at six" is three hours early for São
Paulo.

## What it costs, and what it needs

**A scheduled query is billed as the query it runs**, on demand or on a reservation, with lesson 14's
rules: this one reads three columns of one day of orders, the 10 MB minimum at Quitanda's size. The
schedule itself adds nothing to the bytes. Over a month, the cost is thirty runs of the query, and the
cost to watch is a query that reads more each night because it was written without a partition filter.

**It runs as somebody**, the user who created it or a service account, and that identity needs to read
the source and write the destination for as long as the schedule exists. A schedule created by a person
who later leaves the company stops on the day their access does; the documentation's advice to run
schedules as a service account is that lesson, learnt in advance.

**And it fails quietly unless told otherwise.** A failed run shows in the transfer's run history and
nowhere else, unless the schedule sends a notification by e-mail or to a Pub/Sub topic, which is an
option of the transfer. A dashboard reading `daily_median` the morning after a failed run shows
yesterday's medians as today's, and only a notification says otherwise.

## View or schedule

**If the SQL qualifies as an incremental materialised view, make it one**: BigQuery maintains it,
answers queries with fresh results, and rewrites queries to use it. **If it does not, schedule it**, make
each run safe to repeat, partition its output like its input so a run touches one day, and have its
failures reach a person. Lesson 24 brings Cloud Composer, which is what a chain of scheduled steps grows
into when one query's output is the next one's input.
