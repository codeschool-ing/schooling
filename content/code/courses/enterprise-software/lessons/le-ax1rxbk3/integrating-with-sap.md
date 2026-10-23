---
title: The doors into SAP, and the one that stays shut
version: 1
---

Lesson 1 ended with Joana's rule for the Portal B2B: *the portal does not read SAP's tables*. That
rule says where not to go. This section says where to go instead. **SAP publishes four kinds of
door, and each one suits a different conversation**: IDocs for documents that travel
asynchronously, BAPIs called over RFC for a synchronous business operation, OData services for web
clients, and files for batches. The database is not a door, for writing or for reading. Choosing
among the four is most of what integrating with SAP means, and Serra Alta uses all of them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 370\" role=\"img\" data-fig=\"l02-doors\" aria-label=\"SAP ECC drawn as a box with four doors on its edges. On the left, supermarket orders arrive from the EDI provider through the bus as IDocs, and Coleta sends its nightly file at 02:00. On the right, the Portal B2B creates orders by calling a BAPI over RFC, and checks available-to-promise through an OData service. Every door leads to SAP's own code, which prices, checks, numbers, records the document flow and checks authorisation, and only that code writes to the database. Below, a SQL client reaching for the database directly is crossed out: the tables are SAP's private model and not a door.\"><defs><marker id=\"l02-doors-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-doors-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"230.0\" y=\"40.0\" width=\"260.0\" height=\"260.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">SAP ECC</text><rect x=\"292.0\" y=\"110.0\" width=\"136.0\" height=\"80.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"130.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SAP's own code:</text><text x=\"360.0\" y=\"143.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">prices, checks,</text><text x=\"360.0\" y=\"156.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">numbers, document</text><text x=\"360.0\" y=\"169.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">flow, authorisation</text><rect x=\"285.0\" y=\"228.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"241.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">database</text><text x=\"360.0\" y=\"254.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SAP's private model</text><path d=\"M360.0 191.0 L360.0 226.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-doors-es-ah-phosphor)\"></path><rect x=\"189.0\" y=\"112.0\" width=\"82.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">IDoc</text><path d=\"M272.0 125.0 L290.0 125.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-doors-es-ah-phosphor)\"></path><rect x=\"189.0\" y=\"162.0\" width=\"82.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">file</text><path d=\"M272.0 175.0 L290.0 175.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-doors-es-ah-phosphor)\"></path><rect x=\"449.0\" y=\"112.0\" width=\"82.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">BAPI / RFC</text><path d=\"M448.0 125.0 L430.0 125.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-doors-es-ah-phosphor)\"></path><rect x=\"449.0\" y=\"162.0\" width=\"82.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">OData</text><path d=\"M448.0 175.0 L430.0 175.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-doors-es-ah-phosphor)\"></path><rect x=\"11.0\" y=\"104.0\" width=\"168.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"118.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">supermarket orders,</text><text x=\"95.0\" y=\"131.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">EDI through the bus</text><path d=\"M179.0 125.0 L187.0 125.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-doors-es-ah-phosphor)\"></path><rect x=\"11.0\" y=\"154.0\" width=\"168.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"168.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Coleta, its file</text><text x=\"95.0\" y=\"181.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">every night at 02:00</text><path d=\"M179.0 175.0 L187.0 175.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-doors-es-ah-phosphor)\"></path><rect x=\"541.0\" y=\"104.0\" width=\"168.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"118.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Portal B2B orders,</text><text x=\"625.0\" y=\"131.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">through the bus</text><path d=\"M541.0 125.0 L533.0 125.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-doors-es-ah-phosphor)\"></path><rect x=\"541.0\" y=\"154.0\" width=\"168.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"168.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Portal B2B</text><text x=\"625.0\" y=\"181.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">stock check</text><path d=\"M541.0 175.0 L533.0 175.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-doors-es-ah-phosphor)\"></path><rect x=\"285.0\" y=\"330.0\" width=\"150.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"345.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a SQL client</text><path d=\"M360.0 330.0 L360.0 304.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l02-doors-es-ah-amber)\"></path><path d=\"M350.0 307.0 L370.0 323.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M370.0 307.0 L350.0 323.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"560.0\" y=\"323.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">not a door, for writing</text><text x=\"560.0\" y=\"336.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">or for reading</text></svg>", "caption": "Four published doors, and every one leads through SAP's own code. The database is behind that code, not beside it."}
```

## IDoc: a document that travels

An *IDoc*, an intermediate document, is SAP's format for a business document moving between
systems. It has a control record saying what it is, who sent it and who receives it; a list of data
segments carrying the content; and status records added as it is processed. **What an IDoc carries
is named by its message type**, and the common ones are the documents of commerce: `ORDERS` for a
purchase order, `DESADV` for a despatch advice, `INVOIC` for an invoice. Each message type has a
versioned structure behind it, such as `ORDERS05`, so a partner can be on an older layout without
the others changing.

Serra Alta's big supermarket chains order this way. A chain's order arrives at the EDI provider,
which passes it to the integration bus, which turns it into an `ORDERS` IDoc and hands it to SAP.
SAP creates a sales order from it. When the goods leave, SAP sends a `DESADV` back the same way, and
an `INVOIC` follows the billing.

**An IDoc is asynchronous, and that changes what "sent" means.** When the bus hands an `ORDERS`
IDoc to SAP, SAP accepts it and stores it, and only then tries to post it. If the posting works, the
IDoc reaches status `53`, application document posted. If it fails, because a material is blocked
or a customer has no partner function for the delivery address, the IDoc stops in status `51` and
waits in a monitor until a person fixes the cause and reprocesses it. The sender was told nothing
went wrong, because at the moment it sent, nothing had. **An integration built on IDocs needs
somebody who watches status `51`**, and at Serra Alta that is a morning task in Rui Andrade's team,
taken over by Edson's people whenever the cause is inside SAP.

## BAPI over RFC: a business operation, synchronously

A *BAPI*, a business API, is a function SAP publishes on one of its business objects: create a
sales order, change a purchase order, read a material. It runs inside SAP, so it applies the same
checks as a user's screen: pricing, credit, availability, authorisation. External programs call it
through *RFC*, SAP's remote function call protocol, using libraries SAP provides for Java, .NET and
C.

`BAPI_SALESORDER_CREATEFROMDAT2`, for instance, takes an order header and its items and returns
the new order's number, or a table of messages saying why there is none. Two habits catch people
from outside SAP. **A BAPI that writes does not commit on its own**: the caller has to call
`BAPI_TRANSACTION_COMMIT` afterwards, and a program that forgets gets a number for an order that was
never saved. And a BAPI reports failure in that returned message table rather than as an exception,
so a caller that reads only the order number reads an empty string as success.

The Portal B2B creates its orders this way, through the bus. A bakery that presses *confirm* wants
an order number on its screen, and a synchronous call is the honest way to give it one. The price is
lesson 1's fourth point: on Sunday nights between 01:00 and 05:00 there is nobody to answer, and the
portal has to queue the order and say so.

## OData: SAP on HTTP

SAP Gateway exposes services over HTTP following the OData protocol, with JSON payloads and URLs
that address entities and collections. It is the door SAP's own web interface, Fiori, uses, and the
one most familiar to a developer who has only met REST. On S/4HANA SAP publishes many standard OData
APIs and lists them in its online API catalogue. On ECC there are far fewer standard ones, and a
company usually builds its own on Gateway.

That is what Edson's team did for the available-to-promise check from lesson 1: a small OData
service that answers, per material and plant, how much can be promised for a date. It runs SAP's own
calculation, so the portal gets SAP's number and not a guess at it. Writing it took Edson's team
three weeks and two transports; reading it from the portal took the portal team an afternoon.

## Files: the oldest door, still open

Some conversations are batches, and a file is the right shape for a batch. Two of Serra Alta's
oldest integrations are files. Every night Coleta writes one fixed-width line per farm collected,
about 1,900 of them, and at 02:00 an ABAP program reads the file and creates a goods receipt for
each line. And SAP's payment run writes a CNAB 240 file for the bank with the farm and supplier
payments, then reads the bank's return file to learn which ones were paid.

**A file is a published door when SAP's own program reads it**, because that program posts through
the same logic as a user would. What a file lacks is an answer: Coleta does not learn that line 1,412
was rejected unless somebody builds a way to tell it. Lesson 9 takes the Coleta file apart and shows
what a file interface needs to be trustworthy.

## Choosing a door

| door | style | use it when | watch for |
|---|---|---|---|
| IDoc | asynchronous, one document at a time | a business document travels between companies or systems, and the sender need not wait | failures parked in status `51` that nobody watches |
| BAPI over RFC | synchronous call | the caller needs the result now, such as an order number on a screen | the explicit commit, errors returned as data, and SAP's downtime |
| OData | synchronous, over HTTP | a web or mobile client, or a team with no SAP libraries | on ECC, most services are ones you build and maintain |
| file | batch | a day's worth of records moves at once, on a schedule | no reply to the sender, and partial loads |

Serra Alta reaches most of these doors through its integration bus, IBM Integration Bus, which has
adapters for IDocs and RFC. SAP sells its own middleware for the same job, Process Orchestration on
premises and the Integration Suite in its cloud, and many SAP customers use it. Serra Alta chose
IBM's in 2015, and lesson 8 is about living with that bus.

## The door that stays shut: writing to tables

Writing to SAP's tables with SQL is the one rule here with no exception at Serra Alta. Joana's
fintech instinct was that an `INSERT` is an `INSERT`, and Edson answered with what a sales order
created that way would lack.

**A row written straight into SAP's tables skips everything SAP does when it creates a document.**
No pricing and no credit check. No number taken from SAP's number range, so a later order may be
given the same number. No lock, so a clerk in `VA01` may be changing the same customer at that
moment. No entry in the document flow, so the delivery, the billing and the NF-e never follow. No
change documents, so the audit trail shows an order nobody created. And no authorisation check, so
a program did what no person at Serra Alta is allowed to do. SAP's support will not help with data
created that way, and the next upgrade is free to change the table underneath it.

## Why reading is a trap too

Lesson 1 gave two reasons not to read SAP's tables either: the structure is SAP's private model and
it moves, and the meaning lives in the code rather than in the rows. Up close there are more:

- **every business table carries the client** as the first column of its key, and a query that
  forgets it adds the training data in client `300` to production's;
- **values are stored in SAP's internal form**, so customer `12345` is the text `0000012345` and a
  date is the eight characters `20261023`, and what a status code means is in the customising;
- **some tables are not ordinary tables in ECC**: on the databases ECC was designed for, the
  accounting line items in `BSEG` live in a cluster that SQL cannot read as rows, which is how
  Serra Alta's ECC stores them;
- **SAP's authorisations are checked in its application tier**, so a database account sees every
  row, including the ones no user at Serra Alta is allowed to see.

Every one of those is solved by a door, because the door runs SAP's code.

## The licence, counted by door

Lesson 1 told the story of *SAP v Diageo* and SAP's move to pricing indirect use by the documents
created rather than by the people. **For an architect that turns every integration into a line in a
register: which SAP documents does it create, and how many a month?** The Coleta file alone creates
a goods receipt for every farm collected, about 1,900 a day, which is around 57,000 a month. The
supermarket EDI orders, the Portal B2B orders and the bank's return file each add their own lines.

Whether each of those counts, and at what price, depends on the contract Serra Alta signed, which is
a question for the contracts team and SAP, not for this course. What the architect owes them is the
count, kept current, because a new integration that creates documents in SAP changes a bill that
nobody on the project team will see.
