---
title: A copy for developers
version: 1
---

Developers need data. A query plan, a migration, a bug that only appears with a customer who has
sixty orders — all of them are easier with realistic data, and the easiest realistic data is a copy
of production. **That copy is the most common place personal data ends up where nobody meant it to
be**: a laptop, a test database with a weak password, a CI system's cache, a screenshot in a bug
report.

**Static masking** makes the copy safe before it leaves: the same shape and the same distributions,
with nobody in it.

```sql
-- A copy of the customers for the developers' database: the same shape and
-- the same distributions, and nobody in it.
SET ROLE ipe_owner;
COPY (
  SELECT customer_id,
         'Customer ' || customer_id                     AS full_name,
         'customer' || customer_id || '@example.com'    AS email,
         make_date(extract(year FROM birth_date)::int, 1, 1) AS birth_date,
         sex, left(cep, 2) || '000-000'                  AS cep,
         city, state, created_at, marketing_opt_in
  FROM sales.customers ORDER BY customer_id
) TO STDOUT WITH (FORMAT csv, HEADER true);
```

```
ana@lab:~/gov$ psql -X -q -f dev.sql > dev_customers.csv && head -n 3 dev_customers.csv && wc -l dev_customers.csv
customer_id,full_name,email,birth_date,sex,cep,city,state,created_at,marketing_opt_in
1,Customer 1,customer1@example.com,1998-01-01,F,01000-000,São Paulo,SP,2025-01-07 12:04:18-03,t
2,Customer 2,customer2@example.com,1985-01-01,F,90000-000,Porto Alegre,RS,2020-07-16 12:14:56-03,f
6013 dev_customers.csv
```

Each column was decided:

- **the id is kept**, so orders, items and tickets copied the same way still join to the right
  customer — a developer debugging "the customer with sixty orders" still finds them;
- **the name and e-mail are replaced**, deterministically, by values that say what they are;
- **the date of birth keeps its year** and loses the day, which keeps every age-based feature
  testable;
- **the CEP keeps its region** (the first two digits) and loses the street;
- **the CPF is not exported at all** — and since this lesson's later sections, there is no
  plaintext CPF left to export.

6,013 lines: a header and every customer.

## Masked is not anonymous

This file is much safer than the table and **it is still personal data**. The customer ids join to
production; the city, sex, year of birth and sign-up time together single out many people, as
section 9 measures. A masked copy belongs in an environment with access control, not in a public
repository or a vendor's demo.

The alternative is the one this course is built on: **generate the data**. Lesson 1's `generate.py` writes
6,012 customers with fixed seeds, every CPF failing its check digit and every e-mail under a domain
reserved for examples. Nobody in it exists, so nobody can be exposed by it, and a test that needs
"a customer under eighteen" or "a duplicate sign-up" gets one because somebody wrote it into the
generator. For most development work, a generator is cheaper than a well-masked copy and safer than
any copy.
