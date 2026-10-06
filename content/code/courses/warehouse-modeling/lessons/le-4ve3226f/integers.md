---
title: Integers in as few bits as they need
version: 1
---

Every integer column of `fact_sales` is declared as a 64-bit integer, eight bytes. Look at how much of
that eight bytes each one needs:

```sql
-- The range of values in some integer columns, and the bits that range needs.
SELECT 'quantity' AS column_name, min(quantity) AS lowest, max(quantity) AS highest,
       ceil(log2(max(quantity) - min(quantity) + 1)) AS bits_needed FROM fact_sales
UNION ALL
SELECT 'shop_key', min(shop_key), max(shop_key),
       ceil(log2(max(shop_key) - min(shop_key) + 1)) FROM fact_sales
UNION ALL
SELECT 'order_id', min(order_id), max(order_id),
       ceil(log2(max(order_id) - min(order_id) + 1)) FROM fact_sales;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < ints.sql
┌─────────────┬────────┬─────────┬─────────────┐
│ column_name │ lowest │ highest │ bits_needed │
│   varchar   │ int64  │  int64  │   double    │
├─────────────┼────────┼─────────┼─────────────┤
│ quantity    │      1 │       3 │         2.0 │
│ shop_key    │      1 │       7 │         3.0 │
│ order_id    │ 100001 │  677468 │        20.0 │
└─────────────┴────────┴─────────┴─────────────┘
```

`quantity` is always 1, 2 or 3: two bits of information, stored in sixty-four. `shop_key` needs three.
Even `order_id`, which runs past half a million, varies across a range that fits in twenty bits once its
smallest value is subtracted.

Two techniques together take advantage of that:

- **Frame of reference.** Store the block's minimum once, and each value as its distance from it.
  `order_id` 677,468 becomes 577,467 above a base of 100,001, a smaller number to store.
- **Bit-packing.** Store each value in exactly as many bits as the largest one in the block needs, packed
  together with no padding. A block of quantities becomes a stream of 2-bit numbers, thirty-two to every
  eight bytes.

That is the `BitPacking` that DuckDB reported for most columns. The Parquet metadata of the previous
section shows the same idea at work: `quantity` takes 116,206 bytes for 887,477 values, about one bit each,
where the type would have taken sixty-four.

**The declared type does not decide the storage.** Choosing `BIGINT` for a column of small numbers costs
almost nothing in a column store, because the encoding looks at the values. In a row store it costs the full
eight bytes per row, every row, which is one of the reasons lesson 6's tables were three times larger in
PostgreSQL.
