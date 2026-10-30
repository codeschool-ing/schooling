---
title: Grouping, and the numbers the stores watch
version: 1
---

**A thousand crash reports are rarely a thousand bugs; they are usually three bugs, each reported
hundreds of times.** A crash reporter's most useful work is **grouping**: deciding which reports are
the same problem, so the team sees a short list of issues with counts, not a stream of reports.

## How reports are grouped

Mostly by the **stack**: the type of the error and the top frames of the code that was running,
with the parts that vary from one occurrence to the next, such as addresses, removed. Two reports
with the same exception thrown from the same function in the same file are one issue. That is why
symbols matter twice: an unsymbolicated stack cannot be grouped well, because the same bug looks
different in two builds whose names were shortened differently.

Grouping is a guess and sometimes wrong. One bug can split into several issues when it crashes in
different places; two bugs can merge when they crash in the same generic function, such as a
network library's error handler. Every reporter lets a person merge and split issues by hand.

## The two rates

| | what it counts | what it says |
|---|---|---|
| **crash-free sessions** | the share of app sessions that ended without a crash | how often the app crashes while in use |
| **crash-free users** | the share of people who did not see a crash in the period | how many people the crashes reach |

Lesson 8's rule used crash-free users, because a release decision is about how many people are
hurt. A crash that hits one person forty times barely moves crash-free users and drags crash-free
sessions down: the two numbers disagree exactly when a crash is concentrated on a few people.

## The thresholds Google Play watches

Google Play's **Android vitals** compute a **user-perceived crash rate** per app and per phone model,
and treat an app above the threshold as behaving badly, which affects how visible it is in the store.
The thresholds, from Android's developer documentation in October 2026:

| | overall, across devices | on one phone model |
|---|---|---|
| user-perceived crash rate | 1.09% | 8% |
| user-perceived ANR rate, lesson 14 | 0.47% | 8% |

**The per-model threshold is the one that catches a team out**: an app fine on average can be above
8% on one popular phone, and Play may show a warning to people who have that model. Apple publishes
no equivalent number; App Store Connect shows crash counts per version and device, and the
**Xcode Organizer** shows the crash logs of people who share diagnostics.

## What to do with the list

Sort the issues by **people affected**, not by count. Read the newest release first. Fix the issue
whose count rose with the release, because that one is yours, before the one that has been there
for a year. And add a breadcrumb wherever a report left you guessing what the person was doing; the
next report will say.
