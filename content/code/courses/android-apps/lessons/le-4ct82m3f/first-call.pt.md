---
title: Um servidor dentro do teste
version: 1
---

**O MockWebServer é um servidor HTTP de verdade que um teste inicia no endereço do próprio
computador e instrui exatamente sobre o que responder.** O código do app não sabe que não está
falando com `api.example.com`: ele abre uma conexão, envia uma requisição e lê uma resposta, tudo pelo
OkHttp e pelo Retrofit de verdade. O que o teste controla é a outra ponta, então ele pode pedir as
respostas difíceis de conseguir de um servidor real na hora: um erro, uma desconexão, um servidor que
leva três segundos.

O primeiro teste pede os cursos, e depois pergunta ao servidor o que ele recebeu:

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

Leia as duas metades uma contra a outra. O lado do cliente imprimiu objetos Kotlin, `CourseDto` e
`SessionDto`, feitos do JSON que o servidor foi instruído a mandar, inclusive `done = false`
preenchido pelo valor padrão porque a resposta do `POST` o omitiu. O lado do servidor imprimiu o que
chegou pelo fio: o método, o caminho que o Retrofit montou a partir de `courses/{id}/sessions` e da
URL base, o corpo que ele codificou a partir de `NewSessionDto`, e o cabeçalho que o interceptor da
seção 06 acrescentou. **Um teste que confere só o resultado lido passaria com um caminho errado**; o
`takeRequest()` é como a própria requisição é cobrada pelo contrato da seção 02.

`server.url("/v1/")` é um endereço em `127.0.0.1`, numa porta que o sistema operacional escolheu
quando o servidor começou, então muda a cada execução e dois testes nunca colidem. O `@After` fecha o
servidor, e com ele a porta.
