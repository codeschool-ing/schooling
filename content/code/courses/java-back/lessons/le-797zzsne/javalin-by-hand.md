---
title: A Javalin service by hand
version: 1
---

This section builds the smallest service that does part of the bookshop's job: list the books, and
fetch one by its id. It lives in its own directory, `~/javalin-hello`, beside the bookshop, and it is
two files. Make the directory for the source:

```sh
mkdir -p ~/javalin-hello/src/main/java/com/example/hello
```

and save this as `~/javalin-hello/pom.xml`. It leaves one dependency out on purpose, for a reason the
first run shows:

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

Read it against the bookshop's pom. There is **no parent**, so nothing manages versions: each
dependency names its own, and the plugins are pinned the way lesson 1 pinned them, because Maven
3.8.7's built-in plugin versions are old. There are two dependencies, Javalin and `slf4j-simple`,
the smallest backend for the SLF4J facade Javalin logs through (lesson 16 is about that pair). The
**maven-shade-plugin** is there because the jar Maven builds holds only your own classes, which
lesson 1 met when it had to put the dependencies on the classpath by hand. Shading copies the classes
of every dependency into one jar and writes `Main-Class` into its manifest, so `java -jar` is enough.
Spring Boot's plugin solves the same problem another way, keeping each library as a jar inside the
jar, and lesson 23 opens one.

Then save the whole program as `src/main/java/com/example/hello/HelloApp.java`:

```schooling-example
{"language": "java", "file": "src/main/java/com/example/hello/HelloApp.java", "parts": [{"code": "package com.example.hello;\n\nimport java.util.List;\n\nimport io.javalin.Javalin;\nimport io.javalin.http.NotFoundResponse;\n", "note": "Two imports from Javalin and none from an annotation package: nothing in this file is read by reflection."}, {"code": "public class HelloApp {\n\n    record Book(long id, String isbn, String title, String author, int priceCents) {\n    }\n\n    static final List<Book> BOOKS = List.of(\n            new Book(1, \"9786500000016\", \"Dom Casmurro\", \"Machado de Assis\", 3990),\n            new Book(2, \"9786500000023\", \"The Time Machine\", \"H. G. Wells\", 2950),\n            new Book(3, \"9786500000030\", \"Frankenstein\", \"Mary Shelley\", 3500));\n", "note": "The data the service answers with: the same three books lesson 5's in-memory repository seeds, held in a list. A `record` inside the class keeps the program to one file."}, {"code": "    public static void main(String[] args) {\n        Javalin.create(config -> {", "note": "`main` is the whole application. `Javalin.create` takes a lambda that fills in the configuration, and in Javalin 7 the routes are part of it, so they are all known before the server starts."}, {"code": "            config.routes.get(\"/books\", ctx -> ctx.json(BOOKS));", "note": "A route is a path and a lambda. `ctx` is the request and the response at once; `ctx.json` turns the list into JSON and sets the content type."}, {"code": "            config.routes.get(\"/books/{id}\", ctx -> {\n                long id = ctx.pathParamAsClass(\"id\", Long.class).get();\n                Book book = BOOKS.stream()\n                        .filter(b -> b.id() == id)\n                        .findFirst()\n                        .orElseThrow(() -> new NotFoundResponse(\"No book with id \" + id));\n                ctx.json(book);\n            });", "note": "`pathParamAsClass` converts `{id}` and refuses a value that is not a number with a 400. `NotFoundResponse` is Javalin's exception for a 404: thrown from a handler, it becomes the response."}, {"code": "        }).start(7070);\n    }\n}", "note": "`start(7070)` opens Jetty on port 7070, a port the bookshop does not use, so both can run at once."}]}
```

Check that the two files are where Maven expects them, then build. `-B` is Maven's batch mode and `-q`
keeps it silent unless something fails, so a build that works prints nothing:

```
ana@vm:~/javalin-hello$ find . -type f | sort
./pom.xml
./src/main/java/com/example/hello/HelloApp.java
```

```
ana@vm:~/javalin-hello$ mvn -B -q package
ana@vm:~/javalin-hello$ ls -l target/*.jar
-rw-r--r-- 1 ana ana 7170648 Oct 22 19:20 target/javalin-hello-0.1.0.jar
-rw-r--r-- 1 ana ana    5188 Oct 22 19:20 target/original-javalin-hello-0.1.0.jar
```

Two jars. `original-javalin-hello-0.1.0.jar` is the one before shading, 5,188 bytes: your class
and Maven's own metadata; the other is the same class with Javalin, Jetty, Kotlin's standard library and the logger
copied in. Start it in one terminal and leave it running. From a second terminal, ask for the books:

```
ana@vm:~/javalin-hello$ curl -s -o /dev/null -w '%{http_code}\n' localhost:7070/books
500
```

A 500. The first terminal says why, below the banner Javalin prints when it starts:

```
ana@vm:~/javalin-hello$ java -jar target/javalin-hello-0.1.0.jar
[main] INFO io.javalin.Javalin - Starting Javalin ...
[main] INFO org.eclipse.jetty.server.Server - jetty-12.1.12; built: 2026-08-03T22:37:55.389Z; git: 10dd3948f37767b84cc2c62358364f042e51dbbe; jvm 25.0.4.1+1-1-24.04.4-Ubuntu
[main] INFO org.eclipse.jetty.session.DefaultSessionIdManager - Session workerName=node0
[main] INFO org.eclipse.jetty.server.handler.ContextHandler - Started oeje10s.ServletContextHandler@611889f4{ROOT,/,b=null,a=AVAILABLE,h=oeje10s.SessionHandler@1da2cb77{STARTED}}
[main] INFO org.eclipse.jetty.ee10.servlet.ServletContextHandler - Started oeje10s.ServletContextHandler@611889f4{ROOT,/,b=null,a=AVAILABLE,h=oeje10s.SessionHandler@1da2cb77{STARTED}}
[main] INFO org.eclipse.jetty.server.AbstractConnector - Started oejs.ServerConnector@59505b48{HTTP/1.1, (http/1.1)}{0.0.0.0:7070}
[main] INFO org.eclipse.jetty.server.Server - Started oejs.Server@48aca48b{STARTING}[12.1.12,sto=0] @611ms
[main] INFO io.javalin.Javalin - 
       __                  ___          _____
      / /___ __   ______ _/ (_)___     /__  /
 __  / / __ `/ | / / __ `/ / / __ \      / /
/ /_/ / /_/ /| |/ / /_/ / / / / / /     / /
\____/\__,_/ |___/\__,_/_/_/_/ /_/     /_/

       https://javalin.io/documentation

[main] INFO io.javalin.Javalin - Javalin started in 2209ms \o/
[main] INFO io.javalin.Javalin - Listening on http://localhost:7070/
[main] INFO io.javalin.Javalin - You are running Javalin 7.2.3 (released August 11, 2026).
[JettyServerThreadPool-33] WARN io.javalin.Javalin - 
#########################################################################
It looks like you don't have an object mapper configured.
The easiest way to fix this is to simply add the 'jackson-databind' dependency:

pom.xml:
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
    <version>2.22.1</version>
</dependency>

build.gradle or build.gradle.kts:
implementation("com.fasterxml.jackson.core:jackson-databind:2.22.1")

If you're using Kotlin, you will need to add 'jackson-module-kotlin'.

To use a different object mapper, visit https://javalin.io/documentation#configuring-the-json-mapper
#########################################################################
```

`ctx.json` needs something that turns a Java object into JSON, and Javalin does not bring one. **Its
default mapper uses Jackson 2 if Jackson 2 is on the classpath**, there was none, and it said so in the
log and in the body of the 500. The bookshop never met this, because `spring-boot-starter-webmvc`
brought Jackson along and lesson 4's autoconfiguration set it up. A library leaves the choice to you,
and so it also leaves you the moment when nothing was chosen. Notice when it surfaced, too: at the
first request that needed JSON, not at start.

Stop the server with Ctrl+C in the first terminal, and replace the `<dependencies>` block of the pom
with this one. It adds `jackson-databind` 2, the version Javalin's message names, rather than the
Jackson 3 the bookshop uses, because 2 is what Javalin's default mapper is written for:

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

Build again, and the jar grows by Jackson:

```
ana@vm:~/javalin-hello$ mvn -B -q package
ana@vm:~/javalin-hello$ ls -l target/javalin-hello-0.1.0.jar
-rw-r--r-- 1 ana ana 9534256 Oct 22 19:20 target/javalin-hello-0.1.0.jar
```

Start it in the first terminal:

```
ana@vm:~/javalin-hello$ java -jar target/javalin-hello-0.1.0.jar
[main] INFO io.javalin.Javalin - Starting Javalin ...
[main] INFO org.eclipse.jetty.server.Server - jetty-12.1.12; built: 2026-08-03T22:37:55.389Z; git: 10dd3948f37767b84cc2c62358364f042e51dbbe; jvm 25.0.4.1+1-1-24.04.4-Ubuntu
[main] INFO org.eclipse.jetty.session.DefaultSessionIdManager - Session workerName=node0
[main] INFO org.eclipse.jetty.server.handler.ContextHandler - Started oeje10s.ServletContextHandler@611889f4{ROOT,/,b=null,a=AVAILABLE,h=oeje10s.SessionHandler@1da2cb77{STARTED}}
[main] INFO org.eclipse.jetty.ee10.servlet.ServletContextHandler - Started oeje10s.ServletContextHandler@611889f4{ROOT,/,b=null,a=AVAILABLE,h=oeje10s.SessionHandler@1da2cb77{STARTED}}
[main] INFO org.eclipse.jetty.server.AbstractConnector - Started oejs.ServerConnector@59505b48{HTTP/1.1, (http/1.1)}{0.0.0.0:7070}
[main] INFO org.eclipse.jetty.server.Server - Started oejs.Server@48aca48b{STARTING}[12.1.12,sto=0] @145ms
[main] INFO io.javalin.Javalin - 
       __                  ___          _____
      / /___ __   ______ _/ (_)___     /__  /
 __  / / __ `/ | / / __ `/ / / __ \      / /
/ /_/ / /_/ /| |/ / /_/ / / / / / /     / /
\____/\__,_/ |___/\__,_/_/_/_/ /_/     /_/

       https://javalin.io/documentation

[main] INFO io.javalin.Javalin - Javalin started in 749ms \o/
[main] INFO io.javalin.Javalin - Listening on http://localhost:7070/
[main] INFO io.javalin.Javalin - You are running Javalin 7.2.3 (released August 11, 2026).
```

`Javalin started in 749ms` is Javalin's own stopwatch; the next section says why it is not
the number to compare. Now the second terminal:

```
ana@vm:~/javalin-hello$ curl -s localhost:7070/books | python3 -m json.tool
[
    {
        "id": 1,
        "isbn": "9786500000016",
        "title": "Dom Casmurro",
        "author": "Machado de Assis",
        "priceCents": 3990
    },
    {
        "id": 2,
        "isbn": "9786500000023",
        "title": "The Time Machine",
        "author": "H. G. Wells",
        "priceCents": 2950
    },
    {
        "id": 3,
        "isbn": "9786500000030",
        "title": "Frankenstein",
        "author": "Mary Shelley",
        "priceCents": 3500
    }
]
ana@vm:~/javalin-hello$ curl -si -w '\n' localhost:7070/books/2
HTTP/1.1 200 OK
Date: Thu, 22 Oct 2026 22:20:24 GMT
Content-Type: application/json
Content-Length: 99

{"id":2,"isbn":"9786500000023","title":"The Time Machine","author":"H. G. Wells","priceCents":2950}
ana@vm:~/javalin-hello$ curl -si -w '\n' localhost:7070/books/9
HTTP/1.1 404 Not Found
Date: Thu, 22 Oct 2026 22:20:24 GMT
Content-Type: text/plain
Content-Length: 17

No book with id 9
ana@vm:~/javalin-hello$ curl -s localhost:7070/books/two
{"id":[{"message":"TYPE_CONVERSION_FAILED","args":{},"value":"two"}]}
```

`-w '\n'` asks curl to print a line break after the body, which neither answer ends with. The list
and the single book are the bookshop's JSON, field for field. The other two answers are where the
difference from lesson 7 shows. A missing book is a 404 in **plain text**, `No book with id 9`, where
the bookshop answers `application/problem+json` with a type, a title and a detail; Javalin would do
that too, once you register an exception handler that writes it (`config.routes.exception` is where it
goes). And `two` is refused with a 400 in **Javalin's own format** for a failed conversion, a third
shape of error that no client of the bookshop knows how to read.

What is absent matters as much. `BOOKS` is a static list because there is no container to hand a
repository to a handler: in a real Javalin service, `main` builds the repository and the service with
`new` and passes them to the lambdas, which is lesson 5's constructor injection written by hand, with
nothing checking it but the compiler.
