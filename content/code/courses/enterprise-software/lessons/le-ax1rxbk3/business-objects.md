---
title: Business Objects, BW and nine hundred reports
version: 1
---

Marcos Teles judges SAP by one thing he sees every month: the reports. When Joana asked him what he
wanted from the move to S/4HANA, his answer had nothing to do with tables or transports. He wanted
the board pack to stop disagreeing with itself. **At Serra Alta, reporting is three layers bought from
SAP: a warehouse, a semantic layer and a reporting tool. Its problem sits in none of the three: it is
nine hundred reports that nobody owns.** This section is about those layers and that problem.

## How BusinessObjects came to be SAP's

BusinessObjects was a French software company, founded in 1990, whose product let people ask
questions of a database in business words rather than SQL. It had itself bought Crystal Decisions,
the maker of Crystal Reports. SAP bought BusinessObjects in a deal that closed in early 2008, and
the product kept its name inside SAP: today it is the *SAP BusinessObjects Business Intelligence*
platform, and Serra Alta runs version 4 of it.

Three pieces of it matter to an architect.

| piece | what it is | at Serra Alta |
|---|---|---|
| universe | a semantic layer: business names mapped once onto tables, joins and calculations | *Litres collected*, *Farm*, *Plant* and *Net sales*, defined for report writers |
| Web Intelligence | the query and reporting tool most users meet, through a browser | most of the 900 reports, from the daily milk intake to the monthly margin by customer |
| Crystal Reports | formatted reports laid out to the millimetre, for printing or PDF | documents sent outside the company, where the layout is part of the content |

**A universe is where a company's definitions live.** A report writer drags *Net sales* and *Plant*
onto a query, and the universe turns them into SQL with the right joins and the right formula. That
is a strength when there is one universe and a weakness when there are several. Serra Alta has two
universes that define *Net sales*: one subtracts returns, one does not. The commercial team's
reports use the first and finance's use the second, so the board pack carries two sales figures for
the same month that differ by the returns, and somebody explains the gap at every meeting. Nothing is
broken. Two definitions are both being applied correctly.

## BW, the warehouse underneath

The universes do not query the production ERP. They query SAP BW, the Business Warehouse, which Serra
Alta has run since 2013 and which is on version 7.5.

BW is a data warehouse built for SAP's own data. It takes data out of ECC through *extractors*, SAP
programs that know how to read a business area such as sales orders or billing documents and send
only what changed since the last run. It stores the result in its own structures. One of them, the
*InfoCube*, is a star schema with SAP's extensions: the facts in the middle, the dimensions around
them. If you took `warehouse-modeling` on this track, you have seen the shape, and the questions it
answered there apply here too: what grain the facts have, and what happens to a dimension when the
thing it describes changes.

**The warehouse remembers what the ERP overwrites.** When a bakery moves from the Juiz de Fora sales
region to Barbacena's, SAP changes the customer's master record and the old region is gone from it.
A report run against SAP would put all of that bakery's past sales in Barbacena. BW kept the region
each sale had when it happened, which is what the regional managers' bonuses are calculated on.

## Production or the warehouse

Every so often somebody at Serra Alta proposes reporting straight from SAP: no nightly load, no
warehouse, numbers as of this second. There are two arguments against it on ECC, and one of them
weakens with HANA.

The first is load. ECC's database is tuned for the 1,400 orders a day and the clerks entering them.
**A report that scans a year of order lines on the production database at ten in the morning
competes with the people taking orders**, and on a row-oriented database that scan is slow and
heavy. This is the argument HANA weakens. On S/4HANA a column store can answer many operational
questions on live data without hurting the transactions, and SAP ships analytical views inside the
ERP for exactly that.

The second is history and breadth, and HANA does not touch it. Production holds the current state of
one system. The warehouse holds the past, as the bakery's region shows, and it can hold more than SAP:
the cheese plant's sales from Business Central, the Salesforce pipeline. **Reporting on live data is
right for questions about now; the warehouse is still right for questions about then, and about more
than one system.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l02-reporting\" aria-label=\"Serra Alta's reporting as four boxes from left to right. SAP ECC in production holds the current state of one system. Extractors load what changed each night into BW 7.5, which keeps history, such as the region each sale had when it happened. Universes sit on BW and hold the definitions, including two different definitions of Net sales. Web Intelligence reports sit on the universes: about 900, of which about 300 were not opened in a year. A dashed arrow from the reports back to production shows the alternative of reporting straight on SAP, which competes with order entry and has no history.\"><defs><marker id=\"l02-reporting-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-reporting-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"22.0\" y=\"123.0\" width=\"146.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"143.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SAP ECC</text><text x=\"95.0\" y=\"156.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">production</text><text x=\"95.0\" y=\"207.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the current state</text><text x=\"95.0\" y=\"220.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">of one system</text><rect x=\"202.0\" y=\"123.0\" width=\"146.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"143.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">BW 7.5</text><text x=\"275.0\" y=\"156.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the warehouse</text><text x=\"275.0\" y=\"207.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">history: the region</text><text x=\"275.0\" y=\"220.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">each sale had</text><rect x=\"382.0\" y=\"123.0\" width=\"146.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"143.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">universes</text><text x=\"455.0\" y=\"156.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">semantic layer</text><text x=\"455.0\" y=\"207.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">definitions: two</text><text x=\"455.0\" y=\"220.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">kinds of net sales</text><rect x=\"562.0\" y=\"123.0\" width=\"146.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"143.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Web Intelligence</text><text x=\"635.0\" y=\"156.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reports</text><text x=\"635.0\" y=\"207.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">about 900; about 300</text><text x=\"635.0\" y=\"220.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">unopened in a year</text><path d=\"M169.0 150.0 L200.0 150.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-reporting-es-ah-phosphor)\"></path><path d=\"M349.0 150.0 L380.0 150.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-reporting-es-ah-phosphor)\"></path><path d=\"M529.0 150.0 L560.0 150.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-reporting-es-ah-phosphor)\"></path><text x=\"185.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">extractors, nightly</text><path d=\"M635.0 122.0 L635.0 76.0 L95.0 76.0 L95.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l02-reporting-es-ah-amber)\"></path><text x=\"365.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">reporting straight on production: no nightly load, but it competes with order entry and keeps no history</text><text x=\"365.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">live data answers questions about now; the warehouse answers questions about then, and about more than one system</text></svg>", "caption": "Three layers bought from SAP, and the shortcut around them. The shortcut gains freshness and loses history and breadth."}
```

## Nine hundred reports

The BusinessObjects platform keeps an audit of who opened what. In her second week Joana asked
Edson for a year of it, and the result was the number this section is named for: about 900 Web
Intelligence reports, and a third of them, about 300, not opened by anybody in twelve months.

Her first proposal was to delete those 300. Edson asked her to wait, and Cláudia Mendes explained
why. Some reports are opened once a year: the one that assembles the batch records for the annual
FSSC 22000 audit, the year-end inventory valuation, a recall simulation that the plants run every
twelve months and that lands a few weeks outside the audit window. **A report used once a year looks
dead to any measurement shorter than a year and a bit**, which is the same caution the section on
HANA raised about Z objects that run only at the annual close.

So the retirement went in steps, and the steps are general.

1. **Measure over more than a full business cycle.** A year and a quarter catches the annual reports.
2. **Find an owner for each report**, by asking who created it and who receives it. A report with no
   owner after a month of asking is archived, not deleted, and restored if anybody asks.
3. **Group the survivors by what they answer.** At Serra Alta about forty reports turned out to
   answer one question, the day's milk intake by plant, each with a different filter.
4. **Fix the definitions before the layout.** The two meanings of *Net sales* are a decision for
   Marcos, and no report tool can make it for him.

**The number of reports is not a measure of how well a company is informed**; it is closer to a
measure of how many people needed an answer and could not find the existing one. The 300 unopened
reports cost licences, upgrades and testing every time BW or the platform changes, and they will cost
all three again if they are carried into S/4HANA.

## Where SAP is taking analytics

SAP's newer analytics products are cloud services. *SAP Analytics Cloud* covers dashboards, planning
and reporting, and *SAP Datasphere*, formerly called Data Warehouse Cloud, is its cloud data
warehouse. BW's on-premises successor is *BW/4HANA*. BusinessObjects remains supported, on dates SAP
publishes and revises, and Edson's team checks those dates against SAP's maintenance pages rather
than from memory, because they have moved before.

For Serra Alta the reporting decision follows the ERP decision. If ECC becomes S/4HANA, BW's
extractors have to be checked against the new data model, some reports will move to the analytics
inside S/4HANA, and the warehouse question gets asked again. **What should not move is the 300 reports
nobody opens, or the two definitions of one number.** Those are cheaper to settle now, while the
system they run on is still familiar to everybody, than in the middle of a migration.
