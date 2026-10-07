---
title: Who row security does not apply to
version: 1
---

A policy is a rule for roles, and three kinds of role are not bound by it. Each is reasonable on
its own, and each is a way round the rule that somebody has to know about.

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT count(*) FROM sales.customers"
SET
 count 
-------
  6012
(1 row)

ana@lab:~/gov$ psql -c "SELECT relname, relrowsecurity, relforcerowsecurity FROM pg_class WHERE relname = 'customers'"
  relname  | relrowsecurity | relforcerowsecurity 
-----------+----------------+---------------------
 customers | t              | f
(1 row)

ana@lab:~/gov$ psql -c "\du postgres"
                             List of roles
 Role name |                         Attributes                         
-----------+------------------------------------------------------------
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS
```

**The table's owner sees every row.** `ipe_owner` counted 6,012. Policies apply to the owner only
when the table is in `FORCE ROW LEVEL SECURITY` mode, and the catalogue says `customers` is not:
`relforcerowsecurity` is `f`. That is deliberate — the owner is who maintains the table and the
policies — and it is why nobody should be reading data as the owner.

**A superuser sees every row**, and so does any role with the `BYPASSRLS` attribute, which `\du`
prints for `postgres`. Backups are taken by a role like that, because a backup that obeyed the
policies would be a backup of whatever the person running it could see.

## A view runs as its owner, and so does its row security

The third is the subtle one, and it follows from the last section. The analysts' view reads the
table as `ipe_owner`. Ana grants the same view to the support job, to see what an agent would get:

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "GRANT SELECT ON sales.customer_profile TO support_agent"
SET
GRANT
ana@lab:~/gov$ psql service=carla -c "SELECT count(*) FROM sales.customer_profile"
 count 
-------
  6012
(1 row)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "ALTER VIEW sales.customer_profile SET (security_invoker = true)"
SET
ALTER VIEW
ana@lab:~/gov$ psql service=carla -c "SELECT count(*) FROM sales.customer_profile"
 count 
-------
  3386
(1 row)

ana@lab:~/gov$ psql service=bruno -c "SELECT count(*) FROM sales.customer_profile"
ERROR:  permission denied for table customers
```

Through the view, **Carla sees all 6,012 customers**. The policy on the table was evaluated for
the view's owner, who is exempt from it. Nothing about the policy changed; the door was in a
different wall.

`security_invoker = true`, available since PostgreSQL 15, makes a view check privileges and
policies as **the person reading it** rather than its owner. Set on this view, it gives Carla her
3,386 — and refuses Bruno outright, because now *he* needs `birth_date` and does not have it. So
the two kinds of view do different jobs:

| | runs as | good for |
|---|---|---|
| a default view | its owner | exposing derived columns of rows everybody in the job may see — the analysts' profile |
| a `security_invoker` view | its reader | a convenience over a table whose row security must still hold |

Ana puts the view back as it was and revokes it from support. The lesson she writes down is the
one to keep: **row security protects a table, not the data in it.** Anything that reads the table
on somebody else's behalf — a view, a function, a materialised view, a nightly copy into another
table, an export — carries whatever its owner could see.
