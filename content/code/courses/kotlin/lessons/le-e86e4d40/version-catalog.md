---
title: One file for every version
version: 1
---

The planner's build names `2.4.21` and `1.11.0` inside strings, and `1.11.0` twice. With one project
that is tolerable. With several, the same version is written in each, and an upgrade that misses one
leaves two modules on two versions of a library. **A version catalog is one file, `gradle/libs.versions.toml`,
that names every version and library once**, and Gradle reads it automatically:

```toml
# gradle/libs.versions.toml
[versions]
kotlin = "2.4.21"
coroutines = "1.11.0"

[libraries]
kotlinx-coroutines-core = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-core", version.ref = "coroutines" }
kotlinx-coroutines-test = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-test", version.ref = "coroutines" }

[plugins]
kotlin-jvm = { id = "org.jetbrains.kotlin.jvm", version.ref = "kotlin" }
```

Gradle turns each name into an accessor on `libs`, with the dashes becoming dots, and the build script
refers to those instead of to strings:

```kotlin
// build.gradle.kts
import org.gradle.api.tasks.testing.logging.TestExceptionFormat

plugins {
    alias(libs.plugins.kotlin.jvm)
    application
}

repositories {
    mavenCentral()
}

dependencies {
    implementation(libs.kotlinx.coroutines.core)
    testImplementation(kotlin("test"))
    testImplementation(libs.kotlinx.coroutines.test)
}

kotlin {
    jvmToolchain(21)
}

application {
    mainClass = providers.gradleProperty("main").orElse("HelloKt")
}

tasks.test {
    useJUnitPlatform()
    testLogging {
        events("passed", "failed")
        exceptionFormat = TestExceptionFormat.FULL
        showStackTraces = false
    }
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=WeekModelKt
loading…
2 sessions, 75 min
3 sessions, 135 min
```

The program printed what it printed in lesson 17, which is the test of a change like this: **the build
means the same thing, and the versions now live in one place**. `kotlin("test")` stays as it was,
because it already takes its version from the Kotlin plugin.

A typo is caught where it is made. `libs.kotlinx.corutines.core` is not a property of `libs`, so the
build script fails to compile, naming the line, before any download is attempted. A misspelt string,
the old way, fails later and further away, as a dependency Maven Central does not have.

The catalog is also what `android-apps` reads: a new Android project comes with a
`gradle/libs.versions.toml` already written, in exactly this shape.
