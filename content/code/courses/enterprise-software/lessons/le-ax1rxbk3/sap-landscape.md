---
title: One product, three systems and the road to production
version: 1
---

Joana spent her second week at Serra Alta with Edson Prado's SAP team, and she arrived holding the
picture most engineers from a product company hold. SAP, she thought, was one large application:
installed once, upgraded now and then, and reached through some kind of API. **At Serra Alta, SAP
is one product split into modules that share one database. It runs as three separate systems, changes
only by moving a recorded change from one system to the next, and is mostly configured rather than
programmed.** Each of those clauses limits what an architect can do around it, and this section takes
them in turn.

Like the other four products in lessons 2 to 6, SAP is taught here from its published documentation
and from how one company uses it. You will not log on to an SAP system in this course. SAP sells its
software to companies, under contracts negotiated by a sales team, and not to individuals. It does
publish trial systems for developers, but they ask for far more memory than a laptop has, and nothing
here depends on one. What an architect needs is to know where the edges are, and those are written
down.

## Fifty years of one product

SAP was founded in 1972 by five former IBM employees in Germany, and its idea from the start was
standard software: one program, sold to many companies, that each of them configures instead of
writing its own. The line has four names worth knowing, and Serra Alta runs the third.

| generation | when | what it ran on |
|---|---|---|
| R/2 | 1979 | mainframes |
| R/3 | 1992 | client-server, in three tiers |
| ECC 6.0 | the last release of the classic line | the same three tiers, on any of several databases |
| S/4HANA | 2015 | the same three tiers, on SAP's own HANA database only |

**R/3 set the shape that every later release kept.** It split the system into three tiers: the
*presentation* tier, which is the SAP GUI on each user's desk; the *application* tier, a set of
application servers running SAP's programs; and one *database*. Add application servers and the
system serves more users. The database stays single, and that is what lesson 1 meant by one
database: when a clerk in Lavras posts a goods receipt, the stock that a sales clerk in Juiz de Fora
sees has changed in the same transaction.

ECC 6.0, the release Serra Alta installed in 2011, is the end of the classic line. SAP did not ship
an ECC 7. Improvements arrived afterwards as *enhancement packages* applied on top of 6.0, so two
companies that both say "ECC 6.0" may be several years apart in what they actually run. S/4HANA is
the next generation and it is not a newer ECC, which the next section explains.

## Modules are not boundaries

Lesson 1 listed the seven modules Serra Alta licenses, FI, CO, SD, MM, PP, QM and WM, and what each
records there. An SAP team talks in those codes all day, and in a second vocabulary as well: the
*transaction code* that opens each screen. `VA01` creates a sales order, `ME21N` a purchase order,
`MIGO` posts a goods movement. Joana kept a list of them on a card for her first month, because
Edson's people would say "it fails in `VA01`" the way her old team said "it fails on checkout".

**A module is a licensing and organisational boundary more than a technical one.** The seven share
one database and one document flow, so a sales order in SD reserves stock in MM, its billing posts
to FI, and its margin lands in CO, without any of them calling the others through an interface. That
is why "we only integrate with SD" is rarely true: each of the 1,400 orders a day that enter SD
touches four modules before the day is out. The module codes say who in Edson's team to ask; they do
not say where an integration's effects stop.

## Three systems, not one

The second surprise for Joana was that Serra Alta does not have an SAP system. It has three.

**Every change to SAP is made in a development system, tested in a quality system, and only then
copied into production.** Each is a complete SAP installation with its own database, its own
application servers and its own three-character system ID. At Serra Alta they are called `DEV`,
`QAS` and `PRD`, which is common enough that you will meet those IDs elsewhere. Nobody changes
production directly. `PRD` is set so that its programs and its configuration cannot be edited at
all, and that setting is checked by the auditors who certify the books.

What moves between them is a *transport*. When one of Edson's developers changes a program or a
setting in `DEV`, SAP records the change in a *transport request* with an ID such as `DEVK900123`:
the system it came from, a `K`, and a number. The developer releases the request when the work is
done. The transport management system then imports it into `QAS`, where the key users test it, and
later imports the same request, unchanged, into `PRD`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-transports\" aria-label=\"Three SAP systems side by side, each a complete installation with its own database. DEV, development, holds client 100; QAS, quality, holds client 200 for testing and client 300 for training; PRD, production, holds client 100 and cannot be edited. A transport request, DEVK900123, is released in DEV and imported into QAS, where key users test it; the same request, unchanged, is then imported into PRD, on Tuesday or Thursday evenings and never in the first five working days of the month.\"><defs><marker id=\"l02-transports-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"25.0\" y=\"60.0\" width=\"190.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"120.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">DEV</text><text x=\"120.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">development</text><rect x=\"82.0\" y=\"117.0\" width=\"76.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">client 100</text><text x=\"120.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">own database</text><rect x=\"265.0\" y=\"60.0\" width=\"190.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">QAS</text><text x=\"360.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">quality</text><rect x=\"280.0\" y=\"117.0\" width=\"76.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"318.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">client 200</text><rect x=\"364.0\" y=\"117.0\" width=\"76.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"402.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">client 300</text><text x=\"360.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">own database</text><rect x=\"505.0\" y=\"60.0\" width=\"190.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">PRD</text><text x=\"600.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">production</text><rect x=\"562.0\" y=\"117.0\" width=\"76.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">client 100</text><text x=\"600.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">own database</text><rect x=\"188.0\" y=\"32.0\" width=\"104.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DEVK900123</text><path d=\"M240.0 56.0 L240.0 104.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><rect x=\"428.0\" y=\"32.0\" width=\"104.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DEVK900123</text><path d=\"M480.0 56.0 L480.0 104.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><path d=\"M217.0 125.0 L261.0 125.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l02-transports-es-ah-phosphor)\"></path><text x=\"240.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">import</text><path d=\"M457.0 125.0 L501.0 125.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l02-transports-es-ah-phosphor)\"></path><text x=\"480.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">import</text><text x=\"360.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">the same request moves on, unchanged</text><text x=\"120.0\" y=\"211.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a change is made and</text><text x=\"120.0\" y=\"224.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">recorded in a request</text><text x=\"360.0\" y=\"211.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">key users test it</text><text x=\"360.0\" y=\"224.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">against realistic data</text><text x=\"600.0\" y=\"211.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Tue and Thu evenings;</text><text x=\"600.0\" y=\"224.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">never in the close week</text><text x=\"600.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">nobody edits PRD directly</text><text x=\"360.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every system that talks to SAP needs a test counterpart pointed at QAS, never at PRD</text></svg>", "caption": "The road to production. A change is recorded once in DEV and the same request moves on; production is never edited in place."}
```

**Transports are imported in the order they were released**, and that order matters. A request that
changes a table and a later one that uses the new field only work in that sequence; importing the
second alone into production breaks something that worked in `QAS`. Serra Alta imports into
production twice a week, on Tuesday and Thursday evenings, with Edson's approval in each case, and
not at all during the first five working days of the month, while finance closes the books. Outside
those windows a change waits, however urgent it feels, unless Edson signs an emergency transport.

For an architect, two consequences follow. **A change in SAP reaches production at transport speed,
not at deployment speed**: a field added to support a new integration takes days at best, because
it goes through `QAS` and a test cycle like everything else. And every system that talks to SAP
needs a counterpart that talks to `QAS`. When the Rota team tests a release, its test environment has
to point at `QAS`, never at `PRD`, and somebody has to keep the data in `QAS` realistic enough for
the test to mean something.

## The client inside a system

Inside one SAP system there is a further division that has no equivalent in most software Joana had
used. A *client* (*Mandant*, in SAP's German) is a three-digit number that partitions the business
data inside one installation. Serra Alta's production data lives in client `100` of `PRD`. Its `QAS`
system has two clients: `200` for testing and `300` for training new users.

Almost every table that holds business data carries the client as the first column of its key, and
SAP's programs add it to every query on their own. Programs and table definitions, on the other
hand, are shared by every client in the system. So a program change reaches all clients at once,
while the orders in client `200` are invisible from client `300`.

**An integration connects to a system and a client, never to a system alone.** A connection set up
against `QAS` with the wrong client will log on, run and post documents into the training data. SAP
landscapes often name each pair as a *logical system*, such as `PRDCLNT100`, and Serra Alta follows
that convention.

## Customising, and the 1,800 objects that are not SAP's

SAP is changed in two very different ways, and confusing them is the most expensive mistake an
architect can make in a first conversation with an SAP team.

*Customising* is configuration through SAP's own *Implementation Guide*, opened with the transaction
`SPRO`. A new plant, a new pricing condition, a new document type for a returns order: each is a row
in a configuration table that SAP's code reads, and it is the first of lesson 1's three rings,
configuration. When the Alagoa plant joins SAP one day, most of what has to happen is customising.
**Customising is SAP's code behaving as you configured it**, and SAP's upgrades are designed to
carry it across.

*Custom code* is programs the company writes itself, in ABAP, SAP's own programming language. SAP
reserves names that begin with `Z` or `Y` for customers, so custom objects are called *Z objects*
and an SAP team says "there's a Z program for that". Serra Alta has about 1,800 of them: reports,
tables, function modules, screens, and code hooked into SAP's own transactions at the points SAP
leaves open for it. The ABAP program that loads Coleta's file every night at 02:00 is one of them,
and so is the table it writes.

Joana's first reading of that number was that the Z objects were plug-ins, separate from the core
and easy to set aside. Edson showed her otherwise. **A Z object lives inside SAP: it reads SAP's
tables, runs in SAP's transactions and is moved by the same transports**, and the 1,800 hold fifteen
years of decisions about how Serra Alta works. Some are essential and documented nowhere else; some
have not run since the person who asked for them left. Nobody at Serra Alta knows the split without
measuring it, and the next section shows why the answer is about to cost money.

That number is also the honest size of the system you are designing around. The licence buys SAP's
standard; what Serra Alta actually runs is that standard, its customising, and 1,800 objects that
only Edson's six people and the consultancy understand.
