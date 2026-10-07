---
title: Taking access away
version: 1
---

Lia left on 30 June. Lesson 1 gave her role an expiry date, so her password stopped working on
its own, and lesson 1 also said that was not the whole job. With jobs and grants in place, the
rest of it can be done — and checked.

Her role is still a member of `analyst`, which this lesson made her:

```
ana@lab:~/gov$ psql -c "\drg lia"
              List of role grants
 Role name | Member of |   Options    | Grantor 
-----------+-----------+--------------+---------
 lia       | analyst   | INHERIT, SET | ana
(1 row)

ana@lab:~/gov$ psql -c "ALTER ROLE lia NOLOGIN" -c "REVOKE analyst FROM lia"
ALTER ROLE
REVOKE ROLE
ana@lab:~/gov$ sudo -u postgres psql -c "REASSIGN OWNED BY lia TO ipe_owner" -c "DROP OWNED BY lia"
REASSIGN OWNED
DROP OWNED
ana@lab:~/gov$ psql -c "\drg lia"
            List of role grants
 Role name | Member of | Options | Grantor 
-----------+-----------+---------+---------
(0 rows)

ana@lab:~/gov$ psql -c "\du lia"
                      List of roles
 Role name |                 Attributes                  
-----------+---------------------------------------------
 lia       | Cannot login                               +
           | Password valid until 2026-06-30 00:00:00-03
```

Four statements, in an order that matters:

1. **`NOLOGIN` first**, so that no new session opens by any method while the rest is undone —
   including a certificate or a `peer` rule that the expiry date never covered.
2. **`REVOKE analyst`** removes the job, and with it everything the job grants.
3. **`REASSIGN OWNED`** gives anything she created — a table, a view, a saved query in a schema —
   to the role that owns the data, so it outlives her account instead of vanishing with it.
4. **`DROP OWNED`** removes every privilege granted to her directly, in this database.

The last two needed the superuser. They act on everything a role owns or holds, and PostgreSQL
lets only a role with the departing role's own privileges do that. Ana created Lia and may manage
her membership, but she does not hold Lia's privileges — `CREATEROLE` lets her administer a role,
not become it — so the step goes to `postgres`, through `sudo`, where it leaves a line in the
operating system's log as well.

`\drg lia` is empty and `\du lia` says `Cannot login`. **The role is kept, not dropped.** Lesson 10
needs the name to mean something in the audit trail for as long as the trail is kept: a log line
saying `lia` read a table in May should still resolve to a role that existed, with a history,
rather than to nothing.

## What a review looks for

Offboarding one person is a procedure. Knowing that nobody was missed is a review, and the server
can be asked the questions directly:

- **Roles that can log in and have not been seen** — a login with no connection in the log for
  ninety days belongs to somebody who no longer needs it, or to nobody.
- **Logins with direct grants** — after this lesson every grant should be to a job. A person with a
  grant of their own is an exception somebody made in a hurry.
- **Members of `ipe_owner`** — the list should be short enough to read aloud.
- **Passwords with no expiry on people's roles** — every contractor's role should carry one.

Each is a query against `pg_roles`, `pg_auth_members` and the privileges the matrix in the last
section reads. None of them is clever. What makes them work is running them on a calendar and
writing down who looked.
