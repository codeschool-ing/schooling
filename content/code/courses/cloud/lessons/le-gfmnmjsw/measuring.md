---
title: The bill as data, and the number that matters
version: 1
---

The invoice at the end of the month is the least useful form the bill takes. It arrives late, it is one
total per service, and it cannot be asked a question. **The same charges are available as data**, and
every provider offers two ways to read them.

## Views and exports

The first is a **cost explorer**, a screen that groups and filters the charges: by service, by region,
by tag, by day. AWS calls it Cost Explorer, Google Cloud has its billing reports, and Azure has cost
analysis in Cost Management. It answers the questions of the routine in the section on budgets: which
line moved, since when, and under which tag.

The second is an **export**: every charge, one row per resource per period, delivered as files or into a
database you can query. AWS delivers the Cost and Usage Report to an S3 bucket; Google Cloud exports
billing data to BigQuery; Azure writes cost exports to a storage account. The rows carry the same fields
this lesson has been reading on the price list, a usage type, a quantity, a unit and a cost, plus the
resource and its tags. Once the bill is a table, "how much did staging cost last quarter, per team" is a
query rather than an afternoon.

Both are hours behind the usage, for the reason the section on budgets gave, and both show amounts that
can still change until the month is closed. Neither is a live meter.

## Unit cost

A total alone cannot tell you whether a bill is healthy. The application from this lesson's estimate
costs 298.64 a month; a year later it costs 900. That is either a problem or excellent news, and the
total cannot say which.

**Unit cost is the total divided by the thing the business sells**: cost per customer, per thousand
requests, per order, per gigabyte processed. Say the application had 2,000 active users when it cost
298.64: about 0.15 per user a month. If a year later it costs 900 for 12,000 users, that is 0.075 per
user. The total tripled and **each user became cheaper to serve**, which is what a design that
scales well looks like.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Two charts over twelve months of the same application. Left, total cost a month in USD rises from 298.64 to 900. Right, cost per active user a month falls from 0.15 to 0.075, while the users grow from 2,000 to 12,000.\"><defs><marker id=\"unit-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">total cost a month, USD</text><path d=\"M60 220 L310 220\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60 220 L60 50\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60.0 199.0 L82.7 194.5 L105.5 187.2 L128.2 178.1 L150.9 167.8 L173.6 156.4 L196.4 144.0 L219.1 130.8 L241.8 116.8 L264.5 102.1 L287.3 86.7 L310.0 70.7\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"60.0\" cy=\"199.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"310.0\" cy=\"70.7\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"70.0\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">298.64</text><text x=\"304.0\" y=\"56.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">900</text><text x=\"60\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">month 1</text><text x=\"310\" y=\"238\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">month 12</text><text x=\"380\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">cost per active user a month, USD</text><path d=\"M420 220 L670 220\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M420 220 L420 50\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M420.0 76.0 L442.7 93.6 L465.5 106.7 L488.2 118.4 L510.9 129.4 L533.6 139.9 L556.4 149.9 L579.1 159.6 L601.8 169.0 L624.5 178.2 L647.3 187.2 L670.0 196.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"420.0\" cy=\"76.0\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><circle cx=\"670.0\" cy=\"196.0\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"430.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0.15</text><text x=\"664.0\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0.075</text><text x=\"420\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">month 1</text><text x=\"670\" y=\"238\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">month 12</text><text x=\"360\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">over the same year, active users grow from 2,000 to 12,000</text></svg>", "caption": "The example from this section, drawn: the total triples and each user becomes cheaper to serve. The line in between the two points is illustrative; only the ends are the section's numbers."}
```

The opposite curve is the warning. When cost per user rises as users grow, something in the design
grows faster than the business: logs kept forever, a query that scans every row it ever stored, a
replica per customer, a NAT gateway carrying traffic that doubles every time a feature is added.
A total rising is normal; **a unit cost rising is a defect waiting to be found**.

Choosing the unit is a decision in itself. It should be something the product counts anyway, that grows
with the work the system does, and that a person outside engineering understands. Cost per active user
works for most applications; cost per gigabyte processed works for a data pipeline; cost per build works
for a CI system. The number is only useful if it is tracked every month, the same way, so a change in it
means a change in the system and not in the arithmetic.
