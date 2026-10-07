---
title: Putting technical debt on the table
version: 1
---

**Technical debt enters a deadline negotiation in one of two ways: openly, as a priced item the other
side can see and agree to, or silently, as a shortcut nobody mentions and everybody pays for later.**
Only the first is a negotiation. The second is the quality lever moved in the dark.

`process-management` lesson 14 covers recording debt and paying it down as a project practice. Here
the question is narrower: what to say about it when somebody wants a date.

## Debt as interest, in their unit

Ward Cunningham, who coined the metaphor in 1992, meant it precisely: shipping code you know is not
quite right is like borrowing money, and every change made on top of it pays interest until the debt
is repaid. The metaphor works in a negotiation only if the interest is stated in a unit the other side
uses.

Henrique's team had a number for it. **Over the past year, eleven changes to checkout and logistics
had each needed extra days to work around the order state machine, about 25 engineer-days in total.**
That is the interest. The three weeks of untangling are the principal. Put that way, Renata did not
hear "engineering wants a refactor"; she heard "this costs us about a month a year, and fixing it once costs
three weeks that this feature needs anyway".

## Two kinds of debt in one conversation

- **Debt being repaid inside the feature.** The state machine work. It goes in the plan as its own
  line with its own number, so nobody can later ask why the feature took three weeks longer than "the
  feature".
- **Debt being taken on to hit the date.** If the team decides, together with Renata, that editing
  orders will be done crudely in December (cancel and reorder), that is a deliberate shortcut. It is
  named, written down with its expected interest, and scheduled.

Martin Fowler's *technical debt quadrant* separates debt taken on deliberately from debt taken on
by accident, and prudently from recklessly. **The goal of the conversation is that any debt taken on
is in the deliberate, prudent corner**: chosen, priced and planned, by people who knew what they were
doing.

## What not to say

| instead of | say |
|---|---|
| "We need time to refactor" | "This piece costs about 25 engineer-days a year in workarounds; fixing it is three weeks, once" |
| "The code is a mess" | "Every change here takes longer than the same change elsewhere; here are the last eleven" |
| "We'll clean it up later" | "We're taking this shortcut; it will cost about X until we fix it in January" |

Each left-hand sentence is true and loses, for the reason lesson 4 gave: an adjective cannot be
weighed against a feature.
