---
title: Attributes, and what CREATEROLE stopped meaning
version: 1
---

A role carries two kinds of power, and they are kept in different places. **Attributes** are
powers over the cluster as a whole: whether the role may log in, create databases, create other
roles, or skip every check. **Privileges** are rights on one object: a table, a schema, a database.
Attributes are set with `CREATE ROLE` and `ALTER ROLE` and shown by `\du`; privileges are the
subject of lesson 12.

## The attributes

| attribute | what it lets the role do | `\du` shows |
|---|---|---|
| `LOGIN` | connect at all | `Cannot login` when it is missing |
| `SUPERUSER` | anything, with no check of any kind | `Superuser` |
| `CREATEDB` | create databases | `Create DB` |
| `CREATEROLE` | create roles, and manage the ones it has ADMIN on | `Create role` |
| `INHERIT` | use the privileges of the roles it is a member of, by default | `No inheritance` when it is off |
| `REPLICATION` | connect as a replication client | `Replication` |
| `BYPASSRLS` | ignore row-level security policies | `Bypass RLS` |
| `CONNECTION LIMIT n` | at most n sessions at once | `n connections` |
| `VALID UNTIL 'time'` | use its password until then | `Password valid until …` |

Each one has a `NO` form, and `ALTER ROLE bruno NOLOGIN` is how an account is switched off without
dropping what it owns. `REPLICATION` belongs to db-reliability lesson 11; `BYPASSRLS` meets row-level
security in lesson 12; `VALID UNTIL` is the last section of this lesson.

**`SUPERUSER` is not a bigger set of privileges; it is the absence of the check.** A superuser can
read any table, change any role, read files on the server through `COPY` and run programs on it as
the `postgres` user. `ana` has it because she is the administrator of a server that exists to be
administered. An application, an analyst and a monitoring tool never need it, and each of the next
three lessons shows the narrower thing they need instead.

## CREATEROLE in PostgreSQL 16

A role with `CREATEROLE` can create roles. What it may do to roles **it did not create** is the
part that changed in version 16, and the change is the reason a team can now hand that attribute
to somebody who is not a superuser.

Make a `steward` role with it, become that role with `SET ROLE`, and try four things:

```
shop=# CREATE ROLE steward LOGIN CREATEROLE;
CREATE ROLE

shop=# SET ROLE steward;
SET

shop=> CREATE ROLE intern LOGIN;
CREATE ROLE

shop=> ALTER ROLE bruno CREATEDB;
ERROR:  permission denied to alter role
DETAIL:  Only roles with the CREATEROLE attribute and the ADMIN option on role "bruno" may alter this role.

shop=> ALTER ROLE intern SUPERUSER;
ERROR:  permission denied to alter role
DETAIL:  Only roles with the SUPERUSER attribute may change the SUPERUSER attribute.

shop=> GRANT pg_read_all_data TO intern;
ERROR:  permission denied to grant role "pg_read_all_data"
DETAIL:  Only roles with the ADMIN option on role "pg_read_all_data" may grant this role.

shop=> RESET ROLE;
RESET

shop=# \drg
            List of role grants
 Role name | Member of | Options | Grantor  
-----------+-----------+---------+----------
 steward   | intern    | ADMIN   | postgres
(1 row)
```

The prompt changed from `#` to `>` because the current role stopped being a superuser. `steward`
created `intern`, and **creating it gave `steward` the ADMIN option on it**, which is the row
`\drg` printed: `steward` is a member of `intern` with `ADMIN`, granted by `postgres`, the
bootstrap superuser, because the server made that grant itself. With ADMIN on `intern`, `steward`
may alter it, rename it, drop it and grant it to others. On `bruno`, which somebody else made, it
may do none of that. And no `CREATEROLE` role can hand out an attribute it lacks or a role it holds
no ADMIN on, so it cannot make a superuser or grant itself into a predefined role like
`pg_read_all_data`.

**On PostgreSQL 15 and earlier, `CREATEROLE` could alter or drop any role that was not a superuser,
and grant membership in any role at all**, including the predefined roles that read and write the
server's files and run programs on it. The documentation of those versions told you to treat it as
almost a superuser, and it was right. If you administer an older server, a role with `CREATEROLE`
there deserves the same suspicion as one with `SUPERUSER`.

`steward` can clean up after itself, and `ana` removes `steward`:

```
shop=# SET ROLE steward;
SET

shop=> DROP ROLE intern;
DROP ROLE

shop=> RESET ROLE;
RESET

shop=# DROP ROLE steward;
DROP ROLE
```

`SET ROLE` was the honest tool here, because every refusal above is a check of the current role's
privileges and `SET ROLE` changes exactly that. The next section finds the one check it does not
change.

## Parameters per role

One more thing `ALTER ROLE` does that has nothing to do with power: it can set a **parameter for
every session of that role**. `ALTER ROLE bruno SET statement_timeout = '5min'` stops any report
of his from running for an hour, and `ALTER ROLE app SET idle_in_transaction_session_timeout =
'1min'` puts lesson 10's timeout on the application alone. The setting applies from the role's next
login, and only to the role that logged in: a setting on the group `reporting` reaches none of its
members, because nobody logs in as a group. Lesson 5 shows where these rank among the other places
a parameter can come from.
