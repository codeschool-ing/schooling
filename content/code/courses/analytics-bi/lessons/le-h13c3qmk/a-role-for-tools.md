---
title: A role for the tools, that reads only the layer
version: 1
---

Metabase will connect to PostgreSQL as a database user. It could connect as you, and it should
not: your role is a superuser, so any question anybody builds in Metabase could read every table,
and a mistake in the tool's configuration could write to them. **A BI tool gets a role of its own,
which reads the layer and nothing else.**

Create it in `psql lantern`. Choose your own password — this one is printed in a course:

```sql
CREATE ROLE metabase LOGIN PASSWORD 'pick-your-own-password';
```

Then let it see the schema and read what is in it:

```sql
GRANT USAGE ON SCHEMA semantic TO metabase;
GRANT SELECT ON ALL TABLES IN SCHEMA semantic TO metabase;
```

`USAGE` on a schema is permission to look inside it; `SELECT` on its tables and views is
permission to read them. Together:

```
lantern=# CREATE ROLE metabase LOGIN PASSWORD 'pick-your-own-password';
CREATE ROLE

lantern=# GRANT USAGE ON SCHEMA semantic TO metabase;
GRANT

lantern=# GRANT SELECT ON ALL TABLES IN SCHEMA semantic TO metabase;
GRANT
```

Two checks, from the shell, connecting the way Metabase will — over the network to `localhost`,
with the password:

```
ana@vm:~$ PGPASSWORD=pick-your-own-password psql -h localhost -U metabase lantern -c 'SELECT count(*) FROM semantic.orders'
 count 
-------
  7098
(1 row)

ana@vm:~$ PGPASSWORD=pick-your-own-password psql -h localhost -U metabase lantern -c 'SELECT count(*) FROM shop.orders'
ERROR:  permission denied for schema shop
LINE 1: SELECT count(*) FROM shop.orders
                             ^
```

The layer answers, and the shop's own tables refuse. The views in `semantic` read from `shop`
anyway, because a view runs with its owner's permissions — yours — so the role can see exactly
what the layer shows and nothing it hides. **That is the boundary self-service needs**: people
building charts can ask any question of the layer, and no question of anything else.

`GRANT SELECT ON ALL TABLES` applies to the views that exist when it runs. Re-run `semantic.sql`
and the views are new objects with no grants, so the second block has to run again — three sections
on shows what that looks like from Metabase's side.
