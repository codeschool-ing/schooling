---
title: kotlinx.serialization, from the plugin to the first round trip
version: 1
---

**kotlinx.serialization is two things: a compiler plugin and a library.** The plugin reads every
class marked `@Serializable` and writes, inside the compiled class, the code that turns it into
JSON and back. The library holds `Json`, which drives that code. Leave out the plugin and the
annotation compiles to nothing, which is the first mistake people make with it.

This lesson's build file applies the plugin, and adds everything the lesson uses: the JSON
library, Moshi and the KSP plugin for section 06, and Retrofit and MockWebServer for section 07.
The `testOptions` block asks Gradle to print what a test writes to standard output, so each test
below can show you what it decoded:

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

## The DTO

The DTO has one property per key of the JSON, and the server's names where they differ from
Kotlin's:

```kotlin
// app/src/main/java/com/example/planner/data/SessionDto.kt
package com.example.planner.data

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SessionDto(
    val id: Long,
    @SerialName("course_id") val courseId: String,
    val date: String,
    val minutes: Int,
    val done: Boolean = false,
)
```

`@SerialName("course_id")` is the whole of the snake-case problem: the property is `courseId` in
Kotlin and `course_id` on the wire, in both directions. The date stays a `String` for now, and
section 05 is about why that is not good enough.

## A round trip

```kotlin
// app/src/test/java/com/example/planner/data/SessionJsonTest.kt
package com.example.planner.data

import kotlinx.serialization.json.Json
import org.junit.Test

class SessionJsonTest {
    private val text =
        """{"id": 7, "course_id": "android", "date": "2026-10-27", "minutes": 45, "done": false}"""

    @Test
    fun roundTrip() {
        val session = Json.decodeFromString<SessionDto>(text)
        println(session)
        println(Json.encodeToString(session))
    }
}
```

`decodeFromString<SessionDto>` reads the text into the class named between the angle brackets;
`encodeToString` writes it back. Run the project's unit tests:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest 2>&1 | grep -E "STANDARD_OUT|PASSED|FAILED|^    |^BUILD"
SessionJsonTest > roundTrip STANDARD_OUT
    SessionDto(id=7, courseId=android, date=2026-10-27, minutes=45, done=false)
    {"id":7,"course_id":"android","date":"2026-10-27","minutes":45}
SessionJsonTest > roundTrip PASSED
BUILD SUCCESSFUL in 8s
```

The first line is Kotlin's `toString()` of the decoded object, with `courseId` filled from
`course_id`. The second is the object written back as JSON, and **it is not the text that came
in**: the spaces are gone, and so is `"done": false`. kotlinx.serialization leaves out a property
whose value equals its default, unless `Json { encodeDefaults = true }` asks for it. A server that
treats a missing `done` as `false` will not notice; one that treats it as an error will, and the
setting is how you find out which one you have.

**Nothing here used reflection.** The plugin wrote a serializer into `SessionDto` when it compiled.
You can see it, as a nested class, in the compiled output:

```
ana@vm:~/planner$ find app/build/intermediates -name "SessionDto*.class" | sed "s|.*/classes/||" | sort
com/example/planner/data/SessionDto$$serializer.class
com/example/planner/data/SessionDto$Companion.class
com/example/planner/data/SessionDto.class
```

`SessionDto$$serializer` is the generated code that reads and writes each field. Its existence is
the whole difference between "annotated" and "serializable". Take the plugin out of the build file,
and the annotation still compiles, the test still compiles, and the run is where you find out:

```
ana@vm:~/planner$ sed -i "/kotlin.serialization/d" app/build.gradle.kts
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest 2>&1 | grep -E "PASSED|FAILED|Exception|^BUILD"
> Task :app:testDebugUnitTest FAILED
SessionJsonTest > roundTrip FAILED
    kotlinx.serialization.SerializationException at SessionJsonTest.kt:19
BUILD FAILED in 5s
ana@vm:~/planner$ grep -o "message=\"[^\"]*\"" app/build/test-results/testDebugUnitTest/*SessionJsonTest.xml
message="kotlinx.serialization.SerializationException: Serializer for class 'SessionDto' is not found.&#10;Please ensure that class is marked as '@Serializable' and that the serialization compiler plugin is applied.&#10;"
```

Gradle's summary names only the exception's class. The XML report it writes for every test class
keeps the message, with `&#10;` where the line breaks were, and the second command reads it from
there. **The message names the cause, and it arrives at run time.** Without the plugin, nothing wrote a
serializer into the class, and `decodeFromString` looks for one when it is called. In an app that
means a crash on the first screen that loads data, not a red line in the build. If you meet this
message, check the `plugins` block of the module the class lives in before anything else. Put the
line back and the test passes again.
