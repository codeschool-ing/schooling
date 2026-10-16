---
title: The number in the agreement
version: 1
---

A provider's **service level agreement** (SLA) promises an availability, a percentage of the month in
which the service answers. The percentages look alike, so turn them into time:

```
shop=# SELECT p AS availability, justify_interval(interval '30 days' * (1 - p / 100)) AS down_per_month, justify_interval(interval '365 days' * (1 - p / 100)) AS down_per_year FROM (VALUES (99.0), (99.9), (99.95), (99.99)) AS t(p);
 availability | down_per_month |  down_per_year  
--------------+----------------+-----------------
         99.0 | 07:12:00       | 3 days 15:36:00
         99.9 | 00:43:12       | 08:45:36
        99.95 | 00:21:36       | 04:22:48
        99.99 | 00:04:19.2     | 00:52:33.6
(4 rows)
```

**99.95%**, a common figure for a database with a standby in a second data centre, allows **21
minutes and 36 seconds** of downtime a month, more than four hours a year. 99.99% allows four minutes a
month, about as long as one failover with everybody reconnecting. These are budgets the provider is
allowed to spend, not predictions.

## In a chain

An application needs the database **and** everything between them: its own servers, the network, the
DNS. Availabilities in a chain multiply:

```
shop=# SELECT round(99.95 * 99.95 / 100, 4) AS database_and_app, round(99.95 * 99.95 * 99.9 / 10000, 4) AS with_a_network_link;
 database_and_app | with_a_network_link 
------------------+---------------------
          99.9000 |             99.8001
(1 row)

shop=# SELECT justify_interval(interval '30 days' * (1 - 99.95 * 99.95 * 99.9 / 1000000)) AS down_per_month;
 down_per_month  
-----------------
 01:26:20.760648
(1 row)
```

Two components at 99.95% each give 99.90% together; add a network link at 99.9% and the whole is
**99.80%**, nearly an hour and a half a month. The database's number is an upper bound on what the
application can have, never what it will have.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Three boxes in a row joined by arrows: the application at 99.95%, the network at 99.9% and the managed database at 99.95%. Below them, a bracket over all three reads 99.80% together, about 1 hour 26 minutes of downtime a month.\"><defs><marker id=\"l21c-pa\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"180\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">application</text><text x=\"110\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">99.95%</text><rect x=\"270\" y=\"30\" width=\"180\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">network</text><text x=\"360\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">99.9%</text><rect x=\"520\" y=\"30\" width=\"180\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">managed database</text><text x=\"610\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">99.95%</text><path d=\"M202 60 L268 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l21c-pa)\"></path><path d=\"M452 60 L518 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l21c-pa)\"></path><path d=\"M20 108 L20 116 L700 116 L700 108\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"360\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">together: 99.80%, about 1 h 26 min down a month</text></svg>", "caption": "Availabilities in a chain multiply. The database's number is an upper bound on the application's, never what the application gets."}
```

## What the agreement pays

When the provider misses its number, the agreement pays a **service credit**: a percentage of that
month's bill for that service, against future bills, usually on request and within a deadline:

```
shop=# SELECT 2000.00 AS monthly_bill, 2000.00 * 0.10 AS credit_at_10_percent, interval '3 hours' AS outage, 50000 AS orders_per_day, round(50000 / 24.0 * 3) AS orders_not_taken;
 monthly_bill | credit_at_10_percent |  outage  | orders_per_day | orders_not_taken 
--------------+----------------------+----------+----------------+------------------
      2000.00 |             200.0000 | 03:00:00 |          50000 |             6250
(1 row)
```

A three-hour outage costs a shop that takes 50,000 orders a day about **6,250 orders** not taken, and
the agreement returns 10% of a 2,000 bill. **An SLA is a promise about the provider's revenue, not
about yours.** It tells you how often to expect trouble; it is not insurance against it, and
lesson 8's RPO and RTO are still numbers you have to meet with things you control.
