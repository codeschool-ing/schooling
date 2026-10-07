---
title: What is not technical debt
version: 1
---

A metaphor that covers everything explains nothing. Teams that call every complaint about their code "technical debt" end up with a debt list so long that nobody takes it seriously, and the items that really cost interest get lost among the rest. Drawing the boundary is part of managing it.

## Not a defect

A **defect** is the system doing something it should not: a booking saved for the wrong day, a reminder sent twice. It is a failure against the requirements, it goes into the backlog as a bug, and it is fixed because it is wrong. Technical debt is code that **works** but is expensive to change. The two overlap — debt makes defects more likely — but a list of bugs is not a debt register.

## Not a missing feature

A feature nobody has built yet is **scope**, not debt. "We have no reporting module" is a product decision about what to build next, and it belongs in the prioritisation of lesson 12 as a feature.

## Not a preference

"I would have used a different framework" is an opinion about a design that works and is not costing extra time. A design that a newer developer finds unfamiliar is not debt unless the unfamiliarity has a recurring cost — slower changes, more mistakes — that can be pointed at. **If you cannot name the interest, it is not yet debt**; it may be a reasonable choice somebody else would not have made.

## Not everything old

Old code is not debt because it is old. A stable module that has not needed a change in three years, written in a style the team no longer uses, costs nothing while it is left alone. It becomes debt the day a change has to be made to it and the change takes three times as long as it should.

## What is

Technical debt is **a property of the code or the system that makes future changes more expensive than they need to be**, with a recurring cost that can be described. Typical examples, all of which the Agenda team's register contains in some form:

- a test suite that fails at random and has to be re-run, wasting time on every change;
- a deployment that needs three hours of manual steps;
- a module that only one person understands, so every change to it waits for them;
- a database version leaving support, after which security flaws will not be fixed;
- a duplicated piece of business logic, so every rule change has to be made in two places and is sometimes made in one.
