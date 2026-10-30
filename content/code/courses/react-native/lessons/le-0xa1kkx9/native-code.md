---
title: Kotlin and Swift
version: 1
---

The Android side replaces the template's class. Save
`modules/week-start/android/src/main/java/org/example/weekstart/WeekStartModule.kt`:

```kotlin
// modules/week-start/android/src/main/java/org/example/weekstart/WeekStartModule.kt
// The first day of the week in the phone's own calendar, for JavaScript.
package org.example.weekstart

import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import java.util.Calendar
import java.util.Locale

// The rule, with nothing of React Native in it, so a plain JVM test can run it.
// Calendar counts SUNDAY = 1 to SATURDAY = 7; JavaScript's Date.getDay() counts Sunday = 0.
fun firstWeekday(locale: Locale): Int = Calendar.getInstance(locale).firstDayOfWeek - 1

class WeekStartModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("WeekStart")

    Function("firstWeekday") {
      firstWeekday(Locale.getDefault())
    }
  }
}
```

- **`firstWeekday(locale)` is the rule, and it is a plain Kotlin function.** It knows nothing of React
  Native, so the JVM on your computer can run it in a test, which the section on JVM tests does.
- **`Calendar.getInstance(locale).firstDayOfWeek`** is Java's calendar, which Android implements with the
  same calendar data the platform uses everywhere else. It counts Sunday as 1, so the function subtracts
  one to count as JavaScript's `Date.getDay()` does.
- **`ModuleDefinition` describes what JavaScript sees.** `Name("WeekStart")` is the name JavaScript asks
  for; `Function("firstWeekday")` is a synchronous function, called through JSI on the JavaScript thread,
  whose return value is converted to a JavaScript number.

The iOS side does the same in Swift. Save `modules/week-start/ios/WeekStartModule.swift`:

```swift
// modules/week-start/ios/WeekStartModule.swift: the first day of the week in the phone's own calendar, for JavaScript.
import ExpoModulesCore

public class WeekStartModule: Module {
  public func definition() -> ModuleDefinition {
    Name("WeekStart")

    // Calendar counts Sunday = 1; JavaScript's Date.getDay() counts Sunday = 0.
    Function("firstWeekday") { () -> Int in
      return Calendar.current.firstWeekday - 1
    }
  }
}
```

`Calendar.current` is the person's own calendar, with whatever first weekday they chose in the phone's
settings, and it also counts Sunday as 1. **The two definitions have the same shape on purpose**: a `Name`,
a `Function` with the same name, a value of the same meaning. Nothing checks that they agree but you, and a
test on each platform. *The Swift file was not compiled for this course: building for iOS needs Xcode, which
runs only on a Mac. Lesson 20 is about building for iOS without one.*

A function that takes time, a file read or a network call, would be an `AsyncFunction`, which JavaScript
receives as a promise; `Events` sends values to JavaScript as they happen; `View` exposes a native view as
a component. The planner's question needs none of them.
