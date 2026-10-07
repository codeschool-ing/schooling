---
title: Grant to the job, not to the person
version: 1
---

Bruno's grant answered one question: what may Bruno read? The question that survives a year of
hires and departures is a different one — **what may an analyst read?** — and its answer should
be written once, in one place, and apply to whoever is an analyst today.

That is **role-based access control**: privileges are granted to roles that stand for jobs, and
people are made members of the jobs they do.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l2-rbac\" aria-label=\"Role-based access control in Ipê's database. On the left, the logins: bruno, carla, site_app and etl_loader. In the middle, the jobs they are members of: analyst, support_agent, app_web and pipeline. On the right, what each job may do. Privileges are granted to the jobs only; no arrow goes from a person to a table.\"><defs><marker id=\"dg-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"dg-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"80.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">logins</text><text x=\"300.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">jobs</text><text x=\"560.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">privileges</text><rect x=\"20.0\" y=\"44.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">bruno</text><rect x=\"225.0\" y=\"44.0\" width=\"150.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">analyst</text><rect x=\"440.0\" y=\"40.0\" width=\"260.0\" height=\"52.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"57.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SELECT orders, items, products</text><text x=\"570.0\" y=\"74.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SELECT 6 columns of customers</text><path d=\"M140.0 66.0 L223.0 66.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><path d=\"M375.0 66.0 L438.0 66.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-phosphor)\"></path><rect x=\"20.0\" y=\"108.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">carla</text><rect x=\"225.0\" y=\"108.0\" width=\"150.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">support_agent</text><rect x=\"440.0\" y=\"104.0\" width=\"260.0\" height=\"52.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"121.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SELECT customers, orders</text><text x=\"570.0\" y=\"138.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UPDATE (status) tickets</text><path d=\"M140.0 130.0 L223.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><path d=\"M375.0 130.0 L438.0 130.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-phosphor)\"></path><rect x=\"20.0\" y=\"172.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">site_app</text><rect x=\"225.0\" y=\"172.0\" width=\"150.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app_web</text><rect x=\"440.0\" y=\"168.0\" width=\"260.0\" height=\"52.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"185.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SELECT products</text><text x=\"570.0\" y=\"202.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">INSERT orders, items, payments</text><path d=\"M140.0 194.0 L223.0 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><path d=\"M375.0 194.0 L438.0 194.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-phosphor)\"></path><rect x=\"20.0\" y=\"236.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">etl_loader</text><rect x=\"225.0\" y=\"236.0\" width=\"150.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pipeline</text><rect x=\"440.0\" y=\"232.0\" width=\"260.0\" height=\"52.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"249.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SELECT customers, orders, items,</text><text x=\"570.0\" y=\"266.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">payments, products</text><path d=\"M140.0 258.0 L223.0 258.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><path d=\"M375.0 258.0 L438.0 258.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-phosphor)\"></path></svg>", "caption": "People are members of jobs; jobs hold privileges. A new analyst is one membership, not forty grants."}
```

In PostgreSQL a job is just a role that cannot log in:

```sql
-- One role per job, none of which can log in. People are made members.
CREATE ROLE analyst       NOLOGIN;
CREATE ROLE support_agent NOLOGIN;
CREATE ROLE app_web       NOLOGIN;
CREATE ROLE pipeline      NOLOGIN;

GRANT analyst       TO bruno, lia;
GRANT support_agent TO carla;
GRANT app_web       TO site_app;
GRANT pipeline      TO etl_loader;

-- What each job may do, granted to the job and never to the person.
SET ROLE ipe_owner;
GRANT USAGE ON SCHEMA sales TO analyst, support_agent, app_web, pipeline;
GRANT USAGE ON SCHEMA support TO support_agent;

GRANT SELECT ON sales.orders, sales.order_items, sales.products TO analyst;
GRANT SELECT ON sales.orders, sales.order_items, sales.products,
                sales.customers, sales.payments TO pipeline;
GRANT SELECT ON sales.products TO app_web;
GRANT INSERT ON sales.orders, sales.order_items, sales.payments TO app_web;
GRANT SELECT ON sales.customers, sales.orders TO support_agent;
GRANT SELECT, UPDATE (status) ON support.tickets TO support_agent;

-- Bruno's own grants were the first draft. The group replaces them.
REVOKE SELECT ON sales.orders FROM bruno;
REVOKE USAGE ON SCHEMA sales FROM bruno;
```

```
ana@lab:~/gov$ psql -f groups.sql
CREATE ROLE
CREATE ROLE
CREATE ROLE
CREATE ROLE
GRANT ROLE
GRANT ROLE
GRANT ROLE
GRANT ROLE
SET
GRANT
GRANT
GRANT
GRANT
GRANT
GRANT
GRANT
GRANT
REVOKE
REVOKE
ana@lab:~/gov$ psql -c "\drg"
                 List of role grants
 Role name  |   Member of   |   Options    | Grantor  
------------+---------------+--------------+----------
 ana        | analyst       | ADMIN        | postgres
 ana        | app_web       | ADMIN        | postgres
 ana        | bruno         | ADMIN        | postgres
 ana        | carla         | ADMIN        | postgres
 ana        | davi          | ADMIN        | postgres
 ana        | etl_loader    | ADMIN        | postgres
 ana        | ipe_owner     | SET          | postgres
 ana        | lia           | ADMIN        | postgres
 ana        | pipeline      | ADMIN        | postgres
 ana        | site_app      | ADMIN        | postgres
 ana        | support_agent | ADMIN        | postgres
 bruno      | analyst       | INHERIT, SET | ana
 carla      | support_agent | INHERIT, SET | ana
 etl_loader | pipeline      | INHERIT, SET | ana
 lia        | analyst       | INHERIT, SET | ana
 site_app   | app_web       | INHERIT, SET | ana
(16 rows)

ana@lab:~/gov$ psql -c "\dp sales.orders"
                                  Access privileges
 Schema |  Name  | Type  |      Access privileges      | Column privileges | Policies 
--------+--------+-------+-----------------------------+-------------------+----------
 sales  | orders | table | ipe_owner=arwdDxt/ipe_owner+|                   | 
        |        |       | analyst=r/ipe_owner        +|                   | 
        |        |       | pipeline=r/ipe_owner       +|                   | 
        |        |       | app_web=a/ipe_owner        +|                   | 
        |        |       | support_agent=r/ipe_owner   |                   | 
(1 row)

ana@lab:~/gov$ psql service=bruno -c "SELECT count(*) FROM sales.order_items"
 count 
-------
 63472
(1 row)

ana@lab:~/gov$ psql service=bruno -c "SELECT count(*) FROM health.prescriptions"
ERROR:  permission denied for schema health
LINE 1: SELECT count(*) FROM health.prescriptions
                             ^
```

`\drg` lists who is a member of what. Ana appears with `ADMIN` on every role she created — she can
add and remove members — and with `SET` alone on `ipe_owner`, the arrangement of lesson 1. Each
person is a member of one job with `INHERIT, SET`: the job's privileges flow to them without
their having to ask.

The table's privileges no longer mention a person. `\dp sales.orders` lists four jobs, and
`app_web=a` says the website may insert orders and do nothing else with them. Bruno reads
`order_items` now, through `analyst`, and `health.prescriptions` stays closed at the schema:
nobody granted any job `USAGE` on `health`.

## What it buys

**A new analyst is one statement**, `GRANT analyst TO …`, and gets exactly what the others have.
**A departure is one statement** too, and the grants on forty tables do not have to be found.
**An access review reads four jobs**, not every person: "what may an analyst read" is answered by
`\dp`, and "who is an analyst" by `\drg`.

And the grants become **a description of the business** that somebody other than Ana can read.
`support_agent` may update one column of the tickets table, `status`, and no other: written down
that way, the question "may support close a ticket?" has an answer, and so does "may support
rewrite what a customer said?".

## Where it stops being enough

Roles are coarse on purpose. Every analyst gets the same rows and the same columns, and that is
right until the rule depends on **something about the row**, or **something about the person**
that a job title does not carry: Carla serves São Paulo and Rio, another agent serves the south.
Two more tools take it from there — privileges on columns, and policies on rows — and an
attribute-based rule is a policy that reads an attribute. The rest of this lesson builds each.
