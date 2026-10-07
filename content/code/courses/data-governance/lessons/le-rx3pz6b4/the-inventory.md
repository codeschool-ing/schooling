---
title: The inventory
version: 1
---

Everything in this lesson — and most of what the law asks in lesson 7 — assumes Ipê can answer
**"what personal data do you hold, where, and why?"** A company that cannot answer that cannot
answer a customer asking for their data, cannot assess a risk, and cannot say what a breach exposed.

The LGPD makes the answer an obligation. **Article 37**: the controller and the processor must keep a
**record of the processing operations** they carry out — especially when the legal basis is
legitimate interest. In GDPR's vocabulary it is a ROPA, a record of processing activities. Its
columns, in practice:

| question | an example at Ipê |
|---|---|
| what data | customers' name, e-mail, CPF, date of birth, address |
| about whom | customers, including adolescents |
| for what purpose | selling and delivering medicines |
| on which legal basis | performance of a contract; for prescriptions, health protection (lesson 7) |
| shared with whom | the payment provider, the delivery company |
| kept for how long | lesson 10 |
| protected how | lessons 1 to 5 |

That record is written by people who know the purposes. The data team's part is the first row and
the last two: knowing exactly what is stored, where, and how it is protected — and keeping that true
as the schema changes.

## Starting from the schema

The database can say what exists. A first count:

```sql
-- The first draft of an inventory: every column that exists, per table.
SET ROLE ipe_owner;
SELECT table_schema || '.' || table_name AS table, count(*) AS columns
FROM information_schema.columns
WHERE table_schema IN ('sales', 'health', 'support')
  AND table_name IN (SELECT table_name FROM information_schema.tables
                     WHERE table_type = 'BASE TABLE')
GROUP BY 1 ORDER BY 1;
```

```
ana@lab:~/gov$ psql -f inventory.sql
SET
         table         | columns 
-----------------------+---------
 health.prescriptions  |       7
 sales.customers       |      13
 sales.deliveries      |       2
 sales.order_items     |       5
 sales.orders          |       5
 sales.payments        |       5
 sales.products        |       6
 sales.returns         |       3
 support.agent_regions |       2
 support.tickets       |       5
(10 rows)
```

Ten tables and 53 columns in three schemas — small, and already more than anybody would keep in their
head. Real databases have hundreds of tables, and the inventory that matters is not "which tables
exist" but **"which columns hold what kind of data"**, because grants, masking, encryption and
retention are all decided per column. The next section builds that, in the database, where a
query can check it.
