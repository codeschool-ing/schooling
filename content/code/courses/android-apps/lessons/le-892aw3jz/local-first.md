---
title: Writing locally first
version: 1
---

**A session the student adds must appear the moment they add it, whatever the network is doing.**
The wrong design sends it to the server and, when the server answers, writes it to Room and shows
it. On a train that is a spinner, then an error, then a session the student has to type again. The
repository's `add()` does the opposite: it writes to Room first, marked `synced = false`, so the
week's `Flow` shows it at once; then it makes one attempt to send it, and marks it synced if that
worked.

The test adds one session while the server answers `503`, and one after it recovers:

```kotlin
// app/src/test/java/com/example/planner/data/WriteTest.kt
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
class WriteTest {
    @Test
    fun theSessionIsThereBeforeTheServerIs(): Unit = runBlocking {
        val server = MockWebServer()
        server.enqueue(MockResponse.Builder().code(503).build())
        server.enqueue(
            MockResponse.Builder()
                .body("""{"id": 2, "course_id": "sql", "date": "2026-10-29", "minutes": 90}""")
                .build(),
        )
        server.start()
        val db = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext<Context>(),
            PlannerDatabase::class.java,
        ).build()
        val repo = SessionRepository(db.sessions(), plannerApi(server.url("/").toString()))
        val monday = LocalDate.of(2026, 10, 26)

        repo.add("android", LocalDate.of(2026, 10, 27), 45)
        repo.add("sql", LocalDate.of(2026, 10, 29), 90)
        repo.week(monday).first().forEach { println(it) }
        println("waiting to be sent: ${db.sessions().unsynced().map { it.id }}")
        println("requests: ${server.requestCount}, first body: ${server.takeRequest().body?.utf8()}")

        db.close()
        server.close()
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*WriteTest" 2>&1 | grep -E "^    |PASSED|FAILED|^BUILD|^e: "
    StudySession(id=1, courseId=android, date=2026-10-27, minutes=45, done=false)
    StudySession(id=2, courseId=sql, date=2026-10-29, minutes=90, done=false)
    waiting to be sent: [1]
    requests: 2, first body: {"id":1,"course_id":"android","date":"2026-10-27","minutes":45}
WriteTest > theSessionIsThereBeforeTheServerIs PASSED
BUILD SUCCESSFUL in 27s
```

**Both sessions are in the week**, the one the server refused included: the student sees exactly
what they typed. The difference is one column. Session 1 is still waiting to be sent, and session 2,
whose `POST` got an answer, is not. The last line is the first request the server received, the
refused one, with the JSON lesson 14's DTO wrote.

## Who sends session 1?

**Nobody, yet, and that is where this lesson stops on purpose.** Sending the unsynced rows later is a
queue that has to survive the app being closed, retry with growing gaps, and never send the same
session twice. Lesson 18's WorkManager is the Android tool that runs such work when the network
returns, even after a restart. The design of the queue itself, the **outbox**, belongs to the
`mobile-offline` course: its lesson 7 is this section's idea in full, its lesson 8 is the outbox,
and its lesson 10 is the idempotency key that stops a retried `POST` creating a session twice.

Two things the code above does not handle, so that you recognise them when they bite. The id is
chosen by the phone, which works for one phone and collides the day the same student uses two. And
section 04's refresh writes the server's copy over an unsynced local row with the same id. Both are
the `mobile-offline` course's subject, and both are invisible until a second device exists.
