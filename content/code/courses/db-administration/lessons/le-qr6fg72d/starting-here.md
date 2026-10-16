---
title: Where this lesson starts
version: 1
---

This lesson uses the three roles lesson 11 made in its last two sections: **`reporting`**, a group
that cannot log in; **`bruno`**, an analyst who can, and is a member of `reporting`; and **`app`**,
the application. Both login roles have a password, kept in `~/.pgpass` so that psql can use them
without asking. If you followed lesson 11 on your server, all of it is there and you can skip to the
check at the end of this section.

If you are starting here, connect to `shop` as `ana` with `psql shop` and make the roles:

```sql
-- where lesson 12 starts: lesson 11's three roles, run in shop as ana
CREATE ROLE reporting;
CREATE ROLE bruno LOGIN IN ROLE reporting;
CREATE ROLE app LOGIN;
```

`IN ROLE reporting` makes `bruno` a member of the group with the default options. Then give the two
login roles their passwords with psql's `\password`, which asks twice and shows nothing: type
`bruno-lab-only` after `\password bruno` and `app-lab-only` after `\password app`. Lesson 11's
passwords section explains why a password is set that way and never inside an `ALTER ROLE`
statement.

Last, open `~/.pgpass` in an editor, put these lines in it, and make it readable by you alone with
`chmod 600 ~/.pgpass`. libpq ignores the file otherwise.

```conf
# ~/.pgpass: hostname:port:database:username:password
localhost:5432:*:bruno:bruno-lab-only
localhost:5432:*:app:app-lab-only
```

Whichever way you arrived, this is the state to compare with. If you came from lesson 11, `app` also
carries `Password valid until infinity`, which changes nothing.

```
shop=# \du
                             List of roles
 Role name |                         Attributes                         
-----------+------------------------------------------------------------
 ana       | Superuser, Create role, Create DB
 app       | 
 bruno     | 
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS
 reporting | Cannot login

shop=# \drg
               List of role grants
 Role name | Member of |   Options    | Grantor  
-----------+-----------+--------------+----------
 bruno     | reporting | INHERIT, SET | postgres
(1 row)
```

**Every test of another role in this lesson logs in as that role for real**, with
`psql -h localhost -U bruno shop`: over the network door, with the password from `~/.pgpass`, the
way the application connects. Lesson 11 showed why `SET ROLE` from a superuser's session is not
enough here: the first door in this lesson is checked when the connection opens, and `SET ROLE`
never opens one.
