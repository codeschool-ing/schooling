---
title: Moving data between Lisbon and São Paulo
version: 1
---

Ipê's Lisbon orders go into a database in São Paulo. Under the GDPR that is a **transfer to a third
country**, and Chapter V allows it only on one of a few grounds. The order of preference is fixed:

1. an **adequacy decision** (art. 45): the European Commission has decided that the country's law
   gives essentially equivalent protection, and data flows as if it were inside the Union;
2. **appropriate safeguards** (art. 46): most often the Commission's **standard contractual clauses**,
   signed between exporter and importer, with an assessment of whether the destination's law lets
   them be honoured;
3. **derogations** for specific situations (art. 49): the person's explicit consent to that transfer,
   a contract with them that needs it, and a few others — meant for the occasional case, not for a
   daily pipeline.

## Brazil is adequate, since January 2026

On **26 January 2026** the Commission adopted **Implementing Decision (EU) 2026/179**, finding that
Brazil ensures an adequate level of protection, after an opinion of the European Data Protection
Board in November 2025. Brazil adopted its own decision recognising the European Union in a
coordinated way, and the two were announced together on 27 January. They are **two separate
decisions**, each under its own law.

For Ipê this removes a contract: Lisbon to São Paulo needs no standard clauses, and neither does the
other direction. It does not remove the rest of the GDPR — the data is just as personal on arrival,
the Portuguese customers keep every right, and the CNPD can still ask how it is protected.

## The LGPD's side

The LGPD has its own chapter on international transfers (articles 33 to 36), with the same shape:
adequacy, contractual clauses, and specific cases. **Resolução CD/ANPD nº 19/2024** regulated them
and published Brazil's standard contractual clauses. Data leaving Brazil for a country without an
adequacy decision — a cloud region in the United States, a support tool hosted somewhere else — still
needs one of the other grounds.

## What this is in the data

A transfer is a fact about **where data goes**, so it belongs in the record of processing beside the
purpose and the basis: which systems receive which tables, in which country, on which ground. The
question a regulator asks — "where are my citizens' data, and why may they be there?" — should be one
query against that record, and the backup in another region, the analytics tool and the e-mail
provider are where it usually turns out to be incomplete.
