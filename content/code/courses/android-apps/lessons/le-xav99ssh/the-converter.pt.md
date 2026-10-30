---
title: O conversor, onde o Retrofit encontra a biblioteca de JSON
version: 1
---

**O Retrofit não lê JSON; ele entrega o corpo da resposta a um conversor.** A aula 13 montou a
interface e o cliente. Um conversor é o objeto que transforma os bytes do corpo no tipo de retorno de
cada método, e o da kotlinx.serialization é feito a partir do `plannerJson` da seção 04, então toda
regra definida ali vale para toda resposta.

```kotlin
// app/src/main/java/com/example/planner/data/PlannerApi.kt
package com.example.planner.data

import okhttp3.MediaType.Companion.toMediaType
import retrofit2.Retrofit
import retrofit2.converter.kotlinx.serialization.asConverterFactory
import retrofit2.http.GET

interface PlannerApi {
    @GET("sessions")
    suspend fun sessions(): List<SessionDto>
}

fun plannerApi(baseUrl: String): PlannerApi = Retrofit.Builder()
    .baseUrl(baseUrl)
    .addConverterFactory(plannerJson.asConverterFactory("application/json".toMediaType()))
    .build()
    .create(PlannerApi::class.java)
```

`List<SessionDto>` basta para o conversor saber o que ler: o plugin gerou um serializador para
`SessionDto`, e a biblioteca monta um para uma lista deles.

Um teste precisa de um servidor, e o **MockWebServer** é um: um servidor HTTP de verdade dentro do
teste, que responde com o que você enfileirar. Este manda um corpo como o servidor de amanhã poderia
mandar, com uma chave que este app nunca viu:

```kotlin
// app/src/test/java/com/example/planner/data/PlannerApiTest.kt
package com.example.planner.data

import kotlinx.coroutines.test.runTest
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import org.junit.Test

class PlannerApiTest {
    @Test
    fun readsTheWeek() = runTest {
        val server = MockWebServer()
        server.enqueue(
            MockResponse.Builder()
                .addHeader("Content-Type", "application/json")
                .body(
                    """[
                      {"id": 7, "course_id": "android", "date": "2026-10-27", "minutes": 45},
                      {"id": 8, "course_id": "sql", "date": "2026-10-29", "minutes": 90,
                       "done": true, "room": "B2"}
                    ]""",
                )
                .build(),
        )
        server.start()
        val week = plannerApi(server.url("/").toString()).sessions().map { it.toDomain() }
        week.forEach(::println)
        println("total ${week.sumOf { it.minutes }} min, done ${week.count { it.done }}")
        println("request: ${server.takeRequest().target}")
        server.close()
    }
}
```

O teste passa, e o Gradle imprime um longo stack trace no caminho; o `grep` guarda as duas primeiras
linhas dele:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*PlannerApiTest" 2>&1 | grep -E "^    [a-zA-Z]|PASSED|FAILED|^BUILD"
    Possibly running android unit test without robolectric
    java.lang.RuntimeException: Method isLoggable in android.util.Log not mocked. See https://developer.android.com/r/studio-ui/build/not-mocked for details.
    StudySession(id=7, courseId=android, date=2026-10-27, minutes=45, done=false)
    StudySession(id=8, courseId=sql, date=2026-10-29, minutes=90, done=true)
    total 135 min, done 1
    request: /sessions
PlannerApiTest > readsTheWeek PASSED
BUILD SUCCESSFUL in 6s
```

**Um teste de unidade roda contra um esboço do Android, e todo método do esboço lança exceção.**
Estes testes rodam na JVM do seu computador com um `android.jar` cujos métodos existem só para o
código compilar: chame um e ele lança `RuntimeException`, "not mocked". O OkHttp confere se está no
Android quando começa, encontra as classes do Android no classpath e chama `Log.isLoggable`. Ele
sobrevive à exceção, e por isso o teste passou, e a imprime, e por isso você a está lendo. O
Robolectric responderia a chamada direito, e faz toda classe de teste começar mais devagar. Para
testes que só tocam o Android por acidente, uma linha em `testOptions` faz todo esboço devolver zero,
`false` ou `null` em vez disso:

```kotlin
// app/build.gradle.kts
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.ksp)
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
        unitTests.isReturnDefaultValues = true
        unitTests.all {
            it.testLogging {
                events("passed", "failed")
                showStandardStreams = true
            }
        }
    }
}

dependencies {
    implementation(libs.core.ktx)
    implementation(libs.activity.compose)
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.material3)
    implementation(libs.serialization.json)
    implementation(libs.moshi)
    ksp(libs.moshi.codegen)
    implementation(libs.retrofit)
    implementation(libs.retrofit.kotlinx.serialization)

    testImplementation(libs.junit)
    testImplementation(libs.coroutines.test)
    testImplementation(libs.okhttp.mockwebserver)
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*PlannerApiTest" 2>&1 | grep -E "^    |PASSED|FAILED|^BUILD"
    StudySession(id=7, courseId=android, date=2026-10-27, minutes=45, done=false)
    StudySession(id=8, courseId=sql, date=2026-10-29, minutes=90, done=true)
    total 135 min, done 1
    request: /sessions
PlannerApiTest > readsTheWeek PASSED
BUILD SUCCESSFUL in 9s
```

Duas sessões, a segunda com um `room` que o app ignora porque o `plannerJson` manda, as duas
transformadas em `StudySession` com datas de verdade antes de qualquer tela vê-las. O total da
semana, 135 minutos com uma sessão feita, é calculado a partir do modelo e não do JSON. A última
linha é o que o servidor recebeu: o caminho `/sessions`, do `@GET` da interface.

Com a linha no lugar o trace some, e os sete testes da aula passam juntos:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest 2>&1 | grep -E "PASSED|FAILED|^BUILD"
DatesTest > aDateIsADate PASSED
MoshiTest > theSameFourPayloads PASSED
PlannerApiTest > readsTheWeek PASSED
ServerChangesTest > strict PASSED
ServerChangesTest > lenient PASSED
ServerChangesTest > coerced PASSED
SessionJsonTest > roundTrip PASSED
BUILD SUCCESSFUL in 5s
```

**Não executado:** esta aula nunca chama o servidor real do planner, que ainda não existe; a aula 16
põe a rede e o banco atrás de um repositório único, e as requisições ali vão para o mesmo
MockWebServer.
