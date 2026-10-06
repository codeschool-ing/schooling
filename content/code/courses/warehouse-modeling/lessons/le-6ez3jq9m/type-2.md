---
title: Type 2, a new row for every version
version: 1
---

**Type 2 adds a new row when a tracked attribute changes**, and leaves the old row as it was. Each
row is one version of the customer, and carries the period it was true for. Customer number one, in
the warehouse's `dim_customer`:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT customer_key, tier, city, valid_from, valid_to, is_current FROM dim_customer WHERE customer_id = 1 ORDER BY valid_from"
┌──────────────┬─────────┬─────────┬──────────────────────────┬──────────────────────────┬────────────┐
│ customer_key │  tier   │  city   │        valid_from        │         valid_to         │ is_current │
│    int64     │ varchar │ varchar │ timestamp with time zone │ timestamp with time zone │  boolean   │
├──────────────┼─────────┼─────────┼──────────────────────────┼──────────────────────────┼────────────┤
│            1 │ reader  │ Recife  │ 2022-11-19 20:06:40-03   │ 2024-01-08 17:21:54-03   │ false      │
│            2 │ regular │ Recife  │ 2024-01-08 17:21:54-03   │ 2025-01-30 14:20:27-03   │ false      │
│            3 │ patron  │ Recife  │ 2025-01-30 14:20:27-03   │ 9999-12-31 00:00:00-03   │ true       │
└──────────────┴─────────┴─────────┴──────────────────────────┴──────────────────────────┴────────────┘
```

Three rows, three surrogate keys. Each row has:

- **`valid_from` and `valid_to`**, the period in which this version was true. The end of one is
  exactly the start of the next, so every moment belongs to one version and no moment to two.
- **`is_current`**, true on the latest version only, so "customers as they are now" is a filter
  rather than a calculation.
- **a surrogate key of its own.** This is what lesson 4 promised: one customer, several keys, and each
  sale points at the key of the version that was true when it happened.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A timeline of customer 1 from November 2022 to the present, split into three versions in dim_customer. Key 1, reader, from 19 November 2022 to 8 January 2024. Key 2, regular, from 8 January 2024 to 30 January 2025. Key 3, patron, from 30 January 2025, current. A sale on 15 March 2024 falls in the second version and points at key 2; a sale in June 2025 falls in the third and points at key 3.\"><defs><marker id=\"ah-type-2-timeline\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30.0\" y=\"60\" width=\"236.21052631578948\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"148.10526315789474\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">key 1 · reader</text><rect x=\"266.2105263157895\" y=\"60\" width=\"229.26315789473682\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"380.8421052631579\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">key 2 · regular</text><rect x=\"495.4736842105263\" y=\"60\" width=\"194.5263157894737\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"592.7368421052631\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">key 3 · patron</text><text x=\"30\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">customer 1 in dim_customer</text><line x1=\"30.0\" y1=\"102\" x2=\"30.0\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"30.0\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Nov 2022</text><line x1=\"266.2105263157895\" y1=\"102\" x2=\"266.2105263157895\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"266.2105263157895\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">8 Jan 2024</text><line x1=\"495.4736842105263\" y1=\"102\" x2=\"495.4736842105263\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"495.4736842105263\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">30 Jan 2025</text><line x1=\"316.57894736842104\" y1=\"185\" x2=\"316.57894736842104\" y2=\"106\" stroke=\"var(--paper)\" stroke-width=\"1.5\" marker-end=\"url(#ah-type-2-timeline)\"></line><text x=\"316.57894736842104\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sale, 15 Mar 2024 → key 2</text><line x1=\"573.6315789473684\" y1=\"185\" x2=\"573.6315789473684\" y2=\"106\" stroke=\"var(--paper)\" stroke-width=\"1.5\" marker-end=\"url(#ah-type-2-timeline)\"></line><text x=\"573.6315789473684\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sale, Jun 2025 → key 3</text></svg>", "caption": "Type 2: one row per version, and each sale points at the version true on its date."}
```

A sale by this customer on 15 March 2024 would point at key 2, the *regular*; one in June 2025 at
key 3, the *patron*. The fact rows never change, and the past keeps the description it had.

How many versions does that make?

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT versions, count(*) AS customers FROM (SELECT customer_id, count(*) AS versions FROM dim_customer WHERE customer_key > 0 GROUP BY customer_id) GROUP BY versions ORDER BY versions"
┌──────────┬───────────┐
│ versions │ customers │
│  int64   │   int64   │
├──────────┼───────────┤
│        1 │     32542 │
│        2 │      5686 │
│        3 │      1694 │
│        4 │        78 │
└──────────┴───────────┘
```

32,542 customers never changed anything tracked, and have one row. 5,686 have two, 1,694 three, 78
four. **The dimension grew from 40,000 rows to 49,309** (with the unknown member), about a quarter
larger, to keep two years of history. That is a typical ratio, and it is the main thing type 2 costs:
rows, and a slightly more careful join. The next section is the join.
