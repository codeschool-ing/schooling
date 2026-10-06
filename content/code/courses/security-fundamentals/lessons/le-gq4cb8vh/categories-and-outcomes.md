---
title: Categories and outcomes
version: 1
---

Under the six functions, the CSF breaks the ground down twice more. In version 2.0 there are **22
categories** and **106 subcategories**, and every one of them is written as an **outcome**: a state of
affairs to achieve, not an instruction on how to achieve it.

A few examples, with their identifiers:

| identifier | category | an outcome it contains, in short |
|---|---|---|
| **GV.RM** | risk management strategy | risk appetite and tolerance are established and communicated |
| **ID.AM** | asset management | inventories of hardware, software, services and data are maintained |
| **PR.AA** | identity management, authentication and access control | access is limited to authorised users, with least privilege |
| **PR.DS** | data security | backups are created, protected, maintained and tested |
| **DE.CM** | continuous monitoring | networks, users and systems are monitored to find adverse events |
| **RS.MA** | incident management | incidents are triaged, prioritised and escalated |
| **RC.RP** | incident recovery plan execution | restoration is carried out to ensure operational availability |

The identifier is built from the function's two letters and the category's: `PR.AA` is Protect,
identity management and access control. Subcategories add a number, such as `PR.DS-11` for the backup
outcome in the table.

### Outcomes, not instructions

The difference matters. "Backups are created, protected, maintained and tested" does not say nightly,
does not say which tool, does not say 3-2-1. Lesson 12 is one way to meet it; a cloud service with
immutable snapshots is another. That is why the CSF fits a nine-person shop and a bank equally: each
decides **how**, and the framework only names **what**.

For the how, the CSF points elsewhere. NIST publishes **informative references** that map each
subcategory to specific controls in other documents, including ISO 27001's Annex A, CIS Controls (lesson
16) and NIST's own control catalogue, SP 800-53. And CSF 2.0 adds **implementation examples**: short,
concrete illustrations of what meeting each outcome might look like.

### Using the categories

The categories turn the six functions into something an organisation can score itself against. For each
subcategory: do we meet this outcome fully, partly, or not at all? The answers, written down, are the
raw material for the next section's profiles. They are also a natural place to attach evidence in the
sense of lesson 13: next to `PR.DS-11`, the restore test log.
