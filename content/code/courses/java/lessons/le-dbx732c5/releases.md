---
title: Versions, and why this course uses 25
version: 1
---

A Java version is two things that are easy to confuse: **the language and its library**, which
change by release, and **the build of one JDK**, which a vendor patches inside a release. The
version string carries both, and the class file carries a third number that follows the first.

## A release every six months, a long one every two years

Until 2017 a new Java arrived when it was ready, and the gaps ran to five years. Since Java 10, in
March 2018, **a feature release comes out every March and every September**, whether or not a
large feature is ready: whatever is finished goes in, and whatever is not waits six months.

Most of those releases are supported only until the next one, six months later. **Every two years
one is a long-term support release, LTS**, which vendors keep patching for years. Companies run the
LTS releases and skip the rest, so those are the versions you meet at work:

| release | out | class file major version | |
|---|---|---|---|
| Java 8 | March 2014 | 52 | LTS, still running in a great many companies |
| Java 11 | September 2018 | 55 | LTS |
| Java 17 | September 2021 | 61 | LTS |
| Java 21 | September 2023 | 65 | LTS, the one Maven pulled in |
| **Java 25** | **September 2025** | **69** | **LTS, the one this course uses** |

The major version is the release plus 44, a habit kept since the first one. **This course uses 25
because it is the newest LTS** and because Ubuntu 24.04 packages it. Everything it teaches works on
25 and on every later release; a handful of things, each named where it appears, do not exist on 21.

## Reading the version string

```
ana@vm:~/jvm$ java -version
openjdk version "25.0.4.1" 2026-08-18
OpenJDK Runtime Environment (build 25.0.4.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 25.0.4.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
ana@vm:~/jvm$ java -XshowSettings:properties -version 2>&1 | grep -E "java.(version|vendor|specification.version) ="
    java.specification.version = 25
    java.vendor = Ubuntu
    java.version = 25.0.4.1
```

`25.0.4.1` is four numbers, by a rule the JDK has followed since Java 10:

| position | here | means |
|---|---|---|
| feature | 25 | the release: language, library and class file version |
| interim | 0 | always 0 so far |
| update | 4 | the fourth security and bug-fix update of 25 |
| patch | 1 | an urgent fix on top of that update |

The date is when that build was released, and everything after `build` belongs to whoever built
it, here Ubuntu, for its 24.04 archive. `java.specification.version` is the number a program can ask
for when it wants to know which release it runs on, and it is the feature number alone. `mixed mode`
on the last line is section 05's interpreter and JIT, working together.

## Old class files run on new JVMs

The compatibility record is the reason a 2014 program still runs, and you can watch it. `javac`
takes `--release N` and compiles for release N as if it were that JDK, with that release's library
and that class file version:

```
ana@vm:~/jvm$ javac --release 8 Hello.java
warning: [options] source value 8 is obsolete and will be removed in a future release
warning: [options] target value 8 is obsolete and will be removed in a future release
warning: [options] To suppress warnings about obsolete options, use -Xlint:-options.
3 warnings
ana@vm:~/jvm$ javap -v Hello.class | grep major
  major version: 52
ana@vm:~/jvm$ java Hello
Hello, Java
ana@vm:~/jvm$ javac --release 7 Hello.java; echo $?
error: release version 7 not supported
Usage: javac <options> <source files>
use --help for a list of possible options
2
ana@vm:~/jvm$ javac --release 25 Hello.java && javap -v Hello.class | grep major
  major version: 69
```

Four things in that transcript, in order:

1. **Version 52, Java 8's, ran on the Java 25 JVM** without a word. A JVM runs every class file
   version up to its own, which is the other half of section 04's `UnsupportedClassVersionError`.
2. `javac` warned three times and compiled anyway. **A warning does not stop a build**; it says
   that compiling for 8 will stop working in some future JDK. Read them, as you would any message.
3. Java 7 is gone: `javac` 25 cannot produce version 51 at all, and refused with exit status 2.
4. `--release 25` put the number back to 69, which is the default and what every later lesson uses.

**`--release` is how a team builds on a new JDK for an old server.** Compile with `--release 21`
and the class files run on 21, which is the second fix section 04 promised. The flag also refuses any library call
that release did not have, which a plain change of the version number would not catch until the
program ran. Lesson 18 sets the same thing for a whole project, in Maven's file, as
`maven.compiler.release`.
