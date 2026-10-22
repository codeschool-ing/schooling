---
format: 5
course: java
---

# java

**Java** · `co-vfke61r6` · 80 h declared · beginner · 40 lessons · `programming` · paid

## Reach

In **1 track** — `backend`(5, choice *Java*).

**Reached through a choice**, never in sequence — so **no course after that fork may assume it was taken**.

**Depends on it:** `java-functional`

## Assumes, and leaves ready

**Assumes:** **nothing.** Beginner, no `requires`, reached only as a fork option.

**Leaves ready:** the language, for `java-functional`.

## Shape

| | |
|---|---|
| declared hours | 80 h |
| lessons | 40 |
| **hours per lesson** | **2.00** |
| section budget | ~171, about 4.3 a lesson |
| exercises | ~800, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **a JDK** |
| browser · database | no · no |
| exercises **blocked** | **~600 (70%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~60 — the class hierarchy, static against dynamic binding, pass-by-value with an object reference, the collections chosen by shape |

## The environment it leaves, for `java-functional` and `java-back`

The three Java courses are one chain on the `backend` fork, and **the student installs once**. This
course builds the environment in lesson 1 and decides the project layout in lesson 18; the two
after it reuse both exactly, and open with a short section that gives the setup in brief and points
here.

- **The JDK** is OpenJDK 25, the package `openjdk-25-jdk` from Ubuntu 24.04's own archive
  (25.0.4.1 when this course was recorded). `JAVA_HOME` stays unset: `default-java` points at 21.
- **Maven** is Ubuntu's `maven` package, 3.8.7. It needs no Wrapper, because every plugin is pinned.
  It pulls in a Java 21 runtime of its own, which `update-alternatives` ranks below 25.
- **The layout** is Maven's standard one: `src/main/java`, `src/test/java`, groupId `com.example`,
  artifactId the project's name, base package `com.example.<artifactId>`, and
  `maven.compiler.release` 25 with UTF-8 sources.
- **The plugins**, pinned in `pluginManagement` in every `pom.xml`: maven-clean-plugin 3.5.0,
  maven-resources-plugin 3.5.0, maven-compiler-plugin 3.15.0, maven-surefire-plugin 3.5.6,
  maven-jar-plugin 3.5.1, maven-install-plugin 3.2.0. A course that adds one, a test framework
  for instance, pins it the same way.
- **What every build prints first** is four `WARNING` lines about `sun.misc.Unsafe`, from the
  Guava inside Ubuntu's Maven running on JDK 25. Lesson 18 explains them; they are harmless.

## Ageing

**Low.** LTS releases and a compatibility record measured in decades. Lesson 40 (JPMS) is the one nobody uses and it is honest to keep.

## Flags

**1 ·** **Forty lessons at 2.00 hours each**, the same granularity as `go` and for the same reason: a beginner language course written as one idea per lesson. 4.3 sections a lesson, on the floor.

**2 ·** **Lesson 30 is the course knowing where its readers fall over** — *"Pass by value: the most common misunderstanding in Java"* — and it arrives after twenty-nine lessons that make the misunderstanding possible. Right position, and the kind of lesson that gets moved earlier by somebody tidying.

**3 ·** **It opens the second-most expensive path in the fork**: `java` → `java-functional` → `java-back` is 220 hours, against 140 for JavaScript. Fewer courses than Go's four and still 1.57× the cheapest option.
