---
title: The forced update
version: 1
---

**A forced update is the app refusing to go on until the person updates it, and it is the one
measure that reaches every phone, eventually.** Lesson 8's halted rollout left 1011 phones on a
crashing 1.5.0; a minimum version of 1.5.1, read by the app at start-up, puts a screen in front of
each of them the next time they open it. It works only if 1.5.0 already contained the code that reads
the minimum. **The check has to ship before the version it will one day refuse.**

## The decision, in three outcomes

| the installed version is | what the app does |
|---|---|
| below the **minimum version** | a screen that cannot be dismissed: this version no longer works, update to continue |
| at least the minimum, below the **latest version** | a gentle prompt, once in a while, that can be dismissed |
| the latest | nothing |

Both numbers come from a server, not from the app, so they can change without a release. The next
section's script decides exactly this.

## The platforms' own tools

**Android** has the **In-App Updates** API in Google Play's libraries, with two flows, from Android's
documentation, October 2026:

- **immediate**: a full-screen flow that requires the person to update and restart before using the
  app; Google Play installs the update and restarts it;
- **flexible**: the update downloads in the background while the person keeps using the app, and is
  installed when they agree.

Google Play also lets a release carry an **update priority**, from 0 to 5, which the app reads to
choose between the two, and the API reports how many days the update has been available.

**iOS has no equivalent API.** The app compares its own version with a minimum from your server, and
sends the person to the App Store page with a link; the store does the rest. Apple's guidelines expect
the app to keep working while that is decided, so the forced screen is reserved for versions that are
truly broken or unsafe, not for nudging people towards a new feature.

**React Native** uses the store flows through libraries for each platform, and adds a door of its
own: an over-the-air update of the JavaScript bundle, such as Expo's, reaches people without the
store, within the limits of lesson 6. It cannot replace native code, so a minimum version is still
needed for the fixes that are native.

## When to use it

Rarely, and on purpose: a security fix, a crash that loses data, a server change the old version
cannot survive, lesson 20. **A forced update is the most annoying screen an app can show**, and an app
that shows it every month teaches people that updating is a chore, which is the opposite of the goal.
