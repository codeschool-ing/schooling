---
title: The converter, where Retrofit meets the JSON library
version: 1
---

**Retrofit does not read JSON; it hands the response body to a converter.** Lesson 13 built the
interface and the client. A converter is the object that turns the body's bytes into the return
type of each method, and the one for kotlinx.serialization is made from the `plannerJson` of section
04, so every rule set there applies to every response.

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

`List<SessionDto>` is enough for the converter to know what to read: the plugin generated a
serializer for `SessionDto`, and the library builds one for a list of them.

A test needs a server, and **MockWebServer** is one: a real HTTP server inside the test, which
answers with whatever you queue. This one sends a body the way tomorrow's server might, with a key
this app has never seen:

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

The test passes, and Gradle prints a long stack trace on the way; the `grep` keeps its first two
lines:

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

**A unit test runs against a stub of Android, and every stub method throws.** These tests run on
your computer's JVM with an `android.jar` whose methods exist only so the code compiles: call one and
it throws `RuntimeException`, "not mocked". OkHttp checks whether it is on Android when it starts,
finds Android's classes on the classpath, and calls `Log.isLoggable`. It survives the exception,
which is why the test passed, and prints it, which is why you are reading it. Robolectric would
answer the call properly, and makes every test class start more slowly. For tests that only touch Android by
accident, one line in `testOptions` makes every stub return zero, `false` or `null` instead:

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

Two sessions, the second with a `room` the app ignores because `plannerJson` says to, both turned
into `StudySession` with real dates by the time a screen would see them. The week's total, 135
minutes with one session done, is computed from the model and not from the JSON. The last line is
what the server received: the path `/sessions`, from the `@GET` of the interface.

With the line in place the trace is gone, and the lesson's seven tests pass together:

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

**Not run:** this lesson never calls the planner's real server, which does not exist yet; lesson 16
puts the network and the database behind one repository, and the requests there go to the same
MockWebServer.
