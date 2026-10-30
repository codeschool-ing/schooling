---
title: Consultas que devolvem um Flow, e respondem de novo
version: 1
---

**Um método de DAO que devolve um `Flow` não roda uma vez; roda de novo toda vez que muda uma tabela
que ele lê.** O Room registra quais tabelas cada consulta toca. Quando uma escrita é confirmada numa
delas, todo `Flow` que a lê roda a consulta de novo e emite o resultado novo. Uma tela que coleta
`minutesBetween` mostra então o total certo depois de cada insert, e ninguém escreveu o código que
manda ela atualizar.

É a propriedade sobre a qual a aula 16 monta o repositório, então vale vê-la acontecer em vez de
aceitá-la na confiança. O teste coleta o total da semana num canal, depois insere duas vezes e marca
uma sessão como feita, lendo o canal depois de cada escrita:

```kotlin
// app/src/test/java/com/example/planner/data/FlowTest.kt
package com.example.planner.data

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import java.time.LocalDate
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class FlowTest {
    @Test
    fun theTotalFollowsTheTable() = runBlocking {
        val db = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext<Context>(),
            PlannerDatabase::class.java,
        ).build()
        db.courses().upsert(listOf(CourseEntity("android", "Android Apps")))
        val monday = LocalDate.of(2026, 10, 26)

        val totals = Channel<Int>(Channel.UNLIMITED)
        val watcher = CoroutineScope(Dispatchers.IO)
        watcher.launch {
            db.sessions().minutesBetween(monday, monday.plusDays(6)).collect { totals.send(it) }
        }
        suspend fun next() = withTimeout(5_000) { totals.receive() }

        println("empty week: ${next()}")
        val id = db.sessions().insert(SessionEntity(courseId = "android", date = monday.plusDays(1), minutes = 45))
        println("after 45 min: ${next()}")
        db.sessions().insert(SessionEntity(courseId = "android", date = monday.plusDays(3), minutes = 90))
        println("after 90 min: ${next()}")
        db.sessions().insert(SessionEntity(courseId = "android", date = monday.plusDays(9), minutes = 50))
        println("a session next week: ${next()}")
        db.sessions().markDone(id)
        println("marked one done: ${next()}")

        watcher.cancel()
        db.close()
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*FlowTest" 2>&1 | grep -E "^    |PASSED|FAILED|^BUILD"
    empty week: 0
    after 45 min: 45
    after 90 min: 135
    a session next week: 135
    marked one done: 135
FlowTest > theTotalFollowsTheTable PASSED
BUILD SUCCESSFUL in 20s
```

**Toda escrita em `sessions` fez a consulta rodar de novo**, inclusive as duas que não podiam mudar o
total da semana. A sessão da semana que vem está fora do intervalo, e marcar uma como feita não toca
em `minutes`; o total foi recalculado assim mesmo e deu o mesmo número. O Room sabe quais tabelas uma
consulta lê, não quais linhas: a invalidação é por tabela.

Duas consequências vêm daí. **Um `Flow` do Room pode emitir o mesmo valor duas vezes seguidas**, então
uma tela que faz trabalho a cada emissão deveria pôr `distinctUntilChanged()`, um operador do
`kotlinx.coroutines`, na frente dele. E **o custo de uma escrita é pago por toda consulta que observa
aquela tabela**, o que para um planner é um punhado de somas pequenas e para um feed de milhares de
linhas é o motivo para manter as consultas estreitas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O tempo corre da esquerda para a direita. Quatro escritas na tabela sessions: inserir 45 minutos, inserir 90 minutos, inserir 50 minutos na semana que vem, marcar uma sessão como feita. Depois que cada escrita é confirmada, o Room invalida a tabela sessions, a consulta roda de novo e o Flow emite: 0 no começo, depois 45, depois 135, depois 135 de novo, e 135 mais uma vez. As duas últimas emissões repetem o valor porque a invalidação é por tabela, não por linha.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"230\" fill=\"var(--ink)\"></rect><text x=\"20\" y=\"28\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">escritas na tabela sessions</text><line x1=\"20\" y1=\"110\" x2=\"700\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><rect x=\"150\" y=\"45\" width=\"110\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"205\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">inserir 45 min</text><rect x=\"280\" y=\"45\" width=\"110\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"335\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">inserir 90 min</text><rect x=\"410\" y=\"45\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"475\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">50 min, semana que vem</text><rect x=\"560\" y=\"45\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"625\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">marcar uma feita</text><text x=\"20\" y=\"150\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">o Flow emite</text><circle cx=\"80\" cy=\"110\" r=\"6\" fill=\"var(--phosphor)\"></circle><circle cx=\"205\" cy=\"110\" r=\"6\" fill=\"var(--phosphor)\"></circle><circle cx=\"335\" cy=\"110\" r=\"6\" fill=\"var(--phosphor)\"></circle><circle cx=\"475\" cy=\"110\" r=\"6\" fill=\"var(--phosphor-dim)\"></circle><circle cx=\"625\" cy=\"110\" r=\"6\" fill=\"var(--phosphor-dim)\"></circle><text x=\"80\" y=\"185\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">0</text><text x=\"205\" y=\"185\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">45</text><text x=\"335\" y=\"185\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">135</text><text x=\"475\" y=\"185\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">135</text><text x=\"625\" y=\"185\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">135</text><text x=\"550\" y=\"215\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o mesmo valor de novo: a tabela mudou, a soma não</text></svg>", "caption": "O Room roda a consulta de novo depois de cada escrita numa tabela que ela lê, então o total é emitido cinco vezes e duas delas repetem o último valor."}
```
