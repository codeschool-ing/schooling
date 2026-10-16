---
title: Enterprise architecture: the whole portfolio
version: 1
---

Enterprise architecture has a reputation, and the reputation is binders. A department that
produces frameworks, reference models and approval boards, whose documents nobody in a delivery
team has read. That version exists, and lesson 17 names it as the ivory tower. **The work
underneath it is simpler and necessary: looking at everything the company runs, against what the
company needs to be able to do, over a horizon of years.** At a bank with five thousand engineers
that takes a department. At Carreto it takes a page, a spreadsheet and a few days a quarter.

## What it decides

Application architecture asks how one system is built, and solution architecture asks how several
systems deliver one outcome. **Enterprise architecture asks which systems the company should have
at all**, and what they should share. Its decisions look like this:

- which business capabilities the company has, and which system is the one that provides each;
- which systems to invest in, which to keep as they are, and which to retire;
- what every team shares rather than chooses alone: the cloud provider, the observability stack,
  the message broker, how services authenticate each other;
- which capabilities to build, which to buy, and which to leave to a partner;
- what the technology landscape should look like in three years, and what has to happen first.

The horizon is the giveaway. **A decision at this level is judged three to five years out**, by
whether the company can still change direction cheaply when the strategy changes. That is a
different question from whether one feature ships this quarter, and it needs a different reader.

## The capability map

The central artefact is a **capability map**: a list of what the business does, written in
business words and not in system names, with each capability mapped to the systems that provide
it today. "Quote a freight" is a capability; "the Pricing service" is a system that provides it.
Keeping the two apart is the point, because a capability is stable for years while the systems
under it change.

Renata built Carreto's first map in her second month, in a spreadsheet, in two afternoons of
asking tech leads and one of checking their answers against the code. A slice of it:

| capability | systems that provide it today | owner |
|---|---|---|
| post a load | Shipper app, the monolith's load module | Shipper |
| quote a freight | Pricing service | Pricing |
| offer a load to drivers | Matching service | Matching |
| issue the CT-e | the monolith's fiscal module; a script inside Payments | nobody single |
| notify a driver | the Driver app's push service; SMS from the monolith; Matching's own notifier | three teams |
| prove a delivery | Tracking service | Tracking |
| pay a driver | Payments | Payments |

Two rows stopped the meeting where she showed it. **The CT-e was issued from two places**: the
monolith's fiscal module for most loads, and a script inside Payments for a kind of load the
monolith had never supported, written in a hurry two years earlier. When the tax authorities change
the layout of the CT-e, both have to change, and only one team knew the second existed.
**Notifying a driver had three implementations**, each with its own rules for when a driver may be
messaged at night, so a driver could be woken at two in the morning by one of them and protected
from it by the other two.

Nothing about those rows was secret. Each team knew its own part. **The map was the first place
anyone could see them side by side**, which is most of what this level is for.

## The portfolio and its verdicts

The second artefact is the **application portfolio**: one row per system, with its owner, what it
costs to run, how healthy it is, and a verdict. A common set of verdicts is four words: invest
(grow it), keep (maintain it, change it only when needed), migrate (move what it does somewhere
else) and retire (switch it off). Carreto's portfolio lists the monolith, the services carved out
of it, the scripts and the outside products, and writing it down was the first time anyone had
counted them all. Lesson 12 counts the services and asks how many a company of fifty engineers
needs; here the point is only that the count did not exist before.

The verdicts are where enterprise architecture meets money. Sílvio Matos, the finance director,
had never seen engineering spending laid out by system, and the portfolio let him ask the
question he cared about: which of these are we paying to keep alive without a reason?
`tech-strategy` lesson 9 prices that properly, as total cost of ownership; this lesson only needs
the list to exist.

## Shared standards, and who owns them

**The third output is the small set of things every team shares.** At Carreto, Paula Reis's
Platform team runs most of them: the cloud account, the CI pipelines, logging and metrics, the
message broker. Enterprise architecture decides that they are shared, and Platform makes sharing
them the easiest path; the standard sticks because it saves each team work, not because a board
approved it. Lesson 9 is about writing such standards and enforcing them, and lesson 10 names the
team shapes, a platform team among them.

A standard at this level earns its place by preventing a cost that only shows up across teams. Seven
teams choosing seven logging formats is fine for each team and expensive the first night an
incident crosses three services and nobody can follow a request through them. One format, chosen
once, is cheap for everybody.

## The frameworks, named

Large organisations often run enterprise architecture through a framework. The best known is
**TOGAF**, The Open Group Architecture Framework, which describes a cycle for developing an
enterprise architecture (its Architecture Development Method) and the layers it covers: business,
data, application and technology. Zachman's framework is older and is a classification of the
documents an enterprise might keep, rather than a method. `architecture-modeling` teaches both, in
lessons 8 and 10; this course does not.

What matters here is the relationship between the frameworks and the work. **A framework is a
checklist for a large organisation that needs everybody to describe things the same way**, and at
Carreto's size following one in full would produce documents faster than anyone could read them.
Renata borrows the vocabulary (capability, portfolio, business and technology layers) and none of
the ceremony.

## Three levels, one person

In a company of fifty engineers, the three levels are rarely three people. **Renata works at all
three, in different proportions, and the skill is knowing which one a question belongs to.** Her
first quarter came out roughly like this: about a day a week on application questions, almost all
of them reviews the teams asked for; about three days on solution work, the 24-hour payout above
all; and the rest on the map, the portfolio and the shared standards.

The proportions are not a rule and they will move. As Carreto grows, the solution work will need
more people, and one day the company may hire an architect for each group of teams and keep one
person on the portfolio. What stays fixed is the difference between the questions:

| | application | solution | enterprise |
|---|---|---|---|
| asks | how is this system built? | how do these systems deliver this outcome? | which systems should we have at all? |
| horizon | months to two years | a programme, then its life | three to five years |
| reads it | the team and its callers | several teams, product, finance, partners | executives, finance, every tech lead |
| writes | component view, contracts, ADRs in the repo | context and container views, budgets, cross-team ADRs | capability map, portfolio, shared standards |

**A question answered at the wrong level is answered badly.** Treating the duplicated CT-e
issuing as a Payments bug would have fixed one script and left the next one to appear; treating
the Matching cache from the first section as a company-wide caching policy would have spent a
month on a standard to solve a problem one contract field solved. The table is less a taxonomy
than a set of questions to ask before starting work.
