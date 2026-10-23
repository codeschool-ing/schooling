---
title: One platform, many tenants
version: 1
---

Joana's first meeting with Talita Gomes, Serra Alta's Salesforce administrator, opened with the
question she had asked about every system at the fintech: where does the database run, and can the
reporting team have a read replica? Talita laughed, not unkindly. **There is no database Serra Alta
can connect to, and there will not be one.** Salesforce is not software that Serra Alta installed
somewhere. It is one platform shared by many thousands of companies, and Serra Alta rents a slice of
it, which Salesforce calls an **org**.

Everything else in this lesson follows from that sentence. The way you customise Salesforce, the
way you integrate with it and the limits you meet on the way are all consequences of sharing.

## Hosted is not the same as multitenant

The common picture is of a hosted copy. Somewhere in a data centre a server runs
"Serra Alta's Salesforce", with Serra Alta's database on it, the way a hosting company might run
a copy of an ERP for each customer. That arrangement exists and has a name, single-tenant hosting.
It is not this one.

**In a multitenant platform, every customer runs on the same application code and the same
database, and what keeps them apart is an identifier on every row.** Serra Alta's accounts, its
opportunities and its cases sit in the same physical tables as the records of a bank, a hospital and
a retailer, each row stamped with the org it belongs to. The platform adds that condition to every
query it runs on your behalf. You never see it, and you cannot remove it.

The obvious objection is that companies want different fields. Serra Alta's Account has a field for
the SAP customer number and another for the cooling capacity at a distributor's warehouse; a bank's
Account has neither. If every org shares one table, where do those fields live?

**The answer is that a field you add is data about your org, not a change to the database.** When
Talita creates a field, no `ALTER TABLE` runs anywhere. The platform records a row of **metadata**:
this org, this object, a field with this name, this type and this label. Salesforce's own published
description of the design, written when the platform was still called Force.com, explains that
records are kept in large shared tables with generic columns, and that the metadata says which
generic column holds which of your fields. When a page is drawn, a report is run or an API call
arrives, the platform reads your metadata and builds the answer from it.

That is why a new field appears in the page editor, the reports and the API within seconds of being
saved. It is also why the whole of your configuration can be read out as files, which section 03
returns to, and why you will never be handed a connection string. Your data is in tables you would
not recognise, mixed with everybody else's.

## Standard objects and custom objects

Salesforce calls its tables **objects** and its columns **fields**. Some objects come with every
org, because every company that sells needs them. These are the five an architect meets first:

| standard object | what one record is | at Serra Alta |
|---|---|---|
| Account | a company you sell to, or one site of it | a supermarket chain, a distributor, one of a chain's 300 stores |
| Contact | a person at an account | the chain's dairy category buyer |
| Lead | somebody who might become a customer, not yet qualified | a regional chain that asked for a price list |
| Opportunity | a possible sale, with an amount, a stage and a date | a year's supply of UHT milk to a new distributor |
| Case | a problem a customer raised | a complaint about a swollen yoghurt pot; a question about a recalled batch |

Everything a company adds is custom, and **the API name of a custom object or a custom field ends
in `__c`**. Serra Alta has `Visit__c`, one record per visit a rep makes to a store, and `Invoice__c`,
a copy of the invoices SAP issues, filled every night by an integration. It also has custom fields on
standard objects: `Account.SAP_Customer_Number__c` is a field Serra Alta added to the standard
Account. The suffix is useful when you read an integration mapping, because it tells you at once
which half of a name Salesforce shipped and which half somebody at Serra Alta invented.

You read the data with **SOQL**, Salesforce's query language. It looks like SQL and is narrower: a
`SELECT` over one object and the objects related to it, with no arbitrary joins, no `UPDATE` and no
way past the platform. `SELECT Name, SAP_Customer_Number__c FROM Account WHERE Industry = 'Retail'`
is a SOQL query, and it runs through the platform like everything else.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l04-tenants\" aria-label=\"Four orgs side by side at the top: Serra Alta's org, two other companies' orgs, and a box for the thousands more. Each holds its own metadata and its own rows. Below them a dashed amber line, the governor limits, applies to every org alike: per transaction, 100 SOQL queries, 150 DML statements and 10 seconds of CPU. Under the line is one platform: shared application servers, shared tables where a field is a row of metadata rather than a column, and three releases a year arriving for every org at once.\"><defs><marker id=\"l04-tenants-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"21.0\" y=\"28.0\" width=\"158.0\" height=\"84.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Serra Alta's org</text><text x=\"100.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its metadata</text><text x=\"100.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its rows</text><path d=\"M100.0 114.0 L100.0 156.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M100.0 176.0 L100.0 196.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-tenants-es-ah-paper-dim)\"></path><rect x=\"194.0\" y=\"28.0\" width=\"158.0\" height=\"84.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"273.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a bank's org</text><text x=\"273.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its metadata</text><text x=\"273.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its rows</text><path d=\"M273.0 114.0 L273.0 156.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M273.0 176.0 L273.0 196.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-tenants-es-ah-paper-dim)\"></path><rect x=\"367.0\" y=\"28.0\" width=\"158.0\" height=\"84.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"446.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a hospital's org</text><text x=\"446.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its metadata</text><text x=\"446.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its rows</text><path d=\"M446.0 114.0 L446.0 156.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M446.0 176.0 L446.0 196.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-tenants-es-ah-paper-dim)\"></path><rect x=\"540.0\" y=\"28.0\" width=\"158.0\" height=\"84.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"619.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">thousands more</text><text x=\"619.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its metadata</text><text x=\"619.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its rows</text><path d=\"M619.0 114.0 L619.0 156.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M619.0 176.0 L619.0 196.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-tenants-es-ah-paper-dim)\"></path><path d=\"M24.0 150.0 L696.0 150.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"360.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">governor limits, the same for every org: per transaction, 100 SOQL queries, 150 DML statements, 10 s of CPU</text><rect x=\"24.0\" y=\"198.0\" width=\"672.0\" height=\"112.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">one platform</text><text x=\"360.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shared application servers and shared tables, every row stamped with its org</text><text x=\"360.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a field you add is a row of metadata, not a column you own</text><text x=\"360.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">three releases a year, arriving for every org at once</text></svg>", "caption": "What multitenant means. Every org runs on the same code and the same tables; the fence between them and the platform is the governor limits, and it is the same fence for all."}
```

## Three releases a year, on somebody else's calendar

At Serra Alta the SAP team decides when SAP changes. Lesson 1 described the calendar Edson Prado's
team keeps: the maintenance window every Sunday from 01:00 to 05:00, and the frozen week while
finance closes the month. **Salesforce changes on Salesforce's calendar.** There are three major
releases a year, named Spring, Summer and Winter with a year after them, and each one reaches every
org on the platform within a few weeks. The year in the name runs ahead of the calendar: a Winter
release arrives in the northern autumn before it.

You cannot decline a release or postpone it. What you get is notice: release notes published
before the upgrade, and a **preview window** in which a sandbox can be upgraded some weeks before
production. Talita's routine is built on that window. Serra Alta's Full sandbox, the copy of
production described in section 03, is put on the preview, and Rui Andrade's team runs the
integration flows against it before the release reaches the 140 reps.

Each release also brings a new version of the APIs. Old versions keep working for years, and then
Salesforce announces that a range of them will be retired on a date. **An integration nobody has
touched since 2018 can stop working because of a date in somebody else's release notes**, and
nothing in Serra Alta's own change log will explain it. Knowing which API version each flow calls is
part of Rui's inventory now.

## Governor limits: the price of sharing

A shared platform has a problem a private server does not. If one org runs a badly written loop
that queries the database a million times, every other org on the same servers slows down. The
platform's answer is to put a fence around every piece of code that runs on it.

**Every transaction in Salesforce runs under governor limits, and code that crosses one is stopped,
not slowed.** These four are long-standing and documented in Salesforce's own Apex reference:

| limit, per transaction | synchronous | asynchronous |
|---|---|---|
| SOQL queries issued | 100 | 200 |
| DML statements (insert, update, delete…) | 150 | 150 |
| CPU time | 10 seconds | 60 seconds |
| records retrieved by all SOQL queries | 50,000 | 50,000 |

Code written in Apex, Salesforce's programming language, that issues its 101st query in a
synchronous transaction gets an exception with a famous message, `Too many SOQL queries: 101`. Apex
cannot catch it. **The whole transaction is rolled back**, including every record it had already
written, and whoever started it, a person pressing Save or an integration calling the API, gets the
error.

At the fintech, a query inside a loop was a slow endpoint, a graph that went up on a Monday and a
ticket for somebody to fix. Here it is a failure the moment the volume crosses a line, and the line
is fixed by the platform, not by Serra Alta. Joana found the arrangement harsh for about a week. Then
she saw what it buys: no other org can slow Serra Alta down either, and code that survives the limits
has been written to work on records in sets, which is the habit section 04 shows Serra Alta lacking.

There are limits at the level of the whole org as well as the transaction: how much data it may
store, and how many API requests every integration together may make in 24 hours. The second one is
where Serra Alta was hurt, and it has a section of its own.

## A free org to look around in

Salesforce gives a free **Developer Edition** org to anybody who signs up. It has the standard
objects, the setup screens, Flow and the APIs, with small storage and small allowances. **Nothing in
this lesson needs it.** If you want to see the object manager, create a field and watch it appear in
the API, it is the cheapest way there is to look at the inside of the product.
