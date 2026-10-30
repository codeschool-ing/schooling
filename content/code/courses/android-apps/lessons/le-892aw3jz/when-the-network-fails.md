---
title: When the network fails, and the data stays
version: 1
---

**With one source of truth, a failed request is not an empty screen.** The data the user saw a
minute ago is still in Room, and the week screen keeps reading it. What the failure changes is a
message, not a list. That only holds if the repository reports the failure instead of hiding it, and
if the screen shows both: the sessions it has, and a line saying they may be out of date.

A network fails in two ways, and they are different exceptions. The server can answer with an error
status, a `503` while it is being deployed, which Retrofit turns into an `HttpException`. Or there
is no answer at all: no connection, a refused port, a timeout, which arrive as an `IOException`. The
repository of section 03 catches exactly those two. The test produces both:

```kotlin
// app/src/test/java/com/example/planner/data/OfflineTest.kt
package com.example.planner.data

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import java.time.LocalDate
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class OfflineTest {
    @Test
    fun theWeekSurvivesTheNetwork(): Unit = runBlocking {
        val server = MockWebServer()
        server.enqueue(
            MockResponse.Builder()
                .body("""[{"id": 7, "course_id": "android", "date": "2026-10-27", "minutes": 45}]""")
                .build(),
        )
        server.enqueue(MockResponse.Builder().code(503).build())
        server.start()
        val db = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext<Context>(),
            PlannerDatabase::class.java,
        ).build()
        val repo = SessionRepository(db.sessions(), plannerApi(server.url("/").toString()))
        val monday = LocalDate.of(2026, 10, 26)

        println("online:     ${repo.refresh()}")
        println("503:        ${repo.refresh()}")
        server.close()
        println("no server:  ${repo.refresh().exceptionOrNull()?.let { it::class.simpleName }}")
        println("the week:   ${repo.week(monday).first()}")

        db.close()
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*OfflineTest" 2>&1 | grep -E "^    [a-z0-9]|PASSED|FAILED|^BUILD|^e: "
    online:     Success(1)
    503:        Failure(retrofit2.HttpException: HTTP 503 Server Error)
    no server:  ConnectException
    the week:   [StudySession(id=7, courseId=android, date=2026-10-27, minutes=45, done=false)]
OfflineTest > theWeekSurvivesTheNetwork PASSED
BUILD SUCCESSFUL in 32s
```

**Three refreshes, two failures, and the week did not lose a session.** The first refresh wrote one
session. The second met a `503` and reported `HTTP 503`, an `HttpException` inside a `Result`. Then
the server was shut down, so the third found nobody listening and failed with an `IOException`
subclass, `ConnectException`. After all of it, the week still holds the session from the first
refresh, because nothing in a failed refresh touches Room.

## What the screen does with a `Result`

The ViewModel of lessons 10 and 11 calls `refreshIfStale()` and keeps the outcome in its UI state
beside the sessions: a `Failure` becomes a line such as "Could not reach the server; showing what
was saved", and the list underneath stays. **Two mistakes are common here, and both look like
working code.** One clears the list when the refresh fails, which turns a slow network into lost
data on screen. The other swallows the failure and shows nothing, so the user trusts a week that
may be stale. The repository makes both avoidable by returning the failure and leaving the data
where it was.
