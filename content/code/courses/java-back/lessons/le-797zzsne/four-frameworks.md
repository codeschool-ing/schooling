---
title: Quarkus, Micronaut, Javalin and Play
version: 1
---

Two of the four do Spring's job earlier, one declines the job, and one comes from another language.
Each paragraph below says what the framework is for, what its code looks like to somebody who knows
Spring, and where you are likely to meet it. None of this was run for the course except Javalin,
which the next section builds.

**Quarkus** (Red Hat, first released in 2019) wires the application **during the build**. Every
library it supports, from Hibernate to the Kafka client, comes as a Quarkus **extension**, and the
extensions run inside the Maven or Gradle build: they scan the classes, read the annotations and
record what the application will do at start, so the start only replays that record. The code is
written against Jakarta standards, so it is readable on the first day: `@Path("/books")` and `@GET`
from Jakarta REST mark the routes, `@ApplicationScoped` and `@Inject` from CDI mark the beans and
their injection points. Its dev mode (`mvn quarkus:dev`) recompiles on every save, and its Dev
Services start a PostgreSQL in a container for the tests by themselves, the job lesson 19 does by
hand with Testcontainers. You meet Quarkus in Red Hat's world, on OpenShift and Kubernetes, and in
teams moving off a Jakarta EE application server. Its project generator, `code.quarkus.io`, plays the
part `start.spring.io` plays for Spring.

Quarkus is also the framework most associated with **native images**. GraalVM's `native-image`
compiles the application, its libraries and the parts of the JDK they use into one executable for one
operating system, ahead of time, so nothing is loaded or compiled when it starts. A native image
starts much faster and uses less memory than the same program on a JVM; it costs a build of several
minutes, and anything the program reaches by reflection has to be declared before that build. That
last condition is easy for a framework that already decided its wiring at build time, and is the
reason Spring needed its AOT step.

**Micronaut** (Object Computing, 2018, by the team behind Grails) wires the application **while it
compiles**. Its annotation processors run inside `javac` and write, for every bean, a small class that
knows how to build it, so the start has nothing to scan and nothing to reflect on. The annotations
resemble Spring's on purpose: `@Controller("/books")` on the class, `@Get("/{id}")` on the method,
`@Singleton` and `@Inject` for the beans. Micronaut Data goes one step further and turns a repository
method's name into its query during compilation, so a method whose name names no field fails the
build rather than the start. The price is a slower compile, and a build that must have the annotation
processors configured, or produces an application that finds none of its beans. You meet it in serverless
functions, where a cold start is waited on by a user, and in Oracle's cloud tooling, which is built on
it.

**Javalin** (2017, begun as a fork of the small SparkJava framework) **declines the job**. It is a
library: an embedded Jetty server, a table of routes and a `Context` object for each request. There
is no container, no scanning and no annotation. A route is a lambda you register, and the objects
your handlers need are built with `new` in your `main`, which makes `main` the whole wiring of the
application, in plain Java. What you give up is everything Spring adds around the handler:
lesson 6's Bean Validation, lesson 7's problem details, security, transactions. Each is a library you choose and
connect yourself. You meet Javalin in small internal services and tools, in Kotlin teams (it is
written in Kotlin and has a Kotlin API beside the Java one), and wherever a team wants to read every
line between the socket and its code.

**Play** (2007, created by Guillaume Bort, later maintained by Lightbend and by its community since
2022) comes from **Scala**, with a Java API beside the Scala one. Its routes live in a `conf/routes`
file, one line per route such as `GET /books/:id controllers.Books.show(id: Long)`, and that file is
compiled into code, so a route naming a method that does not exist fails the build. It is
non-blocking throughout, on Apache Pekko since Play 3 (on Akka before Akka changed its licence), and
during development it recompiles changed code when the next request arrives. Its Java API wires controllers with Guice,
at start, by reflection. It is built with sbt, Scala's build tool, even for a Java project. You meet
it in Scala companies and in Java code bases from the 2010s, more often than in new projects.

| | wired | beans | a route looks like | built with | version, October 2026 |
|---|---|---|---|---|---|
| Spring Boot | at start, by reflection | Spring's container | `@GetMapping("/{id}")` | Maven or Gradle | 4.1 |
| Quarkus | in the build, by extensions | CDI | `@GET @Path("/{id}")` | Maven or Gradle | 3.40, 4.0 in beta |
| Micronaut | in the compiler, by annotation processors | its own, generated | `@Get("/{id}")` | Maven or Gradle | 5.2 |
| Javalin | by you, in `main` | none | `config.routes.get("/books/{id}", ...)` | anything that builds a jar | 7.2 |
| Play | at start, by Guice | Guice | a line in `conf/routes` | sbt | 3.0, 3.1 in milestones |

The version column will be out of date before this lesson is; it is there so that a reader can tell
a current release from an old one in a job advert or a pom.
