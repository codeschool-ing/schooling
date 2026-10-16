---
title: Membership, and the three options of a grant
version: 1
---

**A group is a role that other roles are members of**, and membership is granted with the same
`GRANT` that grants a table, with a role where the table would be. Privileges are then given once,
to the group, and a person gets them by joining it. When an analyst leaves, one `REVOKE` takes
everything away, instead of a hunt through every table he was ever given.

What PostgreSQL 16 added is a precise answer to "gets them how". A membership now carries three
options of its own, and **each one answers a different question**:

| option | the question it answers | default |
|---|---|---|
| `INHERIT` | does the member use the group's privileges without asking? | on, from the member's `INHERIT` attribute |
| `SET` | may the member become the group with `SET ROLE`? | on |
| `ADMIN` | may the member grant the group to others, and take it away? | off |

## Inheriting

Give the group one privilege, a single `SELECT` on `customers` (lesson 12 is about `GRANT` on
tables; one line is enough here), and put `bruno` in the group:

```
shop=# GRANT SELECT ON customers TO reporting;
GRANT

shop=# GRANT reporting TO bruno;
GRANT ROLE

shop=# \drg
               List of role grants
 Role name | Member of |   Options    | Grantor  
-----------+-----------+--------------+----------
 bruno     | reporting | INHERIT, SET | postgres
(1 row)

shop=# SET ROLE bruno;
SET

shop=> SELECT current_user, session_user;
 current_user | session_user 
--------------+--------------
 bruno        | ana
(1 row)

shop=> SELECT count(*) FROM customers;
 count 
-------
 50000
(1 row)

shop=> SELECT count(*) FROM orders;
ERROR:  permission denied for table orders

shop=> RESET ROLE;
RESET
```

`\drg` is new in psql 16 and lists memberships with their options; older versions of psql showed a
`Member of` column in `\du` instead. The defaults came out as `INHERIT, SET`. `bruno` read
`customers` without doing anything, because he inherits `reporting`'s privilege, and was refused
`orders`, which nobody gave the group.

`SELECT current_user, session_user` is worth typing whenever you test like this. **`session_user`
is who logged in; `current_user` is whose privileges are being checked.** `SET ROLE` changes the
second and leaves the first alone.

Now take the inheritance away and keep the membership:

```
shop=# GRANT reporting TO bruno WITH INHERIT FALSE;
GRANT ROLE

shop=# SET ROLE bruno;
SET

shop=> SELECT count(*) FROM customers;
ERROR:  permission denied for table customers

shop=> RESET ROLE;
RESET
```

Granting a membership that already exists changes its options, so this did not add a second one.
`bruno` is still in `reporting`, and the privilege no longer comes to him on its own. He has to
switch to the group with `SET ROLE reporting` first, and that is the point of `INHERIT FALSE`. A
dangerous group, one that can drop tables, is then used on purpose and for a moment, and every other
statement runs with the person's ordinary rights.

## The one check SET ROLE does not change

`SET` is the opposite case: inherit the privileges, but never be allowed to become the group. Turn
it off, and test it from `ana`'s session the same way as before:

```
shop=# GRANT reporting TO bruno WITH INHERIT TRUE, SET FALSE;
GRANT ROLE

shop=# \drg
            List of role grants
 Role name | Member of | Options | Grantor  
-----------+-----------+---------+----------
 bruno     | reporting | INHERIT | postgres
(1 row)

shop=# SET ROLE bruno;
SET

shop=> SET ROLE reporting;
SET

shop=> SELECT current_user, session_user;
 current_user | session_user 
--------------+--------------
 reporting    | ana
(1 row)

shop=> RESET ROLE;
RESET
```

`bruno` has no `SET` option on `reporting`, and the switch worked anyway. **Whether you may `SET
ROLE` is decided by the session user, not the current one**, and the session user here is `ana`, a
superuser who may become anybody. So `SET ROLE` is a faithful way to test what a role may do to
tables, and a worthless way to test what it may do with its memberships. The same is true of
anything checked when the connection opens, which is why the next section logs in as `bruno` for
real and repeats this test.

## ADMIN, and older servers

`ADMIN` is the option `steward` received in the section before. A member with it may grant the
group to other roles and revoke it from them, which is how a team lead can manage who reads the
reports without being a superuser. It is given with `GRANT reporting TO bruno WITH ADMIN TRUE`.

Before version 16 there was no `SET` option at all, and `INHERIT` was not a property of a
membership: it was only the member role's attribute, so a role inherited from **all** its groups or
from none. `WITH ADMIN OPTION` existed and meant the same as today. The attribute still exists
in 16 and supplies the default for new grants; the grant decides from then on.
