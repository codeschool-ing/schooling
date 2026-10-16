---
title: "A detour: the same application without the web starter"
version: 1
---

The quickest way to see that autoconfiguration follows the classpath is to take something off
it. This section is a detour: it changes the pom, looks, and puts the pom back.

Replace the `<dependencies>` block of `pom.xml` with the core starter alone, the one every other
starter depends on:

```xml
  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter</artifactId>
    </dependency>
  </dependencies>
```

Build it, and this time run it in the first terminal, because it will not stay running:

```
ana@vm:~/bookshop$ mvn -B -q package
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v4.1.1)

2026-10-16T20:20:49.830-03:00  INFO 1664 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Starting BookshopApplication v0.1.0 using Java 25.0.4.1 with PID 1664 (/home/ana/bookshop/target/bookshop-0.1.0.jar started by ana in /home/ana/bookshop)
2026-10-16T20:20:49.833-03:00  INFO 1664 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : No active profile set, falling back to 1 default profile: "default"
2026-10-16T20:20:50.294-03:00  INFO 1664 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 0.88 seconds (process running for 1.198)
```

The same banner, the same `Started BookshopApplication`, and then the prompt comes back. Nothing
failed. With no web server on the classpath, the conditions on Tomcat's configuration did not
hold, no server was created, and the context had nothing left to do once it started.
`SpringApplication.run` returned, `main` ended, and the JVM exited because **no thread was left
running**. With the web starter it is Tomcat's threads, waiting for connections, that keep the
process alive.

The tree is smaller by everything the web starter brought:

```
ana@vm:~/bookshop$ mvn -q dependency:tree -DoutputFile=/tmp/tree.txt && grep -c ':compile' /tmp/tree.txt
21
```

That shape is not a broken web application. It is the right one for a program that does some
work and stops, a nightly import or a report, which still gets Boot's properties, logging and
dependency injection. The bookshop is a web API, so put the `<dependencies>` block back as the
first section has it, with `spring-boot-starter-webmvc`, and run `mvn -B -q package` again
before the next section.
