---
title: A scope that ends with the screen
version: 1
---

**Every coroutine a ViewModel starts should end when the ViewModel does.** Lesson 15 of `kotlin`
made the rule general: no coroutine outlives the work it belongs to. On Android the work is a screen,
the screen's state lives in its ViewModel, and so the scope belongs to the ViewModel. That scope is
`viewModelScope`, and the base class cancels it in `onCleared()`, the moment section 04 of lesson
10 described: the activity destroyed for good, not by a rotation.

The wrong picture is `GlobalScope.launch` in a click handler, or a scope created in the activity.
The first runs until it finishes whatever happens to the screen; the second is cancelled on every
rotation, halfway through a write. `viewModelScope` does neither, because it lives exactly as long
as the ViewModel.

## Where the planner's sessions come from now

Lesson 10 kept the sessions in a list inside the ViewModel. They now come from a **store** that
exposes them as a `Flow` and writes with `suspend` functions. Lesson 15 makes it a Room database
and lesson 16 a repository; for this lesson an in-memory version is enough, and it is the shape that
matters:

```kotlin
// app/src/main/java/com/example/planner/data/SessionStore.kt
package com.example.planner.data

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update

interface SessionStore {
    fun sessions(): Flow<List<StudySession>>
    suspend fun add(session: StudySession)
    suspend fun toggleDone(id: Long)
}

class InMemorySessionStore : SessionStore {
    private val all = MutableStateFlow<List<StudySession>>(emptyList())

    /** How many collectors are listening right now; section 04 prints it. */
    val subscribers: StateFlow<Int> get() = all.subscriptionCount

    override fun sessions(): Flow<List<StudySession>> = all

    override suspend fun add(session: StudySession) = all.update { it + session }

    override suspend fun toggleDone(id: Long) = all.update { list ->
        list.map { if (it.id == id) it.copy(done = !it.done) else it }
    }
}

/** The one store the app uses until lesson 12 lets Hilt make it. */
object Stores {
    val sessions = InMemorySessionStore()
}
```

The same build file as lesson 10, with the lifecycle libraries and the coroutine test tools:

```kotlin
// app/build.gradle.kts
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
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
}
```

The model is lesson 10's, unchanged:

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

## A write that is cancelled with its screen

The ViewModel writes through `viewModelScope.launch`. To see what the scope buys, this test gives a
ViewModel a store that takes ten seconds to write, starts a write, and then clears the ViewModel the
way a finished activity does, through its `ViewModelStore`. The store says whether its write
completed:

```kotlin
// app/src/test/java/com/example/planner/ui/CancelTest.kt
package com.example.planner.ui

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.ViewModelStore
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.example.planner.data.InMemorySessionStore
import com.example.planner.data.SessionStore
import com.example.planner.data.StudySession
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Before
import org.junit.Test
import java.time.LocalDate

@OptIn(ExperimentalCoroutinesApi::class)
class CancelTest {
    private val dispatcher = StandardTestDispatcher()

    @Before fun mainIsATestDispatcher() = Dispatchers.setMain(dispatcher)
    @After fun mainIsRestored() = Dispatchers.resetMain()

    private class SlowStore(private val inner: SessionStore = InMemorySessionStore()) : SessionStore by inner {
        override suspend fun add(session: StudySession) {
            try {
                delay(10_000)
                inner.add(session)
                println("write completed")
            } catch (e: CancellationException) {
                println("write cancelled")
                throw e
            }
        }
    }

    @Test fun clearingTheViewModelCancelsItsWrite() = runTest(dispatcher) {
        val store = ViewModelStore()
        val factory = viewModelFactory { initializer { WeekViewModel(SlowStore(), SavedStateHandle()) } }
        val vm = ViewModelProvider.create(store, factory)[WeekViewModel::class]
        vm.onDraftChange("45")
        vm.onAdd(LocalDate.of(2026, 10, 26))
        advanceTimeBy(1_000)
        println("one second in, clearing the ViewModel")
        store.clear()
        advanceTimeBy(20_000)
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*CancelTest' 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)|PASSED|FAILED|^    [a-z]"
    one second in, clearing the ViewModel
    write cancelled
CancelTest > clearingTheViewModelCancelsItsWrite PASSED
BUILD SUCCESSFUL in 4s
30 actionable tasks: 11 executed, 19 up-to-date
```

**The write never finished, and nobody had to remember to stop it.** Clearing the store called
`onCleared()`, which cancelled `viewModelScope`, which cancelled the coroutine in the middle of its
`delay`; the `CancellationException` passed through the store's `catch` and was rethrown, as lesson
15 of `kotlin` says it must be. `advanceTimeBy` is section 07's subject: the test's ten seconds pass in
no time at all.

Cancelling a database write half-way is sometimes exactly wrong. A write the student expects to
survive the screen, a session they pressed **Add** for and then left, belongs to work that outlives
the ViewModel, and lesson 18 gives it to WorkManager.
