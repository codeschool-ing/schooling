---
title: Row-level security
version: 1
---

A column grant hides columns. **Row-level security hides rows**: a table with it switched on shows
each role only the rows a **policy** lets that role see, and every query against the table, from
any client, gets the policy's condition added to it by the server. It is the tool for "each
analyst sees one country" or "each tenant sees its own customers", where the alternative is a view
per country and a new view every time a country is added.

## Switching it on denies everything

Turn it on for `customers` and ask `bruno`, who can read four of its columns, how many rows there
are:

```
shop=# ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT count(*) FROM customers;
 count 
-------
     0
(1 row)
```

**No error, no warning, zero rows.** A table with row-level security and no policy for a role shows
that role nothing, and says nothing about it. An application whose role nobody wrote a policy for
does not fail on the day this is switched on; it returns empty pages, which is a much harder fault
to find. Write the policies first and enable the table second.

## A policy

A policy names a command, the roles it applies to, and a condition in `USING` that each visible row
must satisfy:

```
shop=# CREATE POLICY reporting_brazil ON customers FOR SELECT TO reporting USING (country = 'BR');
CREATE POLICY
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT country, count(*) FROM customers GROUP BY country;
 country | count 
---------+-------
 BR      | 10000
(1 row)
shop=# SELECT count(*) FROM customers;
 count 
-------
 50000
(1 row)

shop=# \dp customers
                                         Access privileges
 Schema |   Name    | Type  | Access privileges | Column privileges |           Policies            
--------+-----------+-------+-------------------+-------------------+-------------------------------
 public | customers | table | ana=arwdDxt/ana   | id:              +| reporting_brazil (r):        +
        |           |       |                   |   reporting=r/ana+|   (u): (country = 'BR'::text)+
        |           |       |                   | name:            +|   to: reporting
        |           |       |                   |   reporting=r/ana+| 
        |           |       |                   | country:         +| 
        |           |       |                   |   reporting=r/ana+| 
        |           |       |                   | created_at:      +| 
        |           |       |                   |   reporting=r/ana | 
(1 row)
```

`bruno` sees the 10,000 Brazilian customers and has no way to learn that the other 40,000 exist.
`\dp` lists the policy beside the grants: `(r)` for `SELECT`, `(u)` for the `USING` condition. A
policy for `INSERT` or `UPDATE` takes a `WITH CHECK` condition as well, which a new or changed row
must satisfy, so that a tenant cannot write a row into somebody else's data. The condition can
call functions and read settings, and `USING (tenant_id = current_setting('app.tenant')::int)` is
the usual shape when one application role serves many tenants.

Policies sit on top of grants and never replace them: `bruno` still needs `SELECT` on the columns,
and the policy only narrows what that grant shows.

## Who is not filtered

`ana` counted all 50,000. **A superuser skips the policies always**, and so does a role with the
`BYPASSRLS` attribute. That attribute exists for the role that takes backups: a `pg_dump` run by a
filtered role would save a filtered copy, so `pg_dump` refuses to read such a table unless told to,
and the role it runs as is the one to give `BYPASSRLS`.

**The table's owner skips them too**, unless the table is also given `ALTER TABLE customers FORCE
ROW LEVEL SECURITY`. An application that connects as the owner of its tables is therefore never
filtered, which is one more reason for the owner to be a separate role, as the next section
arranges.

## Switching it off again

The rest of the course reads `customers` as a whole, so remove the policy and turn the feature off:

```
shop=# DROP POLICY reporting_brazil ON customers;
DROP POLICY

shop=# ALTER TABLE customers DISABLE ROW LEVEL SECURITY;
ALTER TABLE
```

Disabling keeps any policies that still exist and stops applying them; enabling again brings them
back. Row-level security costs a condition on every query of the table, and a policy that calls a
slow function makes every query slow, so it is a tool for tables that need it rather than a
default.
