---
title: "Data residency: where the bytes are is a legal fact"
version: 1
---

A region is a place, and a place has laws. **Data residency** is the plain question of where a
piece of data physically is — which country its disks stand in, and its backups, and its copies —
and it matters because the answer decides which rules apply to it. For personal data about people
in Brazil, the rule to read first is the LGPD, the Lei Geral de Proteção de Dados (Law 13,709 of
2018).

## What the LGPD does not say

The wrong idea is common and confidently repeated: *the LGPD requires Brazilians' personal data to
be stored in Brazil*. **It does not.** There is no general localisation requirement in it. What it
regulates is the *international transfer* of personal data, in its Chapter V, and art. 33 opens by
saying such a transfer is permitted only in the cases it lists. Paraphrased, they are:

- to countries or international organisations that provide a level of protection adequate to the
  LGPD's, which the national authority, the ANPD, assesses;
- when the controller offers and proves guarantees that the law's principles and the data
  subject's rights will be respected, in the forms the article names: clauses specific to one
  transfer, standard contractual clauses, global corporate rules, and seals, certificates and codes
  of conduct;
- when the data subject has given specific consent, highlighted, for the transfer, having been told
  beforehand that it is international;
- when it is needed to meet a legal obligation, to perform a contract with the data subject, or
  to exercise rights in legal proceedings;
- and a group of narrower cases: international legal cooperation between intelligence,
  investigation and prosecution bodies; protecting the life or physical safety of the data subject
  or somebody else; authorisation by the ANPD; a commitment in an international cooperation
  agreement; and carrying out a public policy.

The ANPD has since published a regulation on international transfer, with the text of the standard
contractual clauses, in Resolution CD/ANPD No. 19 of 2024. So **a transfer abroad is lawful when it
fits one of those cases**, and the work is showing which one. Whether a particular arrangement is a
transfer, and which case covers it, is a question for whoever answers for the organisation's
compliance, with the law and the regulation open. This lesson does not answer it for you, and
neither does a provider's marketing page.

Sector rules can add what the LGPD does not. The financial sector, for one, has rules from its
regulator on contracting cloud services, including services abroad. Where a requirement about
location exists, it is in rules like those, and you read them in their own words.

## The region is the lever

What a cloud gives you is a clean way to act on the answer. **The region you choose is where the
data at rest is.** Personal data kept in `sa-east-1` sits in São Paulo, and for that copy the
transfer question does not arise.

The mistake is to stop at the primary copy. Every copy is a location:

- a backup replicated to a second region for safety;
- logs shipped to a monitoring service whose servers are in another country;
- a support engineer abroad who opens a customer's record while fixing a bug;
- a content delivery network caching a page with somebody's name on it at an edge far away.

Each of those can put personal data in another country while the database itself never moves. A
map of where the data goes is the first document the compliance question needs, and it is an
engineering document.

Residency has a price, and the sheet shows it. The same `t3.medium` is 0.06720 USD an hour in
`sa-east-1` and 0.04160 in `us-east-1`; S3 Standard storage is 0.04050 per GB-month against 0.02300.
Keeping data in Brazil is a choice with a line on the bill, and knowing what the law actually
requires is how a team avoids paying for an obligation that does not exist, or skipping one that
does. Residency is also not sovereignty: the section on sovereign clouds showed that where the
data sits and which courts can reach it are separate questions. Lesson 9 goes further into regions
and how to choose one.
