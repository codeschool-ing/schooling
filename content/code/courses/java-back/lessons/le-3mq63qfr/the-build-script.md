---
title: The build script
version: 1
---

A Maven project is described in `pom.xml`. A Gradle project is described in two files, and **both
are Kotlin programs**, not documents. That is the first thing to know about Gradle and the source
of most of what is good and bad about it: a build file can contain an `if`, a loop or a function,
because it is code that Gradle compiles and runs. This lesson's files use none of that, and read
almost like a pom without the angle brackets.

## The same sources, a new directory

The project is lesson 1's, rebuilt. Make a directory beside `~/isbn-check` and copy its sources,
both classes and the test, exactly as lesson 1 wrote them:

```
ana@vm:~$ mkdir ~/isbn-gradle && cp -r ~/isbn-check/src ~/isbn-gradle/
```

Gradle expects the same layout as Maven, `src/main/java` and `src/test/java`, so nothing under
`src` changes. That convention is Maven's, and Gradle adopted it so that a project could move from
one tool to the other without moving a file.

## settings.gradle.kts

Create `~/isbn-gradle/settings.gradle.kts` with this one line:

```kotlin
rootProject.name = "isbn-check"
```

The settings file marks the root of a build and names the projects in it. A large build lists
several subprojects here, each with its own build script. This one is a single project, and the
line gives it the name that lesson 1's pom gave in `artifactId`. Without it the project would be
named after its directory, `isbn-gradle`, and so would the jar.

## build.gradle.kts

Create `~/isbn-gradle/build.gradle.kts`:

```schooling-example
{"language": "kotlin", "file": "build.gradle.kts", "parts": [{"code": "plugins {\n    application\n}\n", "note": "A **plugin** brings tasks and conventions. `application` brings `java` with it, so the project compiles, tests and makes a jar, and adds `run` and a launcher script on top."}, {"code": "group = \"com.example\"\nversion = \"1.0.0\"\n", "note": "The same coordinates as the pom's `groupId` and `version`. The artifact's name is not here: it comes from `settings.gradle.kts`."}, {"code": "java {\n    toolchain {\n        languageVersion = JavaLanguageVersion.of(25)\n    }\n}\n", "note": "The **toolchain** says which Java compiles, tests and runs the code. Gradle looks for a JDK 25 on the machine and uses it whatever Java started Gradle itself, which is more than `maven.compiler.release` says."}, {"code": "repositories {\n    mavenCentral()\n}\n", "note": "Where dependencies come from. Maven names Central by default and Gradle names nothing, so this block is not optional."}, {"code": "dependencies {\n    implementation(\"commons-validator:commons-validator:1.11.0\")\n    testImplementation(\"org.junit.jupiter:junit-jupiter:6.0.3\")\n    testRuntimeOnly(\"org.junit.platform:junit-platform-launcher:6.0.3\")\n}\n", "note": "Each line is `group:name:version` in one string, and the word before it says where the jar is needed. `implementation` is Maven's compile scope; `testImplementation` is test scope. The launcher is only needed to RUN tests, and Gradle 9 no longer supplies it."}, {"code": "application {\n    mainClass = \"com.example.isbn.IsbnCheck\"\n}\n", "note": "The class with `main`, for `run` and for the launcher script."}, {"code": "tasks.test {\n    useJUnitPlatform()\n}", "note": "Gradle's `test` task does not assume JUnit 5 or later. This line tells it to run the tests through the JUnit Platform, which is what Jupiter is built on."}]}
```

The `.kts` ending is what makes these files Kotlin. Gradle also reads `build.gradle`, written in
Groovy, which is what most build scripts on the internet still use; the two say the same things
with different punctuation. **The Kotlin DSL is Gradle's default for new builds**, and its
advantage is that an editor knows the type of everything in it, so a misspelt `implementation`
is underlined before the build runs rather than reported after.

Two lines have no counterpart in lesson 1's pom. `repositories` exists because Gradle assumes
nothing about where libraries live, where Maven assumes Central. And the JUnit launcher has to be
named because Gradle 9 stopped putting it on the test classpath by itself. The section on tasks
removes that line on purpose, to see what the failure looks like.

The dependency **configurations** carry what the pom's `scope` carried, with finer cuts.
`implementation` is on the classpath when the main code compiles and when it runs.
`testImplementation` adds to that for the tests. `testRuntimeOnly` is present when the tests run
and absent when they compile, which is right for a library no test class imports. There are
others, such as `compileOnly` for an annotation processor's API, and they are all the same idea:
a name for where a jar is needed.

## gradle.properties

One last file, `~/isbn-gradle/gradle.properties`, holds settings for Gradle itself rather than
for the project:

```properties
org.gradle.console=plain
```

In a terminal, Gradle normally draws a progress area that rewrites itself while it works and
leaves almost nothing behind. **The plain console prints one line per task, with the task's
outcome beside it**, which is what this lesson reads in every build. Delete the line later if you
prefer the progress area.

Every command from here on runs inside the project, so `cd ~/isbn-gradle` and look at what is
there:

```
ana@vm:~/isbn-gradle$ find . -type f | sort
./build.gradle.kts
./gradle.properties
./settings.gradle.kts
./src/main/java/com/example/isbn/IsbnCheck.java
./src/test/java/com/example/isbn/IsbnCheckTest.java
```

Three small files and the unchanged sources. Nothing has been built yet. The Gradle in `~/opt`
could build it now, but the next section first gives the project a Gradle of its own.
