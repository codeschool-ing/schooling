---
title: The same planner, three ways
version: 1
---

**This is one of three courses at the same fork of the `mobile` track, and all three build the same
study planner**: the same four screens, the same courses and sessions, the same week's total, offline
first and synced to a server. `android-apps` builds it with Kotlin and Jetpack Compose and
`react-native` with JavaScript and React Native. Each is declared at 90 hours in 22 lessons, as this
one is. This section compares them from their design sheets and their lists of topics, as they
stood on 30 October 2026. None of the other two was run for this course.

## Piece by piece

| the planner's piece | `ios-apps` | `android-apps` | `react-native` |
|---|---|---|---|
| drawing a screen | SwiftUI views, lessons 2 to 5 | composables and layout, lessons 3 and 6 | core components and Flexbox, lessons 4 and 5 |
| state that redraws | `@State`, `@Observable`, lessons 6 and 7 | `remember`, a ViewModel, lessons 4 and 10 | hooks and a store, lesson 9 |
| the list of sessions | `List` and identity, lesson 8 | `LazyColumn` and keys, lesson 8 | `FlatList` and keys, lesson 7 |
| moving between screens | `NavigationStack`, lesson 9 | Navigation Compose, lesson 9 | React Navigation, lesson 8 |
| the server | `URLSession`, lesson 12 | Retrofit and OkHttp, lessons 13 and 14 | fetching with TanStack Query, lesson 10 |
| the store on the phone | SwiftData, lesson 13 | Room, lesson 15 | SQLite and others, lesson 14 |
| work after the app closes | background tasks, lesson 16 | WorkManager, lesson 18 | location in the background, lesson 15 |
| reminders | notifications, lesson 17 | notifications, lesson 19 | push notifications, lesson 16 |
| asking for access | privacy strings, lesson 18 | runtime permissions, lesson 20 | permissions, lesson 13 |
| tests | Swift Testing and UI tests, lesson 20 | unit, Compose UI and screenshot tests, lesson 21 | debugging and performance, lessons 18 and 19 |
| signing and the store | lessons 21 and 22 | lesson 22 | EAS Build and updates, lessons 20 and 21 |

**The concepts line up; the vocabulary does not.** A key in a `LazyColumn` and an `id` in a SwiftUI
`List` answer the same question, which row is which, and a ViewModel's state and an `@Observable`
model answer the same one too. Somebody who has built one of the three can read the other two's
code by asking which row of this table they are looking at.

## Where the three differ

- **What can be practised without special hardware.** The `android-apps` sheet calls its runtime
  "heavy, and buildable", since the emulator runs on Linux. The `react-native` sheet names "Node, Metro
  and a simulator or device", and its lesson 20 builds an iOS app without a Mac in the room. This
  course's sheet says "no path from a browser at any price", and lesson 1 said which half you could
  practise. That difference is real and it is not in the hours.
- **One platform or two.** `android-apps` and `ios-apps` each reach one platform with its own tools;
  `react-native` reaches both from one codebase, and its last lesson weighs the other multiplatform
  routes.
- **The store at the end.** Both stores review what is published, and `android-apps` lesson 22 and
  `mobile-delivery` lesson 6 cover Google Play's side. Apple's is the one this lesson read: people at
  Apple, against a public document, before every version, section 06.

**What carries over whichever you chose** is the planner's shape: the rules in code that does not
know about screens, the repository between the network and the store, identity that is an `id` and
never a position, a permission asked at the moment of use. The courses after this fork, starting with
`mobile-offline`, assume that shape and none of the three toolkits.
