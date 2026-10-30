---
title: A build with two modules
version: 1
---

The planner is one project holding everything: the week model, the coroutine experiments, the tests.
Real programs split. **A module is a project inside a build, with its own sources and its own
dependencies**, and modules depend on each other the way a project depends on a library. The usual
first split puts the rules in one module and the program in another, so the rules can be tested, and
later reused by a second program, without the first.

A new build, `~/kt/studyplan`, has two modules: `core`, which knows what a study week is, and `app`,
which runs. It starts with a copy of the planner's wrapper and catalog, which are the `gradle` directory
and the two `gradlew` scripts:

```
ana@vm:~/kt/studyplan$ cp -r ../planner/gradle ../planner/gradlew ../planner/gradlew.bat .
ana@vm:~/kt/studyplan$ find . -type f | sort
./gradle/libs.versions.toml
./gradle/wrapper/gradle-wrapper.jar
./gradle/wrapper/gradle-wrapper.properties
./gradlew
./gradlew.bat
```

```kotlin
// settings.gradle.kts
rootProject.name = "studyplan"

dependencyResolutionManagement {
    repositories {
        mavenCentral()
    }
}

include("core", "app")
```

`include` names the modules, each a directory with a build script of its own. The repositories move here,
declared once for every module. The root `build.gradle.kts` has one job:

```kotlin
// build.gradle.kts
plugins {
    alias(libs.plugins.kotlin.jvm) apply false
}
```

`apply false` loads the Kotlin plugin, at the catalog's version, without applying it to the root, which
has no code. **Each module then applies it with no version**, and all of them get the same one.

```kotlin
// core/build.gradle.kts
plugins {
    alias(libs.plugins.kotlin.jvm)
}

dependencies {
    testImplementation(kotlin("test"))
}

kotlin {
    jvmToolchain(21)
}

tasks.test {
    useJUnitPlatform()
}
```

```kotlin
// core/src/main/kotlin/Week.kt
package studyplan.core

data class Session(val course: String, val minutes: Int)

class Week(private val goal: Int) {
    private val sessions = mutableListOf<Session>()

    fun add(s: Session) {
        require(s.minutes > 0) { "minutes must be positive: ${s.minutes}" }
        sessions += s
    }

    val total: Int get() = sessions.sumOf { it.minutes }

    fun summary(): String = "${sessions.size} sessions, $total of $goal min (${percent()}%)"

    internal fun percent(): Int = total * 100 / goal
}
```

**`package studyplan.core` puts the file's declarations in a namespace.** The planner never needed one,
being a single program; two modules that will one day both have a `Week` do. The `app` module depends on
`core` with `project(":core")`:

```kotlin
// app/build.gradle.kts
plugins {
    alias(libs.plugins.kotlin.jvm)
    application
}

dependencies {
    implementation(project(":core"))
}

kotlin {
    jvmToolchain(21)
}

application {
    mainClass = "studyplan.app.MainKt"
}
```

```kotlin
// app/src/main/kotlin/Main.kt
package studyplan.app

import studyplan.core.Session
import studyplan.core.Week

fun main() {
    val week = Week(goal = 300)
    week.add(Session("kotlin", 45))
    week.add(Session("android-apps", 30))
    println(week.summary())
}
```

```
ana@vm:~/kt/studyplan$ ./gradlew :app:run
> Task :app:checkKotlinGradlePluginConfigurationErrors SKIPPED
> Task :core:checkKotlinGradlePluginConfigurationErrors SKIPPED
> Task :core:processResources NO-SOURCE
> Task :app:processResources NO-SOURCE
> Task :core:compileKotlin
> Task :core:compileJava NO-SOURCE
> Task :core:classes UP-TO-DATE
> Task :core:jar
> Task :app:compileKotlin
> Task :app:compileJava NO-SOURCE
> Task :app:classes UP-TO-DATE

> Task :app:run
2 sessions, 75 of 300 min (25%)

BUILD SUCCESSFUL in 5s
4 actionable tasks: 4 executed
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.2/userguide/configuration_cache_enabling.html
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l19-modules\" aria-label=\"The studyplan build. At the top, the root: settings.gradle.kts includes core and app, and gradle/libs.versions.toml holds the versions for both. Below, two modules side by side. core holds Session, Week, and Week.percent(), which is internal. app holds Main.kt and depends on core through implementation(project(&quot;:core&quot;)). app can call Week and summary(); the line from app to percent() is crossed out, because internal stops at the module's edge.\"><defs><marker id=\"l19-modules-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l19-modules-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l19-modules-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"170\" y=\"14\" width=\"380\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the build: studyplan</text><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">settings.gradle.kts  include(\"core\", \"app\")</text><text x=\"360\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">gradle/libs.versions.toml</text><path d=\"M300 76 L190 112\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M420 76 L530 112\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"40\" y=\"114\" width=\"280\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">module core</text><text x=\"180\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Session, Week, summary()</text><rect x=\"70\" y=\"184\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"180\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">internal fun percent()</text><rect x=\"420\" y=\"114\" width=\"260\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">module app</text><text x=\"550\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Main.kt</text><text x=\"550\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">implementation(project(\":core\"))</text><path d=\"M418 162 L322 162\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-modules-ah-phosphor)\"></path><text x=\"370\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">calls</text><path d=\"M418 210 L292 210\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M347 202 L363 218\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M363 202 L347 218\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"355\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">refused</text></svg>", "caption": "Two modules in one build: app depends on core and sees what core makes public, not what it keeps internal."}
```

`:app:run` is the `run` task of the `app` module; the colon path names a module the way a slash path
names a directory. Gradle built `core` first, because `app` depends on it, without being told.
`mainClass` gained the package, `studyplan.app.MainKt`, because a top-level `main` in a packaged file
lives in a class named after the package and the file.
