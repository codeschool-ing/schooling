---
title: Lineage — where it came from, where it goes
version: 1
---

**Lineage** is the map of how data moves: which sources feed a table, which views and jobs read it,
which reports and exports come out the other end. It answers two questions that come up every week in
a data team, and both are governance questions:

- **"If I change this column, what breaks?"** — downstream lineage;
- **"Where did this number come from?"** — upstream lineage.

And a third that comes up in this course: **"which systems hold this person's data?"** — the question
behind every access request, erasure and incident of lesson 7.

## What the database already knows

Inside PostgreSQL, part of the map is recorded for you. A view cannot be created without the
database knowing which tables it reads, because it has to refuse to drop them:

```sql
-- Which views read which tables, from PostgreSQL's own record of it.
SELECT DISTINCT v.relnamespace::regnamespace || '.' || v.relname AS view,
       t.relnamespace::regnamespace || '.' || t.relname          AS reads
FROM pg_depend d
JOIN pg_rewrite r ON r.oid = d.objid
JOIN pg_class v   ON v.oid = r.ev_class
JOIN pg_class t   ON t.oid = d.refobjid
WHERE d.classid = 'pg_rewrite'::regclass
  AND d.refclassid = 'pg_class'::regclass
  AND t.oid <> v.oid
  AND v.relnamespace::regnamespace::text IN ('sales', 'health', 'support', 'gov')
ORDER BY 1, 2;
```

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -f lineage.sql
SET
           view           |         reads         
--------------------------+-----------------------
 sales.consent_now        | sales.consent_events
 sales.customer_profile   | sales.customers
 support.customer_card    | sales.customers
 support.customer_card    | support.agent_regions
 support.tickets_redacted | support.tickets
(5 rows)
```

Five edges, and none of them was written by hand. `support.customer_card` reads `sales.customers` —
which means a change to the customers table is a change to what a support agent sees, and that is
the sort of thing that is learnt the hard way when it is not written anywhere. Lesson 5 learnt it so:
dropping the `cpf` column was refused because two views depended on it.

## What it does not know

The rest of the map lives outside the database, and nobody records it but you:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l9-lineage\" aria-label=\"A lineage map of Ipê's customer data. The shop's loader writes sales.customers, sales.orders and the other tables. Views read them: customer_profile and customer_card read customers, tickets_redacted reads tickets, consent_now reads consent_events. Outside the database, export_subject.py, the RIPD facts query, the analysts, the AI systems and the backups read them too. The database records the edges to the views; the edges outside it are recorded only if somebody declares them.\"><defs><marker id=\"dg-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"dg-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"170.0\" y=\"20.0\" width=\"380.0\" height=\"220.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"360.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">inside PostgreSQL</text><rect x=\"20.0\" y=\"110.0\" width=\"120.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">shop loader</text><text x=\"80.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">upstream</text><rect x=\"190.0\" y=\"44.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"265.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sales.customers</text><path d=\"M140.0 135.0 L188.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"190.0\" y=\"94.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"265.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sales.orders</text><path d=\"M140.0 135.0 L188.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"190.0\" y=\"144.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"265.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">support.tickets</text><path d=\"M140.0 135.0 L188.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"190.0\" y=\"194.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"265.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">consent_events</text><path d=\"M140.0 135.0 L188.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"385.0\" y=\"44.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"460.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">customer_profile</text><path d=\"M340.0 60.0 L383.0 60.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-phosphor)\"></path><rect x=\"385.0\" y=\"94.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"460.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">customer_card</text><path d=\"M340.0 60.0 L383.0 110.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-phosphor)\"></path><rect x=\"385.0\" y=\"144.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"460.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">tickets_redacted</text><path d=\"M340.0 160.0 L383.0 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-phosphor)\"></path><rect x=\"385.0\" y=\"194.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"460.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">consent_now</text><path d=\"M340.0 210.0 L383.0 210.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-phosphor)\"></path><rect x=\"590.0\" y=\"34.0\" width=\"115.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"647.5\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">export_subject.py</text><path d=\"M550.0 135.0 L588.0 50.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"590.0\" y=\"79.0\" width=\"115.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"647.5\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">RIPD facts</text><path d=\"M550.0 135.0 L588.0 95.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"590.0\" y=\"124.0\" width=\"115.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"647.5\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">analysts</text><path d=\"M550.0 135.0 L588.0 140.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"590.0\" y=\"169.0\" width=\"115.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"647.5\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">AI systems</text><path d=\"M550.0 135.0 L588.0 185.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"590.0\" y=\"214.0\" width=\"115.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"647.5\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">backups</text><path d=\"M550.0 135.0 L588.0 230.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"360.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">solid: recorded by the database · dashed: declared, or nowhere</text></svg>", "caption": "Solid lines PostgreSQL knows about; dashed lines only somebody can write down."}
```

- the **loader** that writes the tables from the shop's system;
- the **scripts** that read them — `export_subject.py` of lesson 7, the facts query of the RIPD;
- the **people** who read them, through the roles of lesson 2;
- the **copies**: the backups, the analyst's extract, the AI systems of lesson 8.

Lineage tools collect some of these automatically, by reading query logs or instrumenting jobs —
OpenLineage is an open standard for it. The rest is declared: a job that writes a table says so, in
the same repository as the job. Either way, the test of a lineage map is the question of lesson 7:
when a customer asks for erasure, does the map list every place their data went? The edges a tool
cannot see are exactly the ones where it did not.
