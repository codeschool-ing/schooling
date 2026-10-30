---
title: A server inside the test
version: 1
---

**MockWebServer is a real HTTP server that a test starts on the computer's own address and tells
exactly what to answer.** The app's code does not know it is not talking to `api.example.com`: it
opens a connection, sends a request and reads a response, all through the real OkHttp and the real
Retrofit. What the test controls is the other end, so it can ask for the answers that are hard to get
from a real server on demand: an error, a disconnection, a server that takes three seconds.

The first test asks for the courses, and then asks the server what it received:

```kotlin
// app/src/test/java/com/example/planner/data/remote/PlannerApiTest.kt
package com.example.planner.data.remote

import kotlinx.coroutines.test.runTest
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test

class PlannerApiTest {
    private val server = MockWebServer()

    @Before fun start() = server.start()
    @After fun stop() = server.close()

    private fun api() = Network.api(Network.client(token = { "test-token" }), server.url("/v1/").toString())

    @Test fun coursesAreReadFromTheResponse() = runTest {
        server.enqueue(
            MockResponse.Builder()
                .addHeader("Content-Type", "application/json")
                .body("""[{"id":"kotlin","name":"Kotlin"},{"id":"android","name":"Android Apps"},{"id":"sql","name":"SQL Databases"}]""")
                .build(),
        )
        val courses = api().courses()
        println("courses: $courses")

        val request = server.takeRequest()
        println("request: ${request.method} ${request.target}")
        println("auth:    ${request.headers["Authorization"]}")
        assertEquals(3, courses.size)
    }

    @Test fun aNewSessionIsPostedAsJson() = runTest {
        server.enqueue(
            MockResponse.Builder()
                .code(201)
                .addHeader("Content-Type", "application/json")
                .body("""{"id":7,"courseId":"android","date":"2026-10-28","minutes":25}""")
                .build(),
        )
        val created = api().addSession("android", NewSessionDto(date = "2026-10-28", minutes = 25))
        println("created: $created")

        val request = server.takeRequest()
        println("request: ${request.method} ${request.target}")
        println("body:    ${request.body?.utf8()}")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*PlannerApiTest' 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)|PASSED|FAILED|^    [a-zA-Z0-9]"
    created: SessionDto(id=7, courseId=android, date=2026-10-28, minutes=25, done=false)
    request: POST /v1/courses/android/sessions
    body:    {"date":"2026-10-28","minutes":25}
PlannerApiTest > aNewSessionIsPostedAsJson PASSED
    courses: [CourseDto(id=kotlin, name=Kotlin), CourseDto(id=android, name=Android Apps), CourseDto(id=sql, name=SQL Databases)]
    request: GET /v1/courses
    auth:    Bearer test-token
PlannerApiTest > coursesAreReadFromTheResponse PASSED
BUILD SUCCESSFUL in 13s
30 actionable tasks: 11 executed, 19 up-to-date
```

Read the two halves against each other. The client side printed Kotlin objects, `CourseDto` and
`SessionDto`, made from the JSON the server was told to send, including `done = false` filled in from
the default because the `POST`'s answer left it out. The server side printed what came over the wire:
the method, the path Retrofit built from `courses/{id}/sessions` and the base URL, the body it
encoded from `NewSessionDto`, and the header section 06's interceptor added. **A test that checks only
the parsed result would pass with a wrong path**; `takeRequest()` is how the request itself is held
to the contract of section 02.

`server.url("/v1/")` is an address on `127.0.0.1` at a port the operating system chose when the
server started, so it differs on every run and no two tests can collide. The `@After` closes the
server, and with it the port.
