---
title: Java and Maven, installed
version: 1
---

**REST Assured is a Java library, so the tests of this lesson are Java programs.** To write and run
them you need two things. One is a Java Development Kit, which compiles and runs Java. The other is
a build tool, which downloads the libraries a project names and runs its tests. The build tool here
is Maven. An IDE such as IntelliJ IDEA is not one of the two. It is a comfortable place to write
Java, and everything below works from a terminal and the editor you already use.

## Installing them

On Ubuntu 24.04 or in WSL, both come from Ubuntu's own packages, in one line:

```sh
sudo apt-get install -y openjdk-21-jdk-headless maven
```

`openjdk-21` is Java 21, a long-term support release and the default JDK of Ubuntu 24.04. `-jdk` is
the development kit, with the compiler, rather than only the runtime that runs finished programs.
`-headless` leaves out the libraries for drawing windows, which a test of an API never opens. Maven
arrives in the version Ubuntu packages, which is older than Maven's own latest release. That matters
once, in section 07, and the project of the next section is written so that it does not matter
anywhere else.

Both answer when asked their version:

```
ana@laptop:~$ java -version
openjdk version "21.0.12.1" 2026-08-18
OpenJDK Runtime Environment (build 21.0.12.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 21.0.12.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
ana@laptop:~$ mvn -version
Apache Maven 3.8.7
Maven home: /usr/share/maven
Java version: 21.0.12.1, vendor: Ubuntu, runtime: /usr/lib/jvm/java-21-openjdk-amd64
Default locale: en, platform encoding: UTF-8
OS name: "linux", version: "6.18.44-fc-v114", arch: "amd64", family: "unix"
```

Read two lines of the second answer. `Apache Maven 3.8.7` is the build tool, and
`Java version: 21.0.12.1` is **the JDK Maven will compile your tests with**. That is not always the
one `java -version` names. On a machine with two JDKs installed, Maven uses the one `JAVA_HOME`
points at, and a test that compiles in one terminal and not in another is usually that.

On a Mac, Homebrew installs both with `brew install openjdk@21 maven`, and the version numbers
will differ from these. That was not run for this course.

## What Maven does for a test project

Three jobs, and every line of the next section's `pom.xml` serves one of them.

- It fetches libraries. A project lists what it depends on by three names: a group, an artifact and
  a version, such as `io.rest-assured`, `rest-assured`, `6.0.1`. Maven downloads each one from
  **Maven Central**, the public repository of Java libraries, together with everything that library
  depends on in turn. It keeps them in `~/.m2/repository`, so the next project does not download
  them again.
- It knows where things go. Test code lives in `src/test/java`, in directories that repeat the
  package name, and compiled classes go to `target`. Nobody configures that; a project that follows
  the layout gets it for free, and one that does not finds nothing runs.
- It runs the build in phases. `mvn test` compiles the code, compiles the tests, then runs them,
  stopping at the first phase that fails. Each phase is the work of a **plugin**: the compiler
  plugin compiles and the Surefire plugin runs the tests. Plugins are libraries too, with versions
  of their own, and section 07 shows why the project names those versions rather than taking
  Maven's.
