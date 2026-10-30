---
title: What ios-apps takes from this course
version: 1
---

`ios-apps` builds the study planner as an iPhone app, in twenty-two lessons, with SwiftUI and
SwiftData. It assumes this course and nothing else. **It does not teach the language again**, so
the table below is the honest list of what it will expect you to read without stopping.

| in `ios-apps` | it rests on | here |
|---|---|---|
| lesson 3, views as values, and a body that runs again | structs, value semantics and computed properties | lessons 5 and 6 |
| lesson 5, modifiers, where the order matters | methods that return a new value instead of changing one | lessons 3 and 5 |
| lesson 6, `@State` and `@Binding` | property wrappers and the `$` projection | lesson 16 |
| lessons 2 and 4, the app and its layout in stacks | result builders, and `some View` as an opaque type | lessons 16 and 9 |
| lesson 7, `@Observable` and the environment | classes, references and a macro seen from outside | lessons 5 and 16 |
| lesson 8, lists, `ForEach` and identity | `Identifiable`, `Hashable` and protocols with defaults | lessons 8 and 9 |
| lesson 12, `URLSession` with `async`/`await` | `async` functions, `Codable` and errors | lessons 12, 13 and 14 |
| lesson 13, SwiftData models | classes, macros and optionals | lessons 2, 5 and 16 |
| lesson 14, the repository between the network and the store | protocols as seams, generics | lessons 9 and 10 |
| every screen, every lesson | the `@MainActor` and `Sendable` checking | lesson 15 |
| lesson 20, unit tests and UI tests | XCTest and Swift Testing | lesson 18 |

## The planner's model is already written

The planner of `ios-apps` is the planner of this course: courses, study sessions with a date and a
duration, marked done, and a week's total against a goal. **The model layer you built here, the
structs, the enums, the `Codable` conformances and the tests, is the part that carries over as
code**, because none of it imports anything of Apple's. What `ios-apps` adds is the screens, the
storage on the device, and the work of getting an app onto a phone.

## If you do not have a Mac

The path through the `mobile` track has three options, and this is the one that needs Apple's
hardware next. Everything you learned here is still yours: Swift on a server, as section 04 built,
is a job in its own right, and the language is the same one an iOS developer writes. If the next
step has to be a Mac, it can be one rented by the hour, as section 06 said, for the weeks it takes.
