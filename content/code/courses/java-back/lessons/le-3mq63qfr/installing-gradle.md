---
title: Installing Gradle, once
version: 1
---

Ubuntu's archive has a `gradle` package, and it is the wrong one to install. It is years behind
the current release, and it cannot build this lesson's project: Gradle has to be newer than the
Java it runs on, and Java 25 needs Gradle 9.1 or later. **Gradle is installed from its own
distribution, a zip file**, and on a project you install it once, for one job, which the next two
sections explain.

## The zip, and its checksum

Gradle publishes every release at `services.gradle.org/distributions`. This lesson uses 9.8.1:

```
ana@vm:~$ curl -sLO https://services.gradle.org/distributions/gradle-9.8.1-bin.zip
ana@vm:~$ ls -l gradle-9.8.1-bin.zip
-rw-r--r-- 1 ana ana 151620101 Oct 16 20:23 gradle-9.8.1-bin.zip
```

`-L` follows redirects, which matters here: the address answers with a redirect to GitHub, where
the file is actually stored. `-O` keeps the file's own name. The `-bin` zip holds Gradle itself;
the `-all` zip adds the sources and the documentation, which an editor can use and a build never
does.

A file that crossed two servers should be checked before anything runs from it. **The SHA-256
checksum of the bytes on your disk** must equal the one Gradle published for the release.
Gradle's site lists it beside each download on its release-checksums page, and the same value is
in the versions service, which a command can read:

```
ana@vm:~$ sha256sum gradle-9.8.1-bin.zip
dce76f55f8e251a3a1f130eb120f30b3d271de2b76c9b0729d316b5a1b6dc01f  gradle-9.8.1-bin.zip
ana@vm:~$ curl -s https://services.gradle.org/versions/all | python3 -c 'import json, sys; print(next(v["checksum"] for v in json.load(sys.stdin) if v["version"] == "9.8.1"))'
dce76f55f8e251a3a1f130eb120f30b3d271de2b76c9b0729d316b5a1b6dc01f
```

The two lines agree. Comparing 64 characters by eye is the weak part of this step, and the next
section but one hands the comparison to a program, on every machine that will ever build the
project.

## Unpacking it where nobody else looks

The zip unpacks into one directory, and a directory in your home needs no `sudo`:

```
ana@vm:~$ mkdir -p ~/opt && unzip -q gradle-9.8.1-bin.zip -d ~/opt
ana@vm:~$ ls ~/opt/gradle-9.8.1
LICENSE
NOTICE
README
bin
init.d
lib
```

A fresh Ubuntu Server may not have `unzip` at all, and then the shell reports that it cannot find
the command. `sudo apt install unzip` brings it; this machine already had it, so that command is
shown here and was not run.

Run it by its full path:

```
ana@vm:~$ ~/opt/gradle-9.8.1/bin/gradle --version

Welcome to Gradle 9.8.1!

Here are the highlights of this release:
 - Java 27 support
 - Maven mirror settings reuse
 - Linked problem locations in build output

For more details see https://docs.gradle.org/9.8.1/release-notes.html


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
OS:            Linux 6.18.44-fc-v139 amd64

ana@vm:~$ command -v gradle || echo "not on PATH"
not on PATH
```

The welcome text appears the first time each Gradle version runs for a user, and not again. Below
it, read three lines. `Kotlin: 2.4.10` is the language the build script in the next section is
written in, and Gradle carries its own compiler for it, so nothing else needs installing. `Launcher
JVM` is the Java that started Gradle: the JDK 25 from Ubuntu's archive, the one `java` lesson 1
installed. `Daemon JVM` is the Java of the background process that does the actual building,
which the last section of this lesson meets, and here it is the same JDK.

**`gradle` is deliberately not on `PATH`.** Most guides add it there. This lesson does not need
to, because the installed Gradle will be run exactly once more, by its full path, to give the
project a wrapper. After that every build goes through the project's own `./gradlew`, and the
copy in `~/opt` only matters again on the day you start another project.
