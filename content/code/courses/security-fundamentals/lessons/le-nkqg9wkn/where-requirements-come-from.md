---
title: Where requirements come from
version: 1
---

Requirements reach an organisation from four kinds of source, and they differ in how optional they
are:

| source | example for the shop | can the shop say no? |
|---|---|---|
| **law** | Brazil's LGPD: protect personal data and report serious incidents (lesson 17) | no |
| **sector regulation** | for a bank, the Central Bank's cybersecurity rules; the shop has none | no, if you are in the sector |
| **contract** | the card payment provider requires its merchants to follow **PCI DSS**, the card industry's security standard | only by giving up card payments |
| **voluntary standard** | ISO 27001 (lesson 14), chosen because a large customer asked for it | yes, but the customer may then choose somebody else |

The contract row is often the first one a small business meets. **PCI DSS** (Payment Card Industry
Data Security Standard) is written by the card brands' standards council and imposed on every
business that stores, processes or transmits card data, through the contract with whoever processes
its payments. The shop avoided most of it the way lesson 3 described: by sending customers to the
payment provider's page, so that card numbers never touch the shop's server. The requirements left
for the shop shrank to a short self-assessment questionnaire. That is risk avoidance and compliance
scoping at the same time.

### From requirement to control to evidence

A requirement rarely says exactly what to do. It states an **objective**, and the organisation decides
how to meet it:

1. **the requirement**: "personal data must be protected by appropriate technical and administrative
   measures" (the LGPD's article 46, in lesson 17);
2. **a policy**: the shop's own rule, "access to customer data is granted by role and reviewed every six
   months";
3. **a procedure**: who does the review, with what list, and where the result goes;
4. **evidence**: the signed review from last March, and the one from last September.

The chain matters because an auditor follows it backwards. They start from the requirement, ask for
the policy, ask how it is carried out, and then ask to **see** that it was carried out. A policy with
no evidence is a promise; a procedure nobody follows is fiction.

### One control, many requirements

The same control usually satisfies several requirements at once. An access review answers the LGPD's
security duty, a PCI DSS requirement and an ISO 27001 control. Organisations that keep a **control
mapping**, a table from each control to every requirement it satisfies, do the work once and show it
many times. `threat-modeling` lesson 13 builds such a mapping across ISO 27001, the NIST CSF and SOC 2.
