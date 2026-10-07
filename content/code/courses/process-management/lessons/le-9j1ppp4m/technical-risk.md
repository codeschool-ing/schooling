---
title: Technical risk and the architect
version: 1
---

Most of this lesson applies to any project. The risks an architect is best placed to find and reduce are technical, and they deserve their own treatment, because they behave differently from schedule risks: they are often **binary** — the design works or it does not — and they are discovered late unless somebody goes looking.

## Risk-driven architecture

George Fairbanks's *Just Enough Software Architecture* (2010) proposes a simple rule for how much design effort a system deserves: **do as much architecture as the risks require, and no more**. A small internal tool with familiar technology needs little; a payment system handling other people's money across thirty clinics needs a great deal. The amount is set by naming the risks — *the booking calendar may not handle two receptionists booking the same slot at once* — and choosing design work that reduces each one.

That rule ties together ideas from earlier lessons. Boehm's spiral in lesson 1 ordered work by risk. RUP's elaboration in lesson 7 proved the riskiest decisions in running code before construction. XP's spike in lesson 4 bought knowledge with a short, time-boxed investigation. All three are risk responses: **mitigation by learning early**.

## Kinds of technical risk worth naming

- **Novelty**: a technology, a framework or a cloud service the team has not used in production.
- **Integration**: a system outside the team's control — a payment provider, a government service, a legacy database — whose behaviour is only partly documented.
- **Quality attributes near their limits**: a response time, an availability target or a data volume close to what the design can deliver.
- **Irreversibility**: decisions that are expensive to change later, which lesson 2 listed — the data store, service boundaries, identity.
- **Knowledge concentration**: a part of the system that one person understands, which is how risk B came to be on the Agenda team's register.

## Reducing them

The usual responses are cheap compared with the risks:

- **A spike or a prototype** answers a question about novelty or integration in days.
- **A walking skeleton** — the thinnest end-to-end version of the system, deployed — proves that the parts connect, in the way RUP's elaboration did.
- **A load test against a realistic scenario** turns a quality-attribute risk into a measurement.
- **An architecture review**, such as the SEI's ATAM, makes the trade-offs and sensitivity points of a design explicit, with the stakeholders present.
- **Pairing and documentation** reduce knowledge concentration.

## Translating for the register

Technical risks belong in the same register as the rest, written so that a non-technical sponsor can weigh them: cause, event and effect in terms of time, money or the service. "The ORM may generate N+1 queries" means nothing to a sponsor; "the booking screen may take over two seconds under Monday-morning load, breaching the service level, unless we spend two days on a load test and a fix in Sprint 1" is a decision somebody can make. The `architect-communication` course gives that translation its own lesson, its fourth.
