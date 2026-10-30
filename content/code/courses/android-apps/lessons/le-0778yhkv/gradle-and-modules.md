---
title: The first build, and the three SDK numbers
version: 1
---

**`./gradlew assembleDebug` turns the eight files into an installable app**, and the first time it
runs it does a great deal more than compile. It downloads the Gradle the wrapper names, then the
Android Gradle plugin, then every library the module asks for and every library *those* ask for,
and only then compiles. This was run with Gradle's cache emptied first, so it is the build you will
see:

```
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E "^(Downloading|BUILD|[0-9]+ actionable)"
Downloading https://services.gradle.org/distributions/gradle-9.8.2-bin.zip
BUILD SUCCESSFUL in 2m 50s
36 actionable tasks: 36 executed
ana@vm:~/planner$ ls -lh app/build/outputs/apk/debug/
total 12M
-rw-r--r-- 1 ana ana 12M Oct 30 15:46 app-debug.apk
-rw-r--r-- 1 ana ana 403 Oct 30 15:46 output-metadata.json
```

Nearly three minutes, most of it downloading. The second run, with nothing changed, is a different
number entirely:

```
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)"
BUILD SUCCESSFUL in 1s
36 actionable tasks: 36 up-to-date
```

**36 tasks, and none of them ran again.** Gradle records what each task read and wrote, and skips
the ones whose inputs have not changed. That is why the second build is fast, and why a build that
suddenly is not fast usually means something changed that you did not expect: a file regenerated, a
version moved, a clock.

## What the module asked for, and what arrived

The module's build file names eight libraries for the app itself. Ask Gradle what the app actually
receives at run time:

```
ana@vm:~/planner$ ./gradlew -q :app:dependencies --configuration debugRuntimeClasspath | grep -E "^[+\\\\]---"
+--- org.jetbrains.kotlin:kotlin-stdlib:2.4.21
+--- androidx.compose.ui:ui-tooling -> 1.12.1
+--- androidx.compose.ui:ui-test-manifest -> 1.12.1
+--- androidx.core:core-ktx:1.19.1 (*)
+--- androidx.activity:activity-compose:1.13.0 (*)
+--- androidx.compose:compose-bom:2026.09.00
+--- androidx.compose.ui:ui -> 1.12.1 (*)
+--- androidx.compose.material3:material3 -> 1.4.0 (*)
\--- androidx.compose.ui:ui-tooling-preview -> 1.12.1 (*)
ana@vm:~/planner$ ./gradlew -q :app:dependencies --configuration debugRuntimeClasspath | grep -oE "[a-z][a-z0-9.-]+:[a-z][a-z0-9.-]+" | sort -u | wc -l
103
```

The first command prints the top of the tree: the eight from the build file, plus Kotlin's standard
library, which the Kotlin compiler adds by itself. An arrow means the build file named one version
and Gradle chose another: `ui -> 1.12.1` is the BOM deciding, because the module wrote no version
for `ui` at all. `(*)` means the library's own dependencies were already listed above. The second
command counts the distinct libraries in the whole tree, the dependencies of dependencies included:
**one screen with one sentence, and 103 libraries.** Most of them are small and most of them R8 removes
from a release build, which is lesson 22's subject.

## `compileSdk`, `minSdk` and `targetSdk`

These three numbers are confused more than anything else in an Android build file, because they
look alike and answer three different questions.

| | the question it answers | this project |
|---|---|---|
| **`compileSdk`** | which Android's API does the compiler know about? | 37, the platform section 03 installed |
| **`minSdk`** | what is the oldest Android allowed to install the app? | 26, Android 8.0 |
| **`targetSdk`** | which Android's behaviour has the app been tested against? | 36, Android 16 |

**`compileSdk` changes nothing on a phone.** It is the set of classes and methods your code may
name, and the libraries have a say in it: Compose's September 2026 release refuses to build
against anything below 37, which is why this project says 37. A method that exists only in 37,
called on a phone running 30, crashes; lesson 20 shows how the code asks first.

**`minSdk` is a promise you make to the Play Store**: phones older than 26 will not be offered the
app at all. Lowering it reaches more phones and makes you test on older ones.

**`targetSdk` is the one that changes behaviour.** Every Android release changes rules for apps that
declare they target it, and leaves older apps alone: from 33, an app has to ask before showing a
notification, which is lesson 19. Raising `targetSdk` is opting into the new rules, and Google Play
requires a recent one for new apps and updates; lesson 22 gives the date it was recorded on.

## Modules, and when one is not enough

This project has one module, `:app`. A module is a directory with its own build file, compiled on
its own, and a project splits into several for two reasons: **so that a change recompiles less**,
since Gradle rebuilds only the modules a change touched and the ones that depend on them, and **so
that the dependencies are enforced**, since a module cannot use a class from another it does not
declare. Large apps have dozens. A study planner with one person building it gets nothing from that
split but more build files, so this course keeps one module and lesson 22 returns to the question.
