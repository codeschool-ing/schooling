---
title: Pricing the exit before you enter
version: 1
---

The exit is the line most often left blank, and the reason given is always the same: we are not
planning to leave. **That reason confuses a plan with a price.** Nobody plans to leave a vendor on
the day they sign. Companies leave anyway — the vendor raises its price, is bought, falls behind,
or the company's own needs change — and the cost of leaving was set long before, by decisions
made while integrating.

## What Coreto's exit is made of

Leaving the hosted observability service would cost Coreto **R$ 49,650**, in two parts:

| part | how it was estimated | cost |
|---|---|---|
| moving dashboards, alerts and agents to whatever replaces it | 280 hours at R$ 150 | R$ 42,000 |
| running both while the move happens | one month of licence | R$ 7,650 |
| | | R$ 49,650 |

The 280 hours are a little less than the 320 of the original integration, because the second move
starts from a team that has done one, and from an inventory of dashboards that the first move
produced. Coreto counts the exit in full in its three-year TCO, as if it would leave at the end of
year 3. That is the cautious reading. Lesson 10 asks how likely leaving actually is and weighs the
cost by it; here the point is narrower, and comes first: **you cannot weigh a cost you never
priced.**

## Why at entry, and not when leaving

Three reasons, and each one is lost the day the contract is signed.

**Leverage is at the start.** Before signing, Coreto is a customer the vendor wants. It can ask for
data export in an open format, a notice period it can live with, and the right to keep its data
for a while after the contract ends. A vendor concedes clauses like these to win a deal, and
declines to add them once the deal is won. The exit's price is partly written in the contract, and the contract is
written once.

**The integration decides the exit.** Every dashboard built with the vendor's proprietary query
language, and every service instrumented with the vendor's own library, adds to what leaving will
cost. Instrumenting the services with a vendor-neutral library, and keeping dashboards and alert
rules as files in a repository rather than only in the vendor's interface, costs a little more
during integration and makes the 280 hours smaller. That trade can be made only during
integration.

**A price you wrote down can be watched.** An exit estimated at R$ 49,650 in year 1 can be
re-estimated each year. If it has grown because the teams built dozens more dashboards in the
vendor's own language, somebody can see that and decide whether it matters. An exit nobody priced
grows unseen, and is discovered on the day the company most needs it to be small.

## The checklist

An exit estimate does not need to be precise. It needs every part to be named, because the part
nobody names is the one that is missing:

| part of the exit | the question to ask before signing |
|---|---|
| the data | Can we export all of it, in a format another tool reads, and how long does it take? |
| the integration | How much of our code and configuration speaks the vendor's own language? |
| parallel running | How long will we pay for both, and what does a month of both cost? |
| the contract | What notice do we owe, and what happens to our data when the contract ends? |
| the people | Who has to learn the replacement, and how many hours is that? |

## The exit as a line in every proposal

The exit costs R$ 49,650 out of the hosted option's R$ 452,250, and including it does not change
Coreto's answer: hosting is cheaper with the exit counted in full. That is the common case, and it
is the reason to include it anyway. **An exit line that does not change the decision costs one row
to write.** An exit line left out is a claim, made silently, that the company will never leave
— and the one decision where that claim turns out false is the one where the missing row
costs the most.

Davi added one sentence to the observability recommendation:

> **Exit:** R$ 49,650, included above. Before signing we ask for export of all data in an open
> format and a window to retrieve it after the contract ends; services are instrumented with
> a vendor-neutral library and dashboards are kept as files in our repository.

That sentence is short because the work was done before it. Lesson 10 takes the next step: it puts
a probability beside costs like this one, so that a lock-in can be weighed against what it would
cost to avoid.
