---
title: The repository, built from the pieces of lessons 14 and 15
version: 1
---

**The repository needs a DAO and an API, and both exist already.** This lesson's project is lesson
1's skeleton with the pieces of lessons 14 and 15 brought in, trimmed to what the repository uses:
one table of sessions instead of two, and the session DTO with its date serializer. Read them as a
recap; the new code is the last file.

The build file applies both plugins and adds Room, Retrofit and the test libraries of both lessons:

```kotlin
// app/build.gradle.kts
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.ksp)
    alias(libs.plugins.room)
}

android {
    namespace = "com.example.planner"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.example.planner"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0"
    }

    buildFeatures {
        compose = true
    }

    testOptions {
        unitTests.isIncludeAndroidResources = true
        unitTests.all {
            it.testLogging {
                events("passed", "failed")
                showStandardStreams = true
            }
        }
    }
}

room {
    schemaDirectory("$projectDir/schemas")
}

dependencies {
    implementation(libs.core.ktx)
    implementation(libs.activity.compose)
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.material3)
    implementation(libs.room.runtime)
    implementation(libs.room.ktx)
    ksp(libs.room.compiler)
    implementation(libs.serialization.json)
    implementation(libs.retrofit)
    implementation(libs.retrofit.kotlinx.serialization)

    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
    testImplementation(libs.coroutines.test)
    testImplementation(libs.okhttp.mockwebserver)
}
```

The model, as in every lesson:

```kotlin
// app/src/main/java/com/example/planner/data/Model.kt
package com.example.planner.data

import java.time.LocalDate

data class Course(val id: String, val name: String)

data class StudySession(
    val id: Long,
    val courseId: String,
    val date: LocalDate,
    val minutes: Int,
    val done: Boolean = false,
)
```

The local side, lesson 15's entity with one new column, `synced`, and a DAO with the four queries the
repository needs:

```kotlin
// app/src/main/java/com/example/planner/data/Local.kt
package com.example.planner.data

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Database
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.RoomDatabase
import androidx.room.TypeConverter
import androidx.room.TypeConverters
import androidx.room.Upsert
import java.time.LocalDate
import kotlinx.coroutines.flow.Flow

@Entity(tableName = "sessions")
data class SessionEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    @ColumnInfo(name = "course_id") val courseId: String,
    val date: LocalDate,
    val minutes: Int,
    val done: Boolean = false,
    val synced: Boolean = true,
)

class Converters {
    @TypeConverter fun dateToText(date: LocalDate): String = date.toString()
    @TypeConverter fun textToDate(text: String): LocalDate = LocalDate.parse(text)
}

@Dao
interface SessionDao {
    @Insert suspend fun insert(session: SessionEntity): Long
    @Upsert suspend fun upsertAll(sessions: List<SessionEntity>)

    @Query("SELECT * FROM sessions WHERE date BETWEEN :from AND :to ORDER BY date")
    fun between(from: LocalDate, to: LocalDate): Flow<List<SessionEntity>>

    @Query("SELECT * FROM sessions WHERE synced = 0")
    suspend fun unsynced(): List<SessionEntity>

    @Query("UPDATE sessions SET synced = 1 WHERE id = :id")
    suspend fun markSynced(id: Long)
}

@Database(entities = [SessionEntity::class], version = 1)
@TypeConverters(Converters::class)
abstract class PlannerDatabase : RoomDatabase() {
    abstract fun sessions(): SessionDao
}
```

`synced` says whether the server has this row. Rows that came *from* the server are synced by
definition; a row the user added on the phone is not, until it has been sent. Section 06 is what the
column is for.

The remote side, lesson 14's DTO and API, with a `POST` added for new sessions:

```kotlin
// app/src/main/java/com/example/planner/data/Remote.kt
package com.example.planner.data

import java.time.LocalDate
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import retrofit2.Retrofit
import retrofit2.converter.kotlinx.serialization.asConverterFactory
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST

object LocalDateSerializer : KSerializer<LocalDate> {
    override val descriptor = PrimitiveSerialDescriptor("java.time.LocalDate", PrimitiveKind.STRING)
    override fun serialize(encoder: Encoder, value: LocalDate) = encoder.encodeString(value.toString())
    override fun deserialize(decoder: Decoder): LocalDate = LocalDate.parse(decoder.decodeString())
}

@Serializable
data class SessionDto(
    val id: Long,
    @SerialName("course_id") val courseId: String,
    @Serializable(with = LocalDateSerializer::class) val date: LocalDate,
    val minutes: Int,
    val done: Boolean = false,
)

interface PlannerApi {
    @GET("sessions") suspend fun sessions(): List<SessionDto>
    @POST("sessions") suspend fun create(@Body session: SessionDto): SessionDto
}

val plannerJson = Json { ignoreUnknownKeys = true }

fun plannerApi(baseUrl: String): PlannerApi = Retrofit.Builder()
    .baseUrl(baseUrl)
    .addConverterFactory(plannerJson.asConverterFactory("application/json".toMediaType()))
    .build()
    .create(PlannerApi::class.java)

fun SessionDto.toEntity() = SessionEntity(id, courseId, date, minutes, done, synced = true)
fun SessionEntity.toDto() = SessionDto(id, courseId, date, minutes, done)
```

## The repository

```schooling-example
{"language": "kotlin", "file": "app/src/main/java/com/example/planner/data/SessionRepository.kt", "parts": [{"code": "// app/src/main/java/com/example/planner/data/SessionRepository.kt\npackage com.example.planner.data\n\nimport java.io.IOException\nimport java.time.Duration\nimport java.time.Instant\nimport java.time.LocalDate\nimport kotlinx.coroutines.flow.Flow\nimport kotlinx.coroutines.flow.map\nimport retrofit2.HttpException"}, {"code": "class SessionRepository(\n    private val dao: SessionDao,\n    private val api: PlannerApi,\n    private val now: () -> Instant = Instant::now,\n    private val maxAge: Duration = Duration.ofMinutes(15),\n) {\n    private var lastRefresh: Instant? = null", "note": "Its two collaborators come in through the constructor, which is what lets a test hand it an in-memory database and a server of its own. `now` is a function rather than a call to the clock, for the same reason: section 04 moves time forward without waiting."}, {"code": "    fun week(monday: LocalDate): Flow<List<StudySession>> =\n        dao.between(monday, monday.plusDays(6))\n            .map { rows -> rows.map { it.toDomain() } }", "note": "The only read. It comes from Room, always, and arrives as the model: the screen never sees an entity or a DTO."}, {"code": "    suspend fun refresh(): Result<Int> = try {\n        val sessions = api.sessions()\n        dao.upsertAll(sessions.map { it.toEntity() })\n        lastRefresh = now()\n        Result.success(sessions.size)\n    } catch (e: IOException) {\n        Result.failure(e)\n    } catch (e: HttpException) {\n        Result.failure(e)\n    }", "note": "The network writes into Room and reports how it went. It catches the two failures a network has, no connection and an error status, and lets anything else, a bug, crash loudly. `Result` tells the caller without throwing, because a failed refresh is an ordinary event."}, {"code": "    suspend fun refreshIfStale(): Result<Int>? {\n        val last = lastRefresh\n        if (last != null && Duration.between(last, now()) < maxAge) return null\n        return refresh()\n    }", "note": "The cache policy of section 04 in four lines: refresh when there has never been one, or when the last is older than `maxAge`. `null` means \"not needed\", which is different from failed."}, {"code": "    suspend fun add(courseId: String, date: LocalDate, minutes: Int): Long {\n        val row = SessionEntity(courseId = courseId, date = date, minutes = minutes, synced = false)\n        val id = dao.insert(row)\n        try {\n            api.create(row.copy(id = id).toDto())\n            dao.markSynced(id)\n        } catch (e: IOException) {\n            // stays unsynced; section 06 says who sends it later\n        } catch (e: HttpException) {\n            // the same\n        }\n        return id\n    }\n}", "note": "A write goes to Room first, marked unsynced, so the screen shows it at once. Then one attempt to send it. A failure leaves the row unsynced and the user's work on the phone, which is the whole of section 06."}, {"code": "private fun SessionEntity.toDomain() = StudySession(id, courseId, date, minutes, done)"}]}
```

**Read it top to bottom and the rule of section 02 is visible in the types.** `week()` returns a
`Flow` from the DAO and nothing else. `refresh()` and `add()` write to the DAO and return what
happened, never the data itself: the data arrives through `week()`, like everything else. Three
sections test the three things a repository is for: refreshing, failing, and writing.
