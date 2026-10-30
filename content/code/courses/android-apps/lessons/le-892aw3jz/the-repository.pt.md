---
title: O repositório, montado com as peças das aulas 14 e 15
version: 1
---

**O repositório precisa de um DAO e de uma API, e os dois já existem.** O projeto desta aula é o
esqueleto da aula 1 com as peças das aulas 14 e 15 trazidas, enxugadas ao que o repositório usa: uma
tabela de sessões em vez de duas, e o DTO de sessão com o seu serializador de data. Leia-as como
revisão; o código novo é o último arquivo.

O arquivo de build aplica os dois plugins e acrescenta Room, Retrofit e as bibliotecas de teste das
duas aulas:

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

O modelo, como em toda aula:

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

O lado local, a entidade da aula 15 com uma coluna nova, `synced`, e um DAO com as quatro consultas de
que o repositório precisa:

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

`synced` diz se o servidor tem esta linha. Linhas que vieram *do* servidor estão sincronizadas por
definição; uma linha que o usuário acrescentou no celular não está, até ser enviada. A seção 06 é para
o que serve a coluna.

O lado remoto, o DTO e a API da aula 14, com um `POST` acrescentado para sessões novas:

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

## O repositório

```schooling-example
{"language": "kotlin", "file": "app/src/main/java/com/example/planner/data/SessionRepository.kt", "parts": [{"code": "// app/src/main/java/com/example/planner/data/SessionRepository.kt\npackage com.example.planner.data\n\nimport java.io.IOException\nimport java.time.Duration\nimport java.time.Instant\nimport java.time.LocalDate\nimport kotlinx.coroutines.flow.Flow\nimport kotlinx.coroutines.flow.map\nimport retrofit2.HttpException"}, {"code": "class SessionRepository(\n    private val dao: SessionDao,\n    private val api: PlannerApi,\n    private val now: () -> Instant = Instant::now,\n    private val maxAge: Duration = Duration.ofMinutes(15),\n) {\n    private var lastRefresh: Instant? = null", "note": "Os dois colaboradores entram pelo construtor, e é isso que deixa um teste lhe dar um banco em memória e um servidor próprio. `now` é uma função, e não uma chamada ao relógio, pelo mesmo motivo: a seção 04 adianta o tempo sem esperar."}, {"code": "    fun week(monday: LocalDate): Flow<List<StudySession>> =\n        dao.between(monday, monday.plusDays(6))\n            .map { rows -> rows.map { it.toDomain() } }", "note": "A única leitura. Vem do Room, sempre, e chega como modelo: a tela nunca vê uma entidade nem um DTO."}, {"code": "    suspend fun refresh(): Result<Int> = try {\n        val sessions = api.sessions()\n        dao.upsertAll(sessions.map { it.toEntity() })\n        lastRefresh = now()\n        Result.success(sessions.size)\n    } catch (e: IOException) {\n        Result.failure(e)\n    } catch (e: HttpException) {\n        Result.failure(e)\n    }", "note": "A rede escreve no Room e conta como foi. Ela pega as duas falhas que uma rede tem, sem conexão e status de erro, e deixa qualquer outra coisa, um bug, quebrar alto. O `Result` avisa quem chamou sem lançar exceção, porque um refresh que falha é um acontecimento comum."}, {"code": "    suspend fun refreshIfStale(): Result<Int>? {\n        val last = lastRefresh\n        if (last != null && Duration.between(last, now()) < maxAge) return null\n        return refresh()\n    }", "note": "A política de cache da seção 04 em quatro linhas: atualizar quando nunca houve atualização, ou quando a última é mais velha que `maxAge`. `null` quer dizer \"não precisa\", que é diferente de falhou."}, {"code": "    suspend fun add(courseId: String, date: LocalDate, minutes: Int): Long {\n        val row = SessionEntity(courseId = courseId, date = date, minutes = minutes, synced = false)\n        val id = dao.insert(row)\n        try {\n            api.create(row.copy(id = id).toDto())\n            dao.markSynced(id)\n        } catch (e: IOException) {\n            // stays unsynced; section 06 says who sends it later\n        } catch (e: HttpException) {\n            // the same\n        }\n        return id\n    }\n}", "note": "Uma escrita vai primeiro para o Room, marcada como não sincronizada, então a tela a mostra na hora. Depois, uma tentativa de enviá-la. Uma falha deixa a linha não sincronizada e o trabalho do usuário no celular, que é o conteúdo inteiro da seção 06."}, {"code": "private fun SessionEntity.toDomain() = StudySession(id, courseId, date, minutes, done)"}]}
```

**Leia de cima para baixo e a regra da seção 02 aparece nos tipos.** `week()` devolve um `Flow` do
DAO e nada mais. `refresh()` e `add()` escrevem no DAO e devolvem o que aconteceu, nunca o dado em
si: o dado chega por `week()`, como todo o resto. Três seções testam as três coisas para que um
repositório serve: atualizar, falhar e escrever.
