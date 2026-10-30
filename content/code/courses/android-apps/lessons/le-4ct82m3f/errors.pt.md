---
title: Dois tipos de falha, e um tipo para cada
version: 1
---

**Uma chamada pode falhar porque o servidor respondeu "não", ou porque nenhuma resposta chegou, e o
app precisa tratar as duas de jeitos diferentes.** Um `404` ou um `401` é uma resposta: a rede
funcionou, o servidor olhou a requisição e a recusou, e tentar de novo dá a mesma recusa. Uma conexão
que cai, um tempo esgotado ou um celular num túnel não são resposta: nada foi decidido, e tentar de
novo pode muito bem funcionar. O Retrofit informa o primeiro caso como uma `HttpException` com o
código de status, e o OkHttp informa o segundo como uma `IOException`.

Uma função `suspend` que lança qualquer uma delas é fácil de chamar e fácil de chamar errado: nada na
assinatura diz que ela pode falhar. Então o planner embrulha cada chamada uma vez, na borda, e
transforma as duas exceções em valores que o resto do app é obrigado a olhar:

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

Ela captura exatamente dois tipos. **Uma `CancellationException` passa direto**, como a aula 11
precisa: uma tela que fecha no meio de uma requisição tem de cancelar a chamada, e não transformar o
cancelamento numa mensagem de erro. Um bug, um `NullPointerException` no código, também passa e
quebra o app, o que também é certo: não é uma condição de rede, e escondê-lo num estado de erro o
esconderia de você. A aula 13 de `kotlin` fez a mesma escolha com `Result`.

Três respostas, um teste para cada:

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

A recusa manteve o código, `404`, e nada mais; o corpo que o servidor mandou está na exceção se um
app precisar dele, e o planner não precisa. A conexão derrubada virou `Unreachable` com a descrição do
próprio OkHttp, depois de **três** tentativas: o servidor as contou. É o interceptor de retentativa
da seção 05 trabalhando antes de o `apiCall` ver a exceção, e o motivo de a seção 05 existir.

O que uma tela faz com cada um é assunto da aula 16, onde o repositório tem uma cópia no banco para
se apoiar. A regra que vale levar agora é sobre as palavras: **"Refused" é algo para dizer ao
estudante, "Unreachable" é algo para tentar de novo mais tarde**, e um app que mostra "Algo deu
errado" para os dois jogou essa diferença fora.
