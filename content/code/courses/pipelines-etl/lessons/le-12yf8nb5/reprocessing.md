---
title: Reprocessing a window, every night
version: 1
---

Lesson 11 left `fact_sales` replacing only its newest day, and lesson 12's drift test has failed on
most new days since, because the shop keeps changing sales for weeks after they happen. Every time,
the cure was a full refresh by hand. Two more days, and the same:

```
ana@vm:~/etl$ sudo bash ~/lab/lab.sh until 2026-03-18
ana@vm:~/etl$ python load_raw.py >/dev/null
ana@vm:~/etl/shop$ dbt build --quiet 2>&1 | grep -E "FAIL|Got"
06:56:25  14 of 14 FAIL 8 fact_sales_has_not_drifted ..................................... [FAIL 8 in 0.05s]
06:56:25    Got 8 results, configured to fail if != 0
ana@vm:~/etl$ cat shop/models/marts/fact_sales.sql
-- One row per order line sold. Each run replaces the last thirty days the table
-- already has, and every day after them: the shop changes a sale for weeks after
-- it was made, and a day outside the window is only put right by a full refresh.
{{ config(materialized='incremental',
          incremental_strategy='delete+insert',
          unique_key='order_date') }}
select order_date, order_id, line_no, shop_id, customer_id, book_id, quantity, line_cents
  from {{ ref('int_sales') }}
{% if is_incremental() %}
 where order_date >= (select max(order_date) - 30 from {{ this }})
{% endif %}
ana@vm:~/etl/shop$ dbt build -s fact_sales+ 2>&1 | grep -E " OK | PASS | FAIL |Done"
06:56:28  1 of 2 OK created sql incremental model dbt_marts.fact_sales ................... [INSERT 0 13475 in 0.19s]
06:56:28  2 of 2 PASS fact_sales_has_not_drifted ......................................... [PASS in 0.06s]
06:56:28  Done. PASS=2 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=2
```

Eight days drifted. The model's `where` is the problem: an incremental run that replaces only the
newest day is idempotent — running it twice leaves the same table — but it is not **complete**, because
the days it does not look at can still change. Ana widens what each run is responsible for to the last
thirty days, and says why in the model. That is the rest of the transcript above: the new model,
`cat` after the edit, and its first run. `INSERT 0 13475` is a month of lines
deleted and written again, and the drift test passes without a full refresh. Three more days later:

```
ana@vm:~/etl$ sudo bash ~/lab/lab.sh until 2026-03-21
ana@vm:~/etl$ python load_raw.py >/dev/null
ana@vm:~/etl/shop$ dbt build -s fact_sales+ 2>&1 | grep -E " OK | PASS | FAIL |Done"
06:56:33  1 of 2 OK created sql incremental model dbt_marts.fact_sales ................... [INSERT 0 14895 in 0.21s]
06:56:33  2 of 2 PASS fact_sales_has_not_drifted ......................................... [PASS in 0.07s]
06:56:33  Done. PASS=2 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=2
done
```

Still passing. **Reprocessing a window is the delete-and-insert shape applied to more than one
slice**: the run owns the last thirty days, deletes them and writes them again, and it can do that
every night precisely because the load is idempotent. Without that, a window would mean thirty days
loaded thirty times.

The window is a trade, and the numbers in the transcripts show both sides. Each run now writes about
fourteen thousand lines instead of a few hundred, which on this lab's data costs a fraction of a
second and on a large warehouse might cost real money — lesson 19 is about that. In exchange,
anything the shop changes within a month is right by the next morning. A change older than the
window still needs the full refresh, so the drift test stays; it simply fails rarely enough now that
when it does, it means something.

How wide to make it is a question the data answers. The drift test's failures over a few weeks showed
how far back the shop's changes reached; thirty days covers every one of them here with room to
spare. Elsewhere it could be seven days or ninety, and a refund policy is often where the number
comes from.
