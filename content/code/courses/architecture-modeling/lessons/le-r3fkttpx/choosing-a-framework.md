---
title: Choosing a framework, or choosing not to
version: 1
---

**A framework is worth adopting when it solves a problem the organisation actually has, and the
problems are few and recognisable.** The question is not *which framework is best?* but *what is
going wrong that a shared method or vocabulary would fix?*

## Problems, and what fixes them

| the problem | a symptom | what helps |
| --- | --- | --- |
| **changes that cross teams keep missing pieces** | a programme ships and the cash refunds have nowhere to go | a method with baseline, target and gap: TOGAF's phases B to D |
| **nobody can tell why a system was bought** | the product choices have no reasons above them | levels from reason to product: IAF's grid, or lesson 6's traceability |
| **every team draws differently** | three container diagrams, three notations | a notation and a *how we draw* page: C4 for systems, ArchiMate for the enterprise |
| **many suppliers must describe one system** | the integrator cannot combine the descriptions | a contractual framework: DoDAF, NAF |
| **documents exist and nobody reads them** | a wiki of 200 pages, last edited two years ago | fewer documents, owned and dated: lesson 11 |

None of these problems is *we do not have a framework*. If a company cannot name its problem, a
framework will give it a lot of documents and the same problem.

## Carcará's answer

Carcará uses **C4 for every system, ArchiMate for one enterprise view kept by Tainá, a tailored subset
of TOGAF for changes that cross several teams, and IAF's four levels as a habit of mind** when
writing the information systems part of a programme. It is written down, in one page, in the
architecture repository, as the decision of the Preliminary phase in lesson 8. A new architect can
read in five minutes what is used, what is not, and why.

## When a client or employer requires one

Sometimes the choice is not yours: a public tender requires TOGAF deliverables, or a defence contract
requires NAF views. Then the skill is **to produce what is required while keeping the decisions where
they belong**, in the decision records, the scenarios and the models that the team actually uses,
and to map them into the required format rather than maintaining two descriptions that will drift
apart. Lesson 12 shows one way: a single model, rendered into several views.
