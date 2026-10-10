---
title: Setting the limit
version: 1
---

There is no correct number to start with, and looking for one delays the only thing that produces it: trying a number and watching what happens. What there is, is a small set of choices about **what** to limit, and each choice has a known failure.

## Per person, per column, or per board

| limit on | example | what it catches | how it fails |
|---|---|---|---|
| **each person** | one item per developer | the multitasking that costs switching time | says nothing about queues between people; review can still pile up |
| **each column** | review holds at most two | a queue forming in front of one step | a team can satisfy every column and still have too much open overall |
| **the whole board** | at most six items between *started* and *merged* | everything at once, simply | gives no hint where the work is stuck |

The Billing team chose the first, plus a rule that made the second unnecessary: **review before starting anything**. A per-person limit alone would have left Bia's queue exactly where it was, because each developer, with one item and nothing else to do, would simply have waited. The review-first rule is what turned idle time into review time.

A limit on the whole board is sometimes called CONWIP, for *constant work in progress*, a name from manufacturing. It is the easiest to explain to people outside the team, and it pairs well with the ageing chart, which then says where the stuck work is.

## Where to start

- **Start near the number of people**, or a little below it, for a per-person or whole-board limit. A board limit of six for five developers leaves room for one item waiting for review.
- **Set queue columns low.** A column whose job is waiting, *ready for review* or *ready to deploy*, should hold one or two items, because anything above that is time somebody is waiting.
- **Change one thing at a time, and leave it for a few weeks.** Lesson 1 showed that a change takes most of a month to work through the board; judging a new limit after a week means judging the old system's leftovers.

## Two rules that keep a limit honest

**A blocked item counts.** The Billing team's limit had a door in it: a blocked item stopped counting, so its developer could start something new. Nothing about that is wrong in the moment. Over weeks it produced `BIL-189`, forty days old and invisible. If blocked items count, a blocked item becomes everybody's problem, because it is holding a place the team needs, and **that pressure to unblock it is the point of the limit**.

**Urgent work has its own lane, with a limit of one.** Every team gets work that cannot wait: a production incident, a security fix, a customer who cannot invoice. An *expedite* lane lets it jump the queue without pretending the limit does not exist. Its own limit of one stops "urgent" from becoming the normal way to get anything done; if two things are urgent at once, deciding which goes first is the tech lead's job, and it should be a visible decision.

## How to tell whether the limit is right

A limit **never reached** is not limiting anything; lower it. A limit **always full with old items behind it**, as an ageing chart shows, is pinned by something stuck, and the stuck thing matters more than the number. A limit **always full with young items** is the healthy case: the Billing team's September, where work in progress sat at its limit every day and nothing but `BIL-189` was old. That flat line in lesson 1's chart is what a working limit looks like.
