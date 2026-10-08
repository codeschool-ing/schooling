---
title: Children and adolescents
version: 1
---

Lesson 2's profile view had a band nobody expected in a pharmacy's customer list: **under 18.** The
LGPD gives data about children and adolescents an article of its own, and the first thing to know is
how many there are:

```sql
-- Customers under eighteen on the lab's today, by age.
SET ROLE ipe_owner;
SELECT extract(year FROM age(DATE '2026-07-01', birth_date))::int AS age,
       count(*) AS customers,
       count(*) FILTER (WHERE marketing_opt_in) AS accepted_marketing
FROM sales.customers
WHERE age(DATE '2026-07-01', birth_date) < interval '18 years'
GROUP BY 1 ORDER BY 1;
```

```
ana@lab:~/gov$ psql -f minors.sql
SET
 age | customers | accepted_marketing 
-----+-----------+--------------------
  16 |         5 |                  3
  17 |        15 |                  9
(2 rows)
```

Twenty customers: five aged 16 and fifteen aged 17, and **twelve of them accepted marketing.**

## What article 14 asks

**Article 14** says that processing the data of children and adolescents must be done **in their
best interest**, and adds specific rules. Brazilian law uses the Statute of the Child and Adolescent's
ages: a *child* is under 12, an *adolescent* is 12 to 17.

- **For children**, the article's text asks for the specific consent of at least one parent or
  guardian, with narrow exceptions (contacting the parents, protecting the child), and for reasonable
  efforts to check that the consent really came from the parent. In 2023 the ANPD issued a statement
  (Enunciado CD/ANPD nº 1) reading the article as allowing the other legal bases of articles 7 and 11
  as well — always under the best-interest test.
- **For both**, the controller must not make taking part in games, apps or other activities depend on
  giving more personal data than strictly necessary, and must publish clearly what it collects and
  how it is used, in language the young person can understand.

Ipê has no children in its data; it has adolescents. Their data is personal data with the "best
interest" test on top — and an adolescent's marketing consent, a pharmacy's purchase history and a
prescription for a contraceptive are exactly the combination where "best interest" is not an
abstraction.

Brazil has since added the **ECA Digital** (Law 15.211 of 2025), with duties for digital products and
services aimed at, or likely to be used by, children and adolescents — and made the ANPD the body
that supervises it. A data team does not need to read it clause by clause; it needs to know that age
is a column the law cares about, and to be able to answer the question this section just answered.

## What the data team can do

**Measure it**, as above — a query anybody can run monthly, kept with its results.

**Check what the age changes.** Twelve adolescents accepted marketing: does Ipê's marketing system
treat them differently, and should it? Their order lines include products whose purchase by a
sixteen-year-old is itself sensitive. The answers belong to the DPO and the business; the numbers
are the data team's job.

**Ask why the data contradicts the rules.** If Ipê's terms of use say customers must be adults, then
twenty rows show that the sign-up form does not check, or that somebody is lying about their age —
and a control that was supposed to exist does not. That is a finding for lesson 9's data quality
checks as much as for the law.
