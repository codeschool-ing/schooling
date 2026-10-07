---
title: Owners and stewards
version: 1
---

Three roles appear in nearly every governance programme, under different names:

| role | answers | at Ipê |
|---|---|---|
| **owner** | what the data is for, who may use it, how long it is kept | a business role: head of sales, chief pharmacist |
| **steward** | whether it is correct, complete and documented, day to day | a person who works with it: Bruno, Carla, Davi |
| **custodian** | where it is stored, backed up and secured | the platform: Ana, and the database |

The owner is a **role, not a person**: people change jobs, and a table owned by "Marta" is owned by
nobody the week after she leaves. The steward is a person, because somebody has to be asked when a
number looks wrong. And the custodian is deliberately not the owner: the person who can run `DROP
TABLE` is not the person who decides whether the table should exist.

## Writing it down

```sql
-- Who answers for each table: the owner decides what it is for and who may
-- read it; the steward looks after its quality day to day.
SET ROLE ipe_owner;
CREATE TABLE gov.table_owners (
  table_schema name NOT NULL,
  table_name   name NOT NULL,
  owner        text NOT NULL,
  steward      text NOT NULL,
  PRIMARY KEY (table_schema, table_name)
);
INSERT INTO gov.column_class VALUES
 ('gov','table_owners','table_schema','none','a schema'),
 ('gov','table_owners','table_name','none','a table'),
 ('gov','table_owners','owner','personal','an employee''s name'),
 ('gov','table_owners','steward','personal','an employee''s name');
INSERT INTO gov.table_owners VALUES
 ('sales',  'customers',      'head of sales',      'bruno'),
 ('sales',  'orders',         'head of sales',      'bruno'),
 ('sales',  'order_items',    'head of sales',      'bruno'),
 ('sales',  'payments',       'finance manager',    'bruno'),
 ('sales',  'products',       'head of purchasing', 'bruno'),
 ('sales',  'consent_events', 'DPO',                'davi'),
 ('health', 'prescriptions',  'chief pharmacist',   'davi'),
 ('support','tickets',        'head of support',    'carla'),
 ('gov',    'column_class',   'DPO',                'davi'),
 ('gov',    'subject_requests','DPO',               'davi');
```

```sql
-- Every table nobody has said they answer for.
SELECT t.table_schema, t.table_name
FROM information_schema.tables t
LEFT JOIN gov.table_owners o USING (table_schema, table_name)
WHERE t.table_schema IN ('sales', 'health', 'support', 'gov')
  AND t.table_type = 'BASE TABLE'
  AND o.owner IS NULL
ORDER BY 1, 2;
```

```
ana@lab:~/gov$ psql -f owners.sql
SET
CREATE TABLE
INSERT 0 4
INSERT 0 10
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -f unowned.sql
SET
 table_schema |  table_name   
--------------+---------------
 gov          | ai_systems
 gov          | holidays
 gov          | table_owners
 sales        | deliveries
 sales        | returns
 support      | agent_regions
(6 rows)
```

Ten tables have an owner and a steward. Six do not, and each one says something:

- **`sales.deliveries`, `sales.returns`, `support.agent_regions`** came from lesson 2, created to show
  a privilege, and nobody has been asked about them since. In a real company these are the tables
  whose purpose nobody can explain three years later.
- **`gov.ai_systems` and `gov.holidays`** came from lesson 8. Governance tables need owners too —
  somebody has to add next year's holidays.
- **`gov.table_owners` itself.** The table that records ownership has none. It is the most common
  finding in any first inventory, and it is fixed the same way as the others: one row.

## Making it impossible to forget

The same move as lesson 6: the query above, run with the migrations, fails when it returns a row. A
new table then cannot reach production without somebody naming who answers for it — and the moment
that question is asked is the moment the person creating the table still knows the answer.
