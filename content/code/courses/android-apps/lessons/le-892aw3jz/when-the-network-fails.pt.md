---
title: Quando a rede falha, e os dados ficam
version: 1
---

**Com uma fonte única da verdade, uma requisição que falha não é uma tela vazia.** Os dados que o
usuário viu um minuto atrás continuam no Room, e a tela da semana continua a lê-los. O que a falha
muda é uma mensagem, não uma lista. Isso só se sustenta se o repositório informar a falha em vez de
escondê-la, e se a tela mostrar as duas coisas: as sessões que tem, e uma linha dizendo que podem
estar desatualizadas.

Uma rede falha de dois jeitos, e são exceções diferentes. O servidor pode responder com um status de
erro, um `503` enquanto está sendo implantado, que o Retrofit transforma numa `HttpException`. Ou não
há resposta nenhuma: sem conexão, uma porta recusada, um tempo esgotado, que chegam como
`IOException`. O repositório da seção 03 pega exatamente essas duas. O teste produz as duas:

```kotlin
// app/src/test/java/com/example/planner/data/OfflineTest.kt
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
class OfflineTest {
    @Test
    fun theWeekSurvivesTheNetwork(): Unit = runBlocking {
        val server = MockWebServer()
        server.enqueue(
            MockResponse.Builder()
                .body("""[{"id": 7, "course_id": "android", "date": "2026-10-27", "minutes": 45}]""")
                .build(),
        )
        server.enqueue(MockResponse.Builder().code(503).build())
        server.start()
        val db = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext<Context>(),
            PlannerDatabase::class.java,
        ).build()
        val repo = SessionRepository(db.sessions(), plannerApi(server.url("/").toString()))
        val monday = LocalDate.of(2026, 10, 26)

        println("online:     ${repo.refresh()}")
        println("503:        ${repo.refresh()}")
        server.close()
        println("no server:  ${repo.refresh().exceptionOrNull()?.let { it::class.simpleName }}")
        println("the week:   ${repo.week(monday).first()}")

        db.close()
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*OfflineTest" 2>&1 | grep -E "^    [a-z0-9]|PASSED|FAILED|^BUILD|^e: "
    online:     Success(1)
    503:        Failure(retrofit2.HttpException: HTTP 503 Server Error)
    no server:  ConnectException
    the week:   [StudySession(id=7, courseId=android, date=2026-10-27, minutes=45, done=false)]
OfflineTest > theWeekSurvivesTheNetwork PASSED
BUILD SUCCESSFUL in 32s
```

**Três atualizações, duas falhas, e a semana não perdeu nenhuma sessão.** A primeira atualização
escreveu uma sessão. A segunda encontrou um `503` e informou `HTTP 503`, uma `HttpException` dentro
de um `Result`. Depois o servidor foi desligado, então a terceira não encontrou ninguém escutando e
falhou com uma subclasse de `IOException`, a `ConnectException`. Depois de tudo isso, a semana ainda
tem a sessão da primeira atualização, porque nada num refresh que falha toca no Room.

## O que a tela faz com um `Result`

O ViewModel das aulas 10 e 11 chama `refreshIfStale()` e guarda o resultado no estado da interface ao
lado das sessões: uma `Failure` vira uma linha como "Não foi possível falar com o servidor; mostrando
o que foi salvo", e a lista embaixo continua. **Dois erros são comuns aqui, e os dois parecem código
que funciona.** Um limpa a lista quando o refresh falha, o que transforma uma rede lenta em dados
perdidos na tela. O outro engole a falha e não mostra nada, e o usuário confia numa semana que pode
estar velha. O repositório torna os dois evitáveis devolvendo a falha e deixando os dados onde
estavam.
