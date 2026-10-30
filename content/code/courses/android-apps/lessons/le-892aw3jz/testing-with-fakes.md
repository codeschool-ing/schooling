---
title: Testing the repository with fakes
version: 1
---

**The tests so far ran a real database and a real HTTP server, and that is right for a repository's
own tests.** They proved the SQL, the JSON and the error mapping together. But the ViewModel above
the repository, and any code that only needs "some sessions" or "a network that fails", should not
pay for Robolectric and a server to find out. For that code, the repository's collaborators are
replaced with **fakes**: small, honest implementations of the same interface, kept in memory.

A fake is not a mock. A mock records which methods were called and is told what to return; a fake
*works*, with a tiny implementation you can read in full. `SessionDao` and `PlannerApi` are
interfaces, which is what makes a fake possible:

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

**`FakeSessionDao` keeps a `MutableStateFlow` of rows**, so `between()` answers again after every
write, the property section 06 of lesson 15 measured in Room. That is the part of a fake people get
wrong: a fake DAO that returned a plain list once would make every test of a screen pass while the
real screen updated and the fake one did not.

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

No Robolectric, no server, no database file. The test runs on the plain JVM and checks the
behaviour the screen cares about: an add while offline shows up and is not sent, a refresh while
online brings the server's session in beside it.

**Use both kinds, for different questions.** The real database and the real server answer *does my
SQL, my JSON and my error mapping work*. The fakes answer *does the code above the repository
behave*, quickly enough to run on every change. The lesson's four tests, together:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest 2>&1 | grep -E "PASSED|FAILED|^BUILD"
OfflineTest > theWeekSurvivesTheNetwork PASSED
RefreshTest > refreshesOnlyWhenStale PASSED
RepositoryWithFakesTest > offlineAddThenRefresh PASSED
WriteTest > theSessionIsThereBeforeTheServerIs PASSED
BUILD SUCCESSFUL in 19s
```
