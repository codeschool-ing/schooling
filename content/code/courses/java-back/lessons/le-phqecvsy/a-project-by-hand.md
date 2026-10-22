---
title: A project by hand
version: 1
---

The wrong picture of a build tool is a script: a list of commands somebody wrote to compile and
package their code. Maven is the other way round. **You describe the project, and Maven already
knows the steps.** Where the sources are, what they need, what to produce: those go in one file,
and the commands that turn them into a jar are Maven's, the same in every project that follows
its conventions.

This lesson's project is that file and two classes. It checks ISBNs, the numbers printed on the
back of a book, using a library that is not in the JDK, so that there is something to depend on.
Lessons 2 and 3 build the same two classes with Gradle and with Bazel.

## The layout

Make the directories first. The paths are not a suggestion: they are where Maven looks.

```sh
mkdir -p ~/isbn-check/src/main/java/com/example/isbn ~/isbn-check/src/test/java/com/example/isbn
cd ~/isbn-check
```

`src/main/java` holds the program and `src/test/java` holds its tests, each followed by the
directories of the package. This is the **standard directory layout**, and it is why the pom
below never says where a source file is. A project can override it, and almost none do, because
every developer and every tool expects it.

## The pom

The project's description is `pom.xml`, the **Project Object Model**, at the top of the project.
Create it with this:

```schooling-example
{"language": "xml", "file": "pom.xml", "parts": [{"code": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<project xmlns=\"http://maven.apache.org/POM/4.0.0\"\n         xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n         xsi:schemaLocation=\"http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd\">", "note": "The root element. The namespace and schema attributes change nothing in the build; they let an editor check the file and complete it as you type."}, {"code": "  <modelVersion>4.0.0</modelVersion>\n", "note": "The version of the POM format, not of your project. It is `4.0.0` in every pom Maven 3 reads."}, {"code": "  <groupId>com.example</groupId>\n  <artifactId>isbn-check</artifactId>\n  <version>1.0.0</version>\n  <packaging>jar</packaging>\n", "note": "The coordinates: who publishes the project, what it is called, and which version this is. The three together name it everywhere, in a repository and in another project's dependency list. `packaging` says what the build produces, here a jar."}, {"code": "  <properties>\n    <maven.compiler.release>25</maven.compiler.release>\n    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>\n  </properties>\n", "note": "Settings for the plugins, written as properties. `maven.compiler.release` makes `javac` produce Java 25 class files and check every call against Java 25's library. The encoding fixes how the sources are read, so the build does not depend on the machine's locale."}, {"code": "  <dependencies>\n    <dependency>\n      <groupId>commons-validator</groupId>\n      <artifactId>commons-validator</artifactId>\n      <version>1.11.0</version>\n    </dependency>\n    <dependency>\n      <groupId>org.junit.jupiter</groupId>\n      <artifactId>junit-jupiter</artifactId>\n      <version>6.0.3</version>\n      <scope>test</scope>\n    </dependency>\n  </dependencies>\n", "note": "What the code needs that the JDK does not have, each named by its coordinates. Commons Validator is used by the program; JUnit Jupiter only by the tests, which is what the `test` scope says."}, {"code": "  <build>\n    <pluginManagement>\n      <plugins>\n        <plugin>\n          <artifactId>maven-clean-plugin</artifactId>\n          <version>3.5.0</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-resources-plugin</artifactId>\n          <version>3.5.0</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-compiler-plugin</artifactId>\n          <version>3.15.0</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-surefire-plugin</artifactId>\n          <version>3.5.6</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-jar-plugin</artifactId>\n          <version>3.5.1</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-install-plugin</artifactId>\n          <version>3.1.4</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-deploy-plugin</artifactId>\n          <version>3.1.4</version>\n        </plugin>\n      </plugins>\n    </pluginManagement>\n  </build>", "note": "The version of every plugin the build runs, written down. Without this block Maven 3.8.7 picks versions of its own, and the section on plugins shows what that costs."}, {"code": "</project>"}]}
```

## The code

The program asks Apache Commons Validator whether each argument is an ISBN. `ISBNValidator`
accepts the 10-digit and 13-digit forms, with or without hyphens, checks the last digit, and
returns the number as ISBN-13 without hyphens, or `null` when it is not one.

`src/main/java/com/example/isbn/IsbnCheck.java`:

```java
package com.example.isbn;

import org.apache.commons.validator.routines.ISBNValidator;

public class IsbnCheck {

    private static final ISBNValidator ISBN = ISBNValidator.getInstance();

    public static String verdict(String text) {
        String isbn13 = ISBN.validate(text);
        return isbn13 == null ? "invalid" : "valid, ISBN-13 " + isbn13;
    }

    public static void main(String[] args) {
        for (String arg : args) {
            System.out.println(arg + ": " + verdict(arg));
        }
    }
}
```

And one test class, which feeds it one valid ISBN-13, one ISBN-10 that becomes the same ISBN-13,
and one with a wrong check digit:

`src/test/java/com/example/isbn/IsbnCheckTest.java`:

```java
package com.example.isbn;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class IsbnCheckTest {

    @Test
    void acceptsAnIsbn13WithHyphens() {
        assertEquals("valid, ISBN-13 9780306406157", IsbnCheck.verdict("978-0-306-40615-7"));
    }

    @Test
    void convertsAnIsbn10() {
        assertEquals("valid, ISBN-13 9780306406157", IsbnCheck.verdict("0-306-40615-2"));
    }

    @Test
    void refusesAWrongCheckDigit() {
        assertEquals("invalid", IsbnCheck.verdict("978-0-306-40615-8"));
    }
}
```

## The first build

Three files, each in the place the layout reserves for it:

```
ana@vm:~/isbn-check$ find . -type f | sort
./pom.xml
./src/main/java/com/example/isbn/IsbnCheck.java
./src/test/java/com/example/isbn/IsbnCheckTest.java
```

`mvn compile` is the first build, run in the directory that holds `pom.xml`:

```
ana@vm:~/isbn-check$ mvn compile
[INFO] Scanning for projects...
[INFO] 
[INFO] -----------------------< com.example:isbn-check >-----------------------
[INFO] Building isbn-check 1.0.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:resources (default-resources) @ isbn-check ---
[INFO] skip non existing resourceDirectory /home/ana/isbn-check/src/main/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:compile (default-compile) @ isbn-check ---
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 1 source file with javac [debug release 25] to target/classes
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  0.892 s
[INFO] Finished at: 2026-10-22T19:33:31-03:00
[INFO] ------------------------------------------------------------------------
```

Maven read the pom, found one source file where the layout says the program is, and compiled it
for Java 25 (`release 25`) into `target/classes`. Two plugins ran, each named with its version, and
the section on the lifecycle reads lines like these properly. The resources plugin had nothing to
do, since this project has no `src/main/resources`, and said so.

Nothing was downloaded, because these transcripts were recorded on a machine whose cache was
already full. On your first build the screen fills with `Downloading from central` lines before
any of this, one for every jar and pom Maven had never seen, and that happens once per version of
each file. The section on repositories says where they go.

```
ana@vm:~/isbn-check$ ls target/classes/com/example/isbn
IsbnCheck.class
```

**`target/` belongs to Maven**: everything a build produces goes there, and nothing in it is yours
to edit, because the next build overwrites it.
