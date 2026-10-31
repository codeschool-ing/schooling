---
title: Kotlin Multiplatform
version: 1
---

**Kotlin Multiplatform, from JetBrains, starts from the other end.** Instead of one framework for the whole
app, it shares the part that is the same on both platforms, the models, the rules, the networking, the
storage, as a Kotlin module, and lets each platform keep its own interface.

The planner's rule for the week's total, shared, would be plain Kotlin in a `commonMain` folder:

```kotlin
data class Session(val id: String, val course: String, val date: String, val minutes: Int, val done: Boolean)

fun weekTotal(sessions: List<Session>, monday: String, nextMonday: String): Pair<Int, Int> {
    val week = sessions.filter { it.date >= monday && it.date < nextMonday }
    return week.filter { it.done }.sumOf { it.minutes } to week.sumOf { it.minutes }
}
```

*Written for comparison and not compiled.* Android calls it as ordinary Kotlin; iOS calls it from Swift, as
a framework Kotlin/Native produced. Where the platforms differ, `expect` declares something in common code
and `actual` supplies it per platform, which is lesson 6's `Platform.select` and `.ios.ts` files moved into
the type system.

**What it buys.** Each platform's interface is fully native, Compose on Android and SwiftUI on iOS, so it is
exactly as good as a native app's, because it is one. The shared part can be adopted a module at a time, in
an app that already exists, which no other route allows as gently.

**What it costs.** Two interfaces are still two interfaces: every screen is written twice, by people who
know Compose and SwiftUI. **Compose Multiplatform** removes that by sharing the screens too, drawn by its own
engine on iOS, which brings back Flutter's trade: one interface, not the platform's own.
