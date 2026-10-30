---
title: One state for one screen
version: 1
---

**A screen's state is easiest to reason about when it is one value.** The week screen of the planner
shows a list of sessions, a total, how many are done, and a text field where the student types the
minutes of the next session. Four things, and the tempting way to hold them is four variables, each
changed by whichever piece of code got there first. Then the total is recomputed in one place and
forgotten in another, and the screen shows 90 minutes beside a list that adds up to 135.

The alternative is one immutable class that describes everything the screen draws, and one place
that makes new ones. That place is the **ViewModel**. Lesson 17 of `kotlin` wrote the same shape
with no base class, as `WeekModel`; here it extends `androidx.lifecycle.ViewModel`, and section 04
says what the base class buys.

The ViewModel and the function that connects it to Compose come from two `androidx.lifecycle`
libraries, so the module's build file gains two lines, and a third for the coroutine test tools
section 07 uses. The `testOptions` block also gains a `testLogging` that prints each test's name and
anything it prints, which the next sections read:

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

The planner's model is the same in every lesson that needs it:

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

And the screen's state and the class that owns it:

```schooling-example
{"language": "kotlin", "file": "app/src/main/java/com/example/planner/ui/WeekViewModel.kt", "parts": [{"code": "package com.example.planner.ui\n\nimport androidx.lifecycle.SavedStateHandle\nimport androidx.lifecycle.ViewModel\nimport com.example.planner.data.StudySession\nimport kotlinx.coroutines.flow.MutableStateFlow\nimport kotlinx.coroutines.flow.StateFlow\nimport kotlinx.coroutines.flow.asStateFlow\nimport kotlinx.coroutines.flow.update\nimport java.time.LocalDate"}, {"code": "data class WeekUiState(\n    val sessions: List<StudySession> = emptyList(),\n    val draftMinutes: String = \"\",\n) {\n    val totalMinutes: Int get() = sessions.sumOf { it.minutes }\n    val doneCount: Int get() = sessions.count { it.done }\n    val canAdd: Boolean get() = draftMinutes.toIntOrNull() in 5..240\n}", "note": "Everything the screen draws, in one immutable value. The total, the count and whether the button is enabled are computed from the rest, so they cannot disagree with it."}, {"code": "class WeekViewModel(private val saved: SavedStateHandle) : ViewModel() {\n    private val _state = MutableStateFlow(WeekUiState(draftMinutes = saved[DRAFT] ?: \"\"))\n    val state: StateFlow<WeekUiState> = _state.asStateFlow()\n    private var nextId = 1L", "note": "A private `MutableStateFlow` and a public read-only `StateFlow`: only this class can change the state. The `SavedStateHandle` is section 05's subject."}, {"code": "    fun onDraftChange(text: String) {\n        saved[DRAFT] = text\n        _state.update { it.copy(draftMinutes = text) }\n    }", "note": "Every change is a function named for what the student did, and each makes a new state with `copy`."}, {"code": "    fun onAdd(date: LocalDate) {\n        val minutes = _state.value.draftMinutes.toIntOrNull() ?: return\n        if (minutes !in 5..240) return\n        val session = StudySession(nextId++, \"android\", date, minutes)\n        saved[DRAFT] = \"\"\n        _state.update { it.copy(sessions = it.sessions + session, draftMinutes = \"\") }\n    }", "note": "The date is a parameter rather than a call to the clock, so a test can pass 26 October 2026 and get the same answer every time."}, {"code": "    fun onToggleDone(id: Long) = _state.update { s ->\n        s.copy(sessions = s.sessions.map { if (it.id == id) it.copy(done = !it.done) else it })\n    }\n\n    private companion object {\n        const val DRAFT = \"draft\"\n    }\n}", "note": "Marking a session done replaces one element of the list, and everything computed from the list follows."}]}
```

**`draftMinutes` is a `String`, not an `Int`.** It is what the student has typed so far, and `"4"` on
the way to `"45"` is a legitimate state of a text field that is not yet a valid duration. The
conversion happens once, in `canAdd` and `onAdd`, and the field never fights the keyboard.

Notice what the class does not contain: no `Context`, no `Activity`, no composable, nothing from
`android.view`. It is plain Kotlin over a `StateFlow`, which is why section 07 can test it with no
Android at all. Section 06 says why keeping it that way is a rule and not a taste.

The list itself is held here only for this lesson. **Sessions belong in a database**, which is
lesson 15, and a ViewModel that keeps them in memory loses them the moment the process ends; section
05 is about exactly that loss.
