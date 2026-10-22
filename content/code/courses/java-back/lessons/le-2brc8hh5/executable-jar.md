---
title: A jar that carries its libraries
version: 1
---

A server needs one thing from this course: a file it can start with Java and nothing else. Lesson 4
ran the bookshop with `java -jar` and promised a look inside; this section keeps that promise,
because everything later in the lesson, the layers and the image, is built out of what is in there.

The usual picture of an executable jar is one jar with every library's classes poured into it. That
is what lesson 8's **maven-shade-plugin** does, and it is not what Spring Boot does. Boot keeps each
library as a whole jar, inside the bookshop's jar, and adds a small program whose only job is to read
them from there.

## Two files from one build

Build the bookshop as lesson 22 left it. `-q` keeps Maven quiet unless something goes wrong, and
`-DskipTests` leaves the tests out, because this lesson is about the file and lesson 19 already runs
them:

```
ana@vm:~/bookshop$ mvn -q package -DskipTests
ana@vm:~/bookshop$ ls -lh target/bookshop-0.1.0.jar*
-rw-r--r-- 1 ana ana 66M Oct 22 20:09 target/bookshop-0.1.0.jar
-rw-r--r-- 1 ana ana 47K Oct 22 20:09 target/bookshop-0.1.0.jar.original
```

Two jars. `bookshop-0.1.0.jar.original` is what Maven's own jar plugin made: the bookshop's classes
and resources, 47 KiB. Then `spring-boot-maven-plugin` ran its `repackage` goal, renamed that file
aside and wrote the 66 MiB one in its place. The small one cannot run on its own:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar.original
no main manifest attribute, in target/bookshop-0.1.0.jar.original
```

Its manifest names no class to start, and the classes it does hold would fail at once anyway, with
Spring nowhere on the class path. That was lesson 1's problem, and the class path typed by hand was
lesson 1's answer to it.

## What is inside

A jar is a zip file, so the JDK's `jar` tool can list it. Grouped by their first two directories,
leaving out the directory entries themselves:

```
ana@vm:~/bookshop$ jar tf target/bookshop-0.1.0.jar | grep -v '/$' | cut -d/ -f1-2 | sort | uniq -c
     42 BOOT-INF/classes
      1 BOOT-INF/classpath.idx
      1 BOOT-INF/layers.idx
    112 BOOT-INF/lib
      1 META-INF/MANIFEST.MF
      1 META-INF/build-info.properties
      2 META-INF/maven
      1 META-INF/services
     99 org/springframework
```

Four kinds of thing, and two of them are big:

- **`BOOT-INF/lib`**, 112 entries: every library the bookshop needs at run time, one jar each. The
  test libraries are not among them; Maven's `test` scope keeps them out.
- **`BOOT-INF/classes`**, 42 files: the bookshop's own classes, its properties files and its Flyway
  migrations, as `target/classes` had them.
- **`org/springframework`**, 99 classes: Spring Boot's loader, as plain classes at the top of the jar.
- **`META-INF`** and two index files: the manifest, the build information lesson 22 published, and
  the lists that the next sections read.

The libraries are jars, with their versions in their names:

```
ana@vm:~/bookshop$ jar tf target/bookshop-0.1.0.jar | grep '^BOOT-INF/lib/' | head -n 5
BOOT-INF/lib/
BOOT-INF/lib/logback-classic-1.5.38.jar
BOOT-INF/lib/logback-core-1.5.38.jar
BOOT-INF/lib/log4j-to-slf4j-2.25.5.jar
BOOT-INF/lib/log4j-api-2.25.5.jar
```

## The manifest names two classes

```
ana@vm:~/bookshop$ unzip -p target/bookshop-0.1.0.jar META-INF/MANIFEST.MF
Manifest-Version: 1.0
Created-By: Maven JAR Plugin 3.5.1
Java-Version: 25
Build-Jdk-Spec: 25
Implementation-Title: bookshop
Implementation-Version: 0.1.0
Main-Class: org.springframework.boot.loader.launch.JarLauncher
Start-Class: com.example.bookshop.BookshopApplication
Spring-Boot-Version: 4.1.1
Spring-Boot-Classes: BOOT-INF/classes/
Spring-Boot-Lib: BOOT-INF/lib/
Spring-Boot-Classpath-Index: BOOT-INF/classpath.idx
Spring-Boot-Layers-Index: BOOT-INF/layers.idx
```

`Main-Class` is the attribute the JVM reads, the same one lesson 8's shaded jar had. Here it does not
name the bookshop. It names `JarLauncher`, and the bookshop's own class is in `Start-Class`, an
attribute only Spring Boot reads. `Spring-Boot-Classes` and `Spring-Boot-Lib` tell the launcher where
the rest is.

The indirection exists because **the JVM's class loader cannot load a class from a jar that is inside
another jar**. It reads directories and jar files on the class path, and a nested jar is neither. So
`java -jar` starts the one class it can reach, `JarLauncher`, which is an ordinary class at the top of
the jar. The launcher builds a class loader of its own over `BOOT-INF/classes` and each jar in
`BOOT-INF/lib`, and then calls `BookshopApplication.main` through it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The executable jar holds four things: the manifest, Spring Boot's launcher as plain classes, the bookshop's classes under BOOT-INF/classes, and 112 library jars stored whole under BOOT-INF/lib. java -jar reads Main-Class and runs the launcher, the launcher builds a class loader over the classes and the nested jars, and then calls the main method of Start-Class.\"><defs><marker id=\"l23-ah\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">bookshop-0.1.0.jar</text><rect x=\"20\" y=\"30\" width=\"430\" height=\"262\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"36\" y=\"44\" width=\"398\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"48\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">META-INF/MANIFEST.MF</text><text x=\"48\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Main-Class and Start-Class</text><rect x=\"36\" y=\"96\" width=\"398\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"48\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">org/springframework/boot/loader/</text><text x=\"48\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the launcher, as plain classes</text><rect x=\"36\" y=\"148\" width=\"398\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"48\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BOOT-INF/classes/</text><text x=\"48\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the bookshop's classes and files</text><rect x=\"36\" y=\"200\" width=\"398\" height=\"80\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"48\" y=\"213\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BOOT-INF/lib/</text><text x=\"48\" y=\"229\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">112 jars, each stored whole, uncompressed</text><rect x=\"48\" y=\"242\" width=\"180\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"56\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">spring-core-7.0.9.jar</text><rect x=\"238\" y=\"242\" width=\"180\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"246\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">hibernate-core-7.4.5.Final.jar</text><text x=\"482\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1  java -jar reads Main-Class</text><text x=\"482\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2  JarLauncher builds a class loader</text><text x=\"482\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3  it calls main() of Start-Class</text><path d=\"M 478 64 L 438 64\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-ah)\"></path><path d=\"M 478 116 L 438 116\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-ah)\"></path><path d=\"M 478 168 L 438 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-ah)\"></path><text x=\"498\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">over classes/ and lib/</text><path d=\"M 678 116 L 700 116\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M 700 116 L 700 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M 700 250 L 438 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-ah)\" stroke-dasharray=\"3 3\"></path><text x=\"482\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and reads the nested jars in place</text></svg>", "caption": "One file, read in three steps. Only the launcher is a class the JVM can load on its own; everything else is reached through it."}
```

For that to be quick, a nested jar has to be readable where it lies, without being unpacked first.
`unzip -v` shows how each entry is stored:

```
ana@vm:~/bookshop$ unzip -v target/bookshop-0.1.0.jar | grep -E 'hibernate-core|BookshopApplication.class'
     753  Defl:N      421  44% 2026-10-22 20:09 ff19c656  BOOT-INF/classes/com/example/bookshop/BookshopApplication.class
15279748  Stored 15279748   0% 1980-02-01 00:00 e10da7f3  BOOT-INF/lib/hibernate-core-7.4.5.Final.jar
```

The bookshop's class is `Defl:N`, compressed like any file in a zip. Hibernate's jar, 15 MB of it, is
**`Stored`**: the exact bytes, at a known position in the outer file, which the launcher opens in
place. Compressing it again would have gained almost nothing, since a jar is already compressed
inside. Notice the date too: every nested jar carries `1980-02-01 00:00`, the same in every build, so
the same libraries give the same bytes whenever they are packaged. Two sections on, that is what lets
Docker recognise a layer it already has.

The launcher is a handful of classes, and `JarLauncher` is one of three:

```
ana@vm:~/bookshop$ jar tf target/bookshop-0.1.0.jar | grep 'loader/launch/.*Launcher.class'
org/springframework/boot/loader/launch/ExecutableArchiveLauncher.class
org/springframework/boot/loader/launch/JarLauncher.class
org/springframework/boot/loader/launch/Launcher.class
org/springframework/boot/loader/launch/PropertiesLauncher.class
org/springframework/boot/loader/launch/WarLauncher.class
```

`WarLauncher` starts the same kind of archive packaged as a `.war`, and `PropertiesLauncher` reads its
class path from properties at start-up. The bookshop needs neither.

So the deliverable is **one file, and a server needs nothing but a Java 25 runtime to start it**: no
Maven, no Tomcat installed separately, no directory of libraries beside it.
