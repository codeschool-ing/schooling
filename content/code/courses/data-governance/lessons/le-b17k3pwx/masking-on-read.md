---
title: Masking what is shown
version: 1
---

Carla answers customers. She needs to see who she is talking to — a name, a city — and to check
they are who they say they are. She does not need to see a whole CPF or a whole e-mail address on
her screen, where a photograph, a shoulder or a screen-sharing session can copy it.

**Masking shows part of a value and hides the rest.** Done in the database, it can be the only way
support reads customers at all:

```sql
-- How support sees a customer: enough to recognise them, not enough to
-- copy their documents.
SET ROLE ipe_owner;
CREATE FUNCTION support.mask_cpf(cpf text) RETURNS text
  LANGUAGE sql IMMUTABLE
  RETURN '***.' || substr(cpf, 5, 7) || '-**';
CREATE FUNCTION support.mask_email(email text) RETURNS text
  LANGUAGE sql IMMUTABLE
  RETURN left(email, 1) || '***@' || split_part(email, '@', 2);

CREATE VIEW support.customer_card WITH (security_barrier) AS
SELECT customer_id, full_name,
       support.mask_cpf(cpf)     AS cpf,
       support.mask_email(email) AS email,
       city, state
FROM sales.customers
WHERE state IN (SELECT r.state FROM support.agent_regions r
                WHERE r.agent = current_user);

GRANT SELECT ON support.customer_card TO support_agent;
REVOKE SELECT ON sales.customers FROM support_agent;
```

```
ana@lab:~/gov$ psql -f mask.sql
SET
CREATE FUNCTION
CREATE FUNCTION
CREATE VIEW
GRANT
REVOKE
ana@lab:~/gov$ psql service=carla -c "SELECT * FROM support.customer_card ORDER BY customer_id LIMIT 3"
ERROR:  permission denied for function mask_cpf
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "GRANT EXECUTE ON FUNCTION support.mask_cpf(text), support.mask_email(text) TO support_agent"
SET
GRANT
ana@lab:~/gov$ psql service=carla -c "SELECT * FROM support.customer_card ORDER BY customer_id LIMIT 3"
 customer_id |        full_name        |      cpf       |      email       |   city    | state 
-------------+-------------------------+----------------+------------------+-----------+-------
           1 | Paula Cavalcanti Silva  | ***.874.168-** | p***@example.com | São Paulo | SP
           4 | Samuel Carvalho Barbosa | ***.862.569-** | s***@example.com | Niterói   | RJ
           6 | Davi Almeida Freitas    | ***.836.173-** | d***@example.com | São Paulo | SP
(3 rows)

ana@lab:~/gov$ psql service=carla -c "SELECT count(*) FROM support.customer_card"
 count 
-------
  3386
(1 row)

ana@lab:~/gov$ psql service=carla -c "SELECT cpf FROM sales.customers LIMIT 1"
ERROR:  permission denied for table customers
```

Four things happened, and the first is lesson 2 paying off. **The functions were refused** to
Carla: lesson 2 made every new function closed to `PUBLIC` by default, so a function somebody
writes has to be granted on purpose. One grant later, the card works.

Then the design:

- **The view is a default view, running as its owner**, because it has to read the full CPF to
  mask it. Lesson 2 showed that such a view skips the table's row policy — so this view carries the
  region rule **itself**, in its `WHERE`, reading the same `agent_regions` table. Carla sees her
  3,386 customers, as before.
- **`security_barrier`** stops PostgreSQL from evaluating a condition Carla writes before the
  view's own `WHERE`. Without it, a cleverly written function in her query could be shown rows from
  other regions while the planner was still filtering. With it, her conditions run on what the view
  already allowed.
- **Support's `SELECT` on the table is revoked.** The view is no longer a convenience beside the
  table; it is the only door.

## What masking is, legally and technically

**Masked data is personal data**, and the table under the view still holds every CPF in clear.
Masking protects against what is *shown*: screens, screenshots, reports, the agent who copies a
number onto a sticky note. It does nothing for a backup, a replica or a role with `SELECT` on the
table — that is what lessons 3 and 4 were for.

And the part shown has to be chosen with care. `***.874.168-**` hides the first three digits and
the two check digits; somebody who knows the customer's name and city and sees seven of the eleven
digits has a lot. The usual rule is to show only what the job needs to *confirm*, not to *find*:
"the last four digits" when the customer reads out the number, nothing at all when they do not.
The next sections replace the CPF on this card altogether.
