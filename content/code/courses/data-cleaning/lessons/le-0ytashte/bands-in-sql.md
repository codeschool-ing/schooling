---
title: Bands in SQL
version: 1
---

SQL has two ways to band a number. The general one is a `CASE`, one branch per band, which is what
you write when the edges are irregular or have names:

```sql
CASE WHEN age < 25 THEN '18-24'
     WHEN age < 35 THEN '25-34'
     ELSE '35+' END
```

Each `WHEN` is tested in order, so writing the bands from the bottom up with `<` gives the same
closed-on-the-left bands as `right=False` in pandas. Writing them with `<=` gives the default
`pd.cut` bands, with 25 in the first one. **Pick one convention and use it in both tools**, or the
same customer will be in different bands in the dashboard and in the notebook.

The other is `width_bucket`, for bands of equal width. It takes the value, the low and high edges,
and how many buckets to cut between them, and it does something `pd.cut` does not: it numbers what
falls outside.

```
ana@lab:~/clean$ psql -c "SELECT width_bucket(total::numeric, 0, 200, 4) AS bucket, min(total::numeric), max(total::numeric), count(*) FROM (SELECT DISTINCT * FROM raw.orders) o GROUP BY 1 ORDER BY 1"
 bucket |  min   |   max    | count 
--------+--------+----------+-------
      0 | -17.05 |    -0.10 |   137
      1 |   0.25 |    49.95 | 12176
      2 |  50.00 |    99.95 |  8469
      3 | 100.00 |   149.95 |  3085
      4 | 150.00 |   199.95 |  1597
      5 | 200.00 | 26928.50 |  3062
(6 rows)
```

Buckets 1 to 4 are R$ 50 wide, from 0 to 200, each closed on the left. **Bucket 0 holds everything
below the low edge** and bucket 5 everything at or above the high one, so no value disappears.
Here bucket 0 is the 137 orders with a negative total, the coupons larger than the basket that
lesson 9 decided to read as charged nothing, and bucket 5 is 3,062 orders of R$ 200 or more, up to
the clinic's R$ 26,928.50.

That overflow behaviour is the useful part. A banding that tells you how much fell off each end is
a banding that checks its own edges, the same job the `if` in `bands.py` does by hand.
