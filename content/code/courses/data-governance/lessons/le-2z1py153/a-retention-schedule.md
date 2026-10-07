---
title: A retention schedule, as a table
version: 1
---

A retention schedule says, for each kind of record: **how long**, **counted from when**, **why**, and
**who decided**. Ipê's first three rules:

```sql
-- How long each kind of record is kept, from when, and why. One row per
-- rule; the purge reads nothing else.
SET ROLE ipe_owner;
CREATE TABLE gov.retention (
  table_schema name     NOT NULL,
  table_name   name     NOT NULL,
  keep_for     interval NOT NULL,
  counted_from text     NOT NULL,
  basis        text     NOT NULL,
  decided_by   text     NOT NULL,
  PRIMARY KEY (table_schema, table_name)
);
INSERT INTO gov.column_class
SELECT 'gov', 'retention', c, 'none', 'a rule about tables, not people'
FROM unnest(ARRAY['table_schema','table_name','keep_for','counted_from','basis','decided_by']) c;
INSERT INTO gov.retention VALUES
 ('sales',  'orders',        '5 years', 'the first day of the year after the order',
  'tax records: five years from the start of the following year', 'finance manager'),
 ('health', 'prescriptions', '2 years', 'the day the prescription was issued',
  'the chief pharmacist''s rule, after the health rules for controlled medicines',
  'chief pharmacist'),
 ('support','tickets',       '2 years', 'the day the ticket was opened, once closed',
  'no law asks for more; long enough to see a complaint come back', 'head of support');
```

Each column earns its place:

- **`keep_for`** is an `interval`, so the purge can do arithmetic with it, and so it cannot say
  "a while".
- **`counted_from`** is where retention schedules most often go wrong. Brazilian tax law counts its
  five years from the **first day of the year after** the one the record belongs to, not from the date
  of the order; an order of March 2020 is kept until the end of 2025, not March 2025. A schedule that
  counts from the wrong day deletes too early, and that one is a breach of a different law.
- **`basis`** says why in words. The tickets rule says plainly that no law asks for two years — it is a
  business decision, and saying so is what lets somebody change it later without fearing a law they
  cannot find.
- **`decided_by`** names the role that owns the decision, as in lesson 9.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l10-timeline\" aria-label=\"The retention timeline of an order placed in March 2020. The tax rule counts five years from the first day of the following year, 1 January 2021, so the order may be purged from 1 January 2026. Counting from the order date instead would have deleted it in March 2025, nine months too early. A legal hold stops the clock for as long as it lasts.\"><path d=\"M40.0 110.0 L680.0 110.0\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M40.0 104.0 L40.0 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"40.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2020</text><path d=\"M131.4 104.0 L131.4 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"131.4\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2021</text><path d=\"M222.9 104.0 L222.9 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"222.9\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2022</text><path d=\"M314.3 104.0 L314.3 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"314.3\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2023</text><path d=\"M405.7 104.0 L405.7 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"405.7\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2024</text><path d=\"M497.1 104.0 L497.1 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"497.1\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2025</text><path d=\"M588.6 104.0 L588.6 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"588.6\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2026</text><path d=\"M680.0 104.0 L680.0 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"680.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2027</text><rect x=\"131.4\" y=\"84.0\" width=\"457.1\" height=\"18.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">five years, from 1 January 2021</text><circle cx=\"58.3\" cy=\"110.0\" r=\"6\" fill=\"var(--paper)\"></circle><text x=\"58.3\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ordered</text><text x=\"58.3\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">March 2020</text><circle cx=\"588.6\" cy=\"110.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"588.6\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">may be purged</text><text x=\"588.6\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 January 2026</text><circle cx=\"515.4\" cy=\"160.0\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M515.4 116.0 L515.4 154.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"515.4\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">counted from the order: March 2025, too early</text><text x=\"360.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a legal hold stops the clock until it is released</text></svg>", "caption": "Counted from the wrong day, a retention rule breaks a different law."}
```

## What is overdue today

```sql
-- On the lab's today, how many rows are past what gov.retention allows.
SET ROLE ipe_owner;
SELECT 'sales.orders' AS "table", count(*) AS past_retention
  FROM sales.orders
  WHERE date_trunc('year', ordered_at) + interval '1 year'
        + (SELECT keep_for FROM gov.retention WHERE table_name = 'orders') <= DATE '2026-07-01'
UNION ALL
SELECT 'health.prescriptions', count(*)
  FROM health.prescriptions
  WHERE issued_on + (SELECT keep_for FROM gov.retention WHERE table_name = 'prescriptions')
        <= DATE '2026-07-01'
UNION ALL
SELECT 'support.tickets', count(*)
  FROM support.tickets
  WHERE status = 'closed'
    AND opened_at + (SELECT keep_for FROM gov.retention WHERE table_name = 'tickets')
        <= DATE '2026-07-01';
```

```
ana@lab:~/gov$ psql -f retention.sql
SET
CREATE TABLE
INSERT 0 6
INSERT 0 3
ana@lab:~/gov$ psql -f overdue.sql
SET
        table         | past_retention 
----------------------+----------------
 sales.orders         |            963
 health.prescriptions |           9847
 support.tickets      |            367
(3 rows)
```

On the lab's today, 1 July 2026: **963 orders** from 2020 and before, **9,847 prescriptions** issued
two years ago or more, and **367 closed tickets** older than two years. None of them has a reason to
exist any more, by Ipê's own rules. Every one of them is personal data, nine in ten of them health
data, and every one would be in the next leak.

The query only counts. Deciding to delete is a separate step, and the next section is the reason it
cannot be a plain `DELETE`.
