---
title: Two stores, two ramps
version: 1
---

**A staged release gives a new version to a fraction of the people who would get it, and widens
the fraction as confidence grows.** Both stores offer one, and they differ in who controls the
steps. *Apple's half is read from App Store Connect's help on phased release, October 2026;
Google's from the Play Console Help as published in 2025. Neither console was opened.*

## Google Play: a staged rollout

When a release goes to production, you choose a **percentage** of users who get it, and raise it
when you choose: 1%, then 5%, then 20%, then 100%, on whatever days you like. You can **halt** the
rollout, which stops it reaching anybody new, and **resume** it later at the same or a higher
percentage. Users are picked at random by Google, and once picked, stay picked as the percentage
grows.

## The App Store: a phased release

Apple's **phased release for automatic updates** follows a fixed seven-day schedule:

| day | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|
| share of users with automatic updates | 1% | 2% | 5% | 10% | 20% | 50% | 100% |

You cannot choose the steps, but you can **pause** for up to 30 days in total, and **release to
everybody** at any point. Two details change what it protects you from:

- **It applies only to automatic updates.** Apple's help says it plainly: *apps and app updates in
  phased release can be manually downloaded from the App Store by anyone at any time.* The person
  who opens the store and taps Update gets the new version on day one.
- **New installs get the new version.** Phasing is about updates to people who already have the
  app; a first-time download is always the current version.

## The other platform

A React Native app has both ramps, one per store, and they run on different clocks: Google's moves
when you move it, Apple's moves every day unless paused. A team that wants the two halves of the
same release to reach the same share of people on the same day has to drive Google's by hand to
Apple's schedule.
