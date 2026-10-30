---
title: TestFlight
version: 1
---

**TestFlight is Apple's beta service, and it replaces the ad hoc builds of lesson 2 for almost
every team.** Testers install the TestFlight app, accept an invitation, and get each new build
automatically, with no device registration and no profile to expire on their phone. *Read from
Apple's TestFlight documentation, October 2026; not run.*

## Two kinds of tester

| | internal testers | external testers |
|---|---|---|
| who | people with a role in your App Store Connect team | anybody with an e-mail address or a public link |
| how many | up to 100 | up to 10,000 |
| review | none | the first build sent to a group goes to App Review; later builds may not need a full one |
| for | the team, every build | a beta audience, chosen builds |

**A public link** lets an external group grow without anybody typing addresses, and Apple lets you
limit how many people a link admits, so a link pasted into a forum does not fill all ten thousand
places in an afternoon.

## Builds that run out

**A TestFlight build can be tested for 90 days, and then it stops opening.** A tester who comes
back from holiday to a build that will not start has not found a bug; they have found the calendar.
Uploading at least one build a month to the groups that matter keeps everybody on something that
opens. Builds can also be expired early, which is how a team withdraws a broken beta.

## What TestFlight gives you back

Testers send feedback from the app itself: a screenshot with a note, or a crash report with
their comment attached. Both arrive in App Store Connect beside the build they came from. It is
the cheapest crash report you will ever get, because a person tells you what they were doing; lesson
12 deals with the crashes nobody comments on.

## For React Native and for Android

A React Native app's iOS build goes to TestFlight like any other; Expo's `eas submit` uploads it.
The Android build goes to Play's tracks. There is no cross-platform beta service in the stores,
so a React Native team runs two ladders side by side, one per store.
