---
title: DAOs, e um SQL que o compilador lê
version: 1
---

**Um DAO é uma interface, e cada método traz o SQL que roda.** Você escreve a consulta; o Room
escreve o código que liga os parâmetros, a executa e transforma cada linha numa entidade. Dois tipos
de método convivem: funções `suspend` para uma escrita ou uma leitura avulsa, que o Room roda fora
da thread principal, e funções que devolvem um `Flow`, que são o assunto da seção 06.

```kotlin
// app/src/main/java/com/example/planner/data/Daos.kt
package com.example.planner.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Upsert
import java.time.LocalDate
import kotlinx.coroutines.flow.Flow

@Dao
interface CourseDao {
    @Upsert
    suspend fun upsert(courses: List<CourseEntity>)

    @Query("SELECT * FROM courses ORDER BY name")
    fun all(): Flow<List<CourseEntity>>
}

@Dao
interface SessionDao {
    @Insert
    suspend fun insert(session: SessionEntity): Long

    @Query("UPDATE sessions SET done = 1 WHERE id = :id")
    suspend fun markDone(id: Long): Int

    @Query("SELECT * FROM sessions WHERE course_id = :courseId ORDER BY date")
    fun forCourse(courseId: String): Flow<List<SessionEntity>>

    @Query("SELECT COALESCE(SUM(minutes), 0) FROM sessions WHERE date BETWEEN :from AND :to")
    fun minutesBetween(from: LocalDate, to: LocalDate): Flow<Int>
}
```

`@Upsert` insere um curso ou substitui o que tiver o mesmo id, que é o que sincronizar uma lista do
servidor precisa. `@Insert` devolve o id que o SQLite escolheu. `:courseId` e `:from` são
parâmetros, ligados pelo nome aos argumentos do método, e `from` e `to` passam pelo conversor da
seção 04 porque são `LocalDate`s. **`COALESCE(SUM(minutes), 0)`** está ali porque `SUM` sobre nenhuma
linha é `NULL` em SQL, e uma semana sem sessões deveria somar zero.

O banco entrega os dois DAOs:

```kotlin
// app/src/main/java/com/example/planner/data/PlannerDatabase.kt
package com.example.planner.data

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters

@Database(entities = [CourseEntity::class, SessionEntity::class], version = 1)
@TypeConverters(Converters::class)
abstract class PlannerDatabase : RoomDatabase() {
    abstract fun courses(): CourseDao
    abstract fun sessions(): SessionDao
}
```

## Um erro de digitação, encontrado pelo build

Escreva a tabela errado numa consulta, `session` em vez de `sessions`, e compile:

```
ana@vm:~/planner$ sed -i "s/FROM sessions WHERE course_id/FROM session WHERE course_id/" app/src/main/java/com/example/planner/data/Daos.kt
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E "^e: |^BUILD"
e: [ksp] /home/ana/planner/app/src/main/java/com/example/planner/data/Daos.kt:29: There is a problem with the query: [SQLITE_ERROR] SQL error or missing database (no such table: session)
e: [ksp] /home/ana/planner/app/src/main/java/com/example/planner/data/Daos.kt:29: Not sure how to convert the query result to this function's return type (kotlinx.coroutines.flow.Flow<kotlin.collections.List<com.example.planner.`data`.SessionEntity>>).
BUILD FAILED in 8s
ana@vm:~/planner$ sed -i "s/FROM session WHERE course_id/FROM sessions WHERE course_id/" app/src/main/java/com/example/planner/data/Daos.kt
```

**É para isso que o Room existe.** Com a API do próprio SQLite o mesmo erro compila, é publicado e
lança `no such table` no celular do primeiro usuário que abrir aquela tela. O Room analisou cada
consulta contra o schema que montou a partir das entidades, e o build parou com a consulta, o método
e o problema. O segundo erro decorre do primeiro: sem tabela, o Room não consegue saber o que a
consulta devolve. O `sed` do fim devolve o `s`.

## O DAO em uso

Um teste monta o banco na memória, que é como todo teste de banco deveria começar: novo, vazio e
descartado no fim.

```kotlin
// app/src/test/java/com/example/planner/data/DaoTest.kt
package com.example.planner.data

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import java.time.LocalDate
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class DaoTest {
    private val db = Room.inMemoryDatabaseBuilder(
        ApplicationProvider.getApplicationContext<Context>(),
        PlannerDatabase::class.java,
    ).build()

    @After fun close() = db.close()

    @Test
    fun insertReadAndRefuse(): Unit = runBlocking {
        db.courses().upsert(listOf(CourseEntity("android", "Android Apps"), CourseEntity("sql", "SQL Databases")))
        val id = db.sessions().insert(SessionEntity(courseId = "android", date = LocalDate.of(2026, 10, 27), minutes = 45))
        db.sessions().insert(SessionEntity(courseId = "android", date = LocalDate.of(2026, 10, 26), minutes = 25))
        println("new id: $id, rows changed: ${db.sessions().markDone(id)}")
        db.sessions().forCourse("android").first().forEach { println(it.toDomain()) }
        try {
            db.sessions().insert(SessionEntity(courseId = "rust", date = LocalDate.of(2026, 10, 28), minutes = 50))
        } catch (e: Exception) {
            println("${e::class.simpleName}: ${e.message}")
        }
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*DaoTest" 2>&1 | grep -E "^    |PASSED|FAILED|^BUILD"
    new id: 1, rows changed: 1
    StudySession(id=2, courseId=android, date=2026-10-26, minutes=25, done=false)
    StudySession(id=1, courseId=android, date=2026-10-27, minutes=45, done=true)
    SQLiteConstraintException: FOREIGN KEY constraint failed (code 787 SQLITE_CONSTRAINT_FOREIGNKEY)
DaoTest > insertReadAndRefuse PASSED
BUILD SUCCESSFUL in 32s
```

O primeiro insert recebeu o id 1, e o `markDone` mudou uma linha. As duas sessões voltam **em ordem
de data**, a do dia 26 primeiro embora tenha sido inserida depois, porque a consulta diz
`ORDER BY date` e o conversor guardou datas que se ordenam. A última linha é a chave estrangeira da
seção 03 trabalhando: não existe curso `rust`, e o SQLite recusou a linha em vez de guardar uma
sessão que ninguém conseguiria alcançar.
