---
title: What an ERP is
version: 1
---

The common picture of an ERP is a very large accounting program with too many screens. **An ERP is a
set of business functions — finance, sales, purchasing, stock, production, people — built on one
data model and one database, so that a single event in the business updates all of them at once.**
The screens are the least interesting part. What makes it an ERP is what happens when a truck of
yoghurt leaves the Juiz de Fora plant. The stock falls, the cost of goods sold rises, the customer
owes money and the production plan for next week sees the gap, all in the same transaction and
without anybody copying a number from one place to another.

The letters stand for *enterprise resource planning*, a name that describes where it came from
better than what it does today.

## Where it came from

The lineage is short, and it explains why the ERP is shaped like a factory.

**MRP, material requirements planning, came first, in the 1960s and 1970s.** A manufacturer knows
what it intends to make next week and what each product is made of, its bill of materials. From
those two lists a computer can work out what to buy and when: four thousand litres of milk, two
hundred kilos of culture, eleven thousand pots and their lids, each ordered early enough to arrive
before it is needed. Joseph Orlicky, at IBM, wrote the method down in *Material Requirements
Planning* (1975), and it was among the first serious business uses of a computer.

**MRP II, manufacturing resource planning, widened it in the 1980s** to the rest of the factory:
machine capacity, labour, and the money. Oliver Wight popularised the name and the practice. A plan
that knew the filling line could only run eight hours a day could finally say that the order would
be late before it was.

**The word ERP is Gartner's, from around 1990**, for systems that had reached beyond the factory to
sales, finance, purchasing and personnel, and that shared one database between all of them. SAP's
R/3, released in 1992, is the product most people mean when they picture one. Lesson 2 is about it.

## The modules, at Serra Alta

An ERP is sold and configured in modules. The names differ by vendor; the functions do not. Here is
what Serra Alta's SAP does, in SAP's own module names, which the people in lesson 2 use all day:

| module | what it records | at Serra Alta |
|---|---|---|
| FI, financial accounting | the general ledger, what customers owe and what is owed to suppliers | every NF-e becomes a receivable; every farm payment clears a payable |
| CO, controlling | costs by plant, product and cost centre | what a litre of UHT milk costs to make in Juiz de Fora |
| SD, sales and distribution | quotations, orders, deliveries, invoices | about 1,400 orders a day from supermarkets, distributors and the Portal B2B |
| MM, materials management | purchasing, goods receipts, stock | milk received from farms, packaging bought from suppliers |
| PP, production planning | what to make, when, on which line | the weekly plan of each plant |
| QM, quality management | inspections and results | the laboratory results of every batch |
| WM, warehouse management | where each pallet sits | the cold stores in Juiz de Fora and Barbacena |

**A farm is a supplier.** That surprises people who arrive from outside the industry, and it is
exactly what an ERP's model forces on you. Serra Alta buys milk from 1,900 farms, so each of them is
a vendor master record in SAP, with a tax number, a bank account and payment terms, in the same
table as the company that sells it cardboard. The ERP has no concept of a farm. It has a concept of
somebody Serra Alta pays.

## Bought and configured, not written

**Nobody at Serra Alta wrote SAP, and almost nobody can change how it works.** The vendor wrote
the programs and the database, and sells them with a model of how a business runs: how an order
becomes an invoice, how a payment clears a debt, how a cost is allocated. What a customer does is
**configure** that model, through settings — many thousands of them in a large ERP — that
choose among the behaviours the vendor anticipated. Which documents a sale produces, how an invoice
is numbered, which taxes apply in Minas Gerais.

Where configuration runs out, the customer writes code inside the ERP, in the vendor's language and
under the vendor's rules. Serra Alta has about 1,800 such objects of its own. Lesson 2 counts them
again, because each one is something that has to be carried through every upgrade.

The model comes with a claim attached: that the vendor has seen thousands of companies and the
process it ships is close to the best way to run one. The claim is partly true. Accounting is
accounting, and nobody gains a competitive edge from an unusual way of recording a receivable. It
is also a sales argument, and the parts of a business that are genuinely its own rarely fit the
standard. **Telling those two apart is one of the most valuable things an architect does in a
company like this**, and lesson 15 is about doing it with numbers.

## Who sells them

Four vendors cover most large companies, and one more covers much of Brazil:

| vendor | products |
|---|---|
| SAP | ECC, which most large companies still run, and S/4HANA, its successor |
| Oracle | E-Business Suite and JD Edwards, from before the cloud; Fusion Cloud ERP and NetSuite since |
| Microsoft | Dynamics 365 Finance and Supply Chain Management for large companies; Business Central for smaller ones |
| Infor | industry editions, for manufacturing and distribution among others |
| TOTVS | the Brazilian vendor, with Protheus, RM and Datasul, strongest among small and medium companies |

Odoo and ERPNext are open source and have the same shape on a smaller scale. That is why this
lesson's first section named them as a way to see one working.

**A large company rarely runs only one.** Serra Alta runs SAP, and the cheese company it bought in
2021 runs Microsoft's Business Central, which the purchase did not switch off. Lesson 3 is about
living with two.

## Why an architect should care

Everything above could be the introduction to a course for accountants. It is here because of one
consequence, which the rest of this lesson develops: **the ERP is the system of record for most of
what the company does, and a system of record shapes every system around it.** The Portal B2B, the
truck routing in Rota and the Salesforce screens of the sales team all exist to show, change or
add to something whose true version lives in SAP. Their designs are answers to questions the ERP
asks: what a customer is, when a sale counts, which day the month ends. The next three sections show
where those questions come from.
