---
title: What goes wrong with type 2, and how to catch it
version: 1
---

A type 2 dimension can be wrong in ways that leave every query running. Three properties must hold for
every customer, and each is one query to check:

- **exactly one current row**;
- **no two versions overlapping in time**, or a fact at the overlap would match two rows and be
  counted twice;
- **no gap between one version's end and the next one's start**, or a fact in the gap would match no
  row and fall out of the join.

```sql
-- Three things every type 2 dimension must satisfy, checked.
SELECT
  (SELECT count(*) FROM (SELECT customer_id FROM dim_customer WHERE is_current
                         GROUP BY customer_id HAVING count(*) <> 1))       AS not_one_current,
  (SELECT count(*) FROM dim_customer a JOIN dim_customer b
     ON a.customer_id = b.customer_id AND a.customer_key < b.customer_key
    AND a.valid_from < b.valid_to AND b.valid_from < a.valid_to)            AS overlapping_pairs,
  (SELECT count(*) FROM (SELECT valid_to, lead(valid_from) OVER
                           (PARTITION BY customer_id ORDER BY valid_from) AS next_from
                         FROM dim_customer WHERE customer_key > 0)
    WHERE next_from IS NOT NULL AND next_from <> valid_to)                AS gaps;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < checks.sql
┌─────────────────┬───────────────────┬───────┐
│ not_one_current │ overlapping_pairs │ gaps  │
│      int64      │       int64       │ int64 │
├─────────────────┼───────────────────┼───────┤
│               0 │                 0 │     0 │
└─────────────────┴───────────────────┴───────┘
```

Three zeros. That query belongs in the load, run after every load, failing it if any number is not zero.
It is how the warehouse finds out before the manager does.

## Four ways the zeros stop being zeros

**Two changes in one period.** A snapshot only sees the state at each extract. Customer 1225 moved
from Brasília to Maringá on 28 November 2025 and became a regular on the 30th:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT customer_id, changed_at, field, old_value, new_value FROM staging.customer_changes WHERE customer_id IN (SELECT customer_id FROM staging.customer_changes WHERE field IN ('tier', 'city', 'state') AND changed_at >= '2025-11-01' AND changed_at < '2025-12-01' GROUP BY customer_id HAVING count(DISTINCT changed_at) > 1) ORDER BY changed_at"
┌─────────────┬──────────────────────────┬─────────┬───────────┬───────────┐
│ customer_id │        changed_at        │  field  │ old_value │ new_value │
│    int64    │ timestamp with time zone │ varchar │  varchar  │  varchar  │
├─────────────┼──────────────────────────┼─────────┼───────────┼───────────┤
│        1225 │ 2025-11-28 18:47:05-03   │ city    │ Brasília  │ Maringá   │
│        1225 │ 2025-11-28 18:47:05-03   │ state   │ DF        │ PR        │
│        1225 │ 2025-11-30 19:16:04-03   │ tier    │ reader    │ regular   │
└─────────────┴──────────────────────────┴─────────┴───────────┴───────────┘
```

The December extract shows both changes at once, and `dim_customer_m` records one version starting on 1
December. Two days of being a reader in Maringá are gone, and the move is dated three days late. The
change log keeps them; a snapshot cannot. **The coarser the snapshot, the more of this there is**, and
the only cure is a better source: a log, or change data capture.

**A fact that arrives late.** A sale from last week loaded today must get the version that was true
last week, not the current one. The load in lesson 2 joins on the time of the order, so it does this
right; a load that looked up `is_current` would not.

**A change that arrives late.** The source reports a move that happened two months ago. The new version
should start two months ago, the old version should be shortened, and the sales in between should point
at the new key. That means updating fact rows, which is expensive and is the reason some teams accept
the change as of the day they learned of it, and write that down.

**A customer deleted at the source.** A snapshot that no longer contains a customer does not mean they
stopped existing in the past. The usual answer is to close their current version and leave their
history, never to delete rows that facts point at.
