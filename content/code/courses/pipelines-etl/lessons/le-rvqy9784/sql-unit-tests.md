---
title: A unit test for a SQL model
version: 1
---

A dbt model is code too, and its rules can be tested the same way: a few made-up input rows, and the
output they should give. dbt calls this a **unit test**, and writes it in YAML beside the model. Ana
tests the two rules in `stg_orders` that matter most and are easiest to get wrong: the day an order
belongs to, and what counts as a sale.

```
version: 2

unit_tests:
  - name: order_date_is_the_day_in_sao_paulo
    description: >
      Late on a São Paulo evening is already tomorrow in UTC; the order belongs to
      the shop's day. And only a completed order is a sale.
    model: stg_orders
    given:
      - input: source('raw', 'orders')
        rows:
          - {order_id: 1, shop_id: 1, ordered_at: "2026-03-02 23:30:00-03", status: completed}
          - {order_id: 2, shop_id: 1, ordered_at: "2026-03-03 00:10:00-03", status: completed}
          - {order_id: 3, shop_id: 7, ordered_at: "2026-03-02 12:00:00-03", status: refunded}
    expect:
      rows:
        - {order_id: 1, order_date: 2026-03-02, is_sale: true}
        - {order_id: 2, order_date: 2026-03-03, is_sale: true}
        - {order_id: 3, order_date: 2026-03-02, is_sale: false}
```

`given` replaces the model's input — here the source `raw.orders` — with three rows; columns not
listed are null. `expect` lists the rows the model should return, only in the columns named. The
three rows are chosen for the rules: half past eleven at night in São Paulo, which is already the 3rd
in UTC and must still be the 2nd; ten past midnight, which is the 3rd; and a refunded order, which is
not a sale.

```
ana@vm:~/etl/shop$ dbt test -s test_type:unit 2>&1 | grep -E "PASS|FAIL|Done"
07:30:29  1 of 1 PASS stg_orders::order_date_is_the_day_in_sao_paulo ..................... [PASS in 0.18s]
07:30:29  Done. PASS=1 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=1
```

dbt builds the model's SQL against those rows without touching the real tables, and compares. It
passes, which says the rule from lesson 6 still holds. That is worth checking because the rule is
fragile. `ordered_at::date` instead of `(ordered_at at time zone 'America/Sao_Paulo')::date` looks
almost the same, and gives the right day only while the connection's time zone happens to be São
Paulo's. On a server or a client set to UTC, it puts every late-evening sale on the next day. A unit
test is how a reviewer finds out without reading every character.

Unit tests are run with `dbt test`, but they are not data tests: they need no data in the warehouse,
and they belong in the checks run before a change is merged rather than in the nightly build —
lesson 18 puts them there.
