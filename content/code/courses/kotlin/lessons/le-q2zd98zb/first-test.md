---
title: A first test, run by Gradle
version: 1
---

Every program so far was checked by running it and reading what it printed. That works once. It stops
working the day a change in one file breaks something three files away, and nobody runs the program that
would have shown it. **A test is a check written as code**, kept beside the program, and run by the build
every time, so the reading is done by the machine.

Kotlin's own `kotlin.test` library supplies the assertions, and JUnit runs them; Gradle wires the two
together. The planner's build gains two test dependencies and a `tasks.test` block. Here is the whole file:

```kotlin
// build.gradle.kts
import org.gradle.api.tasks.testing.logging.TestExceptionFormat

plugins {
    kotlin("jvm") version "2.4.21"
    application
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.11.0")
    testImplementation(kotlin("test"))
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.11.0")
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

| line | what it does |
|---|---|
| `testImplementation(kotlin("test"))` | `kotlin.test`, at the same version as the Kotlin plugin, only for test code |
| `kotlinx-coroutines-test` | `runTest` and virtual time, for sections 05 to 08 |
| `useJUnitPlatform()` | run the tests with JUnit 5; the Kotlin plugin picks the matching `kotlin.test` adapter from it |
| `testLogging` | print each test's name and result, and a failure's message without its stack trace |

`testImplementation` keeps the test libraries out of the program: they are on the classpath when tests
compile and run, and absent from what `./gradlew run` starts. Without `testLogging`, Gradle prints
nothing about tests that pass, which is quiet but tells a beginner nothing.

Tests live in `src/test/kotlin`, beside `src/main/kotlin`, and see everything in it that is not
`private`. The first one checks `describe` from lesson 17:

```kotlin
// src/test/kotlin/DescribeTest.kt
import kotlin.test.Test
import kotlin.test.assertEquals

class DescribeTest {
    @Test
    fun loadedWeekIsCounted() {
        assertEquals("2 sessions, 75 min", describe(WeekUi.Loaded(listOf(45, 30))))
    }

    @Test
    fun loadingSaysSo() {
        assertEquals("loading…", describe(WeekUi.Loading))
    }
}
```

```
ana@vm:~/kt/planner$ ./gradlew test
> Task :checkKotlinGradlePluginConfigurationErrors SKIPPED
> Task :processResources NO-SOURCE
> Task :processTestResources NO-SOURCE
> Task :compileKotlin
> Task :compileJava NO-SOURCE
> Task :classes UP-TO-DATE
> Task :jar
> Task :compileTestKotlin
> Task :compileTestJava NO-SOURCE
> Task :testClasses UP-TO-DATE

> Task :test

DescribeTest > loadedWeekIsCounted() PASSED

DescribeTest > loadingSaysSo() PASSED

BUILD SUCCESSFUL in 2s
4 actionable tasks: 4 executed
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.2/userguide/configuration_cache_enabling.html
```

**A test is a function marked `@Test` inside a class**, and it passes if it returns without throwing.
`assertEquals(expected, actual)` throws when the two differ, and the expected value comes first. The
names say what is being claimed, because a name is what Gradle prints when it fails.
