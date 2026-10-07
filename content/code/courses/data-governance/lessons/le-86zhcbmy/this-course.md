---
title: What this course is for
version: 1
---

**Data is a responsibility before it is an asset.** A table of customers is a list of people who
trusted a company with their names, their addresses and, in a pharmacy, the medicines they take.
Everything this course teaches is a way of keeping that trust measurable: who may read the table,
what is encrypted and with which key, what the law says the company may do with it, how long it
is kept, and who changed what.

The course follows one company. **Farmácia Ipê** is an online pharmacy with customers all over
Brazil. It does not exist, and neither does anybody in its database: the lab generates every row
from fixed seeds, and builds the data so that it cannot be real. Every CPF in it fails its own
check digit, every e-mail address is under a domain reserved for examples, and no telephone
number appears at all. Lesson 6 says why test data is built that way.

Ipê is a pharmacy on purpose. A bookshop's customer list is personal data. A pharmacy's is also
**sensitive** data in the sense of Brazil's LGPD, because an order for insulin says something
about somebody's health. That difference changes what the law asks, and most of the course's
decisions are about that difference.

## What it assumes

`sql-databases` is the one course required: you govern data that lives somewhere, and here it
lives in PostgreSQL. You should be able to read a `SELECT` with a join, create a table and know
what a primary key is. Nothing here assumes you have studied security or law before. Where a
subject has a course of its own, this one says so and teaches enough to use it.

## How it is arranged

The eleven lessons go from the door inwards and then outwards:

| lessons | what they cover |
|---|---|
| 1 and 2 | who may connect, and what each role may read, down to the row and the column |
| 3 and 4 | encryption on the wire and on the disk, and the keys that make it worth anything |
| 5 | changing the data itself so that less of it is dangerous: masking, tokens, anonymisation |
| 6 to 8 | what personal and sensitive data are, the LGPD in practice, GDPR and the EU AI Act |
| 9 and 10 | governance: quality, lineage, ownership, retention and the audit trail |
| 11 | agreeing with other teams what a dataset is, and keeping the agreement |

**Law and technique are taught together**, because each one is incomplete without the other. A
legal basis for processing does nothing if every analyst can read every column, and a perfect
grant scheme is still unlawful if nobody had a reason to collect the data.

::: track bi
On the BI track you are most likely the person who is granted access rather than the person who
grants it. That is the seat where governance is most often broken by accident: an export to a
spreadsheet, a dashboard shared with a link, a join that re-identifies somebody. The lessons are
written from the engineer's side because that is where the controls are built, and you will need
to know what each control is for when you ask for an exception to it.
:::

::: track data-platform
On the data platform track you are the person who builds the controls. Most of what follows is
yours to run: the roles, the encryption, the key management, the retention jobs and the audit.
The legal lessons are there because the platform team is the one asked, on a Friday afternoon,
whether a request from the DPO can be answered by Monday.
:::

::: track *
Whichever side of the grant you sit on, the lessons are written from the side that builds the
controls, because that is where they can be seen working. If you are usually the person asking
for access, you will at least know what each control is for when you ask for an exception to it.
:::

## What it does not cover

Cryptography itself — how AES or a TLS handshake work inside — is the `cryptography` course.
Lesson 3 here uses encryption and explains enough to choose where to apply it. Attacks are not
taught anywhere in this course: every lesson is written from the defender's side, about how a
control is built, how it is checked and how a failure is noticed.
