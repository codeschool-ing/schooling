---
title: The compiler's own report on stability
version: 1
---

**The Compose compiler can write down what it decided about every class and every composable**, and
reading that report replaces guessing. Two settings in the module's build file turn it on, and a
third, used below, lets you correct the compiler about a class it cannot see into. This is lesson 2's
build file with the `composeCompiler` block added:

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
                showStandardStreams = true
            }
        }
    }
}

composeCompiler {
    reportsDestination = layout.buildDirectory.dir("compose_compiler")
    metricsDestination = layout.buildDirectory.dir("compose_compiler")
    stabilityConfigurationFiles.add(rootProject.layout.projectDirectory.file("stability.conf"))
}

dependencies {
    implementation(libs.core.ktx)
    implementation(libs.activity.compose)
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.material3)
    implementation(libs.compose.ui.tooling.preview)
    debugImplementation(libs.compose.ui.tooling)
    debugImplementation(libs.compose.ui.test.manifest)

    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
    testImplementation(platform(libs.compose.bom))
    testImplementation(libs.compose.ui.test.junit4)
    testImplementation(libs.roborazzi)
    testImplementation(libs.roborazzi.compose)
}
```

The third line names a file at the project's root. It starts with nothing in it but a comment:

```conf
// stability.conf
// Classes the Compose compiler should treat as stable, one per line.
```

The report is written while the Kotlin compiler runs, so the build has to compile, and `clean`
makes sure it does:

```
ana@vm:~/planner$ ./gradlew --console=plain clean compileDebugKotlin 2>&1 | grep -E "^BUILD"
BUILD SUCCESSFUL in 4s
ana@vm:~/planner$ cat app/build/compose_compiler/app-classes.txt
unstable class com.example.planner.MainActivity {
  <runtime stability> = Unstable
}
unstable class com.example.planner.data.StudySession {
  stable val id: Long
  stable val courseId: String
  unstable val date: LocalDate
  stable val minutes: Int
  stable val done: Boolean
  <runtime stability> = Unstable
}
```

**`StudySession` is unstable, and the report says which field did it**: `date`, a `LocalDate`. The
compiler can prove that a `val` holding a `Long` or a `String` never changes, because it knows
those types. `LocalDate` is a Java class from `java.time`, compiled without the Compose compiler,
and the compiler cannot look inside it, so it assumes the worst. `MainActivity` is unstable too, which
does not matter: nothing passes an activity to a composable.

The report on composables shows the same decision from the other side, for section 03's test:

```
ana@vm:~/planner$ ./gradlew --console=plain compileDebugUnitTestKotlin 2>&1 | grep -E "^BUILD"
BUILD SUCCESSFUL in 7s
ana@vm:~/planner$ grep -A3 -E "fun com.example.planner.(SessionCount|DraftMinutes)" app/build/compose_compiler/app-composables.txt
restartable skippable scheme("[androidx.compose.ui.UiComposable]") fun com.example.planner.SessionCount(
  sessions: List<StudySession>
  stable name: String
)
restartable skippable scheme("[androidx.compose.ui.UiComposable]") fun com.example.planner.DraftMinutes(
  unstable draft: Draft
  stable name: String
)
```

`unstable draft: Draft` is the reason the draft was compared by identity and ran every time.
`sessions` carries no word at all, which the report uses when stability is left to run time
rather than decided by the compiler; section 03 measured what it came to, a comparison by value.
And the module's metrics file says strong skipping is on:

```
ana@vm:~/planner$ grep -A5 featureFlags app/build/compose_compiler/debug/app-module.json
  "featureFlags": {
    "StrongSkipping": true,
    "IntrinsicRemember": true,
    "OptimizeNonSkippingGroups": true,
    "PausableComposition": true
  }
```

## Telling the compiler what it cannot see

`LocalDate` is immutable: Java's documentation for `java.time` calls every one of its classes
immutable and thread-safe. The compiler cannot know that, and the stability file is where you tell it.
One line:

```conf
// stability.conf
// Classes the Compose compiler should treat as stable, one per line.
java.time.LocalDate
```

```
ana@vm:~/planner$ ./gradlew --console=plain clean compileDebugKotlin 2>&1 | grep -E "^BUILD"
BUILD SUCCESSFUL in 3s
ana@vm:~/planner$ grep -A7 StudySession app/build/compose_compiler/app-classes.txt
stable class com.example.planner.data.StudySession {
  stable val id: Long
  stable val courseId: String
  stable val date: LocalDate
  stable val minutes: Int
  stable val done: Boolean
  <runtime stability> = Stable
}
```

**`StudySession` is stable now, and every composable taking one compares it by value.** This is a
promise you make to the compiler, not a fact it checks: list a class here that does change after it
is created, and Compose will skip composables that should have run, showing stale data. Only
classes whose documentation guarantees immutability belong in this file.
