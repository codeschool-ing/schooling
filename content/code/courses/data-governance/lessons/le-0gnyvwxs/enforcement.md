---
title: The DPO, and what the ANPD can do
version: 1
---

## The encarregado

**Article 41** requires the controller to appoint an **encarregado** — the data protection officer.
Their identity and contact details must be **public**, clearly, preferably on the controller's
website (§1). Their activities (§2):

- receiving complaints and communications from data subjects, answering them and taking action;
- receiving communications from the ANPD and acting on them;
- guiding employees and contractors on the practices to follow;
- the other duties the controller assigns or the ANPD's rules establish.

**Resolução CD/ANPD nº 18/2024** regulates the role. The encarregado may be an employee or an
outside person or company. They must be able to communicate clearly in Portuguese with data subjects
and the ANPD, and the controller must give them the means to do the job. And **the responsibility
for complying with the law stays with the controller**: appointing an encarregado does not move it.
Small agents, under Resolução 2/2022, may skip the appointment, but must still offer a channel for
data subjects.

At Ipê the encarregado is Davi, and section 9 gave him exactly what the job needs and no more: read
access to everything about a customer, a short-lived token to decrypt a CPF, and the requests table.

## Sanctions

**Article 52** lists what the ANPD can impose, and it has been able to since August 2021:

- a **warning**, with a deadline for corrective measures;
- a **simple fine** of up to **2% of the revenue in Brazil** of the company, group or conglomerate in
  its last financial year, net of taxes, **limited to R$ 50 million per infraction**;
- a **daily fine**, within the same total limit;
- **publicising** the infraction, once confirmed;
- **blocking** the personal data involved until it is regularised;
- **eliminating** the personal data involved;
- **partial suspension of the database** for up to six months, extendable once;
- **suspension of the processing activity** for up to six months, extendable once;
- **partial or total prohibition** of activities related to processing.

How the amount is calculated — the base, the aggravating and mitigating factors — is in the
**dosimetry regulation**, Resolução CD/ANPD nº 4/2023. Among the mitigating factors are having a
governance programme that works, cooperating, and acting promptly to reduce the damage.

## Reading the list as an engineer

Two observations, neither of them legal advice:

**The fine is not the worst item.** For a company that lives on its data, *blocking* or *eliminating*
the data, or suspending the database, ends the business faster than a fine of 2% does. And
*publicising* is, for a pharmacy, a headline about its customers' prescriptions.

**The mitigating factors are the lessons of this course.** A documented governance programme, a
record of processing, an incident register, roles that read only what they need, keys outside the
database: each is something the dosimetry regulation counts in the company's favour, and each is
something you can show with a query rather than a promise.
