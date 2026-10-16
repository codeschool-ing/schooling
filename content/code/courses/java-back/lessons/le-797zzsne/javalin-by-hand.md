---
title: A Javalin service by hand
version: 1
---

PROSE1

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.example</groupId>
  <artifactId>javalin-hello</artifactId>
  <version>0.1.0</version>

  <properties>
    <maven.compiler.release>25</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

  <dependencies>
    <dependency>
      <groupId>io.javalin</groupId>
      <artifactId>javalin</artifactId>
      <version>7.2.3</version>
    </dependency>
    <dependency>
      <groupId>org.slf4j</groupId>
      <artifactId>slf4j-simple</artifactId>
      <version>2.0.18</version>
    </dependency>
  </dependencies>

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
      </plugins>
    </pluginManagement>
    <plugins>
      <plugin>
        <artifactId>maven-shade-plugin</artifactId>
        <version>3.6.2</version>
        <executions>
          <execution>
            <phase>package</phase>
            <goals>
              <goal>shade</goal>
            </goals>
            <configuration>
              <transformers>
                <transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
                  <mainClass>com.example.hello.HelloApp</mainClass>
                </transformer>
              </transformers>
            </configuration>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>
</project>
```

PROSE2

```schooling-example
{"language": "java", "file": "src/main/java/com/example/hello/HelloApp.java", "parts": [{"code": "package com.example.hello;\n\nimport java.util.List;\n\nimport io.javalin.Javalin;\nimport io.javalin.http.NotFoundResponse;\n", "note": "Two imports from Javalin and none from an annotation package: nothing in this file is read by reflection."}, {"code": "public class HelloApp {\n\n    record Book(long id, String isbn, String title, String author, int priceCents) {\n    }\n\n    static final List<Book> BOOKS = List.of(\n            new Book(1, \"9786500000016\", \"Dom Casmurro\", \"Machado de Assis\", 3990),\n            new Book(2, \"9786500000023\", \"The Time Machine\", \"H. G. Wells\", 2950),\n            new Book(3, \"9786500000030\", \"Frankenstein\", \"Mary Shelley\", 3500));\n", "note": "The data the service answers with: the same three books lesson 5's in-memory repository seeds, held in a list. A `record` inside the class keeps the program to one file."}, {"code": "    public static void main(String[] args) {\n        Javalin.create(config -> {", "note": "`main` is the whole application. `Javalin.create` takes a lambda that fills in the configuration, and in Javalin 7 the routes are part of it, so they are all known before the server starts."}, {"code": "            config.routes.get(\"/books\", ctx -> ctx.json(BOOKS));", "note": "A route is a path and a lambda. `ctx` is the request and the response at once; `ctx.json` turns the list into JSON and sets the content type."}, {"code": "            config.routes.get(\"/books/{id}\", ctx -> {\n                long id = ctx.pathParamAsClass(\"id\", Long.class).get();\n                Book book = BOOKS.stream()\n                        .filter(b -> b.id() == id)\n                        .findFirst()\n                        .orElseThrow(() -> new NotFoundResponse(\"No book with id \" + id));\n                ctx.json(book);\n            });", "note": "`pathParamAsClass` converts `{id}` and refuses a value that is not a number with a 400. `NotFoundResponse` is Javalin's exception for a 404: thrown from a handler, it becomes the response."}, {"code": "        }).start(7070);\n    }\n}", "note": "`start(7070)` opens Jetty on port 7070, a port the bookshop does not use, so both can run at once."}]}
```

PROSE3

```xml
  <dependencies>
    <dependency>
      <groupId>io.javalin</groupId>
      <artifactId>javalin</artifactId>
      <version>7.2.3</version>
    </dependency>
    <dependency>
      <groupId>com.fasterxml.jackson.core</groupId>
      <artifactId>jackson-databind</artifactId>
      <version>2.22.1</version>
    </dependency>
    <dependency>
      <groupId>org.slf4j</groupId>
      <artifactId>slf4j-simple</artifactId>
      <version>2.0.18</version>
    </dependency>
  </dependencies>
```

PROSE4
