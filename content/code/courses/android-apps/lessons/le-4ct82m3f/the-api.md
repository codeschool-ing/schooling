---
title: The planner's API, as an interface
version: 1
---

**Retrofit turns an HTTP API into a Kotlin interface**: one function per endpoint, annotated with
the method and the path, and Retrofit writes the code that builds each request and reads each
response. OkHttp, underneath it, is what actually opens connections, sends bytes and keeps
connections for reuse. This lesson is about the line between the app and the network, and every
test in it runs against a server that runs inside the test.

## The contract

The planner's server, which lesson 16 connects to the database, answers three requests. This is
the whole contract, written the way a backend team would hand it over:

| request | answers |
|---|---|
| `GET /v1/courses` | `[{"id": "kotlin", "name": "Kotlin"}, …]` |
| `GET /v1/courses/{id}/sessions` | `[{"id": 1, "courseId": "android", "date": "2026-10-26", "minutes": 45, "done": true}, …]` |
| `POST /v1/courses/{id}/sessions` with `{"date": "2026-10-28", "minutes": 25}` | the session it created, with its new `id`, and status `201` |

Every request carries `Authorization: Bearer <token>`, and the server answers `401` without it. The
address is `https://api.example.com/v1/`, a domain reserved for documentation, so the app in this
lesson never reaches a real server. That is on purpose: section 03 replaces it with one the test owns.

## The interface, and the shapes it reads and writes

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

**The `Dto` classes are not the app's model.** A `SessionDto` is the shape of the JSON, with the date
as the string the server sends; `StudySession` from lesson 10 is the shape the app works with, with a
`LocalDate`. Keeping two shapes costs a small mapping function and buys the freedom to change either
side without touching the other: when the server renames a field, one class changes. Lesson 14 is
about turning that JSON into these classes, `@Serializable` included, and about the dates.

`suspend` on each function is what lets the ViewModel call it from `viewModelScope` as lesson 11 did:
Retrofit runs the call on OkHttp's own threads and resumes the coroutine with the result, so the main
thread never waits for the network.

## Building one

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

One `OkHttpClient` for the whole app, with its timeouts and three **interceptors**, and one Retrofit
built on it. Sections 05 and 06 take the timeouts and the interceptors apart; the parameters
`token` and `log` are there so that the app and a test can each say where the token comes from and
where the log goes. **`baseUrl` ends in a slash**, and the paths in the interface do not start with
one: Retrofit resolves `courses` against `https://api.example.com/v1/` as a browser resolves a
relative link, and a leading `/` would throw away the `v1/`.

The build file gains Retrofit, its converter, OkHttp, the logging interceptor, the serialization
library and its plugin, and MockWebServer for the tests. It also gains one test option,
`isReturnDefaultValues`, and the reason is OkHttp's. OkHttp 5 notices Android's classes on the
classpath and tries to log through `android.util.Log`, but in a plain JVM test those classes are
stubs that throw. OkHttp catches the throw and prints a warning, so without the option every test
of this lesson printed `Possibly running android unit test without robolectric` followed by
`java.lang.RuntimeException: Method isLoggable in android.util.Log not mocked`. Harmless, and noise
in every transcript; the option makes the stubs return zero, `false` or `null` instead of throwing:

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
