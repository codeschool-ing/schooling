---
title: Testing the server without a network
version: 1
---

Starting a server and typing curl commands is a check that has to be repeated by hand. **Ktor's
`testApplication` runs a module in memory and gives the test a client for it**: no port, no network,
and the same handlers the real server runs.

```kotlin
// src/test/kotlin/ServerTest.kt
package studyplan.server

import io.ktor.client.request.get
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.HttpStatusCode
import io.ktor.http.contentType
import io.ktor.server.testing.testApplication
import kotlin.test.Test
import kotlin.test.assertEquals

class ServerTest {
    @Test
    fun aPostedSessionIsListed() = testApplication {
        application { planner() }
        val created = client.post("/sessions") {
            contentType(ContentType.Application.Json)
            setBody("""{"course":"android-apps","minutes":30}""")
        }
        assertEquals(HttpStatusCode.Created, created.status)
        assertEquals(
            """[{"course":"kotlin","minutes":45},{"course":"android-apps","minutes":30}]""",
            client.get("/sessions").bodyAsText(),
        )
    }

    @Test
    fun zeroMinutesAreRefused() = testApplication {
        application { planner() }
        val response = client.post("/sessions") {
            contentType(ContentType.Application.Json)
            setBody("""{"course":"kotlin","minutes":0}""")
        }
        assertEquals(HttpStatusCode.BadRequest, response.status)
    }
}
```

```
ana@vm:~/kt/server$ ./gradlew -q test && echo tests passed
tests passed
```

**This is why `planner()` is a function and not the body of `main`.** `main` picks an engine and a
port; the module holds the behaviour, and `application { planner() }` installs it in a test with neither.
Each test gets a fresh module, so the session posted in the first does not leak into the second.

The JSON is written as raw strings, lesson 1's `"""…"""`, so the test states exactly what goes over the
wire. That is the contract a client, such as the app `android-apps` builds, depends on.
