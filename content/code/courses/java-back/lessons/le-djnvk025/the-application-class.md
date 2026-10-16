---
title: One class, one jar, one running server
version: 1
---

A Spring Boot application needs one class of yours before it can start, and the bookshop's has
three lines that do anything. Create
`src/main/java/com/example/bookshop/BookshopApplication.java`:

```schooling-example
{
  "language": "java",
  "file": "src/main/java/com/example/bookshop/BookshopApplication.java",
  "parts": [
    {
      "code": "package com.example.bookshop;\n\nimport org.springframework.boot.SpringApplication;\nimport org.springframework.boot.autoconfigure.SpringBootApplication;\n",
      "note": "**The package is where Spring starts looking.** Component scanning begins at this class's package and goes down, so a class in `com.example.bookshop.catalogue`, which lesson 5 adds, is found, and a class in `com.example.reports` would not be."
    },
    {
      "code": "@SpringBootApplication\npublic class BookshopApplication {\n",
      "note": "**`@SpringBootApplication` is three annotations in one**, read off the compiled class just below. The class has no body: nothing in it is wiring written by hand."
    },
    {
      "code": "    public static void main(String[] args) {\n        SpringApplication.run(BookshopApplication.class, args);\n    }\n}",
      "note": "**`SpringApplication.run` builds the application and starts it.** It reads the properties, decides which autoconfiguration applies, creates the beans and, because a web server is on the classpath, starts it. `args` is passed through, which is how `--debug` or `--server.port=9091` on the command line reach Spring later in this lesson."
    }
  ]
}
```

An annotation in Java is an interface, so its own annotations are in the compiled class, and
`javap` reads them out of the jar Maven downloaded:

```
ana@vm:~/bookshop$ javap -v -cp ~/.m2/repository/org/springframework/boot/spring-boot-autoconfigure/4.1.1/spring-boot-autoconfigure-4.1.1.jar org.springframework.boot.autoconfigure.SpringBootApplication | grep -E 'RuntimeVisibleAnnotations|^ +[0-9]+: #[0-9]+|^ +org\.springframework'
  #12 = Utf8               RuntimeVisibleAnnotations
    RuntimeVisibleAnnotations:
      0: #13(#14=c#15)
        org.springframework.core.annotation.AliasFor(
    RuntimeVisibleAnnotations:
      0: #13(#14=c#15)
        org.springframework.core.annotation.AliasFor(
    RuntimeVisibleAnnotations:
      0: #13(#14=c#19,#20=s#21)
        org.springframework.core.annotation.AliasFor(
    RuntimeVisibleAnnotations:
      0: #13(#14=c#19,#20=s#23)
        org.springframework.core.annotation.AliasFor(
    RuntimeVisibleAnnotations:
      0: #13(#14=c#19,#20=s#24)
        org.springframework.core.annotation.AliasFor(
    RuntimeVisibleAnnotations:
      0: #13(#14=c#31)
        org.springframework.core.annotation.AliasFor(
RuntimeVisibleAnnotations:
  0: #34(#35=[e#36.#37])
  1: #38(#35=e#39.#40)
  2: #41()
  3: #42()
  4: #43()
    org.springframework.boot.SpringBootConfiguration
  5: #15()
    org.springframework.boot.autoconfigure.EnableAutoConfiguration
  6: #19(#44=[@#45(#46=e#47.#48,#49=[c#50]),@#45(#46=e#47.#48,#49=[c#51])])
    org.springframework.context.annotation.ComponentScan(
```

Past the two that every annotation carries, there are the three that do the work.
**`@SpringBootConfiguration`** marks the class as a source of bean definitions, the objects Spring
creates and connects, which is lesson 5's subject. **`@EnableAutoConfiguration`** switches on the
mechanism the next section opens up. **`@ComponentScan`** tells Spring to look for your own
classes in this package and every package below it, which is why the main class sits at the top
of the package tree and never in a subpackage of its own.

One more file, `src/main/resources/application.properties`, with one line:

```properties
spring.application.name=bookshop
```

It names the application, and the log below shows where that name appears.

## The executable jar

Build it. `-B` is batch mode, as in lesson 1, and `tail` keeps the last lines:

```
ana@vm:~/bookshop$ mvn -B package | tail -n 8
[INFO] Replacing main artifact /home/ana/bookshop/target/bookshop-0.1.0.jar with repackaged archive, adding nested dependencies in BOOT-INF/.
[INFO] The original artifact has been renamed to /home/ana/bookshop/target/bookshop-0.1.0.jar.original
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.597 s
[INFO] Finished at: 2026-10-16T20:20:39-03:00
[INFO] ------------------------------------------------------------------------
ana@vm:~/bookshop$ ls -l target/*.jar*
-rw-r--r-- 1 ana ana 19904573 Oct 16 20:20 target/bookshop-0.1.0.jar
-rw-r--r-- 1 ana ana     2766 Oct 16 20:20 target/bookshop-0.1.0.jar.original
ana@vm:~/bookshop$ jar tf target/bookshop-0.1.0.jar | grep -c '^BOOT-INF/lib/.*\.jar$'
34
```

`spring-boot-maven-plugin:4.1.1:repackage` ran after the ordinary jar was built and turned it into
an **executable jar**: the bookshop's classes, every library from the tree under
`BOOT-INF/lib`, and a small launcher that knows how to load jars nested inside a jar. That is why
the file is about 19 MB where the `.original`, the jar Maven built first, holds only the bookshop's own class and
properties files. The count is 34, against 39 in the tree, because the starters hold no code and
are left out, and Boot adds one jar of its own, `spring-boot-jarmode-tools`, which lesson 23 uses.
**One file, and nothing else to install but Java**: no Tomcat on the server, no
directory of libraries beside it. Lesson 23 opens it up and puts it in a container image.

## Starting it

Open a second terminal for the application, because it keeps running. In it:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v4.1.1)

2026-10-16T20:20:41.311-03:00  INFO 977 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Starting BookshopApplication v0.1.0 using Java 25.0.4.1 with PID 977 (/home/ana/bookshop/target/bookshop-0.1.0.jar started by ana in /home/ana/bookshop)
2026-10-16T20:20:41.320-03:00  INFO 977 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : No active profile set, falling back to 1 default profile: "default"
2026-10-16T20:20:42.655-03:00  INFO 977 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat initialized with port 8080 (http)
2026-10-16T20:20:42.668-03:00  INFO 977 --- [bookshop] [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2026-10-16T20:20:42.669-03:00  INFO 977 --- [bookshop] [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/11.0.24]
2026-10-16T20:20:42.704-03:00  INFO 977 --- [bookshop] [           main] b.w.c.s.WebApplicationContextInitializer : Root WebApplicationContext: initialization completed in 1272 ms
2026-10-16T20:20:43.083-03:00  INFO 977 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 8080 (http) with context path '/'
2026-10-16T20:20:43.098-03:00  INFO 977 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 2.526 seconds (process running for 3.095)
```

Read it from the top. The banner and the Boot version. `Starting BookshopApplication v0.1.0 using
Java 25.0.4.1 with PID …`: the version is the pom's, and `[bookshop]` after the PID is the
`spring.application.name` you just wrote, on every line. `No active profile set` is the profiles
section's subject. Then Tomcat 11 initialised on **port 8080**, the default, and the line that
says it is ready, with how long that took. The time and the PID will differ on your
machine.

In the first terminal, ask it for something:

```
ana@vm:~/bookshop$ curl -s localhost:8080/; echo
{"timestamp":"2026-10-16T23:20:44.163Z","status":404,"error":"Not Found","path":"/"}
```

A `404`, and that is the right answer. The request reached Spring MVC, nothing in the bookshop
handles `/` yet, and **Boot's default error handling wrote the JSON** without a line of yours.
Lesson 6 adds the first controller; lesson 7 replaces that body with one designed for the
bookshop. Stop the application with Ctrl+C in the second terminal.
