---
title: Timeouts, and the retry that must not repeat a write
version: 1
---

**A request with no time limit can wait for ever**, and on a phone it will: a train enters a tunnel,
the connection neither works nor closes, and a spinner turns until the student gives up on the app.
OkHttp has four limits and the client of section 02 sets three of them:

| timeout | what it limits | the planner's |
|---|---|---|
| `connectTimeout` | opening the connection | 10 s |
| `readTimeout` | the wait between two pieces of the response | 10 s |
| `writeTimeout` | the wait between two pieces of the request | OkHttp's default, 10 s |
| `callTimeout` | the whole call, retries and redirects included | 30 s |

**`readTimeout` is not a limit on the whole response**: a server that sends one byte every nine
seconds never trips it. `callTimeout` is the one that bounds what the student waits for, and it is the
only one that covers the retries below. This test uses a client with a one-second read timeout and a
server that waits three seconds before answering:

```kotlin
// app/src/test/java/com/example/planner/data/remote/TimeoutTest.kt
package com.example.planner.data.remote

import java.util.concurrent.TimeUnit
import kotlinx.coroutines.test.runTest
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import org.junit.After
import org.junit.Before
import org.junit.Test

class TimeoutTest {
    private val server = MockWebServer()

    @Before fun start() = server.start()
    @After fun stop() = server.close()

    @Test fun aSlowServerIsGivenUpOn() = runTest {
        repeat(3) {
            server.enqueue(MockResponse.Builder().headersDelay(3, TimeUnit.SECONDS).body("[]").build())
        }
        val impatient = Network.client(token = { null }).newBuilder()
            .readTimeout(1, TimeUnit.SECONDS)
            .build()
        val started = System.nanoTime()
        val result = apiCall { Network.api(impatient, server.url("/v1/").toString()).courses() }
        val seconds = (System.nanoTime() - started) / 1_000_000_000.0
        println("result:   $result")
        println("attempts: ${server.requestCount}, about ${"%.0f".format(seconds)} s")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*TimeoutTest' 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)|PASSED|FAILED|^    [a-zA-Z0-9]"
    result:   Unreachable(reason=SocketTimeoutException: timeout)
    attempts: 3, about 4 s
TimeoutTest > aSlowServerIsGivenUpOn PASSED
BUILD SUCCESSFUL in 10s
30 actionable tasks: 1 executed, 29 up-to-date
```

`newBuilder()` makes a client that shares everything with the original, the interceptors included,
and changes one setting. Three attempts of about one second each, and then `SocketTimeoutException`,
an `IOException`, so `Unreachable`. Without the read timeout the default of ten seconds would apply,
three times over.

## Retrying, and when not to

```kotlin
// app/src/main/java/com/example/planner/data/remote/RetryInterceptor.kt
package com.example.planner.data.remote

import java.io.IOException
import okhttp3.Interceptor
import okhttp3.Response

class RetryInterceptor(private val maxAttempts: Int) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        if (request.method != "GET") return chain.proceed(request)
        var delayMs = 200L
        repeat(maxAttempts - 1) {
            try {
                return chain.proceed(request)
            } catch (e: IOException) {
                if (chain.call().isCanceled()) throw e
                Thread.sleep(delayMs)
                delayMs *= 2
            }
        }
        return chain.proceed(request)
    }
}
```

It retries on an `IOException` only, never on an answer: a `404` will be a `404` again. It waits
200 ms, then 400 ms, doubling, so that a server already struggling is not hit three times in the
same instant. And **it only retries a `GET`**. A `GET` asks for something and changes nothing, so
asking twice is harmless. A `POST` that timed out may have reached the server, been saved, and lost
only its answer on the way back; sending it again saves the session twice. This test proves the
interceptor refuses:

```kotlin
// app/src/test/java/com/example/planner/data/remote/RetryTest.kt
package com.example.planner.data.remote

import kotlinx.coroutines.test.runTest
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import mockwebserver3.SocketEffect
import org.junit.After
import org.junit.Before
import org.junit.Test

class RetryTest {
    private val server = MockWebServer()

    @Before fun start() = server.start()
    @After fun stop() = server.close()

    private fun api() = Network.api(Network.client(token = { "test-token" }), server.url("/v1/").toString())
    private fun drop() = MockResponse.Builder().onRequestStart(SocketEffect.CloseSocket()).build()
    private fun json(body: String) = MockResponse.Builder().addHeader("Content-Type", "application/json").body(body).build()

    @Test fun aGetSurvivesTwoDrops() = runTest {
        server.enqueue(drop()); server.enqueue(drop()); server.enqueue(json("[]"))
        println("GET:  ${apiCall { api().courses() }} after ${server.requestCount} attempts")
    }

    @Test fun aPostIsNeverRepeated() = runTest {
        server.enqueue(drop()); server.enqueue(json("""{"id":7,"courseId":"android","date":"2026-10-28","minutes":25}"""))
        println("POST: ${apiCall { api().addSession("android", NewSessionDto("2026-10-28", 25)) }} after ${server.requestCount} attempt")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*RetryTest' 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)|PASSED|FAILED|^    [a-zA-Z0-9]"
    GET:  Ok(value=[]) after 3 attempts
RetryTest > aGetSurvivesTwoDrops PASSED
    POST: Unreachable(reason=IOException: unexpected end of stream on http://localhost:57273/...) after 1 attempt
RetryTest > aPostIsNeverRepeated PASSED
BUILD SUCCESSFUL in 7s
30 actionable tasks: 1 executed, 29 up-to-date
```

The `GET` lost two connections and succeeded on the third attempt. The `POST` lost one and
was reported as `Unreachable` after a single attempt, with the second answer still waiting unused in
the server's queue: the interceptor did not try again, by design. How a write is made safe to repeat,
with an **idempotency key** the server recognises, is lesson 10 of `mobile-offline`; until an API has
one, the honest thing a client can do with a failed write is to say so.
