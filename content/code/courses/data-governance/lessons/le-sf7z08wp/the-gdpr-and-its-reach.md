---
title: The GDPR, and when it reaches a Brazilian company
version: 1
---

The **General Data Protection Regulation**, Regulation (EU) 2016/679, has applied in every member
state of the European Union since 25 May 2018. It is a *regulation*, not a directive: the same text is
law in all of them, with a few points left to national law — the age of a child's consent is one. The
LGPD was written with it open on the desk, which is why lesson 7 will feel familiar here, and why the
differences are worth knowing exactly.

## Ipê in Lisbon

From this lesson on, Ipê has a second address. It has opened a small company in **Lisbon** that sells
vitamins and cosmetics — not prescription medicines — to customers in Portugal, from a warehouse with
four employees. Its orders go into the same database in São Paulo, in the same `sales` schema. The
lab's data does not include them: the question here is which law reaches which row, and that can be
answered without a thousand Portuguese orders to look at. The one decision brings in two European
laws, and this section is about how.

**Article 3** of the GDPR has two triggers:

- **establishment** (art. 3(1)): processing *in the context of the activities of an establishment* in
  the Union, wherever the processing physically happens. The Lisbon company is an establishment. What
  it does with customers' data is under the GDPR even though the database sits in São Paulo.
- **targeting** (art. 3(2)): a controller with **no** establishment in the Union is still covered when
  it offers goods or services to people in the Union, or monitors their behaviour there. Had Ipê sold
  to Portugal straight from Brazil — a shop in Portuguese from Portugal, prices in euros, delivery to
  Porto — this trigger would have applied, and article 27 would have required a representative in
  the Union.

Either way the law follows the people, not the server, which is the same idea as LGPD article 3 read
from the other side. A data team cannot answer "are we under the GDPR?" by looking at where the
database runs.

## What is not reached

The Brazilian customers of the São Paulo company are not under the GDPR because their rows share a
table with Portuguese ones. The GDPR applies to the processing done in the context of the Lisbon
establishment and to the people it targets. But a table that holds both is a table where **both laws
apply to different rows**, and the difference has to be visible in the data: a column saying which
company, and so which law, each customer belongs to. A column that decides that has to be
trustworthy (lesson 9).

## Who supervises

Each member state has a **supervisory authority**; in Portugal it is the **CNPD**, the *Comissão
Nacional de Proteção de Dados*. A company established in several member states deals mainly with the
authority of its main establishment, the **one-stop shop**. Ipê has one, so the CNPD is its regulator
in Europe and the ANPD in Brazil.
