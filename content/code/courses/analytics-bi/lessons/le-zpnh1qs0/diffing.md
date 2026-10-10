---
title: Sending only what changed
version: 1
---

Run the sync again, straight away:

```
ana@vm:~/reverse$ bash sync.sh
run 2: sent 0, removed 0, failed 0, retried after 429: 0
```

Nothing sent. That is the most important behaviour of the script, and it comes from one clause in its
first query: `WHERE s.payload IS DISTINCT FROM row_to_json(m)::jsonb`. The model is computed afresh,
each row is compared with what `last_sent` says was last accepted, and only the rows that differ are
sent. **A sync that resends everything every time** is slower, costs requests the CRM may limit or
charge for, and overwrites, every hour, whatever somebody typed into those fields since.

`IS DISTINCT FROM` rather than `<>` because a contact never sent has no row in `last_sent`, so its
payload is `NULL`, and `NULL <> anything` is neither true nor false — the new contact would never be
sent. The `SELECT` lesson of `sql-databases` spent a section on exactly that.

## A day later

The shop's data moves on. To see a change travel, add an order for customer 1500 — this is the course
playing the shop, as `lantern.sql` does:

```sql
INSERT INTO shop.orders VALUES (7103, 1500, '2026-06-17 20:15:00-03', 'paid', 0);
INSERT INTO shop.order_lines VALUES (7103, 1, 4, 1, 4790);
```

```
lantern=# INSERT INTO shop.orders VALUES (7103, 1500, '2026-06-17 20:15:00-03', 'paid', 0);
INSERT 0 1

lantern=# INSERT INTO shop.order_lines VALUES (7103, 1, 4, 1, 4790);
INSERT 0 1
```

Which contacts does the model now disagree with the CRM about?

```
lantern=# SELECT m.external_id, s.payload ->> 'health' AS sent, m.health AS now
lantern-# FROM activation.crm_contacts m JOIN activation.last_sent s USING (external_id)
lantern-# WHERE s.payload IS DISTINCT FROM row_to_json(m)::jsonb;
 external_id  |  sent  |  now   
--------------+--------+--------
 lantern-1500 | lapsed | active
(1 row)
```

One: the CRM was told *lapsed*, and the model now says *active*. The sync sends exactly that:

```
ana@vm:~/reverse$ bash sync.sh
run 2: sent 1, removed 0, failed 0, retried after 429: 0
ana@vm:~/reverse$ curl -s -w '\n' 'localhost:8000/contacts?external_id=lantern-1500'
[{"external_id": "lantern-1500", "segment": "home", "region": "Southeast", "orders": 7, "net_revenue": 601.12, "last_order": "2026-06-17", "health": "active", "crm_id": 558}]
```

One request, and the CRM's record moved with the customer. It calls itself run 2 again because the
number comes from the log, and a run that sent nothing logged nothing. **That is the whole of reverse ETL's core
loop**: compute the model, compare with what was sent, send the difference, remember it.
