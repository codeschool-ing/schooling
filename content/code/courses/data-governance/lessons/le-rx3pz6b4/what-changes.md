---
title: What changes when data is sensitive
version: 1
---

Classifying a column is only worth the effort if the class changes how it is handled. At Ipê it does,
and the rules can be written as one table that a reviewer can hold a pull request against:

| | `none` | `personal` | `identifying` | `sensitive` |
|---|---|---|---|---|
| **who may read it** | anybody with a job that needs the table | jobs that need it (lesson 2) | jobs that need it, through masks where possible (lesson 5) | named jobs only, each with a reason a DPO has seen |
| **legal basis** | none needed | article 7 (lesson 7) | article 7 | **article 11 only** (lesson 7) |
| **encryption** | in transit and at rest | in transit and at rest | plus in the application where it is searched or read rarely (lessons 4 and 5) | plus in the application, or in a schema of its own with its own grants |
| **in exports and analytics** | freely | pseudonymised | never in clear | aggregated with suppression (lesson 5), or not at all |
| **retention** | as the business needs | the period the purpose needs (lesson 10) | the period the purpose needs | the shortest period the purpose allows |
| **assessment** | none | in the record of processing | in the record of processing | a data protection impact assessment (lesson 7) |

**Sensitive data narrows the legal bases.** Article 11 allows sensitive data to be processed only with
the person's specific and highlighted consent, or without it in a short list of cases — a legal
obligation, health protection by health professionals, the exercise of rights in court, fraud
prevention and a few more. Lesson 7 goes through them; the point here is that "the business finds it
useful", which can support processing ordinary personal data, cannot support processing sensitive
data.

**And sensitive data shared for economic advantage is restricted.** Article 11, §4 forbids sharing
health data between controllers to obtain an economic advantage, with exceptions for providing
health services, pharmaceutical assistance and health care in the person's interest. A pharmacy
selling purchase histories to a marketer is exactly what that paragraph exists for.

## The table as a review tool

The value of writing the rules this way is that each cell is checkable. A grant to analysts on
`health.prescriptions` contradicts a cell. An export job selecting `order_items.product_id` for a
partner contradicts a cell. A reviewer does not need to know the LGPD to see the contradiction —
only the class of the column, which section 7 made something a query can answer.
