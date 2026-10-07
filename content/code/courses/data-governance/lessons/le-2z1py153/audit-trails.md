---
title: Audit trails
version: 1
---

An **audit trail** answers "who did what, to which record, and when" after the fact. Lesson 4's
OpenBao kept one for every use of a key; the database needs its own for changes to the data people
care about. Three decisions shape it, and the lab's makes all three on purpose:

```sql
-- Who changed which customer, and which columns. Not the values: the trail
-- would otherwise be a second copy of everything it watches.
SET ROLE ipe_owner;
CREATE TABLE gov.audit_log (
  audit_id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  at          timestamptz NOT NULL DEFAULT now(),
  logged_in   name        NOT NULL,   -- the person who connected
  acting_as   name        NOT NULL,   -- the role they had set
  action      text        NOT NULL,
  rel         text        NOT NULL,
  row_key     text        NOT NULL,
  columns     text[]
);
INSERT INTO gov.column_class
SELECT 'gov', 'audit_log', c, 'personal', 'who did what to whose row'
FROM unnest(ARRAY['audit_id','at','logged_in','acting_as','action','rel','row_key','columns']) c;

CREATE FUNCTION gov.audit_customers() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog AS $$
BEGIN
  INSERT INTO gov.audit_log (logged_in, acting_as, action, rel, row_key, columns)
  SELECT session_user, current_user, TG_OP, TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
         OLD.customer_id::text,
         CASE WHEN TG_OP = 'UPDATE' THEN
           ARRAY(SELECT n.key FROM jsonb_each(to_jsonb(NEW)) n
                 JOIN jsonb_each(to_jsonb(OLD)) o USING (key)
                 WHERE n.value IS DISTINCT FROM o.value ORDER BY n.key)
         END;
  RETURN NULL;
END $$;
CREATE TRIGGER customers_audited AFTER UPDATE OR DELETE ON sales.customers
  FOR EACH ROW EXECUTE FUNCTION gov.audit_customers();

-- The trail itself: inserted into, never changed, never emptied.
CREATE FUNCTION gov.refuse() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION '% is append-only: % is refused', TG_TABLE_NAME, TG_OP;
END $$;
CREATE TRIGGER audit_log_is_append_only BEFORE UPDATE OR DELETE ON gov.audit_log
  FOR EACH ROW EXECUTE FUNCTION gov.refuse();
CREATE TRIGGER audit_log_is_not_emptied BEFORE TRUNCATE ON gov.audit_log
  FOR EACH STATEMENT EXECUTE FUNCTION gov.refuse();
```

```
ana@lab:~/gov$ psql -f audit.sql
SET
CREATE TABLE
INSERT 0 8
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
CREATE TRIGGER
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "UPDATE sales.customers SET city = 'Contagem', cep = '32010-000' WHERE customer_id = 112"
SET
UPDATE 1
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT logged_in, acting_as, action, rel, row_key, columns FROM gov.audit_log"
SET
 logged_in | acting_as | action |       rel       | row_key |  columns   
-----------+-----------+--------+-----------------+---------+------------
 ana       | ipe_owner | UPDATE | sales.customers | 112     | {cep,city}
(1 row)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "DELETE FROM gov.audit_log"
SET
ERROR:  audit_log is append-only: DELETE is refused
CONTEXT:  PL/pgSQL function gov.refuse() line 3 at RAISE
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "TRUNCATE gov.audit_log"
SET
ERROR:  audit_log is append-only: TRUNCATE is refused
CONTEXT:  PL/pgSQL function gov.refuse() line 3 at RAISE
```

**Who.** The row says `logged_in = ana` and `acting_as = ipe_owner`. Both matter. `current_user` alone
would say `ipe_owner` for every change anybody made through that role, which is the same as saying
nobody — which is why lesson 1 made `ipe_owner` a role nobody can log in as, reached only by `SET
ROLE` from a person's own login. `session_user` is the person who connected; the pair says who, and with what
authority.

**What.** The trail records **which columns** changed — `{cep,city}` — and not their values. A trail
that copied old and new values would be a second, permanent copy of every address, e-mail and name it
ever watched, with no retention period and no erasure path. The question an audit answers is
almost always "who changed this, and when", and the current value is in the table.

**Where.** The function is `SECURITY DEFINER`, so the trail is written with the owner's rights even
when the change was made by a role that may not read `gov.audit_log`. It runs `AFTER` the change, so it
records only what actually happened.

## Refusing to be changed

The last two statements were refused. `DELETE` is stopped by a row trigger, and `TRUNCATE` by a
second, statement-level trigger, because PostgreSQL does not fire row triggers for `TRUNCATE`. A trail
with only the first one has a hole exactly the size of the most destructive statement there is. The
next section is about where that lesson was learnt.

## What a trigger cannot stop

The owner of a table can disable its triggers, and the superuser can do anything. A trail inside the
database protects against mistakes and against roles that are not the owner; it does not protect
against the owner. Two additions close most of that gap: the **`pgaudit`** extension, which writes
statements to the server log, outside any table a role can change; and **shipping the log to another
system** as it is written, so that changing the past means changing a machine the database's owner
cannot reach.
