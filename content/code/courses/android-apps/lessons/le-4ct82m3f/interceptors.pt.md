---
title: Interceptors: um lugar para o que toda requisição precisa
version: 1
---

**Um interceptor vê cada requisição na ida e cada resposta na volta**, e isso faz dele o lugar para
tudo o que precisa acontecer com todas elas: um cabeçalho, uma retentativa, uma linha de log. Escrito
uma vez, não pode ser esquecido no próximo endpoint que alguém acrescentar. O cliente do planner tem
três, acrescentados nesta ordem, e o OkHttp os roda nessa ordem na ida.

## O token

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

`chain.request()` é a requisição como chegou, e requisições são imutáveis, então o interceptor faz uma
cópia com um cabeçalho a mais e passa **essa** adiante com `chain.proceed`. O token é uma função, e
não uma string, porque um token muda: o estudante entra, uma renovação o troca, o estudante sai e não
há nenhum, que é a linha do `?: return`. O teste da seção 03 já conferiu que o cabeçalho chega.

## O log, e o que não pode estar nele

O `HttpLoggingInterceptor` escreve cada requisição e resposta pela função que recebe. No nível
`HEADERS` ele escreve o método, o endereço, todos os cabeçalhos e o status. Todos os cabeçalhos
incluem o token, que é uma senha em tudo menos no nome, então o cliente chama
`redactHeader("Authorization")`. Este teste manda uma requisição pelo cliente de verdade e imprime o
que o log recebeu:

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

**`Authorization: ██` é a linha que importa.** O cabeçalho foi enviado, como o teste da seção 03 provou
com o mesmo interceptor, e o log mostra que ele existe sem mostrar o que era. Uma linha de log com um
token acaba num relatório de falha, num chamado de bug, numa captura de tela colada num chat, e dali
qualquer pessoa pode agir como o estudante. Registrar no nível `BODY` acrescentaria o JSON de cada
requisição e resposta, incluindo tudo o que o estudante escreveu; é o nível para uma tarde de
depuração na sua própria máquina, nunca para um build que outra pessoa instala.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 190\" role=\"img\" data-fig=\"l13-chain\" aria-label=\"Cinco caixas em fila: api.courses(), depois AuthInterceptor, que põe o token, depois RetryInterceptor, que repete um GET, depois HttpLoggingInterceptor, que registra com o token oculto, e por fim a rede. Uma seta em cima vai da esquerda para a direita, a requisição na ida; uma seta embaixo vai da direita para a esquerda, a resposta na volta, pelos mesmos interceptors na ordem inversa.\"><defs><marker id=\"l13-chain-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l13-chain-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"70\" width=\"120\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"70.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">api.courses()</text><text x=\"70.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sua chamada</text><rect x=\"140\" y=\"70\" width=\"120\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"200.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">AuthInterceptor</text><text x=\"200.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">põe o token</text><rect x=\"270\" y=\"70\" width=\"120\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"330.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">RetryInterceptor</text><text x=\"330.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">repete um GET</text><rect x=\"400\" y=\"70\" width=\"120\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"460.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">HttpLogging…</text><text x=\"460.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">registra, token oculto</text><rect x=\"530\" y=\"70\" width=\"120\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"590.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">OkHttp</text><text x=\"590.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a rede</text><path d=\"M20 50 L640 50\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#l13-chain-ah-phosphor)\"></path><text x=\"20\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">requisição, na ida</text><path d=\"M640 150 L20 150\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\" marker-end=\"url(#l13-chain-ah-amber)\"></path><text x=\"640\" y=\"172\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">resposta, na volta</text></svg>", "caption": "Os três interceptors do planner, na ordem em que o Network.client os acrescenta. Cada um vê a requisição depois de o da esquerda tê-la mudado."}
```

A ordem importa, e a figura é o motivo. O token é posto primeiro, então a retentativa reenvia uma
requisição que já o carrega, e o log é o último na ida, então vê a requisição exatamente como ela
está prestes a ser enviada, cabeçalho incluído e depois ocultado. Ponha o log primeiro e ele
registraria uma requisição sem cabeçalho `Authorization` nenhum, que é um log que mente sobre o que
foi enviado.
