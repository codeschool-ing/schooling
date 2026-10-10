---
title: pg_stat_statements
version: 1
---

```sql
-- workload.sql: three queries an application might send to shop, for pgbench
\set cid random(1, 50000)
SELECT id, status, total_cents FROM orders WHERE customer_id = :cid ORDER BY created_at DESC LIMIT 10;
SELECT name, country FROM customers WHERE id = :cid;
SELECT count(*) FROM orders WHERE status = 'cancelled' AND total_cents > 49000;
```
