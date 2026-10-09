---
title: Where intelligence comes from
version: 1
---

Five places intelligence comes from, roughly in the order of how much a small company should trust them:

| source | what it offers | the catch |
|---|---|---|
| **your own incidents** | indicators and techniques seen in your own network, with full context | only what already happened to you |
| **sharing groups** | reports from organisations like yours: an ISAC for a sector, a regional group of security teams | you are expected to share back |
| **national CSIRTs** | advisories and incident handling help. In Brazil, **CERT.br** for networks in the country and **CTIR Gov** for the federal government | broad, not tailored to you |
| **open feeds** | free lists of addresses and domains seen in scanning, spam, malware | noisy, and nobody vouches for an entry |
| **commercial providers** | curated, enriched feeds and reports | cost, and the same feed is sold to everybody |

The first row is the one most teams neglect. **Your own incidents are the only intelligence that is
certainly relevant to you**, and writing them up properly (lesson 20) is how a SOC builds it.

The second row is where Thursday's address came from in this lesson's story: a group of accounting firms
that share what they see. Sharing works when it is two-way, timely and **marked**, so that everybody knows
how far a report may travel. That marking is the next section.
