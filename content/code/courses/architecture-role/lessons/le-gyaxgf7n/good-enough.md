---
title: Good enough for its purpose
version: 1
---

Two opposite slogans get repeated about quality. One says always build it properly; the other says
move fast and fix it later. Both treat quality as one dial for the whole system. **Quality is a fit
between a piece of work and what it is for**: how long the code will live, how often it will
change, and what happens when it is wrong. The right bar for the code that pays drivers is the
wrong bar for a script that runs once, and an architect's job is to say which is which.

## The bar differs by part

Renata wrote down the bar for six kinds of work at Carreto, and the table did more to end arguments
about "gold-plating" than any principle had.

| the work | how long it lives | what being wrong costs | the bar |
|---|---|---|---|
| the payout ledger | years, changing monthly | a driver paid twice, or not at all | reviewed design, tests on every money path, idempotent operations |
| CT-e issuance | years, changing with each layout | a truck that cannot leave, and possible fines | tests against the tax authority's validation, a run in its test environment before release |
| the quote engine | years, changing weekly | a quote below the ANTT floor, or a load lost to an overpriced one | tests on the floor rule and on every quote type |
| a monthly report for finance | months | a wrong number on a slide, which a person will probably notice | a second person checks the totals |
| a one-off data migration | one run | run it again | tried on a copy of production, then deleted |
| a kata prototype | one afternoon | nothing | none |

**The bar is set by consequence and lifetime, not by how important the team feels.** A one-off
migration can move a million rows and still deserve a light bar, because its risk is handled by
rehearsing it on a copy rather than by engineering the script for a long life it will never have.
The quote engine is unglamorous and deserves a high one, because a quote below the ANTT floor is a
breach of the law with Carreto's name on it.

Some of these bars belong in lesson 9's standards, written with their reasons: "every change to
Payments ships with tests on the money paths" is a standard with an owner and a reason. Others stay
as judgement, made by the team and reviewed as part of a design.

## Deliberate debt, written down

When a team chooses lower internal quality to gain time, it takes on technical debt. Martin Fowler's
technical debt quadrant, from 2009, sorts debt with two questions: was it taken on deliberately or
without noticing, and was it prudent or reckless? "We must ship now and deal with the consequences"
is deliberate and prudent, a loan taken knowingly with a plan to repay it. "We don't have time for
design" is deliberate and reckless. The `tech-strategy` course takes the quadrant apart in its
lesson 4 and puts a price on debt in its lesson 5, so this section stays narrow.

**The only debt an architect should agree to is deliberate and prudent, and deliberate means written
down.** A shortcut that nobody recorded turns, within a year, into debt nobody can explain: the
people who took it have moved on, the reason is lost, and what was a loan looks like a mess.
Written down, it has an owner, a reason and a date, which the third section shows in full.

## A date nobody can move

The case that tests all of this arrived in Renata's second quarter. From time to time the tax
authorities publish a new version of the CT-e layout, with new fields and changed validation rules,
together with a date after which documents in the old layout are rejected. After that date a CT-e
that Carreto issues in the old layout is refused, and a truck without an authorised CT-e cannot set
off.

Carreto learnt of the new layout with ten weeks to go. **The date was not negotiable, because it was
not Carreto's.** The team was barely more flexible. The CT-e code lives in the monolith, three
engineers on Payments know it, and adding people who do not know the tax rules ten weeks out would
slow the three down, which is Brooks's law from the previous section. Two corners of the triangle
were fixed, and the one left to move was scope.

## Finding the smallest scope that does the job

Renata and Bruno Farias went through the work item by item and asked one question of each: **what
happens on the day if this is not done?**

| item | if it is not done on the day | when |
|---|---|---|
| the new mandatory fields for road freight, about 97% of Carreto's CT-es | every one of those CT-es is rejected | by the date |
| the new validation rules | rejections, one truck at a time | by the date |
| multimodal and other rare cases, about 3% of CT-es | a back-office analyst issues them through a manual procedure for a few weeks | four weeks after |
| the back-office screen that corrects a CT-e after issue | corrections are made by an engineer, a few a week | a month after |
| restructuring the generator so that a layout is a separate, versioned mapping | nothing at all on the day | not needed for the date |

That last row is not part of the scope for the date, and it is where the options in the next section
differ. **Good enough was measured against one purpose, every common CT-e authorised on the day**,
and against that purpose the rows below the first two could wait. Doing that with the business in
the room matters: the 3% handled by hand was the grain cooperative's road-and-rail shipments, and
Helena agreed to call them herself before it happened.

Good enough is not a lower standard. The first two rows still had the full bar from the table above,
tests against the tax authority's validation included, because those are the rows where being wrong
stops trucks. What was cut was scope, never the quality of the scope that remained.
