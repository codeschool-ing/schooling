---
title: Escrevendo primeiro no local
version: 1
---

**Uma sessão que o estudante acrescenta tem de aparecer no momento em que ele a acrescenta, não
importa o que a rede esteja fazendo.** O desenho errado manda a sessão ao servidor e, quando o
servidor responde, a escreve no Room e a mostra. Num trem isso é um indicador de carregamento,
depois um erro, depois uma sessão que o estudante precisa digitar de novo. O `add()` do repositório
faz o contrário: escreve primeiro no Room, marcada `synced = false`, para que o `Flow` da semana a
mostre na hora; depois faz uma tentativa de enviá-la, e a marca como sincronizada se deu certo.

O teste acrescenta uma sessão enquanto o servidor responde `503`, e outra depois que ele se recupera:

```kotlin
// app/src/test/java/com/example/planner/data/WriteTest.kt
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
class WriteTest {
    @Test
    fun theSessionIsThereBeforeTheServerIs(): Unit = runBlocking {
        val server = MockWebServer()
        server.enqueue(MockResponse.Builder().code(503).build())
        server.enqueue(
            MockResponse.Builder()
                .body("""{"id": 2, "course_id": "sql", "date": "2026-10-29", "minutes": 90}""")
                .build(),
        )
        server.start()
        val db = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext<Context>(),
            PlannerDatabase::class.java,
        ).build()
        val repo = SessionRepository(db.sessions(), plannerApi(server.url("/").toString()))
        val monday = LocalDate.of(2026, 10, 26)

        repo.add("android", LocalDate.of(2026, 10, 27), 45)
        repo.add("sql", LocalDate.of(2026, 10, 29), 90)
        repo.week(monday).first().forEach { println(it) }
        println("waiting to be sent: ${db.sessions().unsynced().map { it.id }}")
        println("requests: ${server.requestCount}, first body: ${server.takeRequest().body?.utf8()}")

        db.close()
        server.close()
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*WriteTest" 2>&1 | grep -E "^    |PASSED|FAILED|^BUILD|^e: "
    StudySession(id=1, courseId=android, date=2026-10-27, minutes=45, done=false)
    StudySession(id=2, courseId=sql, date=2026-10-29, minutes=90, done=false)
    waiting to be sent: [1]
    requests: 2, first body: {"id":1,"course_id":"android","date":"2026-10-27","minutes":45}
WriteTest > theSessionIsThereBeforeTheServerIs PASSED
BUILD SUCCESSFUL in 27s
```

**As duas sessões estão na semana**, inclusive a que o servidor recusou: o estudante vê exatamente o
que digitou. A diferença é uma coluna. A sessão 1 ainda espera para ser enviada, e a sessão 2, cujo
`POST` teve resposta, não. A última linha é a primeira requisição que o servidor recebeu, a recusada,
com o JSON que o DTO da aula 14 escreveu.

## Quem envia a sessão 1?

**Ninguém, por enquanto, e é aqui que esta aula para de propósito.** Enviar as linhas não
sincronizadas depois é uma fila que precisa sobreviver ao app ser fechado, tentar de novo com
intervalos crescentes e nunca mandar a mesma sessão duas vezes. O WorkManager da aula 18 é a
ferramenta do Android que roda esse trabalho quando a rede volta, mesmo depois de um reinício. O
desenho da fila em si, a **outbox**, é do curso `mobile-offline`. A aula 7 dele é a ideia desta seção por inteiro, a aula 8 é a outbox, e a aula 10 é a chave de idempotência que impede um `POST` repetido
de criar uma sessão duas vezes.

Duas coisas que o código acima não trata, para você reconhecê-las quando morderem. O id é escolhido
pelo celular, o que funciona para um celular e colide no dia em que o mesmo estudante usar dois. E o
refresh da seção 04 escreve a cópia do servidor por cima de uma linha local não sincronizada com o
mesmo id. As duas são assunto do curso `mobile-offline`, e as duas são invisíveis até existir um
segundo aparelho.
