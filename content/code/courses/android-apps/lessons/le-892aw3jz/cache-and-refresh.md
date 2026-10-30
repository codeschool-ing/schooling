---
title: Cache and refresh, and when to ask the network again
version: 1
---

**Every screen opening is a chance to refresh, and most of them should not take it.** The planner's
week screen opens dozens of times a day. Asking the server each time costs battery and data, and
on a slow network it costs the user a spinner over data they already have. So the repository keeps
a rule about freshness: `refreshIfStale()` asks the network only when there has never been a
refresh, or when the last one is older than fifteen minutes. The data on screen is always Room's;
the rule decides only how often Room is brought up to date.

**Fifteen minutes is a decision, not a fact.** A planner whose sessions change when the student
changes them can wait; a chat could not. Write the number down in one place, as the constructor
does, so that it can be argued about.

The test runs the repository against a real in-memory database and a MockWebServer, and moves time
by hand through the `now` function:

```kotlin
// app/src/test/java/com/example/planner/data/RefreshTest.kt
package com.example.planner.data

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import java.time.Instant
import java.time.LocalDate
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class RefreshTest {
    private val week = """[
        {"id": 7, "course_id": "android", "date": "2026-10-27", "minutes": 45},
        {"id": 8, "course_id": "sql", "date": "2026-10-29", "minutes": 90, "done": true}
    ]"""

    @Test
    fun refreshesOnlyWhenStale(): Unit = runBlocking {
        val server = MockWebServer()
        repeat(2) { server.enqueue(MockResponse.Builder().body(week).build()) }
        server.start()
        val db = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext<Context>(),
            PlannerDatabase::class.java,
        ).build()
        var clock = Instant.parse("2026-10-30T12:00:00Z")
        val repo = SessionRepository(db.sessions(), plannerApi(server.url("/").toString()), now = { clock })
        val monday = LocalDate.of(2026, 10, 26)

        println("before: ${repo.week(monday).first()}")
        println("at 12:00 -> ${repo.refreshIfStale()}")
        repo.week(monday).first().forEach { println("  $it") }
        clock = clock.plusSeconds(5 * 60)
        println("at 12:05 -> ${repo.refreshIfStale()}")
        clock = clock.plusSeconds(15 * 60)
        println("at 12:20 -> ${repo.refreshIfStale()}")
        println("requests the server received: ${server.requestCount}")

        db.close()
        server.close()
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*RefreshTest" 2>&1 | grep -E "^    |PASSED|FAILED|^BUILD|^e: "
    before: []
    at 12:00 -> Success(2)
      StudySession(id=7, courseId=android, date=2026-10-27, minutes=45, done=false)
      StudySession(id=8, courseId=sql, date=2026-10-29, minutes=90, done=true)
    at 12:05 -> null
    at 12:20 -> Success(2)
    requests the server received: 2
RefreshTest > refreshesOnlyWhenStale PASSED
BUILD SUCCESSFUL in 49s
```

Read it as a timeline. **Before the first refresh the week is empty**, because the screen reads Room
and Room has nothing yet. At 12:00 there has never been a refresh, so the repository asks, gets two
sessions, writes them and reports `Success(2)`; the week now holds them, as models. At 12:05 the
data is five minutes old and the answer is `null`, *not needed*, with no request made. At 12:20 it
is twenty minutes old, and the repository asks again. **Two refreshes, two requests**, for three
screen openings.

## What is still missing

**`lastRefresh` lives in memory**, so a process the system killed starts again with no refresh and
asks at once. That is the safe direction to be wrong in. A planner that wants to survive a restart
keeps the time in a small table or in DataStore; the policy does not change.

**The refresh also overwrites.** `upsertAll` writes the server's copy of each session over the
local one with the same id. A session marked done on the phone and not yet sent would be marked
undone again by the next refresh. Section 06 makes the problem visible, and the `mobile-offline`
course, lessons 13 and 14, is about the general version of it: two copies of a row that disagree.
