---
title: A API do planner, como uma interface
version: 1
---

**O Retrofit transforma uma API HTTP numa interface Kotlin**: uma função por endpoint, anotada com o
método e o caminho, e o Retrofit escreve o código que monta cada requisição e lê cada resposta. O
OkHttp, por baixo dele, é quem de fato abre conexões, envia bytes e guarda conexões para reuso. Esta
aula é sobre a linha entre o app e a rede, e todo teste dela roda contra um servidor que roda dentro
do teste.

## O contrato

O servidor do planner, que a aula 16 liga ao banco de dados, responde a três requisições. Este é o
contrato inteiro, escrito como uma equipe de backend o entregaria:

| requisição | responde |
|---|---|
| `GET /v1/courses` | `[{"id": "kotlin", "name": "Kotlin"}, …]` |
| `GET /v1/courses/{id}/sessions` | `[{"id": 1, "courseId": "android", "date": "2026-10-26", "minutes": 45, "done": true}, …]` |
| `POST /v1/courses/{id}/sessions` com `{"date": "2026-10-28", "minutes": 25}` | a sessão que criou, com o `id` novo, e status `201` |

Toda requisição leva `Authorization: Bearer <token>`, e o servidor responde `401` sem ele. O endereço é
`https://api.example.com/v1/`, um domínio reservado para documentação, então o app desta aula nunca
alcança um servidor real. É de propósito: a seção 03 o troca por um que pertence ao teste.

## A interface, e as formas que ela lê e escreve

```kotlin
// app/src/main/java/com/example/planner/data/remote/PlannerApi.kt
package com.example.planner.data.remote

import kotlinx.serialization.Serializable
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Path

@Serializable
data class CourseDto(val id: String, val name: String)

@Serializable
data class SessionDto(
    val id: Long,
    val courseId: String,
    val date: String,
    val minutes: Int,
    val done: Boolean = false,
)

@Serializable
data class NewSessionDto(val date: String, val minutes: Int)

interface PlannerApi {
    @GET("courses")
    suspend fun courses(): List<CourseDto>

    @GET("courses/{id}/sessions")
    suspend fun sessions(@Path("id") courseId: String): List<SessionDto>

    @POST("courses/{id}/sessions")
    suspend fun addSession(@Path("id") courseId: String, @Body session: NewSessionDto): SessionDto
}
```

**As classes `Dto` não são o modelo do app.** Um `SessionDto` é a forma do JSON, com a data como a
string que o servidor manda; o `StudySession` da aula 10 é a forma com que o app trabalha, com um
`LocalDate`. Manter duas formas custa uma pequena função de conversão e compra a liberdade de mudar
um lado sem tocar no outro: quando o servidor renomeia um campo, uma classe muda. A aula 14 trata de
transformar esse JSON nestas classes, o `@Serializable` incluído, e das datas.

O `suspend` em cada função é o que deixa o ViewModel chamá-la do `viewModelScope`, como a aula 11
fez: o Retrofit roda a chamada nas threads do próprio OkHttp e retoma a corrotina com o resultado,
então a thread principal nunca espera pela rede.

## Construindo um

```kotlin
// app/src/main/java/com/example/planner/data/remote/Network.kt
package com.example.planner.data.remote

import java.util.concurrent.TimeUnit
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.kotlinx.serialization.asConverterFactory
import retrofit2.create

object Network {
    const val BASE_URL = "https://api.example.com/v1/"

    fun client(token: () -> String?, log: (String) -> Unit = {}): OkHttpClient =
        OkHttpClient.Builder()
            .connectTimeout(10, TimeUnit.SECONDS)
            .readTimeout(10, TimeUnit.SECONDS)
            .callTimeout(30, TimeUnit.SECONDS)
            .addInterceptor(AuthInterceptor(token))
            .addInterceptor(RetryInterceptor(maxAttempts = 3))
            .addInterceptor(
                HttpLoggingInterceptor(log).apply {
                    level = HttpLoggingInterceptor.Level.HEADERS
                    redactHeader("Authorization")
                },
            )
            .build()

    fun api(client: OkHttpClient, baseUrl: String = BASE_URL): PlannerApi =
        Retrofit.Builder()
            .baseUrl(baseUrl)
            .client(client)
            .addConverterFactory(Json.asConverterFactory("application/json".toMediaType()))
            .build()
            .create()
}
```

Um `OkHttpClient` para o app inteiro, com seus tempos-limite e três **interceptors**, e um Retrofit
construído sobre ele. As seções 05 e 06 desmontam os tempos-limite e os interceptors; os parâmetros
`token` e `log` existem para que o app e um teste digam, cada um, de onde vem o token e para onde vai
o log. **`baseUrl` termina com barra**, e os caminhos da interface não começam com uma: o Retrofit
resolve `courses` contra `https://api.example.com/v1/` como um navegador resolve um link relativo, e
uma `/` no começo jogaria fora o `v1/`.

O arquivo de build ganha o Retrofit, o conversor dele, o OkHttp, o interceptor de log, a biblioteca de
serialização e o plugin dela, e o MockWebServer para os testes. Ganha também uma opção de teste,
`isReturnDefaultValues`, e o motivo é do OkHttp. O OkHttp 5 percebe as classes do Android no
classpath e tenta registrar mensagens pelo `android.util.Log`, mas num teste comum na JVM essas
classes são stubs que lançam exceção. O OkHttp captura a exceção e imprime um aviso, então sem a
opção todo teste desta aula imprimia `Possibly running android unit test without robolectric`
seguido de `java.lang.RuntimeException: Method isLoggable in android.util.Log not mocked`.
Inofensivo, e ruído em toda transcrição; a opção faz os stubs devolverem zero, `false` ou `null` em
vez de lançar:

```kotlin
// app/build.gradle.kts
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.roborazzi)
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
    implementation(libs.compose.ui.tooling.preview)
    implementation(libs.retrofit)
    implementation(libs.retrofit.kotlinx.serialization)
    implementation(libs.okhttp)
    implementation(libs.okhttp.logging)
    implementation(libs.serialization.json)
    debugImplementation(libs.compose.ui.tooling)
    debugImplementation(libs.compose.ui.test.manifest)

    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
    testImplementation(platform(libs.compose.bom))
    testImplementation(libs.compose.ui.test.junit4)
    testImplementation(libs.roborazzi)
    testImplementation(libs.roborazzi.compose)
    testImplementation(libs.coroutines.test)
    testImplementation(libs.okhttp.mockwebserver)
}
```
