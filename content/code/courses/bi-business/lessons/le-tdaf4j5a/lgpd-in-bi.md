---
title: The LGPD in everyday BI
version: 1
---

Lesson 19 met the LGPD where it bites hardest, in health data. This section is about the ordinary
case, which is every company in this course: Varanda has customers' names, addresses and purchase
histories, employees' salaries and absences; Ipê has borrowers' incomes and debts. **Most BI work
needs none of the identities and some of the details**, and the law's demands on a BI team come down
to keeping it that way and being able to show that it does. `data-governance` lessons 6 and 7 cover
the law itself; what follows is what it changes at the analyst's desk.

## Four habits

**Purpose.** Personal data is collected for a purpose, and using it for another needs its own basis.
Varanda collected delivery addresses to deliver sofas. Using them to map where its customers live,
for choosing the next store's location, is a different purpose, and Lívia asked the company's data
protection officer before building the map rather than after. The answer was yes, at the level of the
neighbourhood and not the street.

**Minimisation.** A report carries the fields its question needs and no others. The campaign
analysis of lesson 18 needed, per customer, the group they were in and whether they ordered. It did
not need their names, and the file Lívia worked from did not have them.

**Access by role.** Lesson 19's rule, in a retailer: the store managers see their own store's sales,
Sônia's HR reports with salaries are seen by HR and the directors, and a dashboard shared by link is
checked for what the link exposes before it is sent.

**Aggregation, with small cells in mind.** Sales by neighbourhood are not personal data; sales by
street in a street with three houses may be. The suppression rules of lesson 19 apply to any table
that can be cut finely enough to point at a person.

## Anonymised or pseudonymised

The two words are not interchangeable, and the difference decides whether the law applies.

**Pseudonymised data** has the identity replaced by a code that the company can turn back into a
person: customer 48213 instead of a name, with the key in another table. It is what Débora used at
Jacarandá to link two admissions of the same patient, and what Lívia uses to follow a customer's
orders over time. **It is still personal data**, because the company holds the key.

**Anonymised data**, in the LGPD's terms, is data that can no longer be linked to a person by
reasonable means, and art. 12 says it is not personal data, unless the anonymisation can be reversed.
That last clause is the hard part: removing names is not enough when a birth date, a postcode and a
purchase together point at one person. A table of Varanda's sales by store, month and category is
anonymous; a table of individual purchases with the customer code removed but the date, the store and
the exact basket kept may not be.

The practical test is to ask what somebody holding the file and anything else easily available could
work out. If the answer includes a person, treat the file as personal data.

## When a customer asks

Art. 18 gives the person the data is about, the data subject, rights the company has to answer:
among them, to confirm that their data is processed, to have access to it, to correct it, and to
have unnecessary or excessive data deleted. Requests go to the company's data protection officer,
and the BI team's part is finding the person in everything it holds: the warehouse tables, the
snapshots, the extracts in somebody's folder. **A BI team that cannot say where a customer's data is
cannot answer the request**, which is the best argument for keeping as few copies as the work needs.

Deletion meets the previous section head on. Ipê's frozen snapshots contain borrowers, and a borrower
may ask to be deleted. The law allows data to be kept where a legal or regulatory obligation requires
it, so the snapshot a regulator may ask to see stays, kept apart and with access restricted, while
the copies made for convenience go. Which records fall under which obligation is the compliance and
legal teams' call, written down once; the BI team applies it the same way every time.
