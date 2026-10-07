---
title: The date is a dimension, not a column
version: 2
---

`fact_sales` has a `date_key` rather than a date, and points it at a table with a row for every day.
It looks like a detour, since every database can take the month out of a date. The table exists for
everything a date function cannot work out. This is `dim_date.sql`:

```sql
-- One row per calendar day of the period, and one for a date not reached yet.
CREATE TABLE dim_date AS
WITH days AS (
    SELECT CAST(d AS DATE) AS date
    FROM range(DATE '2024-01-01', DATE '2026-01-01', INTERVAL 1 DAY) AS t(d)
),
holidays (date, holiday) AS (VALUES
    (DATE '2024-01-01', 'New Year'),          (DATE '2024-03-29', 'Good Friday'),
    (DATE '2024-04-21', 'Tiradentes'),        (DATE '2024-05-01', 'Labour Day'),
    (DATE '2024-09-07', 'Independence Day'),  (DATE '2024-10-12', 'Our Lady of Aparecida'),
    (DATE '2024-11-02', 'All Souls'),         (DATE '2024-11-15', 'Republic Day'),
    (DATE '2024-11-20', 'Black Consciousness'), (DATE '2024-12-25', 'Christmas'),
    (DATE '2025-01-01', 'New Year'),          (DATE '2025-04-18', 'Good Friday'),
    (DATE '2025-04-21', 'Tiradentes'),        (DATE '2025-05-01', 'Labour Day'),
    (DATE '2025-09-07', 'Independence Day'),  (DATE '2025-10-12', 'Our Lady of Aparecida'),
    (DATE '2025-11-02', 'All Souls'),         (DATE '2025-11-15', 'Republic Day'),
    (DATE '2025-11-20', 'Black Consciousness'), (DATE '2025-12-25', 'Christmas')
)
SELECT CAST(strftime(date, '%Y%m%d') AS INTEGER) AS date_key,
       date,
       year(date)                  AS year,
       quarter(date)               AS quarter,
       month(date)                 AS month,
       monthname(date)             AS month_name,
       day(date)                   AS day_of_month,
       isodow(date)                AS day_of_week,
       dayname(date)               AS day_name,
       isodow(date) >= 6           AS is_weekend,
       holiday IS NOT NULL         AS is_holiday,
       coalesce(holiday, '')       AS holiday
FROM days LEFT JOIN holidays USING (date)
UNION ALL
SELECT 0, NULL, NULL, NULL, NULL, 'Not yet', NULL, NULL, 'Not yet', NULL, NULL, ''
ORDER BY date_key;
```

Three rows of it:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT * FROM dim_date WHERE date_key IN (0, 20250418, 20250419)"
┌──────────┬────────────┬───────┬─────────┬───────┬────────────┬──────────────┬─────────────┬──────────┬────────────┬────────────┬─────────────┐
│ date_key │    date    │ year  │ quarter │ month │ month_name │ day_of_month │ day_of_week │ day_name │ is_weekend │ is_holiday │   holiday   │
│  int32   │    date    │ int64 │  int64  │ int64 │  varchar   │    int64     │    int64    │ varchar  │  boolean   │  boolean   │   varchar   │
├──────────┼────────────┼───────┼─────────┼───────┼────────────┼──────────────┼─────────────┼──────────┼────────────┼────────────┼─────────────┤
│        0 │ NULL       │  NULL │    NULL │  NULL │ Not yet    │         NULL │        NULL │ Not yet  │ NULL       │ NULL       │             │
│ 20250418 │ 2025-04-18 │  2025 │       2 │     4 │ April      │           18 │           5 │ Friday   │ false      │ true       │ Good Friday │
│ 20250419 │ 2025-04-19 │  2025 │       2 │     4 │ April      │           19 │           6 │ Saturday │ true       │ false      │             │
└──────────┴────────────┴───────┴─────────┴───────┴────────────┴──────────────┴─────────────┴──────────┴────────────┴────────────┴─────────────┘
```

**A holiday is not in the calendar's arithmetic.** Good Friday moves every year, and whether a day is
a holiday in Brazil is a fact that somebody writes down — here, twenty rows of `VALUES`. Written once,
it is a column every fact table can group by. Without the table, it is a list every analyst keeps in
their own query, and no two lists agree.

With it, a question like "do the shops sell more on a holiday?" is one join:

```sql
-- Revenue per shop-day in physical shops: holidays against ordinary days.
SELECT d.is_holiday,
       count(DISTINCT (f.date_key, f.shop_key))             AS shop_days,
       round(sum(f.net_cents) / 100 / count(DISTINCT (f.date_key, f.shop_key)), 2)
                                                            AS brl_per_shop_day
FROM fact_sales f
JOIN dim_date d USING (date_key)
JOIN dim_shop s USING (shop_key)
WHERE s.channel = 'store' AND NOT d.is_weekend
GROUP BY d.is_holiday
ORDER BY d.is_holiday;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < holidays.sql
┌────────────┬───────────┬──────────────────┐
│ is_holiday │ shop_days │ brl_per_shop_day │
│  boolean   │   int64   │      double      │
├────────────┼───────────┼──────────────────┤
│ false      │      2763 │         13018.08 │
│ true       │        44 │         13461.74 │
└────────────┴───────────┴──────────────────┘
```

On a weekday holiday a physical shop took R$ 13,461.74 on average, against R$ 13,018.08 on an
ordinary weekday: slightly more, over 44 shop-days of holiday. The query reads like the question.
The fiscal year, the school holidays, the week of Black Friday and the day the shop changed its
prices would each be one more column, written once.

## The row for a date that has not happened

The first of the three rows has `date_key` 0 and says `Not yet`. **It stands for a date that does not
exist yet**: section 09 has a parcel that has shipped and not arrived, and its delivery date points
here instead of at nothing. A fact that points at nothing drops out of every inner join, and a count
of parcels by delivery month would quietly lose the ones still on the road.

## Why an integer key like `20250418`

It sorts like a date, it is readable in a fact row without a join, and it is four bytes. It is the
one key in the warehouse that is allowed to mean something, because a calendar day does not change
its identity. Lesson 4 is about why every other key must not.
