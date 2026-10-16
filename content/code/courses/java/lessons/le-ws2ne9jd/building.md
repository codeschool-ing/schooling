---
title: A jar that runs, and the build that runs on the wrong Java
version: 1
---

A jar is a zip file of class files with a small text file inside, the **manifest**, that says things
about the rest. `java -jar` runs a jar, and to do that it reads one line of the manifest. The jar
section 04 built does not have that line:

```
ana@vm:~/library$ java -jar target/library-1.0-SNAPSHOT.jar
no main manifest attribute, in target/library-1.0-SNAPSHOT.jar
```

**`no main manifest attribute`**: the JVM opened the jar, read its manifest, and found no
`Main-Class`, so it had no class to start. Nothing tells Maven which of a project's classes holds
the `main` to run; a library has none and a big program can have several. The jar plugin writes the
line when it is told, in its configuration. This is the whole `pom.xml` again, with one addition at
the end, a `<plugins>` element after `pluginManagement`:

```xml
<!-- pom.xml -->
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.example</groupId>
  <artifactId>library</artifactId>
  <version>1.0-SNAPSHOT</version>

  <properties>
    <maven.compiler.release>25</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

  <build>
    <pluginManagement>
      <plugins>
        <plugin>
          <artifactId>maven-clean-plugin</artifactId>
          <version>3.5.0</version>
        </plugin>
        <plugin>
          <artifactId>maven-resources-plugin</artifactId>
          <version>3.5.0</version>
        </plugin>
        <plugin>
          <artifactId>maven-compiler-plugin</artifactId>
          <version>3.15.0</version>
        </plugin>
        <plugin>
          <artifactId>maven-surefire-plugin</artifactId>
          <version>3.5.6</version>
        </plugin>
        <plugin>
          <artifactId>maven-jar-plugin</artifactId>
          <version>3.5.1</version>
        </plugin>
        <plugin>
          <artifactId>maven-install-plugin</artifactId>
          <version>3.2.0</version>
        </plugin>
      </plugins>
    </pluginManagement>
    <plugins>
      <plugin>
        <artifactId>maven-jar-plugin</artifactId>
        <configuration>
          <archive>
            <manifest>
              <mainClass>com.example.library.App</mainClass>
            </manifest>
          </archive>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>
```

The first line, `<!-- pom.xml -->`, is an XML comment that says which file this is, and Maven
ignores it. The new `<plugin>` carries no `<version>`: the one in `pluginManagement` applies.
**`pluginManagement` decides a plugin's version, and `plugins` decides what it does**, which is why
the course keeps the two apart. `-q`, quiet, prints nothing but warnings and errors, which is how a
build that works looks once you trust it:

```
ana@vm:~/library$ mvn -q package
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
WARNING: sun.misc.Unsafe::objectFieldOffset has been called by com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper (file:/usr/share/maven/lib/guava.jar)
WARNING: Please consider reporting this to the maintainers of class com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper
WARNING: sun.misc.Unsafe::objectFieldOffset will be removed in a future release
ana@vm:~/library$ java -jar target/library-1.0-SNAPSHOT.jar
The library has Effective Java
ana@vm:~/library$ jar tf target/library-1.0-SNAPSHOT.jar
META-INF/
META-INF/MANIFEST.MF
com/
com/example/
com/example/library/
META-INF/maven/
META-INF/maven/com.example/
META-INF/maven/com.example/library/
com/example/library/Book.class
com/example/library/App.class
META-INF/maven/com.example/library/pom.xml
META-INF/maven/com.example/library/pom.properties
ana@vm:~/library$ jar xf target/library-1.0-SNAPSHOT.jar META-INF/MANIFEST.MF && cat META-INF/MANIFEST.MF
Manifest-Version: 1.0
Created-By: Maven JAR Plugin 3.5.1
Java-Version: 25
Build-Jdk-Spec: 25
Main-Class: com.example.library.App
```

**`Main-Class: com.example.library.App`**, the full name, and now `java -jar` starts it. The listing
shows what else is in a Maven jar: the package directories with the two classes, and a copy of
`pom.xml` under `META-INF/maven`, so a jar found on its own still says where it came from.
`java -jar` ignores `-cp`: everything the program needs must be in the jar or named in the
manifest, which matters the day a project uses a library, in `java-back`.

## The build on the wrong Java

Lesson 1 section 04 left a promise: with `JAVA_HOME` pointing at Ubuntu's `default-java`, which is
the Java 21 that came with Maven, the first project that asks for 25 fails. Here it is:

```
ana@vm:~/library$ JAVA_HOME=/usr/lib/jvm/default-java mvn -q clean package
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.15.0:compile (default-compile) on project library: Fatal error compiling: error: release version 25 not supported -> [Help 1]
[ERROR] 
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR] 
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoExecutionException
ana@vm:~/library$ mvn -q clean package && echo built
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
WARNING: sun.misc.Unsafe::objectFieldOffset has been called by com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper (file:/usr/share/maven/lib/guava.jar)
WARNING: Please consider reporting this to the maintainers of class com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper
WARNING: sun.misc.Unsafe::objectFieldOffset will be removed in a future release
built
```

**`release version 25 not supported`**, from inside the compiler plugin: Maven ran on Java 21, and
Java 21's `javac` cannot produce version 69 class files. The message never says Maven was on the
wrong Java. You have to know that the release in the message is the one in `pom.xml`, and that the
JDK refusing it is whichever one Maven found. Note what is missing, too: on Java 21 the four
`Unsafe` warnings of section 04 do not appear, because only Java 24 and later print them.

The second command, with `JAVA_HOME` left unset, built cleanly. **When a build says a release is not
supported, run `mvn -v` and read its `Java version` line** before anything else.
