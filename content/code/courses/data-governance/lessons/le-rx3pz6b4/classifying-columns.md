---
title: Classifying every column
version: 1
---

An inventory people trust is one that cannot fall out of date without somebody noticing. The way to
get that is to keep the classification **in the database, beside the columns it describes**, and to
make a query that lists anything left out.

Ipê uses four classes. Fewer would merge things that are handled differently; more would turn every
new column into an argument:

| class | means | example |
|---|---|---|
| `none` | nothing about a person | a product's price |
| `personal` | about a person; identifies them only with other data | a customer's city |
| `identifying` | picks a person out on its own | an e-mail address |
| `sensitive` | article 5, II, or reveals it | a prescription; a pharmacy's order line |

The schema `gov` is created by the superuser for the owner — `ipe_owner` holds no right to create
schemas in the database, which lesson 1 arranged — and the classification goes in a table there. The
start of the file, with every column of `sales.customers`:

```sql
-- Every column of Ipê's tables, and what it holds. Four classes, no more:
--   none         nothing about a person
--   personal     about a person, identifies them only with other data
--   identifying  picks a person out on its own
--   sensitive    article 5, II of the LGPD, or reveals it
SET ROLE ipe_owner;
CREATE TABLE gov.column_class (
  table_schema name NOT NULL,
  table_name   name NOT NULL,
  column_name  name NOT NULL,
  class        text NOT NULL
               CHECK (class IN ('none', 'personal', 'identifying', 'sensitive')),
  why          text NOT NULL,
  PRIMARY KEY (table_schema, table_name, column_name)
);
INSERT INTO gov.column_class VALUES
 ('sales','customers','customer_id','personal','internal number; joins to everything about them'),
 ('sales','customers','full_name','identifying','a name'),
 ('sales','customers','email','identifying','an address that reaches one person'),
 ('sales','customers','birth_date','personal','quasi-identifier (lesson 5)'),
 ('sales','customers','sex','personal','quasi-identifier'),
 ('sales','customers','cep','personal','quasi-identifier; often one street'),
 ('sales','customers','city','personal','quasi-identifier'),
 ('sales','customers','state','personal','quasi-identifier'),
 ('sales','customers','created_at','personal','when this person signed up'),
 ('sales','customers','marketing_opt_in','personal','a choice this person made'),
 ('sales','customers','consent_at','personal','when they made it'),
 ('sales','customers','cpf_ct','identifying','the CPF, encrypted (lesson 4)'),
 ('sales','customers','cpf_hmac','identifying','a stand-in that finds one CPF (lesson 5)'),
```

The file goes on in the same way for every column of every table, 53 rows in all, each with a
**`why`** that says what the column reveals — a classification with no reason is a label somebody
will change without knowing what they are undoing. And a query lists what nobody classified:

```sql
-- Every column of a table in Ipê's schemas that nobody has classified.
-- Run in CI, an answer that is not empty fails the build.
SET ROLE ipe_owner;
SELECT c.table_schema, c.table_name, c.column_name
FROM information_schema.columns c
JOIN information_schema.tables t
  ON t.table_schema = c.table_schema AND t.table_name = c.table_name
LEFT JOIN gov.column_class k
  ON k.table_schema = c.table_schema AND k.table_name = c.table_name
 AND k.column_name = c.column_name
WHERE c.table_schema IN ('sales', 'health', 'support')
  AND t.table_type = 'BASE TABLE'
  AND k.class IS NULL
ORDER BY 1, 2, 3;
```

```
ana@lab:~/gov$ sudo -u postgres psql -c "CREATE SCHEMA gov AUTHORIZATION ipe_owner"
CREATE SCHEMA
ana@lab:~/gov$ psql -f classes.sql
SET
CREATE TABLE
INSERT 0 53
ana@lab:~/gov$ psql -f unclassified.sql
SET
 table_schema | table_name | column_name 
--------------+------------+-------------
(0 rows)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT class, count(*) FROM gov.column_class GROUP BY class ORDER BY 2 DESC"
SET
    class    | count 
-------------+-------
 personal    |    31
 none        |     9
 sensitive   |     9
 identifying |     4
(4 rows)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l6-classes\" aria-label=\"The 53 columns of Ipê's tables by class: 31 personal, 9 sensitive, 9 holding nothing about a person, 4 identifying. The sensitive ones are in health.prescriptions, in sales.order_items.product_id and in support.tickets.body.\"><text x=\"138.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">personal</text><rect x=\"150.0\" y=\"26.0\" width=\"434.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"594.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">31</text><text x=\"138.0\" y=\"86.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sensitive</text><rect x=\"150.0\" y=\"72.0\" width=\"126.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"286.0\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">9</text><text x=\"316.0\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">health.prescriptions (7), order_items.product_id, tickets.body</text><text x=\"138.0\" y=\"132.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">none</text><rect x=\"150.0\" y=\"118.0\" width=\"126.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"286.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">9</text><text x=\"138.0\" y=\"178.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">identifying</text><rect x=\"150.0\" y=\"164.0\" width=\"56.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"216.0\" y=\"178.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4</text><text x=\"246.0\" y=\"178.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">name, e-mail, cpf_ct, cpf_hmac</text></svg>", "caption": "Most columns are personal data, and the sensitive ones are not all in the schema called health."}
```

Nothing unclassified; 31 personal columns, 9 sensitive, 4 identifying, and 9 that hold nothing about
a person. **Most of Ipê's columns are personal data**, as section 2 predicted, and the sensitive ones
are not only in `health`: `order_items.product_id` and the free text of support tickets are there
too, for the reasons sections 4 and 9 give.

## The check that keeps it true

A classification written once is right for a week. The query is what makes it last, because it can
run wherever schema changes run — in the pipeline that applies migrations — and fail when it finds
something:

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "ALTER TABLE sales.orders ADD COLUMN coupon_code text"
SET
ALTER TABLE
ana@lab:~/gov$ psql -f unclassified.sql
SET
 table_schema | table_name | column_name 
--------------+------------+-------------
 sales        | orders     | coupon_code
(1 row)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "INSERT INTO gov.column_class VALUES ('sales','orders','coupon_code','personal','a code may be issued to one person')"
SET
INSERT 0 1
ana@lab:~/gov$ psql -q -At -f unclassified.sql | wc -l
0
```

A developer added `coupon_code` to orders; the check found it on the day it appeared; one row
classifies it and the check is quiet again. **Adding a column without deciding what it holds becomes
impossible rather than discouraged.** The next section shows the same idea in the platform this
course is running on.
