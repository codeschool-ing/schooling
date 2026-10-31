---
title: How a team chooses
version: 1
---

**The framework is rarely the deciding question.** What decides is the team, the code that already exists,
and what the app has to be best at.

| if… | the usual choice |
|---|---|
| the team writes React for the web, and the app shares logic and people with a website | React Native |
| the app's look is its own, heavily animated, identical everywhere, and the team will learn Dart | Flutter |
| two native apps already exist, and the duplicated part is the logic | Kotlin Multiplatform, one module at a time |
| the app lives on one platform's newest features, widgets, watch, car, the system's own look | native, on that platform |
| the team is two people and both platforms are needed next quarter | whichever of the first three they already know |

Three things that are true whichever route is chosen, and which this course spent most of its time on:

- **The native side does not go away.** Gradle, Xcode, signing, permissions, store review and a crash in
  Kotlin or Swift are part of every route. The planner met all of them.
- **The quality is in the habits.** Measuring before optimising, testing what a screen does with each
  answer, checking data at the door, asking for a permission at the moment it is needed: none of them is
  React Native's, and all of them transfer.
- **The decision can be revisited.** React Native and Kotlin Multiplatform can both be added to an existing
  native app, a screen or a module at a time, and so can a native screen to a React Native app. Few
  decisions here are permanent; the cost is in changing them often.
