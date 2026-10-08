---
title: Asking the server who may do what
version: 1
---

After a dozen grants, two policies and a view, the honest answer to "can the website read
prescriptions?" is "I think not". An access review needs better than that, and the server can
give it: **`has_table_privilege` and `has_column_privilege` answer for any role, against the live
grants**, including everything it inherits through jobs.

```sql
-- Who may read what, asked of the server rather than of anybody's memory.
SET ROLE ipe_owner;
SELECT r.rolname AS role,
       has_table_privilege(r.rolname, 'sales.orders', 'SELECT')          AS orders,
       has_column_privilege(r.rolname, 'sales.customers', 'state', 'SELECT') AS cust_state,
       has_column_privilege(r.rolname, 'sales.customers', 'cpf', 'SELECT')   AS cust_cpf,
       has_table_privilege(r.rolname, 'sales.orders', 'INSERT')          AS ins_orders,
       has_table_privilege(r.rolname, 'health.prescriptions', 'SELECT')  AS rx,
       has_table_privilege(r.rolname, 'support.tickets', 'UPDATE')       AS tickets_upd
FROM pg_roles r
WHERE r.rolname IN ('bruno', 'carla', 'davi', 'site_app', 'etl_loader')
ORDER BY 1;
```

```
ana@lab:~/gov$ psql -f matrix.sql
SET
    role    | orders | cust_state | cust_cpf | ins_orders | rx | tickets_upd 
------------+--------+------------+----------+------------+----+-------------
 bruno      | t      | t          | f        | f          | f  | f
 carla      | t      | t          | t        | f          | f  | f
 davi       | f      | f          | f        | f          | f  | f
 etl_loader | t      | t          | t        | f          | f  | f
 site_app   | f      | f          | f        | t          | f  | f
(5 rows)
```

One row per login and one column per question, and every cell is the server's answer rather than
anybody's memory:

- **Bruno** reads orders and the customers' state, never a CPF, inserts nothing, and has no way
  into prescriptions.
- **Carla** reads the CPF — she needs it to confirm who is calling — and that is the column the
  row policy narrows to her states.
- **Davi** has nothing. He is the DPO; lesson 7 grants what answering a data subject's request
  requires, and nothing more.
- **`etl_loader`** reads everything the export needs, CPF included, because the pipeline copies
  the table whole. That is a finding, not a fact of life: lesson 5 asks whether the export needs
  the CPF or a token standing in for it.
- **`site_app`** inserts orders and reads none of these.

One cell needs reading twice. Carla's `tickets_upd` is `f`, and yet section 9 showed her updating
a ticket. `has_table_privilege` asks whether she may update **the table** — every column — and she
may not; her grant is `UPDATE (status)`. `has_column_privilege(…, 'status', 'UPDATE')` would say
`t`. **The function answers exactly the question it was asked**, which is what makes it worth
running, and why the columns of a matrix have to be chosen as carefully as the grants.

## Keeping the answer

A matrix like this is worth running on a schedule and keeping the output, because the
interesting result is the **difference** between two runs: a cell that turned `t` since last
month, with nobody able to say why, is exactly what an access review exists to find. Lesson 10
keeps an audit trail of who changed a grant; this is the other half, a snapshot of what the
grants add up to.
