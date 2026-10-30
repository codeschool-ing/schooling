---
title: Cache e atualização, e quando perguntar à rede de novo
version: 1
---

**Toda abertura de tela é uma chance de atualizar, e a maioria não deveria aproveitá-la.** A tela da
semana do planner abre dezenas de vezes por dia. Perguntar ao servidor a cada vez custa bateria e
dados e, numa rede lenta, custa ao usuário um indicador de carregamento sobre dados que ele já tem.
Então o repositório guarda uma regra de frescor: `refreshIfStale()` pergunta à rede só quando nunca
houve atualização, ou quando a última tem mais de quinze minutos. O dado na tela é sempre o do Room;
a regra só decide com que frequência o Room é posto em dia.

**Quinze minutos é uma decisão, não um fato.** Um planner cujas sessões mudam quando o estudante as
muda pode esperar; um chat não poderia. Escreva o número num lugar só, como o construtor faz, para
que dê para discutir sobre ele.

O teste roda o repositório contra um banco em memória de verdade e um MockWebServer, e move o tempo à
mão pela função `now`:

```kotlin
// app/src/test/java/com/example/planner/data/RefreshTest.kt
package com.example.planner.data

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import java.time.Instant
import java.time.LocalDate
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class RefreshTest {
    private val week = """[
        {"id": 7, "course_id": "android", "date": "2026-10-27", "minutes": 45},
        {"id": 8, "course_id": "sql", "date": "2026-10-29", "minutes": 90, "done": true}
    ]"""

    @Test
    fun refreshesOnlyWhenStale(): Unit = runBlocking {
        val server = MockWebServer()
        repeat(2) { server.enqueue(MockResponse.Builder().body(week).build()) }
        server.start()
        val db = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext<Context>(),
            PlannerDatabase::class.java,
        ).build()
        var clock = Instant.parse("2026-10-30T12:00:00Z")
        val repo = SessionRepository(db.sessions(), plannerApi(server.url("/").toString()), now = { clock })
        val monday = LocalDate.of(2026, 10, 26)

        println("before: ${repo.week(monday).first()}")
        println("at 12:00 -> ${repo.refreshIfStale()}")
        repo.week(monday).first().forEach { println("  $it") }
        clock = clock.plusSeconds(5 * 60)
        println("at 12:05 -> ${repo.refreshIfStale()}")
        clock = clock.plusSeconds(15 * 60)
        println("at 12:20 -> ${repo.refreshIfStale()}")
        println("requests the server received: ${server.requestCount}")

        db.close()
        server.close()
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*RefreshTest" 2>&1 | grep -E "^    |PASSED|FAILED|^BUILD|^e: "
    before: []
    at 12:00 -> Success(2)
      StudySession(id=7, courseId=android, date=2026-10-27, minutes=45, done=false)
      StudySession(id=8, courseId=sql, date=2026-10-29, minutes=90, done=true)
    at 12:05 -> null
    at 12:20 -> Success(2)
    requests the server received: 2
RefreshTest > refreshesOnlyWhenStale PASSED
BUILD SUCCESSFUL in 49s
```

Leia como uma linha do tempo. **Antes do primeiro refresh a semana está vazia**, porque a tela lê o
Room e o Room ainda não tem nada. Às 12:00 nunca houve atualização, então o repositório pergunta,
recebe duas sessões, as escreve e informa `Success(2)`; a semana agora as tem, como modelos. Às 12:05
o dado tem cinco minutos e a resposta é `null`, *não precisa*, sem requisição nenhuma. Às 12:20 ele
tem vinte minutos, e o repositório pergunta de novo. **Duas atualizações, duas requisições**, para
três aberturas de tela.

## O que ainda falta

**`lastRefresh` mora na memória**, então um processo que o sistema matou começa de novo sem
atualização e pergunta na hora. É a direção segura para errar. Um planner que queira sobreviver a um
reinício guarda o horário numa tabela pequena ou no DataStore; a política não muda.

**A atualização também sobrescreve.** `upsertAll` escreve a cópia do servidor de cada sessão por cima
da local com o mesmo id. Uma sessão marcada como feita no celular e ainda não enviada voltaria a não
feita no próximo refresh. A seção 06 torna o problema visível, e o curso `mobile-offline`, aulas 13 e
14, trata da versão geral dele: duas cópias de uma linha que discordam.
