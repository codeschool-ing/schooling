---
title: Choosing the suite
version: 1
---

The tempting definition of regression testing is "run every test again", and it has a name,
**retest all**. It is the safest choice and it is rarely affordable: a product with a few hundred
cases and a release every week cannot spend three days of each week rerunning all of them by hand.
So a regression suite is chosen, release by release, and **the choice is the skill**: a suite that
runs everything finishes after the release has gone, and one that runs whatever is quickest
misses the defect that mattered.

## Three ways to cut it down

**By risk.** Lesson 1 ranked what could go wrong in boxoffice by likelihood and impact, and that
ranking already says what deserves a rerun first. From the top: A, a wrong price; B, a show sold beyond its
seats; C, a refund that should not happen; D, a confirmation e-mail that never arrives; E, a shows
table that is hard to read on a phone. When time runs short, the cases at the bottom are the ones
left out.

**By change.** What did this release touch, and what depends on what it touched? This is the
**impact analysis** of the change, and its sources are the release notes, a conversation with the
developer, and, where the tester can read it, the change itself. A part nobody touched and nothing
depends on can skip a release; a part that was rewritten cannot.

**By history.** Areas that broke before break again: code that is complicated stays complicated,
and so do the reasons people get it wrong. Every defect found is evidence about likelihood, as
lesson 1 put it, and the parts with the longest list of past defects earn a place in every run.

None of the three is enough alone. Risk alone reruns the same cases whatever changed; change alone
misses the regression that comes from the environment; history alone protects yesterday's
problems. In practice they are combined: **the change decides what is likely to have broken, and
the risk decides how much each part is worth checking**.

## The suite for 1.1

Rui's notes name two changes: `discount` was rewritten, and the quantity check now accepts six.
Read against lesson 1's ranking, that gives this suite:

| area | changed in 1.1? | decision | cases |
|---|---|---|---|
| A, price | yes: `discount` rewritten | every rule of lesson 5's discount table | 8 |
| booking quantity, R4 | yes: the limit moved | lesson 4's boundaries, and the input that is not a number | 5 |
| B, seats | no, but an order can now take six | seats taken by an order, given back by a cancel | 2 |
| C, order states | no | the main path of R6, and the refund of a used order | 3 |
| D, confirmation e-mail | no | one sign-up, and its e-mail in the outbox | 2 |
| E, phone layout | no | left out this release: no page changed | 0 |

Twenty checks, about an hour by hand. Three decisions in it deserve a sentence each.

**The price area gets all eight rules**, not the two lesson 9 already checked. Three discounts can
each apply or not, which makes eight combinations, and every one of them goes through the
rewritten function. Lesson 5 built the table; the regression suite reuses it rather than inventing a
smaller one, because the table is exactly the list of things the old function handled.

**Two cases in the suite are expected to fail**: the input that is not a number, and the refund of
a used order, which are the two known defects in Rui's notes. They stay in the suite because the
day they pass is the day somebody fixed them, and the day one of them fails differently is worth
knowing too. Their expected result for this run is "fails as reported", and the run records it as
such.

**E is out, and the reason is written down.** Nothing in 1.1 changed a page's layout, and the
phone defect lesson 7 found is still open and unchanged. If 1.1 had touched the page template, the
same decision would go the other way. A row with zero cases and a reason is a decision somebody
can disagree with; a missing row is a gap, as lesson 1 said of scope.

## The order of the run

The suite runs in the order of the ranking, so that if the hour is cut to twenty minutes, what is
left untested is what matters least: the eight price rules first, then quantity, then seats,
states and e-mail. One practical exception goes first of all: the second account. The
discount table needs a customer who is not a member, and the only account boxoffice starts with is
Bia Souza, who is. So the run begins by creating one, which is also the sign-up check of row D,
done early because everything after it depends on it.

Every case in the table already exists. Lessons 4 and 5 wrote them for 1.0, and lesson 9 added the
retests. **A regression suite is mostly cases you have already written, chosen again**, and the
next section runs this one on 1.1.
