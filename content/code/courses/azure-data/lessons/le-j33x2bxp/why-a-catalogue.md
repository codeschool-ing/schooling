---
title: Why a catalogue, and what Purview is
version: 1
---

**This lesson is taught from Microsoft's documentation, apart from one program of the course's own.**
Microsoft Purview has no emulator and nothing of it runs on a laptop. The section on classification
runs a small classifier written for this course over Quitanda's export in Azurite, to show what a
classifier does; it is not Purview and says so where it runs.

**A data platform that grows without a catalogue ends up holding data nobody can find.** Quitanda's
lessons so far have put the same customer in many places: the orders database of lesson 8, the
nightly export in Blob Storage of lessons 2 to 7, the Delta tables of lesson 18, the files Capture
wrote in lesson 22. Each was a sensible decision. Together they make a question that sounds simple
hard to answer: **where is this customer's CPF stored, and who copied it there?**

That question arrives in a real form. Under Brazil's data protection law, the LGPD, a person may ask
a company what data it holds about them and have it corrected or deleted; what the law requires is
the subject of `data-governance`, lesson 7, which this course does not assume. For the engineer, the
request turns into a search across every store, and the search is only as good as the list of stores
and what is in them. A catalogue is that list, kept up to date by a machine rather than by memory.

## Three jobs

**A catalogue does three things, and Purview's parts map onto them**:

| job | the question it answers | in Purview |
|---|---|---|
| find | what data exists, where, and what is in each column | the Data Map, filled by scans |
| recognise | which columns hold personal or sensitive data | classifications, and sensitivity labels |
| trace | where a table's data came from and where it went | lineage, reported by the tools that move data |

On top of those three sits the part people search and govern through, which Microsoft calls the
**Unified Catalog**: business terms, owners, data products and the rules about who may use what. The
last section of this lesson is about it and about the bill.

## A name that covers two families

**"Microsoft Purview" is the name of two families of products that grew together**, and the
documentation mixes them. One family governs data platforms: the Data Map, scans, lineage and the
catalogue, the subject of this lesson, and the successor of what used to be called Azure Purview and,
before that, Azure Data Catalog. The other family protects documents and messages in Microsoft 365:
sensitivity labels on files and e-mails, data loss prevention, retention of mailboxes. They share a
portal and some concepts, sensitivity labels above all, and a search for "Purview" returns both.
This course is about the first, and it meets the second once, in the section on labels.
