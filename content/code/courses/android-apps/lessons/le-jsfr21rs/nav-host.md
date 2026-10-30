---
title: A NavHost, three routes and one controller
version: 1
---

**An app with one activity still has many screens**, and something has to know which one is
showing, which came before it, and what the back button should do. In Compose that something is a
`NavHostController`, and the screens it moves between are declared in a `NavHost`. Lesson 2 argued
for one activity per app; this lesson is what fills it.

The planner has three screens so far: the list of courses, one course, and a form for adding a
session to that course. Each is a **route**, and since version 2.8 of Navigation Compose a route
can be a Kotlin type rather than a string:

```kotlin
// app/src/main/java/com/example/planner/Routes.kt
package com.example.planner

import kotlinx.serialization.Serializable

@Serializable
object Courses

@Serializable
data class CourseDetail(val courseId: String)

@Serializable
data class AddSession(val courseId: String)
```

`Courses` takes nothing, so it is an `object`. `CourseDetail` and `AddSession` need to know which
course, so they are data classes with a `courseId`. **`@Serializable` is what lets Navigation turn
a route into the string it stores and back**, and that annotation needs the Kotlin serialization
plugin, which is the first change to the module's build file since lesson 1:

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
    }
}

dependencies {
    implementation(libs.core.ktx)
    implementation(libs.activity.compose)
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.material3)
    implementation(libs.compose.ui.tooling.preview)
    implementation(libs.navigation.compose)
    implementation(libs.serialization.json)
    debugImplementation(libs.compose.ui.tooling)
    debugImplementation(libs.compose.ui.test.manifest)

    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
    testImplementation(platform(libs.compose.bom))
    testImplementation(libs.compose.ui.test.junit4)
    testImplementation(libs.navigation.testing)
    testImplementation(libs.roborazzi)
    testImplementation(libs.roborazzi.compose)
}
```

Three lines differ from lesson 1's: the plugin `kotlin.serialization`, and the libraries
`navigation-compose` and `serialization-json`; a fourth, `navigation-testing`, is for section 04's
tests. All four were already in lesson 1's catalogue, so only this file changes.

The screens themselves know nothing about navigation. Each takes the data it shows and a function for
each thing the user can do:

```kotlin
// app/src/main/java/com/example/planner/Screens.kt
package com.example.planner

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

val courseNames = mapOf("kotlin" to "Kotlin", "android" to "Android Apps", "sql" to "SQL Databases")

@Composable
fun CoursesScreen(onOpen: (String) -> Unit) {
    Column(Modifier.padding(16.dp)) {
        Text("Courses", style = MaterialTheme.typography.headlineSmall)
        courseNames.forEach { (id, name) ->
            Text(name, Modifier.fillMaxWidth().clickable { onOpen(id) }.padding(vertical = 12.dp))
        }
    }
}

@Composable
fun CourseDetailScreen(courseId: String, onAdd: () -> Unit, onBack: () -> Unit) {
    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(courseNames.getValue(courseId), style = MaterialTheme.typography.headlineSmall)
        Button(onClick = onAdd) { Text("Add session") }
        TextButton(onClick = onBack) { Text("Back") }
    }
}

@Composable
fun AddSessionScreen(courseId: String, onSaved: () -> Unit) {
    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("New session for ${courseNames.getValue(courseId)}", style = MaterialTheme.typography.titleMedium)
        Button(onClick = onSaved) { Text("Save") }
    }
}
```

`CoursesScreen` does not navigate when a course is tapped; it calls `onOpen` with the course's id
and lets the caller decide what that means. **A screen that takes a `NavController` is a screen
that can only be shown inside that navigation graph**, and cannot be previewed or tested alone;
one that takes functions can be both. Lesson 10 moves the data out of the screens too.

And the graph that joins them:

```kotlin
// app/src/main/java/com/example/planner/PlannerNavHost.kt
package com.example.planner

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.toRoute

@Composable
fun PlannerNavHost(navController: NavHostController = rememberNavController()) {
    NavHost(navController, startDestination = Courses) {
        composable<Courses> {
            CoursesScreen(onOpen = { id -> navController.navigate(CourseDetail(id)) })
        }
        composable<CourseDetail> { entry ->
            val route = entry.toRoute<CourseDetail>()
            CourseDetailScreen(
                courseId = route.courseId,
                onAdd = { navController.navigate(AddSession(route.courseId)) },
                onBack = { navController.popBackStack() },
            )
        }
        composable<AddSession> { entry ->
            val route = entry.toRoute<AddSession>()
            AddSessionScreen(
                courseId = route.courseId,
                onSaved = { navController.popBackStack() },
            )
        }
    }
}
```

`NavHost` takes the controller and the route to start at, and inside it each `composable<Route>`
says what to draw when that route is on top. **`navigate(route)` pushes; `popBackStack()` pops**;
section 04 watches both happen. `rememberNavController()` is the default, so the app calls
`PlannerNavHost()` with nothing, and a test passes a controller it can inspect.
