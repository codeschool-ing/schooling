---
title: Counting the services, and removing some
version: 1
---

Teams ask an architect what to add: a service, a cache, a queue, a tool. Nobody asks what can be
taken away, because removing something produces no feature, no announcement and no line on anybody's
goals for the quarter. **Removal is work the architect has to ask for, and it starts with an
inventory, because nobody can remove what nobody has listed.**

## The inventory

In her first quarter Renata built a table with one row per deployable service. For each one she
recorded the owning team, what calls it, how many times it was deployed in the last 90 days, how
many pages it raised, when its code last changed for a reason other than an upgrade, who could
explain it, and why it exists as a separate deployable rather than as code inside something else.

The last column was the hard one. Nine services had a clear answer to it. Five did not.

| service | team | why it is separate | verdict |
|---|---|---|---|
| monolith | Shipper, Matching, Payments | most of the business, one deploy and one database | keep |
| tracking-ingest | Tracking | takes GPS positions from every moving truck, about 270 a second at peak | keep |
| tracking-api | Tracking | serves positions to the apps and scales apart from the ingest | keep |
| delivery-proof | Tracking | photos and signatures, large uploads kept off the monolith | keep |
| pricing | Pricing | its own release cycle, with quote rules changing weekly | keep |
| cte-issuer | Payments | talks to the tax authority and keeps a slow outside dependency apart | keep |
| pix-payouts | Payments | holds the bank credentials, isolated for security and audit | keep |
| driver-gateway | Driver | the mobile app's API, versioned for old app versions still in use | keep |
| notifications | Platform | push messages and SMS for every team | keep |
| pricing-floor | Pricing | holds the ANTT floor table; called only by pricing | merge into pricing |
| invoice-pdf | Payments | renders invoices once a day; called only by the monolith | fold into the monolith |
| geo-distance | Matching | wraps a routing library; called only by the monolith | make it a library |
| config-service | Platform | homegrown configuration, duplicating environment variables | delete |
| load-search | Matching | search over open loads, built at a hackathon; used by 4% of shippers | ask product |

**The pattern in the five is a separate deployable with exactly one caller, or none that needs it.**
A service with one caller has none of the benefits a service exists for. It cannot be deployed
independently in any way that matters, because its only caller has to change with it; it does not
isolate a failure, because when it is down its caller is down too; and it carries every cost from
the previous section.

## The five, one at a time

**pricing-floor** was split out in 2020 so that the floor "could be updated without deploying
Pricing". ANTT revises its table a few times a year, and every revision still went through an
engineer and a review. In return, every quote made a network call to it, and on two occasions
pricing-floor was down and Pricing could not quote at all. The table became a versioned data file
inside Pricing, changed by a reviewed pull request, which is what had been happening anyway.

**invoice-pdf** is called once a day, by the monolith's nightly invoicing job. It had its own
pipeline, its own base image to patch and its own place on the on-call rota. It became a module the
nightly job calls directly.

**geo-distance** wraps an open-source routing library behind an HTTP API, and the monolith called
it about 40,000 times a day. Each call was a network hop that could time out, for a calculation the
monolith could do in-process. The library moved into the monolith as an ordinary dependency.

**config-service** was Carreto's third way to configure things. When it was down, services could
not start, and it had paged people 11 times in the 90 days. Platform moved every value into the
environment variables its deploy tooling already managed, and switched it off.

**load-search** was the one Renata could not decide. It keeps its own copy of every open load, which
is the copy the failing nightly job maintains, and it serves a search screen that 4% of shippers
use. Taking it away removes a feature, and **removing a feature is a product decision**, so it went
to Helena Prado. She wanted to talk to the shippers who use it first, and at the end of the second
quarter it was still running.

Over two quarters four of the five went, and Carreto had 10 deployable services instead of 14. At
Paula's figure of 6 hours a month each, that is 24 hours of upgrade work a month that nobody does
any more, close to 300 hours a year. The four had raised 23 of the 112 pages in the 90 days before
the inventory, and they raise none now.

## Removing safely

A half-removed service is worse than either a live one or a gone one: it still has an alert that
fires, a dashboard somebody trusts and a page in the wiki that says it is the way to do things.
Renata's teams followed the same steps each time.

1. **Find every caller from traffic, not from documentation.** The access logs and the broker's
   consumers say who calls a service; the wiki says who called it when the page was written.
2. **Move the callers**, one at a time, each change small enough to roll back.
3. **Watch the old service receive nothing** for two weeks, which covers a fortnightly batch job
   that nobody remembered.
4. **Switch it off and keep it switchable** for a month: the image stays in the registry and the
   configuration stays in the repository.
5. **Delete everything it left behind**: the repository or directory, the pipeline, the dashboards,
   the alerts, the secrets and the documentation. Then write one line in the architecture records
   saying it is gone and why.

## Why removal needs the architect

Look at who pays and who saves. Merging pricing-floor cost the Pricing team about two weeks. The
saving went to Platform's upgrade hours and to every engineer on the on-call rota. **When the cost
lands on one team and the saving is spread across all of them, no team's roadmap will ever carry
the work.** The architect sees the whole inventory and can argue for the time. Renata took the table
to Tomás Viana with the hours and the pages beside each row, and asked for three weeks across
Pricing, Payments and Platform. She got them because the table made the cost of keeping visible, and
until then nobody had ever added it up.

## The cheapest piece to remove is one nobody added

The surest way to have less to remove is to add less. **YAGNI**, "you aren't gonna need it", comes
from Extreme Programming in the late 1990s: do not build a capability for a need you only expect to
have. Martin Fowler's essay on it lists what such a presumptive feature costs: the cost of building
it; the cost of delay, because something else was not built in that time; the cost of carrying it,
because it makes everything near it harder to change; and, when the presumed need turns out to be
different, the cost of repairing it.

pricing-floor was a presumptive feature. It was built for business people who would update the
floor themselves, a need that was never confirmed and never arrived, and Carreto paid to carry it
every month from 2020 until Renata's inventory.

Fowler also marks the limit of the rule, and it is easy to get backwards. **YAGNI is about features
for a future nobody has confirmed, never about the work that keeps code easy to change.** Tests,
refactoring and clear module boundaries are what make it cheap to add the feature on the day it is
really needed, so cutting them in YAGNI's name defeats the rule's own purpose. Lesson 17 shows what
happens to a system when nobody applies YAGNI for several years, under the name overengineering.
