---
title: The impact assessment (RIPD)
version: 1
---

The **relatório de impacto à proteção de dados pessoais** — RIPD, the Brazilian name for what the
GDPR calls a DPIA — is defined in **article 5, XVII**: the controller's documentation describing the
processing that **may create risks to civil liberties and fundamental rights**, and the measures,
safeguards and mechanisms that mitigate those risks.

The LGPD does not make it compulsory for every processing. **Article 38** lets the ANPD require one,
"including of sensitive data"; article 10, §3 lets it ask for one when the basis is legitimate
interest. In practice a controller writes it before the ANPD asks, for the processing where the risk
is real, because writing it afterwards, under a deadline, produces a document that describes what
somebody hoped was true.

Article 38's single paragraph says what it contains **at a minimum**:

- a description of the **types of data** collected;
- the **methodology** used to collect them and to keep them secure;
- the controller's analysis of the **measures, safeguards and risk-mitigation mechanisms** adopted.

For a pharmacy, the processing that calls for one is plain: prescriptions, and the order lines that
lesson 6 showed are health data by inference.

## The facts are a query

A RIPD written from memory says "about five thousand customers" and "only the pharmacists read
prescriptions". Ipê's facts section is computed:

```sql
-- The facts section of a data protection impact assessment, computed
-- rather than estimated: how many people, which classes of data, how much.
SET ROLE ipe_owner;
SELECT 'customers'                        AS fact, count(*)::text AS value FROM sales.customers
UNION ALL SELECT 'of whom under 18',
       count(*)::text FROM sales.customers
       WHERE age(DATE '2026-07-01', birth_date) < interval '18 years'
UNION ALL SELECT 'customers with a prescription',
       count(DISTINCT customer_id)::text FROM health.prescriptions
UNION ALL SELECT 'prescriptions held', count(*)::text FROM health.prescriptions
UNION ALL SELECT 'oldest prescription', min(issued_on)::text FROM health.prescriptions
UNION ALL SELECT 'sensitive columns', count(*)::text FROM gov.column_class WHERE class = 'sensitive'
UNION ALL SELECT 'roles that read health', string_agg(DISTINCT grantee, ', ')
       FROM information_schema.role_table_grants
       WHERE table_schema = 'health' AND privilege_type = 'SELECT';
```

```
ana@lab:~/gov$ psql -f ripd-facts.sql
SET
             fact              |           value            
-------------------------------+----------------------------
 sensitive columns             | 9
 roles that read health        | ipe_owner, privacy_officer
 oldest prescription           | 2019-01-06
 prescriptions held            | 29352
 customers with a prescription | 4758
 customers                     | 6012
 of whom under 18              | 20
(7 rows)
```

Every line is a sentence of the report, and several are findings:

- **29,352 prescriptions, the oldest from January 2019.** Seven and a half years of health records.
  The RIPD has to say how long they are kept and why, and right now the honest answer is "we never
  delete them" — lesson 10's work.
- **4,758 of 6,012 customers** have a prescription: health data about 79% of the customer base, not
  a corner of it.
- **20 customers under 18.** Article 14 applies to them (lesson 6), and the RIPD says how.
- **Two roles read the health schema**: the owner and, since section 9, the DPO. No analyst, no
  application role. That is a measured safeguard, which reads very differently from an asserted one.
- **9 sensitive columns**, from lesson 6's classification — the inventory the report describes.

The rows came back in an order the query never asked for — a `UNION ALL` without `ORDER BY` promises
none. For a report that is harmless; for a query whose order matters it would be a bug.

## The rest of the document

The measures and safeguards are the previous six lessons: authentication and roles (1, 2),
encryption in transit and at rest (3), keys held outside the database (4), pseudonymised CPFs
(5), classification and minimisation (6). Each is listed with the evidence — a query, a
configuration file, a capture — rather than a sentence. **The residual risks** are what is left:
prescriptions with no retention period, backups nobody has tested, a support team reading free
text. A RIPD that lists no residual risk has not looked.
