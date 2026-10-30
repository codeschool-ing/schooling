---
title: Queries that return a Flow, and answer again
version: 1
---

**A DAO method that returns a `Flow` does not run once; it runs again every time a table it reads
changes.** Room records which tables each query touches. When a write commits to one of them, every
`Flow` reading it runs its query again and emits the new result. A screen that collects
`minutesBetween` therefore shows the right total after every insert, and nobody wrote the code that
tells it to refresh.

That is the property lesson 16 builds the repository on, so it is worth seeing happen rather than
taking on trust. The test collects the week's total into a channel, then inserts twice and marks one
session done, reading the channel after each write:

```kotlin
// app/src/test/java/com/example/planner/data/FlowTest.kt
package com.example.planner.data

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import java.time.LocalDate
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class FlowTest {
    @Test
    fun theTotalFollowsTheTable() = runBlocking {
        val db = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext<Context>(),
            PlannerDatabase::class.java,
        ).build()
        db.courses().upsert(listOf(CourseEntity("android", "Android Apps")))
        val monday = LocalDate.of(2026, 10, 26)

        val totals = Channel<Int>(Channel.UNLIMITED)
        val watcher = CoroutineScope(Dispatchers.IO)
        watcher.launch {
            db.sessions().minutesBetween(monday, monday.plusDays(6)).collect { totals.send(it) }
        }
        suspend fun next() = withTimeout(5_000) { totals.receive() }

        println("empty week: ${next()}")
        val id = db.sessions().insert(SessionEntity(courseId = "android", date = monday.plusDays(1), minutes = 45))
        println("after 45 min: ${next()}")
        db.sessions().insert(SessionEntity(courseId = "android", date = monday.plusDays(3), minutes = 90))
        println("after 90 min: ${next()}")
        db.sessions().insert(SessionEntity(courseId = "android", date = monday.plusDays(9), minutes = 50))
        println("a session next week: ${next()}")
        db.sessions().markDone(id)
        println("marked one done: ${next()}")

        watcher.cancel()
        db.close()
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*FlowTest" 2>&1 | grep -E "^    |PASSED|FAILED|^BUILD"
    empty week: 0
    after 45 min: 45
    after 90 min: 135
    a session next week: 135
    marked one done: 135
FlowTest > theTotalFollowsTheTable PASSED
BUILD SUCCESSFUL in 20s
```

**Every write to `sessions` made the query run again**, including the two that could not change the
week's total. The session dated next week is outside the range, and marking one done does not touch
`minutes`; the total was recomputed anyway and came out the same. Room knows which tables a query
reads, not which rows: invalidation is per table.

Two consequences follow. **A `Flow` from Room can emit the same value twice in a row**, so a screen
that does work on every emission should put `distinctUntilChanged()`, an operator of `kotlinx.coroutines`, in front of
it. And **the cost of a write is paid by every query watching that table**, which for a
planner is a handful of small sums and for a feed of thousands of rows is the reason to keep queries
narrow.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Time runs left to right. Five writes to the sessions table: insert 45 minutes, insert 90 minutes, insert 50 minutes next week, mark one session done. After each write commits, Room invalidates the sessions table, the query runs again and the Flow emits: 0 at the start, then 45, then 135, then 135 again, then 135 again. The last two emissions repeat the value because invalidation is per table, not per row.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"230\" fill=\"var(--ink)\"></rect><text x=\"20\" y=\"28\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">writes to the sessions table</text><line x1=\"20\" y1=\"110\" x2=\"700\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><rect x=\"150\" y=\"45\" width=\"110\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"205\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">insert 45 min</text><rect x=\"280\" y=\"45\" width=\"110\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"335\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">insert 90 min</text><rect x=\"410\" y=\"45\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"475\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">50 min, next week</text><rect x=\"560\" y=\"45\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"625\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mark one done</text><text x=\"20\" y=\"150\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">the Flow emits</text><circle cx=\"80\" cy=\"110\" r=\"6\" fill=\"var(--phosphor)\"></circle><circle cx=\"205\" cy=\"110\" r=\"6\" fill=\"var(--phosphor)\"></circle><circle cx=\"335\" cy=\"110\" r=\"6\" fill=\"var(--phosphor)\"></circle><circle cx=\"475\" cy=\"110\" r=\"6\" fill=\"var(--phosphor-dim)\"></circle><circle cx=\"625\" cy=\"110\" r=\"6\" fill=\"var(--phosphor-dim)\"></circle><text x=\"80\" y=\"185\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">0</text><text x=\"205\" y=\"185\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">45</text><text x=\"335\" y=\"185\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">135</text><text x=\"475\" y=\"185\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">135</text><text x=\"625\" y=\"185\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">135</text><text x=\"550\" y=\"215\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the same value again: the table changed, the sum did not</text></svg>", "caption": "Room re-runs a query after every write to a table it reads, so the total is emitted five times and two of them repeat the last value."}
```
