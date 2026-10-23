---
title: Properties and per-environment profiles
version: 1
---

The bookshop will run in more than one place: on your machine while you write it, in tests, on a
server. Some settings have to differ between them, and the wrong way to get that is a jar per
place, or a line somebody edits before each build. **Boot reads its settings when the jar
starts, from several places, and a profile chooses a set of them by name**, so one jar serves
every environment.

## application.properties

Everything a starter configures has a property, and `src/main/resources/application.properties`
is where the application keeps its own. The bookshop's has one line so far:

```properties
spring.application.name=bookshop
```

Spring Boot's reference documentation lists every property each module reads, with its default:
`server.port` is 8080 until somebody says otherwise. The file can be YAML too,
`application.yaml`, with the same names nested; this course keeps to properties, one setting per
line, which is easier to search with `grep`.

## A profile is a second file, read on top

A **profile** is a name, and for each active profile Boot also reads
`application-<name>.properties` beside the main file. Create
`src/main/resources/application-dev.properties`:

```properties
server.port=8081
logging.level.org.springframework.web=debug
```

On a developer's machine the bookshop listens on 8081, which leaves 8080 free for something
else, and Spring's web layer logs at `DEBUG`, so each request's handling is visible. The profile
file does not replace the main one: **both are read, and where they disagree the profile wins**,
so `spring.application.name` still comes from the main file.

Rebuild, since both files are packed into the jar, and start it in the second terminal with the
profile named:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.profiles.active=dev

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v4.1.1)

2026-10-22T19:11:09.842-03:00  INFO 6591 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Starting BookshopApplication v0.1.0 using Java 25.0.4.1 with PID 6591 (/home/ana/bookshop/target/bookshop-0.1.0.jar started by ana in /home/ana/bookshop)
2026-10-22T19:11:09.854-03:00  INFO 6591 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : The following 1 profile is active: "dev"
2026-10-22T19:11:11.200-03:00  INFO 6591 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat initialized with port 8081 (http)
2026-10-22T19:11:11.227-03:00  INFO 6591 --- [bookshop] [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2026-10-22T19:11:11.229-03:00  INFO 6591 --- [bookshop] [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/11.0.24]
2026-10-22T19:11:11.250-03:00  INFO 6591 --- [bookshop] [           main] b.w.c.s.WebApplicationContextInitializer : Root WebApplicationContext: initialization completed in 1189 ms
2026-10-22T19:11:11.575-03:00 DEBUG 6591 --- [bookshop] [           main] s.w.s.m.m.a.RequestMappingHandlerMapping : 2 mappings in 'requestMappingHandlerMapping'
2026-10-22T19:11:11.614-03:00 DEBUG 6591 --- [bookshop] [           main] o.s.w.s.handler.SimpleUrlHandlerMapping  : Patterns [/webjars/**, /**] in 'resourceHandlerMapping'
2026-10-22T19:11:11.633-03:00 DEBUG 6591 --- [bookshop] [           main] s.w.s.m.m.a.RequestMappingHandlerAdapter : ControllerAdvice beans: 0 @ModelAttribute, 0 @InitBinder, 2 RequestBodyAdvice, 1 ResponseBodyAdvice
2026-10-22T19:11:11.673-03:00 DEBUG 6591 --- [bookshop] [           main] .m.m.a.ExceptionHandlerExceptionResolver : ControllerAdvice beans: 0 @ExceptionHandler, 1 ResponseBodyAdvice
2026-10-22T19:11:11.729-03:00  INFO 6591 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 8081 (http) with context path '/'
2026-10-22T19:11:11.742-03:00  INFO 6591 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 2.587 seconds (process running for 3.171)
```

`The following 1 profile is active: "dev"` replaces the `No active profile set` of the first run,
Tomcat is on 8081, and the `DEBUG` lines come from `org.springframework.web` at work. Stop it.

## Choosing the profile without the command line

A server is usually started by something other than a person typing, a service definition or a
container, and the place it hands settings to is the environment. Every property can be given as
an **environment variable**, spelt in capitals with underscores for the dots, so
`spring.profiles.active` is `SPRING_PROFILES_ACTIVE`. From here the second terminal sends the log
to a file, as for the report, and the first one searches it:

```
ana@vm:~/bookshop$ SPRING_PROFILES_ACTIVE=dev java -jar target/bookshop-0.1.0.jar > /tmp/bookshop.log 2>&1
```

```
ana@vm:~/bookshop$ grep -E 'profile|Tomcat started' /tmp/bookshop.log
2026-10-22T19:11:14.402-03:00  INFO 6706 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : The following 1 profile is active: "dev"
2026-10-22T19:11:16.364-03:00  INFO 6706 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 8081 (http) with context path '/'
```

The same profile, chosen from the environment. Stop it again.

## A profile nobody wrote

Now mistype it:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.profiles.active=dve > /tmp/bookshop.log 2>&1
```

```
ana@vm:~/bookshop$ grep -E 'profile|Tomcat started' /tmp/bookshop.log
2026-10-22T19:11:18.843-03:00  INFO 6854 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : The following 1 profile is active: "dve"
2026-10-22T19:11:20.654-03:00  INFO 6854 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 8080 (http) with context path '/'
```

It started, it says profile `dve` is active, and it is on 8080. **A profile with no file is not
an error**: a profile can also switch beans on and off with `@Profile`, so a name with no
properties file is legal, and Boot has no list of the names you meant. Nothing warns. The
profile line is the only evidence, which is why it is worth reading after every start that
matters.
