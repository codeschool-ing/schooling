---
title: Integrating continuously
version: 1
---

**Continuous integration** means that everybody on the team merges their work into the shared main line at least once a day, and that every merge is built and tested automatically. Grady Booch used the phrase in 1991; XP turned it into a daily practice; Martin Fowler's article on it, first published in 2000, is still the usual reference.

## The problem it solves

Two developers each spend two weeks on a branch. Each branch works. On the day they merge, the branches disagree about a function both changed, the merge takes a day, and the combined code fails tests that passed on both sides. The cost of integrating grows with the time since the last integration, and it grows faster than linearly, because every day adds changes that can conflict with every other day's.

The cure is to make the gap small. **Integrate every day, or several times a day**, and each merge is small enough to understand. A conflict that would have taken a day to untangle after two weeks takes ten minutes after two hours.

## What it requires

Continuous integration is a practice, not a tool. A server that builds every branch is a CI tool; a team that keeps branches open for weeks is not doing continuous integration, whatever the tool's name is. Four things have to be true:

- **One main line** that everybody merges into at least daily. Short-lived branches of a day or less are compatible with it; long-lived feature branches are not.
- **An automated build and test** that runs on every merge, which is what the test-first practice of the previous section supplies.
- **A fast build.** XP's second edition names it the *ten-minute build*: if the build and tests take an hour, people stop waiting for them, and broken code piles up behind a failure nobody noticed.
- **Fixing a broken build comes first.** When the main line fails, the person who broke it fixes it or reverts the change, before anybody does anything else. A main line that stays red for a day stops being a main line.

## Unfinished work on the main line

The usual objection is that a feature takes two weeks, so it cannot be merged daily. The answer is to merge it **unfinished but hidden**: behind a feature flag that keeps it off for users, or built from the inside out so that nothing calls the new code until it is ready. That keeps integration continuous without exposing half a feature. It also separates two decisions that long branches tie together: when code is merged, which the team decides, and when a feature is released, which the product owner decides.

## Why it belongs in a management course

Continuous integration is the practice behind two of the delivery measures in lesson 13: how often a team deploys and how long a change takes to reach production. A team that integrates once a fortnight cannot deploy daily, whatever process it uses. When a stakeholder asks why releases are slow and risky, the first question to ask is how long the team's branches live.
