---
title: A Gradle project, because coroutines are a library
version: 1
---

Everything so far came with the compiler. Coroutines do not: the language provides the `suspend`
keyword, and **the library `kotlinx-coroutines` provides everything that uses it**, `launch`,
`async`, `delay`, the dispatchers and, in lessons 16 and 17, `Flow`. A library has to be downloaded
and put on the class path at compile time and at run time, and keeping track of that by hand stops
being reasonable at the second library. That is Gradle's job, and Gradle 9.8.2 is already on your
machine from lesson 1.

This section builds the smallest project that works; lesson 19 explains every line of it properly.
Make a directory for it, `~/kt/planner`, and two files at its top. The first names the project:

```kotlin
// settings.gradle.kts
rootProject.name = "planner"
```

The second says how to build it:

```schooling-example
{"language": "kotlin", "file": "build.gradle.kts", "parts": [{"code": "plugins {\n    kotlin(\"jvm\") version \"2.4.21\"\n    application\n}", "note": "The Kotlin plugin, pinned to the same 2.4.21 as the compiler from lesson 1, and `application`, which adds a `run` task."}, {"code": "repositories {\n    mavenCentral()\n}", "note": "Where libraries are downloaded from: Maven Central, the public repository most JVM libraries are published to."}, {"code": "dependencies {\n    implementation(\"org.jetbrains.kotlinx:kotlinx-coroutines-core:1.11.0\")\n}", "note": "The one library, by group, name and exact version. Gradle downloads it, and anything it depends on, the first time."}, {"code": "kotlin {\n    jvmToolchain(21)\n}", "note": "Compile for Java 21, the JDK installed in lesson 1."}, {"code": "application {\n    mainClass = providers.gradleProperty(\"main\").orElse(\"HelloKt\")\n}", "note": "Which `main` to run. Each program in lessons 14 to 17 is its own file, and `-Pmain=LaunchKt` on the command line picks one; without it, `Hello.kt` runs."}]}
```

Programs go in `src/main/kotlin/`. The first is a check that the library arrived:

```kotlin
// src/main/kotlin/Hello.kt
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    println("planner starting")
    delay(200)
    println("coroutines are here")
}
```

## The wrapper, then the first build

`gradle wrapper` writes a small script, `gradlew`, that downloads exactly the Gradle version this
project was made with and runs it. **From now on every build in this course runs through `./gradlew`,
never the `gradle` on your `PATH`**, so the project builds the same on a machine with a different
Gradle installed, or none:

```
ana@vm:~/kt/planner$ gradle wrapper
Starting a Gradle Daemon (subsequent builds will be faster)
> Task :wrapper

BUILD SUCCESSFUL in 42s
1 actionable task: 1 executed
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.2/userguide/configuration_cache_enabling.html
ana@vm:~/kt/planner$ ls
build.gradle.kts
gradle
gradlew
gradlew.bat
settings.gradle.kts
src
ana@vm:~/kt/planner$ ./gradlew run
Fetching distribution.
Downloading https://services.gradle.org/distributions/gradle-9.8.2-bin.zip
..............10%..............20%...............30%..............40%...............50%..............60%...............70%..............80%...............90%..............100%
> Task :checkKotlinGradlePluginConfigurationErrors SKIPPED
> Task :processResources NO-SOURCE
> Task :compileKotlin
> Task :compileJava NO-SOURCE
> Task :classes UP-TO-DATE

> Task :run
planner starting
coroutines are here

BUILD SUCCESSFUL in 30s
2 actionable tasks: 2 executed
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.2/userguide/configuration_cache_enabling.html
```

The first `./gradlew` downloaded Gradle 9.8.2 again, into `~/.gradle/wrapper`, started the Gradle
daemon, a background process that keeps later builds fast, then downloaded the Kotlin plugin and the
coroutines library, compiled `Hello.kt` and ran it. That first build takes a while and needs the
network. **Every later build reuses what was downloaded**:

```
ana@vm:~/kt/planner$ ./gradlew -q run
planner starting
coroutines are here
```

`-q` hides Gradle's own progress lines and leaves only what the program printed, which is how the
rest of these lessons run programs.

## When the first build fails

Two failures are worth seeing on day one, and both name their cause. They were made on a copy of the
project, so the real one stays intact. A version that does not exist:

```
ana@vm:~/kt$ cp -r planner broken-version && cd broken-version && sed -i "s/1.11.0/1.99.0/" build.gradle.kts && ./gradlew -q run 2>&1 | head -9

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':compileKotlin' (registered by plugin 'org.jetbrains.kotlin.jvm').
> Could not resolve all files for configuration ':compileClasspath'.
   > Could not find org.jetbrains.kotlinx:kotlinx-coroutines-core:1.99.0.
     Searched in the following locations:
       - https://maven-central.storage-download.googleapis.com/maven2/org/jetbrains/kotlinx/kotlinx-coroutines-core/1.99.0/kotlinx-coroutines-core-1.99.0.pom
```

`Could not find` with the full coordinates means Gradle reached the repository and the file was not
there: **check the group, the name and the version letter by letter**. A network problem says
`Could not resolve` or `Could not GET` instead, with the address it tried.

A toolchain the machine does not have:

```
ana@vm:~/kt$ cp -r planner broken-toolchain && cd broken-toolchain && sed -i "s/jvmToolchain(21)/jvmToolchain(17)/" build.gradle.kts && ./gradlew -q run 2>&1 | head -8

FAILURE: Build failed with an exception.

* What went wrong:
Could not determine the dependencies of task ':run'.
> Could not resolve all dependencies for configuration ':runtimeClasspath'.
   > Failed to calculate the value of task ':compileJava' property 'javaCompiler'.
      > Cannot find a Java installation on your machine (Linux 6.18.44-fc-v185 amd64) matching: {languageVersion=17, vendor=any vendor, implementation=vendor-specific, nativeImageCapable=false}. Toolchain download repositories have not been configured.
```

`jvmToolchain(17)` asked for a Java 17 that is not installed, and Gradle says so, listing what it
looked for. On the machine from lesson 1 the answer is to ask for 21, the JDK that is there.
