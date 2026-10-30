---
title: The Unified Catalog, and what the map costs
version: 1
---

**This section is taught from Microsoft's documentation and was not run.**

**The Data Map is what a machine found; the Unified Catalog is what people agreed.** Microsoft's
current catalogue organises data by **governance domains**, a business area such as sales or
logistics, each with **data products**: a set of assets published together for a purpose, such as
"Quitanda's orders, daily, for finance", with an owner, a description, the terms of use and a way to
request access. **Glossary terms** give business words one meaning, so that "active customer" is
defined once and linked to the columns that implement it, and **data quality** rules score the assets
of a product against expectations such as "no null order ids". The Data Map's assets are the raw
material; the catalogue is where somebody takes responsibility for them.

**That is also the part no tool fills on its own.** A scan can produce a hundred thousand assets
overnight; it cannot write what "active customer" means or decide who owns the orders table. A
catalogue whose products have no owners and whose terms have no definitions is the scan's output
with a nicer search box, and it is what most catalogues become when the work of curation has nobody
assigned to it.

## What it costs

**The Data Map is billed by capacity, by the hour, and scans by the processing they use**: the map
needs at least one capacity unit for as long as the account exists, more when it holds many assets or
is queried heavily, and each scan is charged for the compute time it runs. The newer catalogue
features carry meters of their own, which have changed as the product changed; the price sheet of
lesson 1 lists what applies on the day you look. The arithmetic below uses illustrative prices, round
numbers for the sum and not Azure's: 0.40 USD per capacity unit-hour for the map, and 0.60 USD per
vCore-hour of scanning.

| item | quantity in a 30-day month | illustrative price | month |
|---|---|---|---|
| Data Map, one capacity unit, always on | 730 unit-hours | 0.40 USD | 292.00 USD |
| a nightly scan of the lake using 4 vCore-hours | 30 × 4 = 120 vCore-hours | 0.60 USD | 72.00 USD |
| | | | **364.00 USD** |

**The map is a fixed cost and the scans are the variable one.** The map's capacity is paid whether
anybody searches or not, which makes a Purview account something to have once for the company rather
than one per team. The scans follow the schedule: scanning the lake every night rather than every
week multiplies that line by seven, and an incremental scan, which reads only what changed, is what
keeps a nightly schedule affordable. Whether a nightly scan is worth it depends on how fast new
personal data appears in places nobody expected, which the classification section showed is exactly
the case it is weakest at.

For the real prices, with the network; it was not run for this course:

```sh
python prices.py "Microsoft Purview"
```

As with every service in this course, the name the price list files a service under is Microsoft's
choice, and an empty answer means the filter matched no service rather than that the service is free.
