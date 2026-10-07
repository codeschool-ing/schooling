---
title: A risk is not yet a problem
version: 1
---

The word *risk* is used loosely for anything that worries people, and that looseness makes risk management harder than it needs to be. The PMBOK Guide's definition is precise and worth adopting: **a risk is an uncertain event or condition that, if it occurs, has a positive or negative effect on one or more of the project's objectives.**

Three parts of that sentence do the work.

## Uncertain

A risk **may or may not happen**. Something that has already happened, or is certain to, is not a risk; it is an **issue**, and it is handled by dealing with it now, not by estimating its probability. The payment provider *might* change its API next quarter: that is a risk. The payment provider *has* announced it will retire the current API in June: that is an issue, with a date, and it goes into the backlog as work.

The distinction matters because the two need different responses. A risk gets a probability, an owner and a plan for what to do if it happens; an issue gets a task and a deadline. A project whose risk register is full of issues is not managing risk; it is keeping a list of known problems it has not scheduled.

## Positive or negative

A risk can be good news. The Agenda team suspects that an existing open-source calendar library may already handle the clinics' recurring appointments, which would save several days. That uncertain event is an **opportunity**, and it deserves the same attention as a threat: somebody should find out, early, whether it is true. Many teams track only threats and miss opportunities that would have paid for several of them.

## Objectives

A risk is defined by its effect on what the project is trying to achieve — time, cost, scope, quality, the benefits it was set up for. "The database might be slow" is not yet a risk statement. "Response times on the booking screen might exceed two seconds under the Monday-morning load, which would breach the service level of lesson 8" is, because it says what would be affected and how.

## Writing a risk down

A useful form is **cause, event, effect**: *because* the billing integration is understood by one developer, *that developer may leave* during the project, *which would* delay the payment work by about four weeks. Each part points at a different response. The cause can be removed (spread the knowledge), the event can be made less likely (talk to the developer), and the effect can be reduced (document the integration). A risk written as a single noun — "staff turnover" — points at none of them.
