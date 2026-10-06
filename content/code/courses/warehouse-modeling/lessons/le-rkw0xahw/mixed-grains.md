---
title: A measure at the wrong grain
version: 1
---

The website charges R$ 14.90 for shipping on orders below R$ 150. The charge belongs to the order: one
fee per parcel, however many books are in it. The manager wants it in the sales reports, and the
obvious place is the sales table:

```sql
-- The shipping fee, copied onto every line of its order.
CREATE TABLE sales_with_shipping AS
SELECT f.*, o.shipping_cents
FROM fact_sales f JOIN staging.orders o USING (order_id);

SELECT (SELECT sum(shipping_cents) FROM sales_with_shipping)        AS summed_over_lines,
       (SELECT sum(shipping_cents) FROM staging.orders
         WHERE status <> 'cancelled')                                AS charged;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < shipping-wrong.sql
┌───────────────────┬───────────┐
│ summed_over_lines │  charged  │
│      int128       │  int128   │
├───────────────────┼───────────┤
│         236410850 │ 225246280 │
└───────────────────┴───────────┘
```

**The table now says the shop charged R$ 2,364,108.50 for shipping. It charged R$ 2,252,462.80.** The
difference, R$ 111,645.70, is the fee of every order with more than one line, counted once per line.
An order with three books carries the fee three times.

Nothing failed. The join was correct, every row is a true statement about its order, and the column
looks like every other measure in the table. The error is only visible against a total computed some
other way, which is exactly the comparison nobody runs on a busy afternoon.

**The fee has one value per order, not per line**, so it fails the test from the previous section. Two
repairs keep the numbers honest, and both appear in real warehouses:

- **Allocate it.** Split each order's fee among its lines so that the parts add back up to the fee.
  Then it *does* have one value per line, and it can be summed with everything else. The next section
  builds that.
- **Keep it at its own grain.** Shipping is charged per order, so it goes in a table whose rows are
  orders. Section 05 shows why that is also the answer for payments.
