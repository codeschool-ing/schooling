---
title: One function, two back ends
version: 1
---

A Kotlin Multiplatform project compiles one set of sources for several targets. **Code in
`src/commonMain` is compiled for every target and may use only what every target has**; code in a
target's own directory, `src/jvmMain` or `src/jsMain`, is compiled for that target alone and may use
everything it offers. A new build, `~/kt/shared`, with the wrapper copied in as before:

```kotlin
// settings.gradle.kts
rootProject.name = "shared"

dependencyResolutionManagement {
    repositories {
        mavenCentral()
    }
}
```

```kotlin
// build.gradle.kts
plugins {
    kotlin("multiplatform") version "2.4.21"
}

kotlin {
    jvmToolchain(21)
    jvm {
        mainRun { mainClass = "MainKt" }
    }
    js {
        nodejs()
        binaries.executable()
    }
}
```

The `multiplatform` plugin replaces `jvm`, and each target is declared inside `kotlin { }`: the JVM,
with the class to run, and JavaScript for Node.js, built as a program rather than a library.

```kotlin
// src/commonMain/kotlin/Week.kt
data class Session(val course: String, val minutes: Int)

fun summary(sessions: List<Session>): String =
    "${sessions.size} sessions, ${sessions.sumOf { it.minutes }} min, on ${platform()}"

expect fun platform(): String
```

```kotlin
// src/commonMain/kotlin/Main.kt
fun main() {
    println(summary(listOf(Session("kotlin", 45), Session("android-apps", 30))))
}
```

**`expect fun platform()` is a promise that every target will supply this function.** Common code calls
it without knowing how it is written; each target keeps the promise with an `actual` declaration in its
own directory, and the build fails for any target that does not.

```kotlin
// src/jvmMain/kotlin/Platform.jvm.kt
actual fun platform(): String = "the JVM " + System.getProperty("java.version")
```

```kotlin
// src/jsMain/kotlin/Platform.js.kt
actual fun platform(): String = "JavaScript"
```

`System.getProperty` is the JVM's, so it can live only in `jvmMain`; written in `commonMain`, it would
not compile. Run the program on each back end:

```
ana@vm:~/kt/shared$ ./gradlew -q jvmRun
2 sessions, 75 min, on the JVM 21.0.12.1
```

```
ana@vm:~/kt/shared$ ./gradlew -q jsNodeDevelopmentRun
2 sessions, 75 min, on JavaScript
```

The first `jsNodeDevelopmentRun` takes a while: Gradle downloads Node.js and the JavaScript packages the
Kotlin/JS build uses into `~/.gradle`, once. **`summary` and `Session` were compiled twice, to bytecode
and to JavaScript**, from one file, and gave the same answer in two runtimes.

## A native target

A third target turns the same code into a Linux executable with no JVM at all. It is two lines in
`build.gradle.kts`, inside `kotlin { }`, and one more `actual`:

```kotlin
    linuxX64 {
        binaries.executable()
    }
```

```kotlin
// src/linuxX64Main/kotlin/Platform.linuxX64.kt
actual fun platform(): String = "Linux, natively"
```

`./gradlew runDebugExecutableLinuxX64` builds and runs it, and on a Mac the target is `macosArm64`. This
is the one program in the course with no transcript. The Kotlin/Native compiler comes from Maven
Central, but the C toolchain it links with is downloaded from `download.jetbrains.com`, which the machine
these lessons were recorded on could not reach, as lesson 1 said. On your machine it is one more download
on the first run.

This is the mechanism behind Compose Multiplatform and shared Android and iOS code: the rules in
`commonMain`, written once, and each platform's screen and storage beside it.
