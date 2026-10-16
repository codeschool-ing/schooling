---
title: A Maven project, and the layout this course keeps
version: 1
---

`javac -d out` with a list of files works for two classes and stops working long before two hundred.
Somebody has to remember which files to compile, which libraries to put on the class path, and how
to pack the result. **Maven is the program that does it from a description of the project**, a file
called `pom.xml`, and most Java projects at work are built by it or by Gradle, which does the same
job. Lesson 1 installed Ubuntu's Maven 3.8.7.

This section decides the layout of every project in this course and in the two that follow it,
`java-functional` and `java-back`, so it is worth getting exactly right once.

## The layout

Maven expects files in fixed places, and in exchange needs to be told almost nothing:

| path | what goes there |
|---|---|
| `pom.xml` | the project's description, at its root |
| `src/main/java` | the program's source, in package directories |
| `src/main/resources` | files the program reads, copied next to the classes |
| `src/test/java` | the tests, in the same packages as what they test |
| `target` | everything Maven produces; deleted by `mvn clean`, never committed |

**The course's decisions**, which the next two courses continue: `groupId` is `com.example`, the
`artifactId` is the project's name, and every class lives under the package
`com.example.<artifactId>`, here `com.example.library`. Classes compile for release 25, and every
plugin is pinned.

## The `pom.xml`

Make a directory `~/library` and save this as `pom.xml` in it:

```schooling-example
{
  "language": "xml",
  "file": "pom.xml",
  "parts": [
    {
      "code": "<project xmlns=\"http://maven.apache.org/POM/4.0.0\"\n         xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n         xsi:schemaLocation=\"http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd\">\n  <modelVersion>4.0.0</modelVersion>",
      "note": "**The root element and the model version.** Every `pom.xml` opens like this, and nobody types it from memory: copy these four lines. `4.0.0` is the only model version Maven 3 understands. There is deliberately no `<?xml ...?>` declaration line; it is optional, and the file is UTF-8 either way."
    },
    {
      "code": "\n  <groupId>com.example</groupId>\n  <artifactId>library</artifactId>\n  <version>1.0-SNAPSHOT</version>",
      "note": "**The project's coordinates, which together name what it builds.** `groupId` is the reversed domain, as in a package name; `artifactId` is the project's own name; `version` ends in `-SNAPSHOT` while the code is still changing. The jar is named after the last two: `library-1.0-SNAPSHOT.jar`."
    },
    {
      "code": "\n  <properties>\n    <maven.compiler.release>25</maven.compiler.release>\n    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>\n  </properties>",
      "note": "**Two settings for every plugin that reads them.** `maven.compiler.release` is lesson 1's `--release`, handed to `javac`, so the classes are version 69 whatever JDK runs Maven. The encoding stops the build depending on the machine's locale."
    },
    {
      "code": "\n  <build>\n    <pluginManagement>\n      <plugins>\n        <plugin>\n          <artifactId>maven-clean-plugin</artifactId>\n          <version>3.5.0</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-resources-plugin</artifactId>\n          <version>3.5.0</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-compiler-plugin</artifactId>\n          <version>3.15.0</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-surefire-plugin</artifactId>\n          <version>3.5.6</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-jar-plugin</artifactId>\n          <version>3.5.1</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-install-plugin</artifactId>\n          <version>3.2.0</version>\n        </plugin>\n      </plugins>\n    </pluginManagement>\n  </build>\n</project>",
      "note": "**Every plugin the build uses, pinned to one version.** Maven does its work through plugins, and without a version here Ubuntu's Maven 3.8.7 would pick its own defaults, years older than these and too old to know `maven.compiler.release` at all. With them, this Maven builds exactly what a current one would. `pluginManagement` fixes the version wherever a plugin runs, without making it run."
    }
  ]
}
```

Then the program. `App` goes in `src/main/java/com/example/library/App.java`:

```java
// src/main/java/com/example/library/App.java
package com.example.library;

public class App {
    public static void main(String[] args) {
        Book book = new Book("Effective Java");
        System.out.println("The library has " + book.title());
    }
}
```

`App` uses `Book` from section 02, in the same package now; it is not shown again, and a copy is
enough:

```
ana@vm:~/library$ mkdir -p src/main/java/com/example/library && cp ~/pkgs/src/com/example/library/Book.java src/main/java/com/example/library/
ana@vm:~/library$ find . -type f | sort
./pom.xml
./src/main/java/com/example/library/App.java
./src/main/java/com/example/library/Book.java
```

Three files, and the package path under `src/main/java` is the same as it was under `src`.

## The first build downloads Maven

A build runs a fixed sequence of **phases**, and `mvn package` runs every phase up to `package`:
copy the resources, compile, compile and run the tests, and pack a jar. The first time, Maven has
none of the plugins that do that work, so it downloads them from Maven Central into
`~/.m2/repository` on your machine. Ana kept that first build's output in a file, with `-B`, batch
mode, which leaves out colours and progress counters:

```
ana@vm:~/library$ mvn -B clean package > first-build.log; echo $?
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
WARNING: sun.misc.Unsafe::objectFieldOffset has been called by com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper (file:/usr/share/maven/lib/guava.jar)
WARNING: Please consider reporting this to the maintainers of class com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper
WARNING: sun.misc.Unsafe::objectFieldOffset will be removed in a future release
0
ana@vm:~/library$ grep -c "Downloaded from" first-build.log
158
ana@vm:~/library$ tail -5 first-build.log
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  23.771 s
[INFO] Finished at: 2026-10-16T19:56:58-03:00
[INFO] ------------------------------------------------------------------------
```

**158 downloads**, the pinned plugins and the libraries they use, and the next build needs none of
them. Delete `~/.m2/repository` and they come back on the next build. The number differs a little
between Maven versions, and the times on the last lines differ on every run.

The four `WARNING` lines went to the screen and not to the file, because the JVM writes them to the
error stream before Maven starts. They come from Maven's own copy of a library called Guava, in
`/usr/share/maven/lib/guava.jar`, which uses `sun.misc.Unsafe`, an internal part of the JDK whose
memory methods are being retired. **Since Java 24 the JVM warns once per run when they are used.**
They say nothing about your project, they appear on every `mvn` command in this course, and nothing
you can change in `pom.xml` removes them. Section 05 shows Maven running on Java 21, where they are
absent.

## Every build after that

```
ana@vm:~/library$ mvn clean package
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
WARNING: sun.misc.Unsafe::objectFieldOffset has been called by com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper (file:/usr/share/maven/lib/guava.jar)
WARNING: Please consider reporting this to the maintainers of class com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper
WARNING: sun.misc.Unsafe::objectFieldOffset will be removed in a future release
[INFO] Scanning for projects...
[INFO] 
[INFO] ------------------------< com.example:library >-------------------------
[INFO] Building library 1.0-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-clean-plugin:3.5.0:clean (default-clean) @ library ---
[INFO] Deleting /home/ana/library/target
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:resources (default-resources) @ library ---
[INFO] skip non existing resourceDirectory /home/ana/library/src/main/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:compile (default-compile) @ library ---
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 2 source files with javac [debug release 25] to target/classes
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:testResources (default-testResources) @ library ---
[INFO] skip non existing resourceDirectory /home/ana/library/src/test/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:testCompile (default-testCompile) @ library ---
[INFO] No sources to compile
[INFO] 
[INFO] --- maven-surefire-plugin:3.5.6:test (default-test) @ library ---
[INFO] No tests to run.
[INFO] 
[INFO] --- maven-jar-plugin:3.5.1:jar (default-jar) @ library ---
[INFO] Building jar: /home/ana/library/target/library-1.0-SNAPSHOT.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.813 s
[INFO] Finished at: 2026-10-16T19:57:02-03:00
[INFO] ------------------------------------------------------------------------
```

Read it from the top: each `---` line names a plugin, its version and the goal it ran, in the order
of the phases. `clean` deleted `target`, `resources` found no `src/main/resources` and said so,
`compile` compiled two files `with javac [debug release 25]`, there were no tests, and `jar` packed
the result. **`BUILD SUCCESS` and an exit status of 0 are the verdict**; everything above them is the
log. What it produced:

```
ana@vm:~/library$ find target -name "*.class" -o -name "*.jar" | sort
target/classes/com/example/library/App.class
target/classes/com/example/library/Book.class
target/library-1.0-SNAPSHOT.jar
ana@vm:~/library$ java -cp target/classes com.example.library.App
The library has Effective Java
```

The classes are in `target/classes`, in the package directories of section 02, so `java -cp
target/classes` runs them as `-cp out` did. The jar is the same classes in one file, and section 05
makes it runnable on its own.
