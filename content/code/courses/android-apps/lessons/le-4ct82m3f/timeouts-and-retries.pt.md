---
title: Tempos-limite, e a retentativa que não pode repetir uma escrita
version: 1
---

**Uma requisição sem limite de tempo pode esperar para sempre**, e num celular espera: um trem entra
num túnel, a conexão nem funciona nem fecha, e um indicador gira até o estudante desistir do app. O
OkHttp tem quatro limites e o cliente da seção 02 define três deles:

| tempo-limite | o que limita | o do planner |
|---|---|---|
| `connectTimeout` | abrir a conexão | 10 s |
| `readTimeout` | a espera entre dois pedaços da resposta | 10 s |
| `writeTimeout` | a espera entre dois pedaços da requisição | o padrão do OkHttp, 10 s |
| `callTimeout` | a chamada inteira, retentativas e redirecionamentos incluídos | 30 s |

**O `readTimeout` não é um limite para a resposta inteira**: um servidor que manda um byte a cada nove
segundos nunca o dispara. O `callTimeout` é o que limita o tempo que o estudante espera, e é o único
que cobre as retentativas abaixo. Este teste usa um cliente com tempo-limite de leitura de um segundo
e um servidor que espera três segundos antes de responder:

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

O `newBuilder()` cria um cliente que compartilha tudo com o original, os interceptors inclusive, e
muda uma configuração. Três tentativas de cerca de um segundo cada, e então `SocketTimeoutException`,
uma `IOException`, logo `Unreachable`. Sem o tempo-limite de leitura valeria o padrão de dez segundos,
três vezes.

## Tentar de novo, e quando não

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

Ele tenta de novo só numa `IOException`, nunca numa resposta: um `404` será um `404` de novo. Espera
200 ms, depois 400 ms, dobrando, para que um servidor que já está sofrendo não seja atingido três
vezes no mesmo instante. E **só repete um `GET`**. Um `GET` pede algo e não muda nada, então pedir duas
vezes é inofensivo. Um `POST` que estourou o tempo pode ter chegado ao servidor, sido salvo e perdido
só a resposta no caminho de volta; mandá-lo de novo salva a sessão duas vezes. Este teste prova que o
interceptor recusa:

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

O `GET` perdeu duas conexões e deu certo na terceira tentativa. O `POST` perdeu uma e foi relatado
como `Unreachable` depois de uma tentativa só, com a segunda resposta ainda esperando, sem uso, na
fila do servidor: o interceptor não tentou de novo, de propósito. Como uma escrita fica segura para
repetir, com uma **chave de idempotência** que o servidor reconhece, é a aula 10 de `mobile-offline`;
até uma API ter uma, o honesto que um cliente pode fazer com uma escrita que falhou é dizer isso.
