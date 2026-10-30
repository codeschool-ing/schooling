---
title: Testando o repositório com fakes
version: 1
---

**Os testes até aqui rodaram um banco de verdade e um servidor HTTP de verdade, e isso é o certo para
os testes do próprio repositório.** Eles provaram o SQL, o JSON e o mapeamento de erros juntos. Mas o
ViewModel acima do repositório, e qualquer código que só precisa de "algumas sessões" ou de "uma rede
que falha", não deveria pagar pelo Robolectric e por um servidor para descobrir isso. Para esse
código, os colaboradores do repositório são trocados por **fakes**: implementações pequenas e
honestas da mesma interface, guardadas na memória.

Um fake não é um mock. Um mock registra quais métodos foram chamados e recebe a ordem do que devolver;
um fake *funciona*, com uma implementação mínima que dá para ler inteira. `SessionDao` e `PlannerApi`
são interfaces, e é isso que torna um fake possível:

```kotlin
// app/src/test/java/com/example/planner/data/Fakes.kt
package com.example.planner.data

import java.io.IOException
import java.time.LocalDate
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.map

class FakeSessionDao : SessionDao {
    private val rows = MutableStateFlow(emptyMap<Long, SessionEntity>())
    private var nextId = 1L

    override suspend fun insert(session: SessionEntity): Long {
        val id = nextId++
        rows.value += id to session.copy(id = id)
        return id
    }

    override suspend fun upsertAll(sessions: List<SessionEntity>) {
        rows.value += sessions.associateBy { it.id }
    }

    override fun between(from: LocalDate, to: LocalDate): Flow<List<SessionEntity>> =
        rows.map { all -> all.values.filter { it.date in from..to }.sortedBy { it.date } }

    override suspend fun unsynced() = rows.value.values.filter { !it.synced }

    override suspend fun markSynced(id: Long) {
        rows.value[id]?.let { rows.value += id to it.copy(synced = true) }
    }
}

class FakePlannerApi(var online: Boolean = true) : PlannerApi {
    val received = mutableListOf<SessionDto>()
    val onServer = mutableListOf<SessionDto>()

    override suspend fun sessions(): List<SessionDto> {
        if (!online) throw IOException("offline")
        return onServer.toList()
    }

    override suspend fun create(session: SessionDto): SessionDto {
        if (!online) throw IOException("offline")
        received += session
        return session
    }
}
```

**O `FakeSessionDao` guarda um `MutableStateFlow` de linhas**, então `between()` responde de novo
depois de cada escrita, a propriedade que a seção 06 da aula 15 mediu no Room. É a parte de um fake
que as pessoas erram: um DAO fake que devolvesse uma lista simples uma vez faria todo teste de tela
passar enquanto a tela de verdade atualizava e a fake não.

```kotlin
// app/src/test/java/com/example/planner/data/RepositoryWithFakesTest.kt
package com.example.planner.data

import java.time.LocalDate
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Test

class RepositoryWithFakesTest {
    @Test
    fun offlineAddThenRefresh() = runTest {
        val dao = FakeSessionDao()
        val api = FakePlannerApi(online = false)
        val repo = SessionRepository(dao, api)
        val monday = LocalDate.of(2026, 10, 26)

        repo.add("android", LocalDate.of(2026, 10, 27), 45)
        println("offline add: ${repo.week(monday).first().map { it.minutes }}, sent ${api.received.size}")
        assertEquals(listOf(1L), dao.unsynced().map { it.id })

        api.online = true
        api.onServer += SessionDto(8, "sql", LocalDate.of(2026, 10, 29), 90, done = true)
        println("refresh: ${repo.refresh()}")
        println("week: ${repo.week(monday).first().map { "${it.courseId} ${it.minutes}" }}")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*RepositoryWithFakesTest" 2>&1 | grep -E "^    |PASSED|FAILED|^BUILD|^e: "
    offline add: [45], sent 0
    refresh: Success(1)
    week: [android 45, sql 90]
RepositoryWithFakesTest > offlineAddThenRefresh PASSED
BUILD SUCCESSFUL in 10s
```

Sem Robolectric, sem servidor, sem arquivo de banco. O teste roda na JVM pura e confere o
comportamento com que a tela se importa: um add offline aparece e não é enviado, um refresh online
traz a sessão do servidor para o lado dela.

**Use os dois tipos, para perguntas diferentes.** O banco e o servidor de verdade respondem *o meu
SQL, o meu JSON e o meu mapeamento de erros funcionam*. Os fakes respondem *o código acima do
repositório se comporta*, rápido o bastante para rodar a cada mudança. Os quatro testes da aula,
juntos:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest 2>&1 | grep -E "PASSED|FAILED|^BUILD"
OfflineTest > theWeekSurvivesTheNetwork PASSED
RefreshTest > refreshesOnlyWhenStale PASSED
RepositoryWithFakesTest > offlineAddThenRefresh PASSED
WriteTest > theSessionIsThereBeforeTheServerIs PASSED
BUILD SUCCESSFUL in 19s
```
