---
title: Recording debt where it can be seen
version: 1
---

Technical debt that lives only in developers' heads has three problems: it is invisible to the people who decide priorities, it is forgotten when the people who knew it leave, and it cannot be compared, because nobody has written down what it costs. Recording it is the step that turns complaints into management.

## A debt register

The simplest form is a list, kept beside the product backlog or inside it, with one entry per debt item:

| field | example |
|---|---|
| what | the end-to-end test suite fails at random about once in every five runs |
| where | the booking and payment tests; the shared test database |
| interest | each developer loses about half an hour a day to re-runs: about 25 hours a Sprint for the team |
| principal | about 60 hours: isolate the test data and replace three time-dependent waits |
| how it arose | prudent, inadvertent: the suite grew faster than its design |
| owner | a named person who keeps the estimate current |
| status | open, last reviewed at the Sprint 14 retrospective |

**The interest field is the one that matters.** Without it, the register is a list of grievances; with it, each item becomes something that can be weighed against a feature, as lesson 12 did with WSJF.

## In the backlog, not beside it

A register kept in a separate document is easy to stop reading. Many teams put debt items **in the product backlog**, tagged so they can be found, where the Product Owner sees them every time the backlog is ordered. The item's description carries the interest and principal, written in the terms lesson 12 asked for: hours lost, risk carried, dates that matter.

## Architecture decision records

Some debt is taken on deliberately, as a decision: "we will keep all clinics' data in one database for now, and split it when we pass fifty clinics". The place for that is an **architecture decision record**, a short document with the context, the decision, the alternatives and the consequences, numbered and kept with the code. An ADR written at the time records the **trigger for repayment** — fifty clinics — so that the debt is paid when it comes due rather than when somebody remembers.

## Tools that estimate debt

Static analysis tools report a figure for technical debt, usually in days of remediation, computed from rule violations in the code. The figure is useful as a trend within one codebase, and misleading as an absolute: it counts the principal of everything the rules can detect, with no idea of the interest. A module with a hundred violations that nobody touches outranks, in the tool's eyes, a flaky test suite that costs the team twenty-five hours a Sprint and contains no violation at all.
