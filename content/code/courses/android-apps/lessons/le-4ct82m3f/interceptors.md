---
title: Interceptors: one place for what every request needs
version: 1
---

**An interceptor sees every request on its way out and every response on its way back**, which
makes it the place for anything that must happen to all of them: a header, a retry, a log line.
Written once, it cannot be forgotten on the next endpoint somebody adds. The planner's client has
three, added in this order, and OkHttp runs them in that order on the way out.

## The token

```kotlin
// app/src/main/java/com/example/planner/data/remote/AuthInterceptor.kt
package com.example.planner.data.remote

import okhttp3.Interceptor
import okhttp3.Response

class AuthInterceptor(private val token: () -> String?) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val current = token() ?: return chain.proceed(chain.request())
        val request = chain.request().newBuilder()
            .header("Authorization", "Bearer $current")
            .build()
        return chain.proceed(request)
    }
}
```

`chain.request()` is the request as it arrived, and requests are immutable, so the interceptor makes
a copy with one header more and passes **that** on with `chain.proceed`. The token is a function, not
a string, because a token changes: the student signs in, a refresh replaces it, the student signs
out and there is none, which is the `?: return` line. Section 03's test already checked that the
header arrives.

## The log, and what must not be in it

`HttpLoggingInterceptor` writes each request and response through the function it is given. At
`HEADERS` level it writes the method, the address, every header and the status. Every header
includes the token, which is a password in all but name, so the client calls
`redactHeader("Authorization")`. This test sends one request through the real client and prints
what the log received:

```kotlin
// app/src/test/java/com/example/planner/data/remote/LoggingTest.kt
package com.example.planner.data.remote

import kotlinx.coroutines.test.runTest
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import org.junit.After
import org.junit.Before
import org.junit.Test

class LoggingTest {
    private val server = MockWebServer()
    private val lines = mutableListOf<String>()

    @Before fun start() = server.start()
    @After fun stop() = server.close()

    @Test fun theTokenNeverReachesTheLog() = runTest {
        server.enqueue(MockResponse.Builder().addHeader("Content-Type", "application/json").body("[]").build())
        val api = Network.api(Network.client(token = { "s3cr3t-t0ken" }, log = { lines += it }), server.url("/v1/").toString())
        api.courses()
        lines.forEach { println("log: $it") }
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*LoggingTest' 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)|PASSED|FAILED|^    [a-zA-Z0-9]"
    log: --> GET http://localhost:46069/v1/courses
    log: Authorization: ██
    log: --> END GET
    log: <-- 200 OK http://localhost:46069/v1/courses (46ms)
    log: Content-Type: application/json
    log: Content-Length: 2
    log: <-- END HTTP
LoggingTest > theTokenNeverReachesTheLog PASSED
BUILD SUCCESSFUL in 8s
30 actionable tasks: 1 executed, 29 up-to-date
```

**`Authorization: ██` is the line that matters.** The header was sent, as section 03's test proved
with the same interceptor, and the log shows that it exists without showing what it was. A log line
with a token in it ends up in a crash report, a bug ticket, a screenshot pasted into a chat, and
from there anyone can act as the student. Logging at `BODY` level would add the JSON of every
request and response, including everything the student wrote; it is the level for one afternoon of
debugging on your own machine, never for a build anybody else installs.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 190\" role=\"img\" data-fig=\"l13-chain\" aria-label=\"Five boxes in a row: api.courses(), then AuthInterceptor, which adds the token, then RetryInterceptor, which tries a GET again, then HttpLoggingInterceptor, which logs with the token hidden, then the network. An arrow above runs left to right for the request on its way out; an arrow below runs right to left for the response on its way back, through the same interceptors in reverse order.\"><defs><marker id=\"l13-chain-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l13-chain-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"70\" width=\"120\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"70.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">api.courses()</text><text x=\"70.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">your call</text><rect x=\"140\" y=\"70\" width=\"120\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"200.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">AuthInterceptor</text><text x=\"200.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">adds the token</text><rect x=\"270\" y=\"70\" width=\"120\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"330.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">RetryInterceptor</text><text x=\"330.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tries a GET again</text><rect x=\"400\" y=\"70\" width=\"120\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"460.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">HttpLogging…</text><text x=\"460.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">logs, token hidden</text><rect x=\"530\" y=\"70\" width=\"120\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"590.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">OkHttp</text><text x=\"590.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the network</text><path d=\"M20 50 L640 50\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#l13-chain-ah-phosphor)\"></path><text x=\"20\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">request, on its way out</text><path d=\"M640 150 L20 150\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\" marker-end=\"url(#l13-chain-ah-amber)\"></path><text x=\"640\" y=\"172\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">response, on its way back</text></svg>", "caption": "The planner's three interceptors, in the order Network.client adds them. Each sees the request after the one to its left has changed it."}
```

The order matters, and the figure is the reason. The token is added first, so the retry resends a
request that already carries it, and the log is last on the way out, so it sees the request exactly
as it is about to be sent, header included and then redacted. Put the logger first and it would log
a request with no `Authorization` header at all, which is a log that lies about what was sent.
