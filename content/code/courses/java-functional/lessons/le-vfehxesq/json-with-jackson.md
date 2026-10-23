---
title: JSON with Jackson
version: 1
---

**JSON is text that names no classes: objects in braces, lists in brackets, strings, numbers, `true`,
`false` and `null`.** Every language reads it, a person can read it, and a reader decides for itself which
class each object becomes. The JDK has no JSON library, so this is the course's first dependency, and its
first Maven project. **Jackson** is the library most Java code uses for it, including Spring, which
`java-back` builds on.

The project follows the layout `java` decided in lesson 18 section 04: make a directory `~/catalogue`
and save this as `pom.xml` in it.

```schooling-example
{
  "language": "xml",
  "file": "pom.xml",
  "parts": [
    {
      "code": "<project xmlns=\"http://maven.apache.org/POM/4.0.0\"\n         xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n         xsi:schemaLocation=\"http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd\">\n  <modelVersion>4.0.0</modelVersion>",
      "note": "**The opening every `pom.xml` has**, as in lesson 18 section 04 of `java`."
    },
    {
      "code": "\n  <groupId>com.example</groupId>\n  <artifactId>catalogue</artifactId>\n  <version>1.0-SNAPSHOT</version>",
      "note": "**The coordinates.** The `artifactId` is this project's name, so the package is `com.example.catalogue`, the rule the `java` course set."
    },
    {
      "code": "\n  <properties>\n    <maven.compiler.release>25</maven.compiler.release>\n    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>\n    <exec.mainClass>com.example.catalogue.App</exec.mainClass>\n  </properties>",
      "note": "**The two settings of `java`, and one more.** `exec.mainClass` is read by the plugin that runs the program, so `mvn exec:java` knows which `main` to call."
    },
    {
      "code": "\n  <dependencies>\n    <dependency>\n      <groupId>tools.jackson.core</groupId>\n      <artifactId>jackson-databind</artifactId>\n      <version>3.2.3</version>\n    </dependency>\n  </dependencies>",
      "note": "**The first dependency of this course.** Maven downloads the library named by these three coordinates, and the libraries it needs in turn, into `~/.m2/repository`, and puts them on the class path when it compiles and runs. Jackson 3 lives under `tools.jackson`; the older Jackson 2 used `com.fasterxml.jackson`."
    },
    {
      "code": "\n  <build>\n    <pluginManagement>\n      <plugins>\n        <plugin>\n          <artifactId>maven-clean-plugin</artifactId>\n          <version>3.5.0</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-resources-plugin</artifactId>\n          <version>3.5.0</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-compiler-plugin</artifactId>\n          <version>3.15.0</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-surefire-plugin</artifactId>\n          <version>3.5.6</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-jar-plugin</artifactId>\n          <version>3.5.1</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-install-plugin</artifactId>\n          <version>3.2.0</version>\n        </plugin>",
      "note": "**The plugins of `java`, pinned to the same versions**, so a student who built that course's project downloads nothing new for them."
    },
    {
      "code": "\n        <plugin>\n          <groupId>org.codehaus.mojo</groupId>\n          <artifactId>exec-maven-plugin</artifactId>\n          <version>3.6.4</version>\n        </plugin>\n      </plugins>\n    </pluginManagement>\n  </build>\n</project>\n",
      "note": "**One new plugin, pinned like the rest.** `exec-maven-plugin` runs a class's `main` with the project's class path, dependencies included."
    }
  ]
}
```

The record the JSON will hold goes in `src/main/java/com/example/catalogue/Book.java`:

```java
// src/main/java/com/example/catalogue/Book.java
package com.example.catalogue;

public record Book(String title, String author, int year) {}
```

and the program in `src/main/java/com/example/catalogue/App.java`:

```java
// src/main/java/com/example/catalogue/App.java
package com.example.catalogue;

import java.util.List;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.json.JsonMapper;

public class App {
    public static void main(String[] args) {
        JsonMapper mapper = JsonMapper.builder().build();
        List<Book> books = List.of(new Book("Dune", "Frank Herbert", 1965), new Book("Emma", "Jane Austen", 1815));

        String json = mapper.writerWithDefaultPrettyPrinter().writeValueAsString(books);
        System.out.println(json);

        List<Book> back = mapper.readValue(json, new TypeReference<List<Book>>() {});
        System.out.println("read back, equal: " + back.equals(books));
        System.out.println(mapper.writeValueAsString(books.get(0)));
    }
}
```

`mvn -q` prints only what the program prints, and `compile exec:java` compiles and runs in one command:

```
ana@vm:~/catalogue$ mvn -q compile exec:java
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
WARNING: sun.misc.Unsafe::objectFieldOffset has been called by com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper (file:/usr/share/maven/lib/guava.jar)
WARNING: Please consider reporting this to the maintainers of class com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper
WARNING: sun.misc.Unsafe::objectFieldOffset will be removed in a future release
[ {
  "title" : "Dune",
  "author" : "Frank Herbert",
  "year" : 1965
}, {
  "title" : "Emma",
  "author" : "Jane Austen",
  "year" : 1815
} ]
read back, equal: true
{"title":"Dune","author":"Frank Herbert","year":1965}
```

## What Jackson did

The four `WARNING` lines are Maven's own, from its copy of Guava, and appear on every `mvn` command;
lesson 18 section 04 of `java` explains them, and they say nothing about this project. After them,
**the list became a JSON array of two objects**, each record component a field with its own name, and
the same text read back gave a list equal to the first. The last line is the same book without the
pretty printer, the form a program sends.

Jackson found the fields by itself. A record says what its components are, and Jackson writes one field
per component and, reading, calls the record's canonical constructor with the values it found. **No
annotation, no setter, no empty constructor**, which is why records and JSON suit each other: the class
is a description of the data, and the constructor is the only way in.

| part | does |
|---|---|
| `JsonMapper.builder().build()` | a mapper with the default settings; make one and share it, it is thread-safe |
| `writeValueAsString(value)` | an object to JSON text |
| `readValue(text, Book.class)` | JSON text to an object of that class |
| `new TypeReference<List<Book>>() {}` | the type to read when it is generic, since `List<Book>.class` does not exist |

The `TypeReference` is the one odd line. Generic types are erased at run time (lesson 35 of `java`), so
`readValue(json, List.class)` would give a list of maps; an anonymous subclass of `TypeReference` keeps
the full type in its declaration, where Jackson can read it.

**What the reader decides here is the class**: `Book`, named in the code. The JSON chose only the values.
That is the difference from the last two sections, and it is why JSON is the format to exchange.
