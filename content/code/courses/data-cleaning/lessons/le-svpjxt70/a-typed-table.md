---
title: A table that refuses bad data
version: 1
---

Everything so far converts a column once. The data keeps coming, though, and next month's export
will have its own spellings. **The last defence is a table that cannot hold a wrong type**, so the
conversion's rules are also written where nobody can skip them:

```sql
CREATE SCHEMA clean;
CREATE TABLE clean.customers (
  customer_id text PRIMARY KEY CHECK (customer_id ~ '^C[0-9]{5}$'),
  birth_year  int  CHECK (birth_year BETWEEN 1920 AND 2010),
  opt_in      boolean
);
INSERT INTO clean.customers
SELECT DISTINCT customer_id,
       CASE WHEN birth_year = '1900' THEN NULL
            WHEN length(birth_year) = 2 AND birth_year > '25' THEN ('19' || birth_year)::int
            WHEN length(birth_year) = 2 THEN ('20' || birth_year)::int
            ELSE birth_year::int END,
       CASE WHEN lower(trim(marketing_opt_in)) IN ('true', '1', 's', 'sim') THEN true
            WHEN lower(trim(marketing_opt_in)) IN ('false', '0', 'n', 'não', 'nao') THEN false
            END
FROM raw.customers;
```

Each column carries its type and a check. The customer code must look like `C` and five digits.
The birth year must be an integer between 1920 and 2010. Consent is a boolean, and `NULL` is
allowed because "not known" is a real answer. The insert repeats the decisions of this lesson in
SQL: placeholders become `NULL`, two-digit years get their century by the same rule, and consent
maps two written-out lists. A spelling in neither list falls through the `CASE` to `NULL`, which
is why the pandas version, which refuses an unknown spelling, runs first.

```
ana@lab:~/clean$ psql -f clean_customers.sql
CREATE SCHEMA
CREATE TABLE
INSERT 0 2376
ana@lab:~/clean$ psql -c 'SELECT count(*), min(birth_year), max(birth_year), count(*) FILTER (WHERE opt_in) AS yes FROM clean.customers'
 count | min  | max  | yes  
-------+------+------+------
  2376 | 1952 | 2006 | 1288
(1 row)

ana@lab:~/clean$ psql -c "INSERT INTO clean.customers VALUES ('C99999', 1890, true)"
ERROR:  new row for relation "customers" violates check constraint "customers_birth_year_check"
DETAIL:  Failing row contains (C99999, 1890, t).
```

2,376 customers, one per code, born between 1952 and 2006, with 1,288 who said yes: the same
numbers pandas gave. **Two implementations that agree are a check on each other**, and if they
ever disagree, one of them has a rule the other does not.

The last command is the point of the whole table. Somebody, next month, tries to insert a customer
born in 1890, and the database refuses with the name of the rule that was broken. **A check
constraint turns a cleaning decision into a property of the data**: it no longer depends on
everyone running the right script, because the wrong row never gets in.

The range itself is a decision like the century rule. 1920 says nobody over 105 is buying
groceries; 2010 says nobody under fifteen has an account. Both are written where a reviewer
can see them and argue, which is better than a range that lives only in somebody's head.
