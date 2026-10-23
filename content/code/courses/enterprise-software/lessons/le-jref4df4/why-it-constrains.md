---
title: Why the ERP constrains the architecture
version: 1
---

An architect arriving from a company that builds everything expects the ERP to be one system among
many: important, large, but a box on the diagram like any other. **In a company that runs one, the
ERP decides a large part of every design around it before the architect has drawn anything** — its
data model, its calendar, its interfaces, its upgrade cycle and its licence. The useful attitude is
the one you would take to a regulation: understand exactly what it requires, and design inside it.

## Joana's first proposal

In her second week at Serra Alta, Joana looks at the Portal B2B. Bakeries order on it, and each page
shows how many cases of each product are in stock. The portal gets those numbers from a file SAP
writes every hour, so a bakery sometimes orders yoghurt that sold out forty minutes earlier, and
customer service calls it back to apologise. That happens about 30 times a week.

Joana's proposal is the one she would have made at the fintech. **SAP runs on a database; set up a
read-only replica of it, and let the portal query the stock tables directly**, live, with no file
and no hour of delay. It is cheap, it is fast, and the replica protects production from the load.
She writes it up in a page and sends it to Edson Prado, who runs the SAP team.

Edson's reply is four points long. Each of them is a constraint the ERP imposes, and together they
are this section.

## 1. The data model is the vendor's, and it moves

**The stock tables Joana would query are SAP's private structure, not an interface.** SAP documents
how to read stock through its programs and services; it promises nothing about the tables
underneath. When Serra Alta moves from ECC to S/4HANA, which it must do before SAP's mainstream
maintenance for ECC ends at the end of 2027, the way stock is stored changes. S/4HANA records
material movements in a new table, `MATDOC`, and computes on the fly figures that ECC kept in
tables of totals. A portal built against ECC's tables would break on the day of the migration, or
worse, keep running and show numbers that were no longer being updated.

This is the general form: **a system that reads another system's tables has made that system's
internal structure part of its own contract**, without the owner agreeing to anything. Inside the
ERP that coupling is tested by the vendor. Outside it nobody tests it.

## 2. The meaning is in the code

As the section on the single database showed, the number a bakery needs is not the number in the
table. "In stock" for a sale means *available to promise*: physical stock, minus what is reserved
for orders already taken, minus what quality has blocked pending a laboratory result, plus what is
due in from another plant before the promised date. SAP computes that figure with its own logic,
configured over years by Edson's team. **A query on a replica would return the physical stock**, and
the portal would go on selling yoghurt that is in the cold store but promised to a supermarket.
Joana's proposal would have replaced a number forty minutes old with a number that is current and
wrong.

## 3. The licence follows the data

**ERP licences are sold per user, and the vendors have long argued about what counts as one.** A
person who reads SAP data through another system is, in SAP's contracts, still using SAP. That is
called *indirect access*. In 2017 the High Court in London decided the leading case, *SAP v Diageo*:
Diageo's sales and customer systems, built on Salesforce, read and wrote data in its SAP system, and
the court agreed with SAP that the people using those systems needed SAP licences. SAP has since
moved to pricing such use by the documents created rather than by the people, but the principle
stands. **A design that puts 4,000 bakeries in front of SAP data is a licensing question before it is
a technical one**, and the answer belongs in the contract, which an architect has to read or have
read.

## 4. The ERP's calendar is everybody's calendar

SAP at Serra Alta stops on purpose. Every Sunday from 01:00 to 05:00 it is down for maintenance. In
the first five working days of every month the finance team closes the previous month, and during
that week the SAP team freezes changes and watches the system's load closely. A replica follows
the primary, so a portal reading it would be down on Sunday nights with SAP. **The ERP's windows
become the windows of everything that depends on it synchronously**, and a portal for bakeries that
order at 04:00 on a Sunday before they open needs an answer for that. Lesson 12 is about designing
for it.

## What the ERP does to your designs, in general

Edson's four points generalise into a list Joana keeps from then on. Every system that touches the
ERP has to answer each line:

| the ERP decides | which means |
|---|---|
| its data model | meanings come from it; your system translates to and from it at the edge |
| its interfaces | you enter through the doors it publishes, never through its tables |
| its document flow | you join the chain at the step you represent, and let it make the rest |
| its calendar | its windows, its close and its batch jobs are constraints on your availability |
| its upgrade cycle | everything you add to it is carried through every upgrade, by somebody |
| its licence | who and what may read its data is in a contract, not only in the code |

## Configure, extend beside, modify never

The fifth line deserves its own picture, because it is the decision a company makes most often
without noticing it. **There are three ways to make an ERP do something it does not do out of the
box**, and they cost very differently over the ERP's life:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l01-three-rings\" aria-label=\"The ERP drawn as a box with a core inside it. The core is the vendor's programs and tables. A small amber patch inside the core is a modification: your code inside theirs, broken by every upgrade. The band around the core is configuration: choices the vendor built, carried through upgrades by the vendor. Outside the box, joined to its edge by a published interface, is an extension beside the ERP: yours to maintain, and not broken by the vendor's release.\"><defs><marker id=\"l01-three-rings-es-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"430.0\" height=\"250.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"235.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">configuration: choices the vendor built</text><text x=\"235.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">carried through upgrades by the vendor</text><rect x=\"70.0\" y=\"88.0\" width=\"330.0\" height=\"170.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the vendor's programs and tables</text><rect x=\"140.0\" y=\"150.0\" width=\"190.0\" height=\"74.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"235.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">modification</text><text x=\"235.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">your code inside theirs</text><text x=\"235.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">broken by every upgrade</text><rect x=\"500.0\" y=\"110.0\" width=\"200.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">extension beside</text><text x=\"600.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">yours to maintain</text><text x=\"600.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">not broken by their release</text><path d=\"M498.0 155.0 L452.0 155.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-three-rings-es-ah-paper)\" marker-start=\"url(#l01-three-rings-es-ah-paper)\"></path><text x=\"468.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a published interface</text><path d=\"M475.0 222.0 L475.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path></svg>", "caption": "Three places to put a change, from cheapest to dearest over the ERP's life: configuration, an extension beside it, and a modification inside it."}
```

**Configuration** chooses among behaviours the vendor built, and the vendor carries it through
upgrades. **An extension beside the ERP** — a separate program that talks to it through its
published interfaces — is yours to maintain but is not broken by the vendor's next release. **A
modification inside the ERP**, changing or adding code in the vendor's programs, is broken by every
upgrade and has to be found, tested and carried forward each time. SAP's name for keeping the
inside free of modifications is a *clean core*. Serra Alta's 1,800 custom objects are what fifteen
years of not keeping it clean look like, and lesson 2 shows what they cost in the move to S/4HANA.

A fourth option sits outside the rings and is the cheapest of all: **change the business process to
fit the standard.** The vendors call it *fit to standard*. It is the right answer more often than a
team that likes building wants it to be, and the wrong one whenever the process is how the company
competes. Lesson 15 is about telling the two apart.

## What Joana wrote instead

Joana's second version kept the portal outside SAP and entered through a published door. SAP
already calculates available-to-promise; the SAP team exposes that calculation as a service the
portal calls when a bakery opens its basket, with a short cache in front so that 4,000 bakeries do
not become 4,000 calls. The licensing question went to the contracts team with a count of documents
per month. And for Sunday night, the portal shows the last figure it had, with the time it was
taken, and accepts the order for confirmation when SAP comes back.

She wrote the reasons down as a decision record, in the folder this course asked you to keep. **The
record's first line names the constraint, not the technology**: *SAP is the system of record for
stock; the portal does not read its tables.* The rest of the course is, in one sense, the long
version of that sentence: lessons 2 to 6 are the systems Serra Alta bought, and lessons 7 to 15 are
how to connect, change and replace them without stopping a company that collects milk every day.
