---
title: Two kinds of failure, and a type for each
version: 1
---

**A call can fail because the server answered "no", or because no answer arrived at all, and the
app must treat them differently.** A `404` or a `401` is an answer: the network worked, the server
looked at the request and refused it, and trying again will get the same refusal. A dropped
connection, a timeout or a phone in a tunnel is no answer: nothing was decided, and trying again may
well work. Retrofit reports the first as an `HttpException` with the status code, and OkHttp reports
the second as an `IOException`.

A `suspend` function that throws either one is easy to call and easy to call wrongly: nothing in
its signature says it can fail. So the planner wraps each call once, at the edge, and turns both
exceptions into values the rest of the app has to look at:

```kotlin
// app/src/main/java/com/example/planner/data/remote/ApiResult.kt
package com.example.planner.data.remote

import java.io.IOException
import retrofit2.HttpException

sealed interface ApiResult<out T> {
    data class Ok<T>(val value: T) : ApiResult<T>
    data class Refused(val code: Int) : ApiResult<Nothing>
    data class Unreachable(val reason: String) : ApiResult<Nothing>
}

suspend fun <T> apiCall(block: suspend () -> T): ApiResult<T> =
    try {
        ApiResult.Ok(block())
    } catch (e: HttpException) {
        ApiResult.Refused(e.code())
    } catch (e: IOException) {
        ApiResult.Unreachable(e.javaClass.simpleName + ": " + e.message)
    }
```

It catches exactly two types. **A `CancellationException` passes through**, as lesson 11 needs it
to: a screen that closes mid-request must cancel the call, not turn the cancellation into an error
message. A bug, a `NullPointerException` in the code, also passes through and crashes, which is right
too: it is not a network condition, and hiding it in an error state would hide it from you. Lesson 13
of `kotlin` made the same choice with `Result`.

Three answers, one test each:

```kotlin
// app/src/test/java/com/example/planner/data/remote/ApiResultTest.kt
package com.example.planner.data.remote

import kotlinx.coroutines.test.runTest
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import mockwebserver3.SocketEffect
import org.junit.After
import org.junit.Before
import org.junit.Test

class ApiResultTest {
    private val server = MockWebServer()

    @Before fun start() = server.start()
    @After fun stop() = server.close()

    private fun api() = Network.api(Network.client(token = { "test-token" }), server.url("/v1/").toString())

    @Test fun anAnswer() = runTest {
        server.enqueue(MockResponse.Builder().addHeader("Content-Type", "application/json").body("[]").build())
        println("200:        ${apiCall { api().courses() }}")
    }

    @Test fun aRefusal() = runTest {
        server.enqueue(MockResponse.Builder().code(404).body("""{"error":"no such course"}""").build())
        println("404:        ${apiCall { api().sessions("chemistry") }}")
    }

    @Test fun noAnswer() = runTest {
        repeat(3) { server.enqueue(MockResponse.Builder().onRequestStart(SocketEffect.CloseSocket()).build()) }
        println("dropped:    ${apiCall { api().courses() }}")
        println("attempts:   ${server.requestCount}")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*ApiResultTest' 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)|PASSED|FAILED|^    [a-zA-Z0-9]"
    200:        Ok(value=[])
ApiResultTest > anAnswer PASSED
    404:        Refused(code=404)
ApiResultTest > aRefusal PASSED
    dropped:    Unreachable(reason=IOException: unexpected end of stream on http://localhost:47881/...)
    attempts:   3
ApiResultTest > noAnswer PASSED
BUILD SUCCESSFUL in 7s
30 actionable tasks: 1 executed, 29 up-to-date
```

The refusal kept its code, `404`, and nothing else; the body the server sent is in the exception if
an app needs it, and the planner does not. The dropped connection became `Unreachable` with
OkHttp's own description, after **three** attempts: the server counted them. That is the retry
interceptor of section 05 at work before `apiCall` ever saw the exception, and the reason section 05
exists.

What a screen does with each is lesson 16's subject, where the repository has a copy in the
database to fall back on. The rule worth taking now is about the words: **"Refused" is something to
tell the student, "Unreachable" is something to try again later**, and an app that shows "Something
went wrong" for both has thrown that difference away.
