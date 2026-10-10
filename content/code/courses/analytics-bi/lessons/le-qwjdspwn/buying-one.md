---
title: Before you buy one
version: 1
---

`sync.sh` is fifty-five lines and moved 2,649 contacts into one CRM. A product moves millions into
dozens of destinations, with bulk APIs, mappings that know each destination's fields, retries tuned to
each API, alerts and a history somebody else maintains. **The question is not whether the product does
more. It is whether the company needs what it does more of**, at what it costs.

Build it by hand when there is one destination, a few thousand records, and somebody who will own the
script. Buy when the destinations multiply, when people outside the data team need to build audiences
themselves, or when the hours spent keeping scripts alive cost more than the licence.

## How they charge

Each of the three counts something different, and that is the first thing to read on its pricing page.
Segment's event collection is priced by **monthly tracked users**, as the identity section described;
reverse ETL products have priced by the number of destinations, of synced records or of features. Prices
and plans change often enough that this course quotes none: read the page on the day you decide, and
work out what *your* count would be — 2,649 contacts and one CRM is a very different bill from two
million visitors a month.

## Questions to ask a vendor

- **Where are the data processed and stored?** Which country, which cloud, and whether rows are kept
  after a run or only pass through.
- **Is there a data processing agreement**, and which sub-processors does it list? Under the LGPD the
  company remains responsible for what the vendor does with the data.
- **How does it reach the warehouse?** A user that can only read the models it needs, like the
  `metabase` role of lesson 3, and never the owner's. If its engine keeps state in the warehouse, it
  writes to a schema of its own and nowhere else.
- **What happens to deletes and to a full resync**, for each destination you will use?
- **What can you get out?** The models are your SQL and stay with you. The mappings, schedules and
  audiences built in its screens are the vendor's format; ask how they are exported, because the day
  you leave is the day you will want them.
