---
title: What became of RUP
version: 1
---

Few organisations say they use RUP today, and it is easy to conclude that it disappeared. It did not; it dispersed. Most of its ideas went into later methods and into the habits of people who learned their trade with it, and some of its weaknesses explain why agile methods are shaped the way they are.

## Why it fell out of favour

RUP was a **process framework**, not a process: a large library of roles, activities, artefacts and guidance from which each project was meant to select what it needed. Its authors said so clearly. In practice, many organisations adopted far more of it than they needed, because selecting is harder than adopting everything, and because every artefact looked like insurance. Teams produced dozens of documents per iteration and used few of them. The heaviness that people remember was usually a failure to tailor — the same failure the PMBOK seventh edition, in lesson 6, puts tailoring at its centre to avoid.

It was also tied to tools sold by the same company, and when the market moved to lighter, open methods, the commercial weight that had spread RUP worked against it.

## Where its ideas went

- **OpenUP**, from the Eclipse foundation, is a deliberately minimal version of the Unified Process, keeping the four phases and iterations and dropping most of the artefacts.
- **The Agile Unified Process**, by Scott Ambler, was a simplified RUP using agile practices.
- **Disciplined Agile Delivery**, by Scott Ambler and Mark Lines (2012), keeps RUP's phase idea in the form of an **inception**, a **construction** and a **transition**, wrapped around agile iterations. It became part of PMI's Disciplined Agile toolkit, which lesson 5 named.
- **SAFe's architectural runway** and **XP's spike** are both answers to the question elaboration answered: how to reduce the biggest technical risks before building on them.

## What an architect should keep

The idea worth keeping is elaboration's rule: **prove the architecture with running code that exercises the riskiest decisions, early**. It is the spiral model's ordering from lesson 1, made concrete. Lesson 11 turns it into a technique for risk, and it is the most direct answer to the cone of uncertainty: the cone narrows when decisions are made, and a working skeleton is a set of decisions that have been tested rather than assumed.
