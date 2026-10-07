---
title: Roles, and the role that logs in
version: 1
---

PostgreSQL has one kind of principal and calls it a **role**. A role that may open a connection is
what other systems call a user; a role that may not is what they call a group. It is one concept
with one attribute, `LOGIN`, and that turns out to be useful: a role can be granted to another
role, so a group is just a role somebody else is a member of.

The fresh cluster has two:

```
ana@lab:~/gov$ sudo -u postgres psql -c "\du"
                             List of roles
 Role name |                         Attributes                         
-----------+------------------------------------------------------------
 ipe_owner | Cannot login
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS
```

`postgres` is the **superuser**. A superuser skips every permission check in the database — the
grants, the row policies, all of it — and on Ubuntu it can only be reached by the operating
system's own `postgres` user, through `sudo`. `ipe_owner` is the role that owns Ipê's tables, and
it cannot log in. Nobody is ever `ipe_owner`; people *become* it, deliberately, when the schema
has to change.

## Ana's own login

Ana is the data engineer. She needs to create the other roles and, now and then, to change the
schema — but she should not hold the owner's privileges all day, because a mistyped `DROP` would
then succeed:

```sql
-- Ana's own login. She creates and manages the other roles, and may
-- become the owner of the tables when she chooses to, never by default.
CREATE ROLE ana LOGIN CREATEROLE;
GRANT ipe_owner TO ana WITH INHERIT FALSE;
```

```
ana@lab:~/gov$ sudo -u postgres psql -d ipe < ana.sql
CREATE ROLE
GRANT ROLE
ana@lab:~/gov$ psql -c "SELECT current_user, session_user"
 current_user | session_user 
--------------+--------------
 ana          | ana
(1 row)
```

Two attributes carry the design.

**`CREATEROLE` lets Ana create roles and manage the ones she created.** Since PostgreSQL 16 that is
all it lets her do: a role created by somebody else is not hers to alter, and she cannot hand out
`SUPERUSER`, which she does not have. Before 16, `CREATEROLE` was close to superuser in disguise.

**`WITH INHERIT FALSE` makes ownership a step she takes.** Ana is a member of `ipe_owner`, but its
privileges do not flow to her automatically. When the schema has to change she types
`SET ROLE ipe_owner`, and the change is made under that name; when she is reading data she is
only `ana`. The difference shows up in the log and in every error message.

## One login per person, one per program

```sql
-- One login per person and one per program. No passwords here: a password
-- typed into SQL travels to the server as text and can land in a log.
CREATE ROLE bruno LOGIN;                          -- analyst, BI
CREATE ROLE carla LOGIN;                          -- customer support
CREATE ROLE davi  LOGIN;                          -- the DPO (encarregado)
CREATE ROLE lia   LOGIN VALID UNTIL '2026-06-30'; -- intern, contract ended
CREATE ROLE site_app   LOGIN CONNECTION LIMIT 3;  -- the website
CREATE ROLE etl_loader LOGIN;                     -- the nightly pipeline
```

```
ana@lab:~/gov$ psql -f logins.sql
CREATE ROLE
CREATE ROLE
CREATE ROLE
CREATE ROLE
CREATE ROLE
CREATE ROLE
```

Six roles, and each one stands for exactly one person or one program. **That is the decision that
makes everything else in this course possible.** An audit trail can only say what `bruno` did if
`bruno` is Bruno. A grant can only be revoked from the intern who left if she had a login of her
own. And lesson 10's question — who read the prescriptions table in May — only has an answer if the
answer is a name.

Two of them carry attributes the others do not, and section 9 uses both: `lia`'s password stops
working on 30 June, and `site_app` can never hold more than three connections at once.

```
ana@lab:~/gov$ psql -c "\du"
                              List of roles
 Role name  |                         Attributes                         
------------+------------------------------------------------------------
 ana        | Create role
 bruno      | 
 carla      | 
 davi       | 
 etl_loader | 
 ipe_owner  | Cannot login
 lia        | Password valid until 2026-06-30 00:00:00-03
 postgres   | Superuser, Create role, Create DB, Replication, Bypass RLS
 site_app   | 3 connections
```

None of them has a password yet, so none of them can log in over the network. The next section
gives them one.
