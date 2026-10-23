---
title: One database for the whole business
version: 1
---

**The single database is what a company buys when it buys an ERP.** The modules can be had
separately, and before the ERP they were: a sales system, a stock system, a payroll system and an
accounting package, each bought for its own department, each with its own database. What the ERP
sold was the end of the arguments between them.

## Before: one system per department

Serra Alta in the 1990s is the example, and it is a typical one. Sales took orders in one program.
Stock was counted in another. Accounting ran a third, fed every night with a file of the day's
invoices. Coleta, the milk collection system, is the survivor of that era, and lesson 13 is about
finally retiring it.

Each system kept its own copy of the things all of them needed. The customer existed three times,
once in each, typed by three different people. A product had a code in sales and a different one in
the warehouse. Every night, files moved between them. **And every month, somebody spent a week
making the numbers agree**: the stock the warehouse counted, the stock the accounts said should be
there, and the sales that sat between them, with a spreadsheet of differences and a column headed
"explanation".

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l01-before-after\" aria-label=\"Two panels. On the left, before the ERP: three systems, sales, stock and accounting, each with its own database holding its own copy of the customer and the product, joined by files sent every night, and a spreadsheet of differences made at the end of every month. On the right, an ERP: six modules, sales, purchasing and stock, finance, controlling, production and quality, all standing on one database that holds the master data once and the transactions that refer to it.\"><defs><marker id=\"l01-before-after-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"175.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">before: one system per department</text><text x=\"545.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">after: modules over one database</text><path d=\"M360.0 36.0 L360.0 310.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"17.0\" y=\"53.0\" width=\"96.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sales</text><rect x=\"25.0\" y=\"120.0\" width=\"80.0\" height=\"62.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">customer</text><text x=\"65.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">product</text><text x=\"65.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its own copy</text><path d=\"M65.0 87.0 L65.0 120.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"127.0\" y=\"53.0\" width=\"96.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">stock</text><rect x=\"135.0\" y=\"120.0\" width=\"80.0\" height=\"62.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">customer</text><text x=\"175.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">product</text><text x=\"175.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its own copy</text><path d=\"M175.0 87.0 L175.0 120.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"237.0\" y=\"53.0\" width=\"96.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">accounting</text><rect x=\"245.0\" y=\"120.0\" width=\"80.0\" height=\"62.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">customer</text><text x=\"285.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">product</text><text x=\"285.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its own copy</text><path d=\"M285.0 87.0 L285.0 120.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M107.0 151.0 L131.0 151.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-before-after-es-ah-paper-dim)\"></path><path d=\"M217.0 151.0 L241.0 151.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-before-after-es-ah-paper-dim)\"></path><text x=\"120.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nightly file</text><text x=\"230.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nightly file</text><rect x=\"40.0\" y=\"232.0\" width=\"270.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">every month: a spreadsheet of differences</text><text x=\"175.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">and a column headed &quot;explanation&quot;</text><rect x=\"386.0\" y=\"56.0\" width=\"48.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"410.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">SD</text><text x=\"410.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">sales</text><path d=\"M410.0 104.0 L410.0 150.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"440.0\" y=\"56.0\" width=\"48.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"464.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">MM</text><text x=\"464.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">stock</text><path d=\"M464.0 104.0 L464.0 150.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"494.0\" y=\"56.0\" width=\"48.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"518.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">FI</text><text x=\"518.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">finance</text><path d=\"M518.0 104.0 L518.0 150.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"548.0\" y=\"56.0\" width=\"48.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"572.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CO</text><text x=\"572.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">costs</text><path d=\"M572.0 104.0 L572.0 150.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"602.0\" y=\"56.0\" width=\"48.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"626.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">PP</text><text x=\"626.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">production</text><path d=\"M626.0 104.0 L626.0 150.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"656.0\" y=\"56.0\" width=\"48.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"680.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">QM</text><text x=\"680.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">quality</text><path d=\"M680.0 104.0 L680.0 150.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"384.0\" y=\"150.0\" width=\"324.0\" height=\"76.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"546.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">one database</text><text x=\"546.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">master data, once: customers, materials, suppliers</text><text x=\"546.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">transactions that point at it: orders, invoices, payments</text><text x=\"546.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">no file to arrive late, no copy to drift</text></svg>", "caption": "What an ERP replaced. The copies on the left were each correct by their own rules, which is why they disagreed; on the right there is one record of each thing and every module reads it."}
```

The differences were not carelessness. Each copy was correct by its own system's rules, and the
rules differed. Sales counted an order as sold when the customer confirmed it; the warehouse counted
it when the truck left; accounting counted it when the invoice was issued. Three true answers to
"what did we sell in March" is the normal result of three databases, and choosing between them was a
monthly meeting.

## After: modules over one database

An ERP replaces the copies with one record of each thing, shared by every module. **The data falls
into two kinds, and the distinction is used everywhere in this course.**

**Master data** describes the things the business deals with and changes slowly: customers,
suppliers, materials, plants, prices, bank accounts. At Serra Alta that means about 9,800 customers,
about 2,600 active materials and the 1,900 farms recorded as suppliers. A customer is created once,
by one team, and every module reads the same record.

**Transactional data** records what happened: an order, a delivery, a goods receipt, an invoice, a
payment. It refers to master data rather than copying it. An order says *customer 100482* and
*material 4000127*; it does not repeat the customer's address or the product's description.

When the sales module posts a delivery, the stock module and the accounting module are not told
about it afterwards. They are reading the same rows. **There is no file to arrive late and no copy
to drift**, which is the whole of the monthly reconciliation gone in one design decision.

## The price of one database

What the single database buys is real, and it is paid for in three ways that matter to an
architect.

**First, everybody has to agree on one meaning.** If sales and finance both read the same customer
record, then "customer" has one definition, and the company has to settle it. Is a supermarket chain
one customer or one per store? Is the bakery that pays through a distributor a customer at all? In
the separate systems each department answered for itself. In the ERP the answer is a configuration
decision taken once, and the department that lost the argument lives with the other's definition.
You met the same tension in `design-patterns` as the bounded context: one model for a whole company
is exactly what Domain-Driven Design warns against. **An ERP is one bounded context stretched over
the whole company on purpose**, and that works because the business functions it covers have
agreed, over decades of accounting practice, what most of the words mean.

**Second, the schema belongs to the vendor.** The database is enormous: an SAP ECC system has tens of
thousands of tables, most named with a few letters of German abbreviation. Customer master data
sits in tables called `KNA1` and `KNB1`, sales order items in `VBAP`. Serra Alta did not design any of
them and cannot change them, and the vendor may restructure them in the next release, which is
exactly what SAP did when it moved from ECC to S/4HANA (lesson 2). A table you can read is not a
table that was designed to be read by you.

**Third, the meaning is in the programs, not in the rows.** A row in the stock table says that 840
cases of UHT milk sit in the Juiz de Fora cold store. Whether any of them can be promised to a
customer depends on the reservations for orders already taken, the cases blocked by quality
pending a laboratory result, and the stock in transit from Barbacena. That calculation is in SAP's
code, not in any table. **Anybody who reads the table and skips the code gets a number that looks
right and is not.**

## Integration by sharing a database, inside one product

In the vocabulary lesson 9 will give you, the modules of an ERP are integrated in the oldest and
tightest of the four integration styles: a **shared database**. Every module reads and writes the
same tables, so a change to one table's meaning reaches all of them.

That style is usually a mistake between independent systems, because it couples them through a
schema neither owns. **Inside an ERP it works, because one vendor owns every program that touches
the schema and tests them together.** The coupling is real; it is held by one company with an
interest in keeping it consistent.

The trouble starts when a system outside the ERP joins the same database. It brings the coupling
with it and none of the vendor's testing. Joana's first proposal at Serra Alta does exactly that,
and the last section of this lesson is about why it was turned down.
