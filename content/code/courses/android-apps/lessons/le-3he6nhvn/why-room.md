---
title: A database on the phone, and what Room adds to it
version: 1
---

**Every Android phone carries SQLite, and Room is a layer over it that checks your SQL while the
app compiles.** SQLite is a whole relational database in one file, the engine that
`mobile-offline`, the course after this one, compares with the alternatives in its lesson 3. Android has offered it since its first release,
through an API where a query is a string and a mistake in it is found when that line runs, on a
phone, in front of a user. Room keeps SQLite and moves the mistakes to the build.

Room is three kinds of thing, each an annotation:

| | what it is | in the planner |
|---|---|---|
| **an entity** | a class that is a table, one row per object | `CourseEntity`, `SessionEntity` |
| **a DAO** | an interface of queries, with the SQL written on each method | `SessionDao` |
| **the database** | an abstract class listing the entities and handing out the DAOs | `PlannerDatabase` |

**KSP reads all three and writes the code that runs the SQL.** Section 05 shows a misspelt table
name failing the build, which is the whole reason to use Room rather than SQLite's own API.

## The build file

Room arrives as a Gradle plugin, a runtime and a compiler that runs on KSP. The plugin's one
setting, `schemaDirectory`, is where Room writes a JSON description of each version of the
database; section 07 needs those files, and the `sourceSets` line hands them to the tests. It names the
`debug` source set and not `test` because Robolectric reads the assets of the debug build; the
schemas therefore travel inside debug APKs, and never inside a release one. The
tests themselves run on Robolectric, because a Room database needs an Android `Context`:

```kotlin
// app/build.gradle.kts
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
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

    sourceSets {
        getByName("debug").assets.srcDir("$projectDir/schemas")
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

    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
    testImplementation(libs.coroutines.test)
    testImplementation(libs.room.testing)
}
```

The model is the one every lesson uses, and the database will hold it:

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

## Where the file lives

On a phone the database is one file in the app's private storage, under
`/data/data/com.example.planner/databases/`, readable by the app and by nobody else. **Not run:**
there is no phone here to look at it on; Android Studio's App Inspection shows the tables of a
running app, and `adb shell run-as com.example.planner` opens that directory on a debug build,
according to Google's documentation. The tests in this lesson use a database Room keeps in memory,
which is gone when the test ends, and section 07 one in a file that Robolectric places in a
temporary directory.
