---
title: internal is visible inside one module
version: 1
---

Lesson 7's table gave `internal` one line and a promise: **visible everywhere in the same module, and
nowhere else**. With one module it behaved like `public`. With two it draws a line, and
`Week.percent()` sits behind it: `summary()` uses it, a test in `core` may check it, and `app` may not
call it.

A test inside `core` can:

```kotlin
// core/src/test/kotlin/WeekTest.kt
package studyplan.core

import kotlin.test.Test
import kotlin.test.assertEquals

class WeekTest {
    @Test
    fun percentOfTheGoal() {
        val week = Week(goal = 300)
        week.add(Session("kotlin", 45))
        week.add(Session("android-apps", 30))
        assertEquals(25, week.percent())
    }
}
```

```
ana@vm:~/kt/studyplan$ ./gradlew -q :core:test && echo tests passed
tests passed
```

With `-q` a passing test prints nothing, so `&& echo` reports it: the `echo` runs only if Gradle exited
with success. Now the same call from `app`, added as the last line of `main`:

```kotlin
    println(week.percent())
```

```
ana@vm:~/kt/studyplan$ ./gradlew -q :app:run 2>&1 | head -3
e: file:///home/ana/kt/studyplan/app/src/main/kotlin/Main.kt:12:18 Cannot access 'fun percent(): Int': it is internal in 'studyplan.core.Week'.

FAILURE: Build failed with an exception.
```

**The compiler refused it, naming the declaration and the reason: it is `internal` to `core`.** Take the line out again.
`internal` is how a module keeps the freedom to change something. `percent()` may become a `Double`, or
take the rounding into account, and only code in `core` has to agree; `public` would have made it a
promise to every module that will ever depend on `core`.

