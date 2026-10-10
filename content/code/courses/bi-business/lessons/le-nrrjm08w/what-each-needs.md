---
title: What each one needs to see
version: 1
---

The usual mistake after drawing the map is to build one dashboard for everybody on it, with a filter
for each person to find their part. **Four people reading the same KPI do not need the same page.**
They ask different questions, at different speeds, about different amounts of detail, and a page
built for all four answers each of them slowly.

## Four questions, one definition

Take the delivery KPI from lesson 10 and the four people who read it most:

| reader | the question | detail | how often | form |
|---|---|---|---|---|
| Helena Prado | is the promise being kept? | one number for the company, and its trend | monthly | a line in the monthly report |
| Caio Barreto | where is it slipping? | by region and by carrier | weekly | a page for the Monday meeting |
| Marcos | which orders need me now? | order by order | several times a day | a list, sorted by urgency |
| Bruno Teixeira | how is my store doing? | his store against the others, by kind | monthly | his own page |

**The definition is the same in every row**: delivered by the promised day, out of deliveries plus
orders cancelled after the date. What changes is the level of detail (the granularity), how often it
is read, and the shape of the answer. That is what makes four views safe. Change the definition
between them and you are back at lesson 1's meeting with two totals.

@@fig:l13-views@@

## Reading the four

**Helena** needs one number and whether it is moving the right way, against the goal she agreed. A
breakdown by region would invite her to manage regions, which is Caio's job; if she wants it, it is
one click below, as a metric.

**Caio** needs the place where the number is slipping, so he can act this week: the region below the
action threshold, the carrier behind it. A company total tells him nothing he can do on Monday.

**Marcos** needs no rate at all. A rate is a summary of orders that are already finished, and what he
manages are the orders still on the road. His view is a list of today's orders at risk, with the time
it was last updated. That kind of screen is the subject of lesson 14.

**Bruno** needs his store compared fairly. Because his bonus depends on it, the comparison has to be
the one lesson 12 built: furniture against furniture and parcels against parcels, never the bare
total that punishes Contagem for selling sofas.

## The questions to ask about each reader

Four questions settle a reader's view before anything is drawn: **what decision do they make with
it, how often do they make it, how much detail does that decision need, and where are they when they
read it** (on a phone before a meeting, at a desk on Monday, on the warehouse floor). The answers are
the specification. How to present to each kind of audience, from a board to a technical team, is
`data-storytelling` lesson 4; how to lay out a dashboard page is `visualization` lesson 18.
