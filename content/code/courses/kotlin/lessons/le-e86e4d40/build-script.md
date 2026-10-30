---
title: Reading a build script
version: 1
---

A Gradle build has two kinds of script, and lesson 14 wrote one of each without dwelling on them.
**`settings.gradle.kts` says what the build is made of**: its name and, in section 06, its modules.
**`build.gradle.kts` says how one project is built**: which plugins, where dependencies come from,
which dependencies, and how its tasks are configured. Both are Kotlin, with Gradle's API in scope.

The planner's build script, read top to bottom:

| block | says |
|---|---|
| `plugins { … }` | what kind of project this is: Kotlin on the JVM, and an `application` with a `run` task |
| `repositories { … }` | where to download dependencies from |
| `dependencies { … }` | what to download, and for which part of the build |
| `kotlin { … }`, `application { … }` | settings for what those plugins added |
| `tasks.test { … }` | settings for one task |

## Configurations: which part of the build a dependency is for

The word before each dependency is a **configuration**, and it decides where the library is visible:

| configuration | compiled against | present when the program runs | seen by projects that depend on this one |
|---|---|---|---|
| `implementation` | yes | yes | no |
| `api` | yes | yes | yes |
| `compileOnly` | yes | no | no |
| `runtimeOnly` | no | yes | no |
| `testImplementation` | tests only | tests only | no |

`implementation` is the default answer. `api` is for a library whose own public functions take or return
the dependency's types, so whoever uses the library needs that dependency too.

Gradle can print what a configuration resolved to, including what each dependency brought with it:

```
ana@vm:~/kt/planner$ ./gradlew -q dependencies --configuration runtimeClasspath

------------------------------------------------------------
Root project 'planner'
------------------------------------------------------------

runtimeClasspath - Runtime classpath of 'main'.
+--- org.jetbrains.kotlin:kotlin-stdlib:2.4.21
|    \--- org.jetbrains:annotations:13.0 -> 23.0.0
\--- org.jetbrains.kotlinx:kotlinx-coroutines-core:1.11.0
     \--- org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:1.11.0
          +--- org.jetbrains:annotations:23.0.0
          +--- org.jetbrains.kotlinx:kotlinx-coroutines-bom:1.11.0
          |    +--- org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:1.11.0 (c)
          |    \--- org.jetbrains.kotlinx:kotlinx-coroutines-core:1.11.0 (c)
          \--- org.jetbrains.kotlin:kotlin-stdlib:2.2.20 -> 2.4.21 (*)

(c) - A dependency constraint, not a dependency. The dependency affected by the constraint occurs elsewhere in the tree.
(*) - Indicates repeated occurrences of a transitive dependency subtree. Gradle expands transitive dependency subtrees only once per project; repeat occurrences only display the root of the subtree, followed by this annotation.

A web-based, searchable dependency report is available by adding the --scan option.
```

The planner named one library besides the standard library, and that library brought its own. **Every
line under a dependency is a dependency of that dependency**: `kotlinx-coroutines-core` is a small entry
pointing at `kotlinx-coroutines-core-jvm`, the code for the JVM, and `(c)` marks a version constraint
rather than another jar.

The arrows are the lines to read. **`2.2.20 -> 2.4.21` means one library asked for an older standard
library and got the newer one**, because two versions of one library cannot both be on a classpath and
Gradle settles on the highest version anybody asked for. `annotations` was settled the same way, 13.0 up
to 23.0.0. That is usually right, and when a program fails with `NoSuchMethodError` after a dependency
upgrade, this report is where to look.
