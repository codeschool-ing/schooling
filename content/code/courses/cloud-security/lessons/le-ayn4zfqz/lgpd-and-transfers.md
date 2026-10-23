---
title: The LGPD and data that leaves the country
version: 1
---

**Under the LGPD, sending personal data to another country is allowed only on one of the grounds its
article 33 lists. A cloud makes that sending one setting away, so the question is no longer whether
the clinic exports data on purpose, but whether it can find every copy that left without anybody
deciding.** This section reads the law at the level an engineer needs; the legal advice belongs to
the clinic's lawyer and its data protection officer, the *encarregado* the law requires.

## Who is who

In the LGPD's vocabulary the clinic is the **controller** (*controlador*): it decides why and how the
patients' data is processed. AWS is an **operator** (*operador*): it processes the data on the
clinic's behalf, under contract. Lesson 2's line reappears here in legal form. AWS answers for running
its infrastructure as the contract says; the clinic answers for what it chose to put where.

## What article 33 allows

Article 33 opens with the rule — an international transfer is permitted *only* in the cases it lists
— and then lists them. The ones a company meets most often:

| ground | what it means in practice |
|---|---|
| a country with an **adequate** level of protection | a country the ANPD, the national data protection authority, has recognised as adequate (article 34 says how it judges) |
| **contractual guarantees** | standard contractual clauses, specific clauses, binding corporate rules, or seals and certifications, which the controller has to offer and be able to prove |
| **specific and highlighted consent** | the patient agreed to that transfer, told separately and clearly that it goes abroad |
| a **legal obligation**, a **contract** with the patient, or the exercise of rights | the transfer is needed for one of those, as article 7 already allows for processing |

The article lists other grounds too, for cooperation between authorities, protection of life and
public policy. None of them is a ground a clinic reaches for when it picks a backup region.

**The ANPD published its regulation of international transfers in August 2024**, with the text of the
standard contractual clauses and twelve months for existing contracts to adopt them. A contract with a
cloud provider is exactly the kind it addresses, which is why the provider's data processing terms
are a document the clinic's *encarregado* should have read before the first bucket was created.

## What makes it urgent in a cloud

On premises, data leaves the country when somebody ships a disk or opens a link to a foreign data
centre: an event with a purchase order behind it. In the cloud it leaves when somebody types a
different region:

- caio creates a backup bucket in `us-east-1` because a blog post said it was the cheapest region;
- a service the clinic wants exists only in some regions, and the console quietly switches to one of
  them;
- a disaster-recovery plan copies everything to a second region, and **AWS and Google Cloud each have
  a single region in Brazil**, both in São Paulo, so a second region means a second country. Azure
  has two in Brazil, Brazil South and Brazil Southeast. **Taken from the providers' region lists,
  not run.**

The last one is the hard case, because it is not a mistake. The `cloud` course's lesson 9 argued for
surviving the loss of a region; residency argues for staying in one country. The clinic resolves it
by deciding, not by drifting: spread across the Availability Zones of `sa-east-1` and accept the
smaller risk of losing the whole region, or replicate abroad on a recorded legal ground, with the
*encarregado* agreeing in writing.

**Either answer is defensible. What is not defensible is a copy in Virginia that nobody can explain.**
The next section finds those copies.
