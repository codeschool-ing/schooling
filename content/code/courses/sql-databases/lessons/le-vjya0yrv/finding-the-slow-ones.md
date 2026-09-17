---
title: Which query is the slow one
version: 1
---

The lesson before this one ended on a rule: add an index because you looked. This lesson is the
looking, and it starts one step earlier than most people do — before you can read a plan, you have
to know **which** query to read the plan of.

The wrong way to find it is to wait for a complaint. The complaint names a screen, the screen runs
six queries, and the one that is slow is not the one the person guessed. The right way is to ask
the database, which has been counting.

## The database keeps the score

PostgreSQL's `pg_stat_statements` extension records every distinct statement the server has run,
with how many times and for how long. It has to be loaded at start-up — `shared_preload_libraries`
in the configuration — and then it is a table you can query like any other.

Here it is on the shop from lesson 1, after a morning's worth of traffic:

```
shop=# SELECT calls, round(total_exec_time::numeric) AS total_ms, round(mean_exec_time::numeric, 1) AS mean_ms, left(query, 55) AS query FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 5;
 calls | total_ms | mean_ms |                          query                          
-------+----------+---------+---------------------------------------------------------
     3 |     1096 |   365.3 | SELECT c.city, count(*) FROM customers c JOIN orders o 
    30 |      890 |    29.7 | SELECT count(*) FROM orders WHERE status = $1
     1 |      115 |   114.7 | SELECT * FROM orders WHERE date(placed_at) = DATE $1
   400 |       24 |     0.1 | SELECT id, name FROM customers WHERE email = $1
   150 |       18 |     0.1 | SELECT id, total FROM orders WHERE customer_id = $1
(5 rows)
```

Three things to read off that table, and they are the three things the tool exists for.

**The literals are gone.** `WHERE email = $1`, not `WHERE email = 'ana@example.com'`. Four hundred
lookups by four hundred different addresses are one row, because they are one query — which is
what you want when the question is "what is this application doing", and it is why the tool is
worth more than the log below.

**Sort by total, not by mean.** The report at the top runs three times and costs a second in
total. The count by status is twelve times faster per call and still second on the list, because it
ran thirty times. A query at one millisecond that runs a million times a day is a thousand seconds
of database time, and it never appears in anybody's complaint.

**The mean is the other list**, and it is where a user's experience lives:

```
shop=# SELECT calls, round(mean_exec_time::numeric, 1) AS mean_ms, left(query, 55) AS query FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 3;
 calls | mean_ms |                          query                          
-------+---------+---------------------------------------------------------
     3 |   365.3 | SELECT c.city, count(*) FROM customers c JOIN orders o 
     1 |   114.7 | SELECT * FROM orders WHERE date(placed_at) = DATE $1
    30 |    29.7 | SELECT count(*) FROM orders WHERE status = $1
(3 rows)
```

The `date(placed_at)` query ran once and took a tenth of a second. Somebody waited for that.
Lesson 9 said why it is slow, and the section on estimates in this lesson shows what the plan says
about it.

Two lists, two questions: **what is costing the server the most**, and **what is costing a person
the most**. Work the first when the machine is busy and the second when somebody is unhappy, and
check both, because they disagree more often than not.

## The log, for the ones that are only sometimes slow

`pg_stat_statements` averages. A query that is fast a thousand times and takes ten seconds once is
a fast query on that table. The other tool catches the once:

```
log_min_duration_statement = 250ms
```

Every statement slower than the threshold is written to the log with its duration and its full
text, literals included:

```
2026-09-17 23:02:51.164 UTC [4335] postgres@shop LOG:  duration: 369.678 ms  statement: SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city;
2026-09-17 23:02:51.594 UTC [4337] postgres@shop LOG:  duration: 398.804 ms  statement: SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city;
```

The literals are the point here. When a query is slow only for one customer, the log has the
customer, and the plan you take next has to be run with that value and not with a placeholder.
A plan for `$1` is a plan for nobody in particular, and the section on estimates says why that can
be a different plan.

Where to set the threshold is a decision, and a low one on a busy server writes a log faster than
anybody reads it. A few hundred milliseconds is where most people start, and it comes down as the
obvious ones are fixed.

MySQL has the same two tools under other names: the slow query log, with `long_query_time`, and
the `performance_schema` tables, which `sys.statement_analysis` summarises in the same shape as
the table above. Lesson 12 has the differences.

## What you now have

A query, with the value it was slow for, and a number for how slow. That is the input to
everything else in this lesson, and it is worth insisting on: **a plan without a measurement to
compare it against is a plan you cannot tell you have improved.**
