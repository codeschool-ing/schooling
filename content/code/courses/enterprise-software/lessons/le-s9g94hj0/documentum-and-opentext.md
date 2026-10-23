---
title: Documentum, EMC and OpenText: a product that changed owners
version: 1
---

Software is bought from a company, and companies are sold. **A product you keep for fifteen years
will probably change owners while you use it**, and each change moves things the licence does not
mention: the roadmap, the people who know the product, the partners who install it. Serra Alta's
document system is worth reading closely because nothing went dramatically wrong with it. It runs
today on a product whose owner the company never chose.

## Four owners in twenty-seven years

Documentum was founded in 1990 and built one of the first enterprise document repositories: a
relational database holding the object model and the metadata, and file stores holding the content
itself. It grew into a suite, with workflows, lifecycles, web clients and records management, and it
found much of its market in regulated industries, pharmaceuticals above all, where controlled
documents are a legal requirement rather than good practice.

Then it was sold, and sold again:

- in **2003** EMC, the storage company, bought Documentum; to a company that sold disks, managing
  the content on them was a natural next layer;
- in **2016** Dell bought EMC, and the combined company was called Dell EMC, with Documentum inside a
  part of it known as the Enterprise Content Division;
- in **2017** OpenText, a Canadian company whose business is content management, bought that
  division from Dell EMC, Documentum included.

Serra Alta's own history runs beside it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l05-owners\" aria-label=\"Two time lines from 1990 to 2026. The upper one is the owner of Documentum: Documentum itself from 1990, EMC from 2003, Dell EMC from 2016 and OpenText from 2017. The lower one is Serra Alta: it buys EMC Documentum in 2010, upgrades it last in 2015, renews support for the first time with OpenText in 2018, the year its implementation partner closes its content practice, and Joana arrives in 2026. Serra Alta made one purchase; the owner changed twice after it.\"><text x=\"110.0\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Documentum's owner</text><rect x=\"110.0\" y=\"58.0\" width=\"214.5\" height=\"24.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"217.2\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Documentum</text><rect x=\"324.5\" y=\"58.0\" width=\"214.5\" height=\"24.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"431.8\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">EMC</text><rect x=\"539.0\" y=\"58.0\" width=\"16.5\" height=\"24.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"555.5\" y=\"58.0\" width=\"158.4\" height=\"24.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"634.7\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">OpenText</text><text x=\"547.2\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">Dell EMC</text><path d=\"M547.2 47.0 L547.2 57.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"110.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1990</text><path d=\"M110.0 100.0 L110.0 104.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"275.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2000</text><path d=\"M275.0 100.0 L275.0 104.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"440.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2010</text><path d=\"M440.0 100.0 L440.0 104.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"605.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2020</text><path d=\"M605.0 100.0 L605.0 104.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M110.0 100.0 L713.9 100.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"110.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Serra Alta</text><path d=\"M440.0 160.0 L713.9 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"440.0\" cy=\"160.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M440.0 166.0 L440.0 182.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"440.0\" y=\"189.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">buys EMC</text><text x=\"440.0\" y=\"202.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Documentum</text><circle cx=\"522.5\" cy=\"160.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M522.5 166.0 L522.5 182.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"522.5\" y=\"189.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">last</text><text x=\"522.5\" y=\"202.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">upgrade</text><circle cx=\"572.0\" cy=\"160.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M572.0 166.0 L572.0 222.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"572.0\" y=\"229.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">first renewal with OpenText;</text><text x=\"572.0\" y=\"242.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">partner closes its practice</text><circle cx=\"704.0\" cy=\"160.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M704.0 166.0 L704.0 182.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"704.0\" y=\"189.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Joana</text><text x=\"704.0\" y=\"202.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">arrives</text><path d=\"M324.5 84.0 L324.5 154.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><path d=\"M539.0 84.0 L539.0 154.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><path d=\"M555.5 84.0 L555.5 154.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path></svg>", "caption": "One purchase, three counterparties. The two sales after 2010 changed who Serra Alta pays and who decides the roadmap, and neither needed Serra Alta to sign anything new."}
```

Serra Alta bought EMC Documentum in 2010, had it installed by a partner from São Paulo, and moved its
quality documents into it. It last upgraded the system in 2015. Its support contract has been with
EMC, then Dell EMC, then OpenText: **the same product on the same servers in the same room, with
three different companies on the other side of the contract.**

## What changes when the owner changes

The licence you already bought does not usually change. What changes is everything around it.

**The roadmap.** Each owner decides what the product is for. To a storage company, a content system
sells storage. OpenText already had a repository of its own, Content Server (formerly Livelink), so
after 2017 it owned two products in the same market and had to decide how much to invest in each. It
kept Documentum and went on releasing new versions. A customer of a product with a sibling inside its
owner should still ask which of the two gets the new features, and should not assume the answer
favours them.

**Support and its terms.** Support is a contract that renews, and a renewal is where a new owner
applies its own price list, its own support levels and its own policy on how long an old version
gets patches. Serra Alta's renewal in 2018 was the first on OpenText's paper. The version it runs,
from the 2015 upgrade, no longer receives patches; the contract still pays for a help desk that
answers questions about it.

**The people.** Expertise in a product lives in the vendor's engineers, in its partners and in the
customer's own staff, and an acquisition shakes all three. The partner that installed Serra Alta's
system closed its content-management practice in 2018. Inside Serra Alta, the configuration is
understood by one administrator in IT infrastructure, trained by that partner in 2011. Expertise
also walks out to start rivals: John Newton, one of Documentum's founders, went on to co-found
Alfresco in 2005, and in 2020 Alfresco itself was bought by Hyland. **In this market an ownership
change is the normal weather, not an accident.**

**Names.** Products, components and documentation get renamed to fit the new owner's catalogue. A
search for an old error message lands on forum posts whose links have moved twice.

None of this was Cláudia's decision, or IT's. **Choosing a vendor includes choosing whoever may buy
that vendor later**, and a decision meant to last ten years has to be judged with that in mind.
Lesson 15 turns it into a question to ask before buying anything: if this supplier is acquired,
what happens to us, and what would it cost to leave?

## The way out: what is standard and what is not

Leaving a document system means moving millions of files and, which is harder, their metadata,
versions, links and audit trails. How hard it is depends on how much of your use of the product goes
through its own proprietary interfaces.

Documentum's native interfaces are its own. DQL, the Documentum Query Language, looks like SQL and
speaks Documentum's object types. DFC, the Documentum Foundation Classes, is the Java API that most
custom code is written against, and there are web-service and REST layers above it. Serra Alta's two
integrations both use DFC: the job that files certificates of analysis, and a small program that
copies the list of procedures in force to the intranet every night. **Both are written against
Documentum's object model, and neither would run against any other repository.**

CMIS (Content Management Interoperability Services) is the vendor-neutral alternative. EMC, IBM and
Microsoft proposed it in 2008, other vendors including Alfresco, OpenText, Oracle and SAP joined, and
OASIS approved version 1.0 as a standard in 2010. Version 1.1 followed in 2013 and added a binding
in JSON meant for browsers. It defines one model that every compliant repository exposes:

| CMIS concept | what it is |
|---|---|
| repository | one store of objects, which describes the capabilities it supports |
| object types | `cmis:document` and `cmis:folder`, plus relationship and policy types; a repository defines subtypes with its own properties |
| properties | typed metadata on every object |
| version series | all the versions of one document; check-out gives a private working copy, and check-in makes the next version |
| query | a language modelled on SQL, over types and properties, with full-text search |
| bindings | the same operations over SOAP web services, over AtomPub, and from 1.1 over JSON |

A program written to CMIS can read and write documents in Documentum, in Alfresco and in several
other repositories without being changed. Here is a CMIS query for the certificates of one batch,
assuming the repository defines a subtype `sa:certificate` with the properties `sa:batch` and
`sa:material`:

```sql
SELECT cmis:objectId, cmis:name, sa:material
FROM sa:certificate
WHERE sa:batch = 'L2610-0457'
```

**The limits of the standard teach as much as the standard does.** CMIS covers the common ground,
which is objects, properties, folders, versions, access lists and query, and it stops there. Several
of those are optional, and a repository declares which ones it supports, so a client has to check
before it relies on them. The parts of a DMS that hold most of a company's own work are outside the
common ground: Documentum's lifecycles and workflows, its retention rules, and the way it composes
one document out of others. A migration through CMIS moves the documents and their metadata. It does
not move the process that governs them, and that has to be rebuilt in the new system.

So CMIS is worth requiring of every new integration, and it is not an exit on its own. An honest
estimate of leaving, for Serra Alta, counts three things. The documents, which CMIS can move. The
approval history and lifecycle states of the 2,300 controlled documents, which is a mapping
exercise. And the retention schedule, which has to be configured again in the new system and tested
before the first disposal run.

## What Joana writes down

After a week with the quality team, Joana sends Regina Fontes a note with three points. The product
is not failing; it is old and the knowledge of it is thin, which is a slower kind of risk. Every new
integration with it uses CMIS or a documented REST interface and never DFC, so that the repository
can be replaced without rewriting its neighbours, and the certificate job is rewritten that way
first. And the next contract renewal is a decision point rather than a formality: before it, Serra
Alta should know what leaving would cost, because a renewal signed without that number is the
company choosing its vendor again without looking.
