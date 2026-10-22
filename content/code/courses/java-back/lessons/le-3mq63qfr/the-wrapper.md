---
title: The wrapper, and why a team commits it
version: 1
---

A build that depends on whichever Gradle each developer happened to install is a build that
behaves differently on each machine. A Gradle older than 9.1 cannot run on Java 25 at all, and
two releases a year apart differ in what they assume, as the JUnit launcher in the section on
tasks shows. **The wrapper takes the choice away from the machine**: a small script and jar, committed with the project, that download the exact Gradle the
project names and run the build with it.

## Generating it

This is the one other time the Gradle in `~/opt` runs. The `wrapper` task writes the wrapper's
files, and the two options pin the version and its checksum, the one checked by eye in the first
section:

```
ana@vm:~/isbn-gradle$ ~/opt/gradle-9.8.1/bin/gradle wrapper --gradle-version 9.8.1 --gradle-distribution-sha256-sum dce76f55f8e251a3a1f130eb120f30b3d271de2b76c9b0729d316b5a1b6dc01f
Starting a Gradle Daemon (subsequent builds will be faster)
> Task :wrapper

BUILD SUCCESSFUL in 16s
1 actionable task: 1 executed
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.1/userguide/configuration_cache_enabling.html
ana@vm:~/isbn-gradle$ find . -type f -not -path "./src/*" -not -path "./.gradle/*" | sort
./build.gradle.kts
./gradle.properties
./gradle/wrapper/gradle-wrapper.jar
./gradle/wrapper/gradle-wrapper.properties
./gradlew
./gradlew.bat
./settings.gradle.kts
```

Sixteen seconds for one tiny task is mostly Gradle starting the daemon it mentions and
compiling the two Kotlin scripts for the first time; the last section comes back to both. The
suggestion about the configuration cache is taken up in the section on incremental builds.

Four files are new:

| file | what it is |
|---|---|
| `gradlew` | the script you run on Linux and macOS |
| `gradlew.bat` | the same for Windows |
| `gradle/wrapper/gradle-wrapper.jar` | a small program the scripts start, which reads the properties and fetches Gradle |
| `gradle/wrapper/gradle-wrapper.properties` | which Gradle, from where, and its checksum |

The properties file is the one to read:

```
ana@vm:~/isbn-gradle$ cat gradle/wrapper/gradle-wrapper.properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionSha256Sum=dce76f55f8e251a3a1f130eb120f30b3d271de2b76c9b0729d316b5a1b6dc01f
distributionUrl=https\://services.gradle.org/distributions/gradle-9.8.1-bin.zip
networkTimeout=10000
retries=0
retryBackOffMs=500
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
```

`distributionUrl` is the version, written as the address of its zip. The backslash before the
colon is how a properties file escapes one, and it is not part of the address.
`distributionSha256Sum` is the checksum the wrapper compares every download against: if the bytes
that arrive differ, it refuses them and stops, and that comparison is now made by a program on
every machine, where the first section made it by eye on one. The `dists` lines say where
downloaded versions are kept, under `~/.gradle`.

## The first ./gradlew

Run the wrapper instead of the installed Gradle:

```
ana@vm:~/isbn-gradle$ ./gradlew --version
Fetching distribution.
Downloading https://services.gradle.org/distributions/gradle-9.8.1-bin.zip
..............10%..............20%...............30%..............40%...............50%..............60%...............70%..............80%...............90%..............100%

------------------------------------------------------------
Gradle 9.8.1
------------------------------------------------------------

Build time:    2026-10-07 16:57:46 UTC
Revision:      39daf39feb60a18b1b6ddccde53366522fef516f

Kotlin:        2.4.10
Groovy:        4.0.33
Ant:           Apache Ant(TM) version 1.10.17 compiled on April 6 2026
Launcher JVM:  25.0.4.1 (Ubuntu 25.0.4.1+1-1-24.04.4-Ubuntu)
Daemon JVM:    /usr/lib/jvm/java-25-openjdk-amd64 (no Daemon JVM specified, using current Java home)
OS:            Linux 6.18.44-fc-v153 amd64

ana@vm:~/isbn-gradle$ ls ~/.gradle/wrapper/dists/
gradle-9.8.1-bin
```

**It downloaded Gradle again**, the same zip you already have in `~/opt`. The wrapper does not
look for an installed Gradle and never uses one: it reads `distributionUrl`, fetches that zip once
into `~/.gradle/wrapper/dists`, checks it, and reuses it for every later build of every project
that names the same version. That indifference is the point. A colleague with Gradle 8 installed,
a CI server with none, and you all run 9.8.1, because the project said so.

The usual wrong picture is that the wrapper is a convenience for people who have not installed
Gradle. It is the opposite: **it is how a project chooses its build tool's version**, and it is
why Gradle's documentation and most Gradle projects write `./gradlew` and almost never `gradle`.
Upgrading is a change to the properties file, made by running the `wrapper` task again with a new
version, and it arrives on every machine through the same commit as any other change.

## What goes in the repository

The four wrapper files are committed with the build scripts and the sources, including the jar,
which is about the only binary a Java repository usually carries. Two directories are not: `build/`,
which holds everything the build produces, and `.gradle/`, which Gradle keeps inside the project
for its own bookkeeping. Both are recreated by the next build, and both belong in `.gitignore`.
Ignoring files is ordinary Git, and for a Gradle project those two lines are the whole of it.
