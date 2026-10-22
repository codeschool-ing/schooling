---
title: Maven or Gradle
version: 1
---

The comparison most people arrive with is speed: Gradle is the fast one. On this project it is
not a contest. Lesson 1's `mvn package` and this lesson's `./gradlew build` both finish in a few
seconds, because two classes and three tests are nothing to either tool. **The difference is in
the model**, and speed is one of the things the model buys on a large project.

| | Maven | Gradle |
|---|---|---|
| what the build file is | a description, in XML | a program, in Kotlin (or Groovy) |
| what runs | a fixed line of phases, with plugins bound to them | a graph of tasks, built for the tasks you asked for |
| when a step runs again | the compiler plugin compares file timestamps, and the tests run again on every build | every task compares the contents of its inputs and outputs |
| reusing work from elsewhere | an extension, not in the default install | the build cache, one line in `gradle.properties` |
| a version conflict between two dependencies | the declaration nearest the project wins | the highest version wins |
| the tool's own version | whatever `mvn` is installed, unless the project adds a wrapper | the wrapper, from the first commit |
| between builds | nothing stays running | a daemon stays in memory, idle |

Two rows deserve a sentence. The conflict rule showed up in this lesson's own dependency report,
where `commons-logging:1.3.5 -> 1.4.0` is Gradle choosing the higher of two requested versions.
Maven would pick 1.4.0 here too, for a different reason: Commons Validator asks for it directly,
one level nearer the project than Commons BeanUtils does. On another project the two rules can
choose differently, and the same dependency list then builds against different jars.

And the daemon is the price of the fast second build. After a build it stays alive, holding the
compiled build script and a warm JVM:

```
ana@vm:~/isbn-gradle$ ./gradlew --status
   PID STATUS   INFO
 25061 IDLE     9.8.1

Only Daemons for the current Gradle version are displayed. For more on this, please refer to https://docs.gradle.org/9.8.1/userguide/gradle_daemon.html#sec:status in the Gradle documentation.
ana@vm:~/isbn-gradle$ ./gradlew --stop
Stopping Daemon(s)
1 Daemon stopped
```

`--stop` ends it, and an idle daemon ends itself after three hours. On a laptop with little
memory, that resident JVM is worth knowing about.

## Where each one is

**A build file that is a program is the strongest thing about Gradle and the most common
complaint about it.** A task can be written in a few lines of Kotlin where Maven would need a
plugin, and a team can also bury logic in the build that nobody else can read. A pom can only say
what the POM format lets it say, which makes every pom look like every other.

Both are everywhere in Java. Android projects build with Gradle, because Google's Android plugin
is a Gradle plugin. Spring Boot's own source code builds with Gradle, and Spring Initializr offers
a new project in either. Many company code bases, especially older ones, are Maven, and a
developer who reads only one of the two will meet the other within a job or two.

## Why the rest of this course uses Maven

From lesson 4 on, the course's project is a Spring Boot application, `~/bookshop`, and its build
file is a pom. The reason is the reading, not the tool. Every lesson that changes the build
changes one declarative block that you can read top to bottom, whether it adds a starter, a
driver or a test plugin. Spring Boot's parent pom then decides the version of nearly every
library, and you can see that happen by reading the file. **A Gradle build of the same
application works just as well**: Spring Boot ships a Gradle plugin that does what its Maven plugin
does, and nothing taught from lesson 4 onwards depends on the choice.

What you take from this lesson to a Gradle project is the vocabulary: a task, its inputs and
outputs, `UP-TO-DATE` and `FROM-CACHE`, the wrapper, and `./gradlew` instead of `gradle`. Lesson 3
looks at Bazel, which takes the idea of a cached, input-driven build much further, for code bases
much larger than this one.
