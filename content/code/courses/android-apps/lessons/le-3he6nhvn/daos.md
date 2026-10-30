---
title: DAOs, and SQL the compiler reads
version: 1
---

**A DAO is an interface, and every method carries the SQL it runs.** You write the query; Room
writes the code that binds the parameters, runs it and turns each row into an entity. Two kinds of
method sit side by side: `suspend` functions for a write or a one-off read, which Room runs off the
main thread, and functions that return a `Flow`, which section 06 is about.

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

`@Upsert` inserts a course or replaces the one with the same id, which is what syncing a list from
the server needs. `@Insert` returns the id SQLite chose. `:courseId` and `:from` are parameters,
bound by name to the method's arguments, and `from` and `to` go through the converter of section 04
because they are `LocalDate`s. **`COALESCE(SUM(minutes), 0)`** is there because `SUM` over no rows
is `NULL` in SQL, and a week with no sessions should total zero.

The database hands out the two DAOs:

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

## A typo, found by the build

Misspell the table in one query, `session` for `sessions`, and build:

```
ana@vm:~/planner$ sed -i "s/FROM sessions WHERE course_id/FROM session WHERE course_id/" app/src/main/java/com/example/planner/data/Daos.kt
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E "^e: |^BUILD"
e: [ksp] /home/ana/planner/app/src/main/java/com/example/planner/data/Daos.kt:29: There is a problem with the query: [SQLITE_ERROR] SQL error or missing database (no such table: session)
e: [ksp] /home/ana/planner/app/src/main/java/com/example/planner/data/Daos.kt:29: Not sure how to convert the query result to this function's return type (kotlinx.coroutines.flow.Flow<kotlin.collections.List<com.example.planner.`data`.SessionEntity>>).
BUILD FAILED in 8s
ana@vm:~/planner$ sed -i "s/FROM session WHERE course_id/FROM sessions WHERE course_id/" app/src/main/java/com/example/planner/data/Daos.kt
```

**That is the reason Room exists.** With SQLite's own API the same typo compiles, ships, and throws
`no such table` on the phone of the first user who opens that screen. Room parsed every query
against the schema it built from the entities, and the build stopped with the query, the method and
the problem. The second error follows from the first: with no table, Room cannot work out what
the query returns. The `sed` at the end puts the `s` back.

## The DAO, used

A test builds the database in memory, the way every test of a database should start: fresh, empty,
and gone at the end.

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

The first insert got id 1, and `markDone` changed one row. The two sessions come back **in date
order**, the 26th first though it was inserted second, because the query says `ORDER BY date` and
the converter stored dates that sort. The last line is the foreign key of section 03 at work: there
is no course `rust`, and SQLite refused the row rather than storing a session nobody could reach.
