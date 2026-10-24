---
title: Choosing between them, for a web team
version: 1
---

**For a team that already has a web app and web developers, the order of the tools is mostly the order of
how much they reuse**, and each step down that order is a step up in cost that has to buy something.

| question | points to |
|---|---|
| the web app works, and the phone adds a few features | Capacitor, and Ionic if the screens should look like a phone's |
| the core is lists, gestures and the platform's own feel | React Native with Expo |
| the core is platform interfaces, reached from TypeScript | NativeScript, or React Native with native modules |
| one look on every platform, pixel for pixel, and a team ready to learn Dart | Flutter |
| everything new on the day it ships, and two native teams | Swift and Kotlin |

**What the planner showed in this lesson is the reuse, measured.** Capacitor took it whole. React Native
took `planner.ts` byte for byte. Flutter took nothing: the rules were written again, and two copies of
the same rules are two places for a bug, which is a cost that grows every time the rules change. The week
came out as 75 and 105 of 125 every time, which is what tests are for when the same logic lives in two
languages.

**The decision is also about people.** A tool the team can maintain beats a better tool nobody on the team
knows. Lesson 16 asks you to choose one for your own app, and the reasons you write down there matter
more than which one you choose.
