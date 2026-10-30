---
title: The wrapper pins Gradle
version: 1
---

Since lesson 14 every build has started with `./gradlew`, not `gradle`. The difference is the whole
reason a Gradle project builds the same on two machines. **`gradlew` is a small script, kept in the
project, that downloads one exact Gradle version and runs it**, whatever Gradle the machine has installed,
or none. The version lives in one file:

```
ana@vm:~/kt/planner$ cat gradle/wrapper/gradle-wrapper.properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-9.8.2-bin.zip
networkTimeout=10000
retries=0
retryBackOffMs=500
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
```

`distributionUrl` names the version, 9.8.2. The first `./gradlew` on a machine downloads that zip into
`~/.gradle/wrapper/dists`, which is the wait lesson 14 saw; every later run finds it there. The rest
are settings for that download.

```
ana@vm:~/kt/planner$ ./gradlew --version

------------------------------------------------------------
Gradle 9.8.2
------------------------------------------------------------

Build time:    2026-10-19 16:29:26 UTC
Revision:      8de7bcf76e785507ad92f0741ab9235a430c95e6

Kotlin:        2.4.10
Groovy:        4.0.33
Ant:           Apache Ant(TM) version 1.10.17 compiled on April 6 2026
Launcher JVM:  21.0.12.1 (Ubuntu 21.0.12.1+1-1-24.04.4-Ubuntu)
Daemon JVM:    /usr/lib/jvm/java-21-openjdk-amd64 (no Daemon JVM specified, using current Java home)
OS:            Linux 6.18.44-fc-v185 amd64
```

Two Kotlin versions are in play, and this output shows the one people confuse. **The `Kotlin: 2.4.10`
line is the Kotlin Gradle uses to run your `.gradle.kts` scripts**, built into Gradle itself. The Kotlin
that compiles your program is the plugin's, `2.4.21`, named in `build.gradle.kts`. The two move
separately, and neither has to match the other.

## What goes into version control

| file | commit it? |
|---|---|
| `gradlew`, `gradlew.bat` | yes: the scripts for Linux and macOS, and for Windows |
| `gradle/wrapper/gradle-wrapper.jar`, `gradle-wrapper.properties` | yes: the downloader and its version |
| `build/`, `.gradle/` | no: produced by the build, and rebuilt from the rest |

Upgrading Gradle is a command that rewrites the properties file, `./gradlew wrapper --gradle-version`
followed by the version, and the change is one line a reviewer can read.
