---
title: Histograms, and the order on disk
version: 1
---

A list of common values cannot help with `placed_at`. No two orders were placed at the same
instant, so no value is common, and a question like "orders before 2024" is about a **range**, not
a value. For that the summary keeps a histogram, and the one PostgreSQL keeps is not the kind most
people draw.

## Equal rows, not equal widths

The histogram you would draw by hand cuts the time axis into equal pieces, one bar per month, and
counts the orders in each. PostgreSQL does the opposite. It sorts the sample, cuts it into **a
hundred buckets that hold the same number of rows**, and writes down only the values where one
bucket ends and the next begins. A hundred buckets need 101 bounds, and that list is all it keeps:

```
market=# SELECT n, b FROM pg_stats, unnest(histogram_bounds::text::timestamptz[]) WITH ORDINALITY AS u(b, n) WHERE tablename = 'orders' AND attname = 'placed_at' AND (n <= 3 OR n IN (12, 13) OR n >= 99);
  n  |               b               
-----+-------------------------------
   1 | 2023-01-06 12:21:36.107502-03
   2 | 2023-04-17 17:45:58.458055-03
   3 | 2023-06-02 20:37:50.19636-03
  12 | 2023-12-29 13:38:09.337447-03
  13 | 2024-01-14 16:08:56.040438-03
  99 | 2025-12-19 19:25:41.315086-03
 100 | 2025-12-25 08:47:22.106654-03
 101 | 2025-12-30 22:55:55.013606-03
(8 rows)

Time: 5.718 ms
```

The query unpacks `histogram_bounds` into numbered rows and keeps eight of the 101. The first
bucket runs from 6 January to 17 April 2023, **101 days**. The last runs from 25 to 30 December
2025, **five and a half days**. Both hold 1% of the orders, about 20,000, so the width of a bucket
says how sparse the orders were there: `market.sql` made each year busier than the one before, and
the buckets narrow as the orders crowd together.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A histogram of when the two million orders were placed, from 2023 to 2025, drawn the way PostgreSQL keeps it: one hundred buckets that each hold one percent of the orders. The first bucket spans 101 days of 2023 and is a low, wide bar; the last spans five and a half days at the end of 2025 and is a tall, narrow one. Every bar has the same area, and the bars rise steadily from left to right because more orders were placed each year.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">each bar holds 1% of the orders, about 20,000</text><rect x=\"53.22\" y=\"201.12\" width=\"59.11\" height=\"8.88\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"112.33\" y=\"190.52\" width=\"26.93\" height=\"19.48\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"139.26\" y=\"184.51\" width=\"20.58\" height=\"25.49\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"159.84\" y=\"180.58\" width=\"17.83\" height=\"29.42\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"177.68\" y=\"174.42\" width=\"14.75\" height=\"35.58\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"192.42\" y=\"169.56\" width=\"12.97\" height=\"40.44\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"205.39\" y=\"165.83\" width=\"11.88\" height=\"44.17\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"217.27\" y=\"173.01\" width=\"14.18\" height=\"36.99\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"231.46\" y=\"158.15\" width=\"10.12\" height=\"51.85\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"241.57\" y=\"157.17\" width=\"9.93\" height=\"52.83\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"251.5\" y=\"158.64\" width=\"10.21\" height=\"51.36\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"261.72\" y=\"154.21\" width=\"9.4\" height=\"55.79\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"271.12\" y=\"148.65\" width=\"8.55\" height=\"61.35\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"279.67\" y=\"143.56\" width=\"7.9\" height=\"66.44\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"287.57\" y=\"149.2\" width=\"8.63\" height=\"60.8\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"296.2\" y=\"142.62\" width=\"7.79\" height=\"67.38\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"303.99\" y=\"142.06\" width=\"7.72\" height=\"67.94\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"311.71\" y=\"141.08\" width=\"7.61\" height=\"68.92\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"319.32\" y=\"144.18\" width=\"7.97\" height=\"65.82\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"327.29\" y=\"138.45\" width=\"7.33\" height=\"71.55\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"334.62\" y=\"133.52\" width=\"6.86\" height=\"76.48\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"341.48\" y=\"130.22\" width=\"6.58\" height=\"79.78\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"348.06\" y=\"130.28\" width=\"6.58\" height=\"79.72\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"354.64\" y=\"134.5\" width=\"6.95\" height=\"75.5\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"361.59\" y=\"130.55\" width=\"6.6\" height=\"79.45\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"368.19\" y=\"126.65\" width=\"6.29\" height=\"83.35\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"374.49\" y=\"123.85\" width=\"6.09\" height=\"86.15\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"380.57\" y=\"124.25\" width=\"6.12\" height=\"85.75\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"386.69\" y=\"124.6\" width=\"6.14\" height=\"85.4\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"392.84\" y=\"116.35\" width=\"5.6\" height=\"93.65\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"398.44\" y=\"112.0\" width=\"5.35\" height=\"98.0\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"403.79\" y=\"125.88\" width=\"6.24\" height=\"84.12\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"410.03\" y=\"114.28\" width=\"5.48\" height=\"95.72\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"415.51\" y=\"113.2\" width=\"5.42\" height=\"96.8\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"420.93\" y=\"111.52\" width=\"5.33\" height=\"98.48\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"426.26\" y=\"108.72\" width=\"5.18\" height=\"101.28\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"431.44\" y=\"109.63\" width=\"5.23\" height=\"100.37\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"436.66\" y=\"106.02\" width=\"5.05\" height=\"103.98\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"441.71\" y=\"117.43\" width=\"5.67\" height=\"92.57\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"447.38\" y=\"102.9\" width=\"4.9\" height=\"107.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"452.27\" y=\"110.35\" width=\"5.26\" height=\"99.65\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"457.54\" y=\"107.93\" width=\"5.14\" height=\"102.07\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"462.68\" y=\"101.69\" width=\"4.84\" height=\"108.31\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"467.52\" y=\"105.68\" width=\"5.03\" height=\"104.32\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"472.55\" y=\"92.97\" width=\"4.48\" height=\"117.03\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"477.03\" y=\"106.8\" width=\"5.08\" height=\"103.2\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"482.12\" y=\"94.15\" width=\"4.53\" height=\"115.85\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"486.65\" y=\"89.23\" width=\"4.34\" height=\"120.77\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"490.99\" y=\"98.67\" width=\"4.71\" height=\"111.33\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"495.7\" y=\"86.84\" width=\"4.26\" height=\"123.16\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"499.96\" y=\"89.96\" width=\"4.37\" height=\"120.04\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"504.33\" y=\"96.42\" width=\"4.62\" height=\"113.58\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"508.95\" y=\"95.62\" width=\"4.59\" height=\"114.38\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"513.54\" y=\"89.33\" width=\"4.35\" height=\"120.67\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"517.89\" y=\"94.99\" width=\"4.56\" height=\"115.01\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"522.45\" y=\"91.24\" width=\"4.42\" height=\"118.76\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"526.87\" y=\"99.89\" width=\"4.76\" height=\"110.11\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"531.63\" y=\"86.84\" width=\"4.26\" height=\"123.16\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"535.89\" y=\"79.37\" width=\"4.02\" height=\"130.63\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"539.91\" y=\"85.88\" width=\"4.23\" height=\"124.12\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"544.13\" y=\"79.06\" width=\"4.01\" height=\"130.94\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"548.14\" y=\"85.81\" width=\"4.22\" height=\"124.19\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"552.36\" y=\"72.79\" width=\"3.82\" height=\"137.21\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"556.19\" y=\"86.77\" width=\"4.26\" height=\"123.23\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"560.44\" y=\"77.4\" width=\"3.96\" height=\"132.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"564.4\" y=\"69.97\" width=\"3.75\" height=\"140.03\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"568.15\" y=\"70.08\" width=\"3.75\" height=\"139.92\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"571.9\" y=\"75.87\" width=\"3.91\" height=\"134.13\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"575.81\" y=\"79.62\" width=\"4.02\" height=\"130.38\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"579.83\" y=\"77.73\" width=\"3.97\" height=\"132.27\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"583.8\" y=\"81.3\" width=\"4.08\" height=\"128.7\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"587.87\" y=\"78.03\" width=\"3.98\" height=\"131.97\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"591.85\" y=\"66.99\" width=\"3.67\" height=\"143.01\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"595.52\" y=\"73.06\" width=\"3.83\" height=\"136.94\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"599.35\" y=\"68.87\" width=\"3.72\" height=\"141.13\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"603.07\" y=\"82.75\" width=\"4.12\" height=\"127.25\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"607.19\" y=\"68.55\" width=\"3.71\" height=\"141.45\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"610.9\" y=\"74.03\" width=\"3.86\" height=\"135.97\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"614.76\" y=\"65.7\" width=\"3.64\" height=\"144.3\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"618.39\" y=\"53.03\" width=\"3.34\" height=\"156.97\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"621.73\" y=\"62.71\" width=\"3.56\" height=\"147.29\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"625.3\" y=\"55.98\" width=\"3.41\" height=\"154.02\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"628.7\" y=\"48.03\" width=\"3.24\" height=\"161.97\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"631.94\" y=\"57.11\" width=\"3.43\" height=\"152.89\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"635.37\" y=\"55.16\" width=\"3.39\" height=\"154.84\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"638.76\" y=\"54.06\" width=\"3.36\" height=\"155.94\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"642.13\" y=\"55.85\" width=\"3.4\" height=\"154.15\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"645.53\" y=\"66.07\" width=\"3.65\" height=\"143.93\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"649.17\" y=\"62.83\" width=\"3.56\" height=\"147.17\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"652.74\" y=\"62.17\" width=\"3.55\" height=\"147.83\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"656.29\" y=\"48.11\" width=\"3.24\" height=\"161.89\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"659.53\" y=\"50.48\" width=\"3.29\" height=\"159.52\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"662.82\" y=\"50.41\" width=\"3.29\" height=\"159.59\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"666.1\" y=\"54.61\" width=\"3.38\" height=\"155.39\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"669.48\" y=\"59.07\" width=\"3.48\" height=\"150.93\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"672.96\" y=\"58.39\" width=\"3.46\" height=\"151.61\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"676.42\" y=\"40.0\" width=\"3.09\" height=\"170.0\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"679.5\" y=\"54.71\" width=\"3.38\" height=\"155.29\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"682.88\" y=\"48.32\" width=\"3.24\" height=\"161.68\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"686.13\" y=\"49.26\" width=\"3.26\" height=\"160.74\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><path d=\"M50 210 L690 210\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M50.0 210 L50.0 215\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"50.0\" y=\"226\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">2023</text><path d=\"M263.13868613138686 210 L263.13868613138686 215\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"263.13868613138686\" y=\"226\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">2024</text><path d=\"M476.86131386861314 210 L476.86131386861314 215\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"476.86131386861314\" y=\"226\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">2025</text><path d=\"M690.0 210 L690.0 215\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"690.0\" y=\"226\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">2026</text><path d=\"M82.8 196 L82.8 120\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><text x=\"76.77525682616923\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">first bucket: 101 days</text><path d=\"M687.8 37 L687.8 28 L676.1 28\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><text x=\"672.126263855096\" y=\"28\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--amber)\">last bucket: 5.6 days</text><text x=\"50\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">placed_at</text></svg>", "caption": "The 101 bounds of orders.placed_at, as bars. Each bucket holds 1% of the orders, so a bar is tall where the orders are dense and wide where they are sparse."}
```

Drawn as bars of equal area, the 101 bounds are the shape of the business. Nothing in the table
says "orders grew every year"; the histogram found it in a sample of 30,000 rows.

## A range, estimated

Ask for the orders before 2024, and compare with the count:

```
market=# EXPLAIN SELECT * FROM orders WHERE placed_at < '2024-01-01';
                                         QUERY PLAN                                         
--------------------------------------------------------------------------------------------
 Index Scan using orders_placed_at_idx on orders  (cost=0.43..8213.26 rows=223019 width=37)
   Index Cond: (placed_at < '2024-01-01 00:00:00-03'::timestamp with time zone)
(2 rows)

Time: 1.381 ms

market=# SELECT count(*) FROM orders WHERE placed_at < '2024-01-01';
 count  
--------
 221610
(1 row)

Time: 18.928 ms
```

**223,019 estimated, 221,610 counted**, 0.6% apart. The arithmetic needs only the bounds above.
Bound 1 to bound 12 are eleven whole buckets, all before 2024: 11% of the rows. The twelfth bucket
runs from 29 December 2023 to 14 January 2024 and 2024 begins inside it, 2.4 days into a bucket
16.1 days wide. The planner assumes the rows inside a bucket are **spread evenly**, so it takes
that 15% of the bucket too: 11.15% of two million is 223,000, the number on the plan.

That evenness is the only assumption, and on a short range it is the one that shows:

```
market=# EXPLAIN SELECT * FROM orders WHERE placed_at >= '2025-06-01' AND placed_at < '2025-06-02';
                                                                       QUERY PLAN                                                                       
--------------------------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using orders_placed_at_idx on orders  (cost=0.43..127.77 rows=3117 width=37)
   Index Cond: ((placed_at >= '2025-06-01 00:00:00-03'::timestamp with time zone) AND (placed_at < '2025-06-02 00:00:00-03'::timestamp with time zone))
(2 rows)

Time: 0.761 ms
```

One day, 1 June 2025, estimated at **3117** where lesson 1 counted **2801**. The day sits inside
a bucket six and a half days wide, from 30 May to 6 June, and the planner gives it about a sixth of
the bucket's 20,000 rows. The first of June was a quieter day than the average day of its bucket,
so the estimate is 11% high.
A finer histogram would narrow the bucket, and section 05 shows the setting that buys one.

One more detail: a column that has common values keeps them out of its histogram. The list from
section 03 covers them, and the buckets share what is left, so a value is described by one of the
two and never by both.

## Correlation: where the rows sit on disk

The last number in the summary, `correlation`, is not about how many rows match. It is about
**where they are**. It compares the order of the values with the order of the rows in the table's
files: 1 means sorted the same way, 0 means no relation, -1 means sorted backwards.

Section 02 showed `placed_at` at **1** and `customer_id` at **0.0064**. Ask for about a hundred
thousand orders by each:

```
market=# EXPLAIN SELECT * FROM orders WHERE placed_at >= '2025-12-01';
                                         QUERY PLAN                                         
--------------------------------------------------------------------------------------------
 Index Scan using orders_placed_at_idx on orders  (cost=0.43..3913.06 rows=106093 width=37)
   Index Cond: (placed_at >= '2025-12-01 00:00:00-03'::timestamp with time zone)
(2 rows)

Time: 2.094 ms

market=# EXPLAIN SELECT * FROM orders WHERE customer_id <= 10000;
                                         QUERY PLAN                                          
---------------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=1271.92..19228.42 rows=103160 width=37)
   Recheck Cond: (customer_id <= 10000)
   ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..1246.13 rows=103160 width=0)
         Index Cond: (customer_id <= 10000)
(4 rows)

Time: 0.886 ms
```

Two conditions that each return about 5% of the table, 106,093 and 103,160 rows estimated, and two
different plans. For `placed_at` the planner chose a plain index scan and costed it at **3,913**.
For `customer_id` it built a bitmap first and costed it at **19,228**, five times more.

The rows are the reason. The orders of December 2025 sit next to each other at the end of the
table, because they were written in that order, so an index scan reading them in `placed_at` order
reads each page of the table once, in sequence. The orders of customers 1 to 10,000 are scattered
across every part of the table, and reading them in `customer_id` order would jump from page to
page and come back to the same page many times. The planner prices that jumping through
`correlation`, and lesson 4's bitmap scan is its way of avoiding it: collect the pages first, sort
them, read each one once.

Correlation is also what makes lesson 8's BRIN index possible. It only works on a column whose
values follow the table's physical order, and `correlation` is where you check that before you
build one.
