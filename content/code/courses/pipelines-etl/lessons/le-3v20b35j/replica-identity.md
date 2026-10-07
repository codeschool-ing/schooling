---
title: What the old row looked like
version: 1
---

The `UPDATE` lines so far carry the new row only. For a copy that is kept current, that is all it
needs. **For a history, it is half the story**: "customer 3145 now lives in Rio de Janeiro" does
not say where they lived before, and a slowly changing dimension — lesson 7 — needs both.

What PostgreSQL writes about the old row is a property of the table, its **replica identity**. The
default is the primary key: enough to find the row, and nothing more. Set it to `FULL` and every
update and delete writes the whole old row into the WAL as well:

```
ana@vm:~/etl$ grep -A1 "^UPDATE customers" /var/lib/etl-data/days/2026-03-15.sql | head -1
UPDATE customers SET city = 'Rio de Janeiro', state = 'RJ', updated_at = '2026-03-15 08:16:38-03:00' WHERE customer_id = 3145;
ana@vm:~/etl$ psql -q -c "ALTER TABLE customers REPLICA IDENTITY FULL"
ana@vm:~/etl$ sudo shop day 2026-03-15
ana@vm:~/etl$ psql -At -c "SELECT data FROM pg_logical_slot_peek_changes('wh_cdc', NULL, NULL) WHERE data LIKE 'table public.customers: UPDATE%' LIMIT 1"
table public.customers: UPDATE: old-key: customer_id[integer]:3145 name[text]:'Débora Mendes' email[text]:'débora.mendes3145@example.net' city[text]:'São Paulo' state[text]:'SP' created_at[timestamp with time zone]:'2025-05-01 12:00:00-03' updated_at[timestamp with time zone]:'2025-05-01 12:00:00-03' new-tuple: customer_id[integer]:3145 name[text]:'Débora Mendes' email[text]:'débora.mendes3145@example.net' city[text]:'Rio de Janeiro' state[text]:'RJ' created_at[timestamp with time zone]:'2025-05-01 12:00:00-03' updated_at[timestamp with time zone]:'2026-03-15 08:16:38-03'
ana@vm:~/etl$ python apply_cdc.py
1246 changes read up to 0/BFA5900: {'INSERT': 22, 'UPDATE': 4, 'DELETE': 1, 'other tables': 739}
```

Now the change says `old-key:` with every column as it was, and `new-tuple:` with every column as
it became: São Paulo before, Rio de Janeiro after, and the two `updated_at` values that bracket the
move. The apply script still works, by luck rather than design — its parser reads the old values and
then overwrites them with the new ones, because the names are the same. A script that needed the
history would split the line at `new-tuple:` and keep both halves.

## What `FULL` costs

Every update now writes the whole old row into the WAL as well as the new one, so the WAL for that
table roughly doubles. For `customers`, a few updates a day, that is nothing. For a table updated
thousands of times a second it is a real cost on the source, and it is paid by the system that
takes the sales.

**That is a decision for the source's owner, not for the pipeline**, which is the pattern of this
whole lesson: CDC asks more of the source database than any query does. `wal_level`, the slot and
the replica identity are all set on a server the pipeline does not own, and the next section is
what happens when that server's owner forgets the slot exists.
