---
title: Stopping it at the door
version: 1
---

Measuring finds the defects that are already in. The cheaper move is to stop the next one from getting
in, and PostgreSQL has a way of doing that without first having to fix every old row:

```sql
-- New rows must have the shape; the old ones are checked separately.
SET ROLE ipe_owner;
ALTER TABLE sales.customers ADD CONSTRAINT email_shape
  CHECK (email ~* '^[^@ ]+@[^@ ]+\.[a-z]{2,}$' OR email LIKE 'erased-%@invalid')
  NOT VALID;
```

```
ana@lab:~/gov$ psql -f email-check.sql
SET
ALTER TABLE
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "INSERT INTO sales.customers (customer_id, full_name, email, birth_date, sex, cep, city, state, created_at, marketing_opt_in) VALUES (9001, 'Teste Novo', 'teste.novoexample.com', '1990-01-01', 'F', '01001-000', 'São Paulo', 'SP', '2026-07-01 09:00-03', false)"
SET
ERROR:  new row for relation "customers" violates check constraint "email_shape"
DETAIL:  Failing row contains (9001, Teste Novo, teste.novoexample.com, 1990-01-01, F, 01001-000, São Paulo, SP, 2026-07-01 09:00:00-03, f, null, null, null).
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "ALTER TABLE sales.customers VALIDATE CONSTRAINT email_shape"
SET
ERROR:  check constraint "email_shape" of relation "customers" is violated by some row
```

`NOT VALID` is the key. The constraint applies to **every new and updated row** from that moment —
the insert of a malformed address is refused at once — but PostgreSQL does not check the rows already
in the table. `VALIDATE CONSTRAINT` does check them, and fails, because the 23 are still there. When
the last of them is corrected, the same command succeeds, and from then on the constraint is a
guarantee about the whole table.

That order of work is what makes it practical:

1. **stop the bleeding**: a constraint `NOT VALID`, today, with no data migration;
2. **fix the old rows** at the owner's pace — here, by asking customers;
3. **validate**, and the rule in `gov.quality_rules` becomes redundant for that table, because the
   database itself now refuses what it counted.

The constraint allows one exception, `erased-%@invalid`, the address lesson 7 put in place of an
erased customer's e-mail. An exception written into the constraint is visible and reviewed; one
handled by "we'll just skip those rows" is invisible and forgotten.

## What a constraint cannot do

The three orders dated in 2027 cannot be stopped this way. A `CHECK` must give the same answer every
time it is asked about the same row, so it cannot compare with the current date: `now()` is not
allowed in one. Rejecting a future date takes a trigger, or — better — a check in the import that
wrote them, which is where the defect was made. The database is the last door, not the only one.
