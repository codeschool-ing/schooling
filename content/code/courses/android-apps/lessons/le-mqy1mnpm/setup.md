---
title: Hilt in the build, the application and the activity
version: 1
---

**Hilt needs four things before it can build anything: two plugins, an `Application` that says
"the graph starts here", the manifest naming that `Application`, and an activity that says "inject
into me".** Each is a line or two, and leaving any of them out produces a message that names it.

The module's build file applies the KSP and Hilt plugins, whose versions lesson 1's catalogue
already pins, and adds Hilt's runtime, its compiler for KSP, Hilt's `hiltViewModel()` for Compose,
and its test library with the same compiler for tests:

```kotlin
// app/build.gradle.kts
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.ksp)
    alias(libs.plugins.hilt)
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
    implementation(libs.lifecycle.viewmodel.compose)
    implementation(libs.lifecycle.runtime.compose)
    implementation(libs.hilt.android)
    implementation(libs.hilt.lifecycle.viewmodel.compose)
    ksp(libs.hilt.compiler)
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
    testImplementation(libs.hilt.android.testing)
    kspTest(libs.hilt.compiler)
}
```

`ksp(libs.hilt.compiler)` is the line that does the work. **KSP**, the Kotlin Symbol Processor, runs
the Hilt compiler over your annotations during the build, and the compiler writes Java source that
becomes part of the app; section 05 opens some of it. `kspTest` runs it again over the test sources,
which have annotations of their own in section 07.

The application class is one annotation on an otherwise empty class:

```kotlin
// app/src/main/java/com/example/planner/PlannerApp.kt
package com.example.planner

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class PlannerApp : Application()
```

and the manifest names it in `android:name`, so that Android creates this class when the process
starts, before any activity:

```xml
<!-- app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <application
        android:name=".PlannerApp"
        android:label="@string/app_name"
        android:theme="@android:style/Theme.Material.Light.NoActionBar">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
```

`@HiltAndroidApp` makes Hilt generate the **singleton component**, the object that holds everything
that lives as long as the app. The activity is marked `@AndroidEntryPoint`, which lets Hilt give it,
and the ViewModels its screens ask for, what they need:

```kotlin
// app/src/main/java/com/example/planner/MainActivity.kt
package com.example.planner

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import com.example.planner.ui.WeekRoute
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                WeekRoute()
            }
        }
    }
}
```

The model is lesson 10's, and the store lesson 11's, with two annotations and no `object Stores`:

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

```kotlin
// app/src/main/java/com/example/planner/data/SessionStore.kt
package com.example.planner.data

import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update

interface SessionStore {
    fun sessions(): Flow<List<StudySession>>
    suspend fun add(session: StudySession)
    suspend fun toggleDone(id: Long)
}

@Singleton
class InMemorySessionStore @Inject constructor() : SessionStore {
    private val all = MutableStateFlow<List<StudySession>>(emptyList())

    override fun sessions(): Flow<List<StudySession>> = all

    override suspend fun add(session: StudySession) = all.update { it + session }

    override suspend fun toggleDone(id: Long) = all.update { list ->
        list.map { if (it.id == id) it.copy(done = !it.done) else it }
    }
}
```

**`@Inject constructor()` tells Hilt how to build the class, and `@Singleton` how many to build.**
One per app is what the planner needs: every screen that asks for the store must see the same
sessions. Without `@Singleton`, each request would get a new, empty store, which is the bug the
hand-written container in section 02 could also make, now visible as one annotation.
