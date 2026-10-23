---
title: What the name Dynamics covers
version: 1
---

Joana's first picture of "Dynamics" was one product, the way "SAP" at Serra Alta means one ECC
system. **Dynamics is a brand over several business systems that Microsoft bought or built
separately**, and each still carries its own history: its own data model, its own programming
language and its own community of people who know it. When somebody says they "know Dynamics", the
useful next question is which one.

This lesson, like lesson 2, is taught from the vendor's documentation and from Serra Alta's
experience, and you will not touch a Microsoft business system to follow it. If you want to look at
one, Microsoft offers time-limited trials of its Dynamics 365 products and a free developer plan for
Power Apps. Both are optional, and no exercise depends on them.

## Bought, then renamed

Microsoft did not grow its business applications; it bought them. In 2001 it acquired Great Plains,
an American maker of accounting software, and in 2002 Navision, a Danish one. Navision brought two
ERPs with it: its own product, also called Navision, and Axapta, which came from Damgaard, the
company Navision had merged with shortly before.

Twenty years of renaming followed, and the old names have not gone away. Consultants, job adverts
and forum posts use all of them, sometimes in the same paragraph. The table is the part worth
keeping.

| sold today as | earlier names | built for | extended with |
|---|---|---|---|
| Dynamics 365 Finance and Dynamics 365 Supply Chain Management | Dynamics AX, and before that Axapta | large companies with many legal entities and countries | X++ |
| Dynamics 365 Business Central | Dynamics NAV, and before that Navision | small and mid-sized companies | extensions written in AL |
| Dynamics 365 Sales, Dynamics 365 Customer Service and their siblings | Dynamics CRM | sales and service teams | configuration on Dataverse, then code |
| Dataverse | Common Data Service | the data under the CRM apps and Power Apps | tables, relationships, business rules |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l03-family\" aria-label=\"The Dynamics family as four lines of descent, read left to right. Axapta became Dynamics AX, then Dynamics 365 for Operations in 2016, and is sold today as Dynamics 365 Finance and Supply Chain Management. Navision became Dynamics NAV and, in 2018, Business Central, which Mantiqueira has run since 2019. Axapta and Navision were both bought by Microsoft in 2002. Dynamics CRM became Dynamics 365 Sales and Customer Service, which are built on Dataverse. Common Data Service was renamed Dataverse in 2020; it is the data under the CRM apps and Power Apps, and the two ERPs keep their own databases outside it.\"><defs><marker id=\"l03-family-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"80.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">origin</text><text x=\"235.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Dynamics era</text><text x=\"605.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">sold today</text><rect x=\"12.0\" y=\"40.0\" width=\"136.0\" height=\"168.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"80.0\" y=\"177.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">bought by</text><text x=\"80.0\" y=\"190.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">Microsoft, 2002</text><rect x=\"15.0\" y=\"50.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Axapta</text><rect x=\"170.0\" y=\"50.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Dynamics AX</text><rect x=\"325.0\" y=\"50.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"63.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Dynamics 365</text><text x=\"400.0\" y=\"76.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">for Operations, 2016</text><rect x=\"505.0\" y=\"50.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"63.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Finance</text><text x=\"605.0\" y=\"76.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Supply Chain Management</text><path d=\"M147.0 70.0 L167.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-family-es-ah-paper-dim)\"></path><path d=\"M302.0 70.0 L322.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-family-es-ah-paper-dim)\"></path><path d=\"M477.0 70.0 L502.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-family-es-ah-paper-dim)\"></path><rect x=\"15.0\" y=\"125.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Navision</text><rect x=\"170.0\" y=\"125.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Dynamics NAV</text><rect x=\"505.0\" y=\"125.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Business Central, 2018</text><path d=\"M147.0 145.0 L167.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-family-es-ah-paper-dim)\"></path><path d=\"M302.0 145.0 L502.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-family-es-ah-paper-dim)\"></path><text x=\"605.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">Mantiqueira, since 2019</text><rect x=\"170.0\" y=\"205.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Dynamics CRM</text><rect x=\"505.0\" y=\"205.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"218.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Dynamics 365 Sales,</text><text x=\"605.0\" y=\"231.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Customer Service</text><path d=\"M302.0 225.0 L502.0 225.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-family-es-ah-paper-dim)\"></path><rect x=\"170.0\" y=\"295.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"315.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Common Data Service</text><rect x=\"505.0\" y=\"293.0\" width=\"200.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"308.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Dataverse, 2020</text><text x=\"605.0\" y=\"321.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">also under Power Apps</text><path d=\"M302.0 315.0 L502.0 315.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-family-es-ah-paper-dim)\"></path><path d=\"M605.0 246.0 L605.0 292.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l03-family-es-ah-paper-dim)\"></path><text x=\"613.0\" y=\"270.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">built on</text><text x=\"400.0\" y=\"345.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">the ERPs keep their own databases</text></svg>", "caption": "Four lines of descent under one brand. The two ERPs came from different companies and keep their own data; only the CRM apps and Power Apps live in Dataverse."}
```

## The large-company ERP

Dynamics AX was renamed Dynamics 365 for Operations in 2016, when Microsoft launched the Dynamics
365 brand, and was later split into the two apps sold today. People who work with them still call
the pair "F&O", short for Finance and Operations, and Microsoft's own documentation calls them the
finance and operations apps.

This is the product that competes with SAP for large companies. It handles many legal entities,
currencies and countries in one installation, and it is customised in X++, a language of its own.
Serra Alta does not run it. It matters to Joana for a different reason: **the end of ECC
maintenance in 2027 is the moment a company that runs SAP has to ask whether it stays on SAP.** The
board will ask Regina Fontes whether this product was considered. Lesson 15 is about answering
that kind of question with numbers rather than loyalty.

## The mid-sized ERP: Business Central

Business Central is what Mantiqueira runs. It descends from Navision through Dynamics NAV and was
launched under its current name in 2018. It covers finance, sales, purchasing, inventory,
warehousing and a measure of manufacturing, which is enough for one cheese plant with about 260
employees, 41 of whom use it. Mantiqueira has run it since 2019 in the online version, which
Microsoft operates as a service; Business Central also exists for installation on a company's own
servers.

The idea in Business Central worth carrying into any system you design is how it is customised. In
NAV, partners changed the base application's code directly, in a language called C/AL. Every
customer's system was therefore a fork of Microsoft's, and every upgrade was a merge of the two.
That is why NAV upgrades had a reputation as projects of their own, and why plenty of customers
stayed on old versions for years.

Business Central online does not allow it. **The base application cannot be modified; everything a
customer adds is an extension**, written in AL, which sits beside the base and attaches to the
events and pages Microsoft publishes. Microsoft updates the base on its own schedule, and the
extensions survive because they never changed it. It is lesson 1's middle ring, "extend beside",
enforced by the product instead of by a team's discipline.

Mantiqueira has six extensions. The largest comes from a Brazilian partner and adds the tax layer:
issuing the NF-e and calculating the Brazilian taxes on each invoice line. Two were written for the
cheese itself, recording each wheel's ripening period and the milk batch it came from. The other
three are reports. When Felipe Arruda receives notice that Microsoft will update the base, his job
is to test those six against the new version in a sandbox, not to merge anybody's code.

Compare Serra Alta's SAP, with about 1,800 custom `Z` objects (lesson 2), each of which has to be
examined again on the move to S/4HANA. **An extension model moves the cost of customisation from
upgrade day to design day.** The partner who wrote Mantiqueira's tax layer had to work within the
events Microsoft exposes, and in return nobody has to re-apply that work every year.

## The CRM line, and the database under it

Dynamics CRM became a set of apps, of which Dynamics 365 Sales and Dynamics 365 Customer Service
are the best known. Those apps are built on **Dataverse**: a database Microsoft runs as a
service, with tables, relationships, security roles and an API. Dataverse was called Common Data
Service until Microsoft renamed it in 2020. It is also the database under Power Apps, so a Power App
that a department builds may store its data in the same kind of tables a CRM uses.

Serra Alta's CRM is Salesforce (lesson 4). The CRM line matters to it only through Dataverse, and
only when somebody's Power App outgrows its spreadsheet.

## Same brand, different data

The wrong idea the brand invites is that everything called Dynamics 365 shares one database and
integrates by itself. Regina asked a version of it in Joana's first month: since Mantiqueira "had
Microsoft", could its customers simply appear in the group's systems? They could not, and nothing
about the brand would make them.

**The ERPs keep their own databases.** Business Central and Finance and Supply Chain Management are
not stored in Dataverse. Each can be connected to it (for Finance and Supply Chain Management,
Microsoft calls the connection dual-write), but what appears in Dataverse is then a copy, with the
delay, the mapping and the conflicts that any copy has. A Business Central customer is a row in
Business Central. It becomes anything else only when something copies it, and that something is an
integration somebody has to own.

What the products do share is real and narrower: a licensing portal, an administration centre and a
sign-in. **In their online versions, every one of them signs its users in through Microsoft Entra
ID**, the same directory that holds Serra Alta's email accounts. That shared sign-in turns out to
be the most consequential integration in this lesson, and it is the subject of the next section.
