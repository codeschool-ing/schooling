---
title: What a dictionary entry holds
version: 1
---

A dictionary has one entry per column, grouped by table, and one entry per table. What goes in an entry is a small,
fairly settled list:

- **The meaning**, in a sentence a person outside the data team can read. "Net sales: gross minus discount, without
  shipping" rather than "net value".
- **The unit**, wherever there is one: centavos, days, copies, percent. A number without a unit is the commonest
  source of a factor-of-a-hundred mistake.
- **What empty and special values mean.** Key 0 is "not identified"; date key 0 is "not yet"; an empty `days_to_ship`
  means the order has not shipped. Each of these was a decision in an earlier lesson, and a reader cannot guess it.
- **How it may be added up**: additive, semi-additive, or not at all, which is lesson 2's distinction written where the
  person writing the `SUM` will see it.
- **Where it comes from**, at least as far as the source system and column; that is the start of lineage.
- **Whether it describes a person**, and how directly. That is the classification of section 9.

A table's entry adds the one thing above all others: **its grain**, one sentence saying what a row is. Lesson 4 spent
a whole lesson on why.

Beside the dictionary there is often a **business glossary**: a list of terms the business uses, such as net sales,
receipts or active customer, each with its definition and an owner. The two are different documents with a link
between them. The glossary says what "net sales" means to the company; the dictionary says which column holds it.
Lesson 11's three revenues were a glossary missing, and a dictionary missing beneath it.
