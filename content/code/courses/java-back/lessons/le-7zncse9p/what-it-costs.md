---
title: What a container costs
version: 1
---

"Integration tests are slow" is said often and measured rarely, and the measurement changes the
advice. Here are the two commands on the same project, one after the other, with the cache warm and
both images already on the machine:

```
ana@vm:~/bookshop$ mvn -B test 2>&1 | grep -E 'Skipped: 0$|Total time'
[INFO] Tests run: 17, Failures: 0, Errors: 0, Skipped: 0
[INFO] Total time:  4.149 s
```

```
ana@vm:~/bookshop$ mvn -B verify 2>&1 | grep -E 'Skipped: 0$|Total time|started in PT|Started .*IT in'
[INFO] Tests run: 17, Failures: 0, Errors: 0, Skipped: 0
2026-10-22T20:19:14.943-03:00  INFO 5668 --- [bookshop] [           main] [] tc.testcontainers/ryuk:0.14.0            : Container testcontainers/ryuk:0.14.0 started in PT0.479669724S
2026-10-22T20:19:16.224-03:00  INFO 5668 --- [bookshop] [           main] [] tc.postgres:16-alpine                    : Container postgres:16-alpine started in PT1.271336317S
2026-10-22T20:19:20.589-03:00  INFO 5668 --- [bookshop] [           main] [] c.e.bookshop.BookshopApplicationIT       : Started BookshopApplicationIT in 9.202 seconds (process running for 10.803)
2026-10-22T20:19:22.385-03:00  INFO 5668 --- [bookshop] [           main] [] tc.postgres:16-alpine                    : Container postgres:16-alpine started in PT1.400510052S
2026-10-22T20:19:22.950-03:00  INFO 5668 --- [bookshop] [           main] [] c.e.bookshop.catalogue.BookRepositoryIT  : Started BookRepositoryIT in 0.558 seconds (process running for 13.164)
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
[INFO] Total time:  20.733 s
```

Four seconds of Maven for the seventeen unit tests, and about twenty-one for the
same seventeen plus three integration tests: five times as long, for three tests. Timings move from
one run to the next, and the section before this one, on the same machine, needed fifteen; what
holds from run to run is the proportion.

## Where the seconds went

Read the second run's lines against each other. **The containers are not the expensive part.** Ryuk
started in under half a second and each PostgreSQL in 1.3 and 1.4 seconds, including the wait until
it accepted connections. What took most of the time was Spring: the whole application context, for
`BookshopApplicationIT`, needed 9.2 seconds, while the persistence slice of `BookRepositoryIT` was
ready in just over half a second. Packaging the jar is in the total too, because `verify` comes after
`package`.

So the cost of an integration test is mostly the context it starts, and two habits follow from that.

**Share a context, and the container comes with it.** Spring's test framework keeps a context once
it is built and hands it to every later test class with the same configuration: the same annotations,
the same profiles, the same imports. A second `@SpringBootTest` class with `@ActiveProfiles("test")`
and `@Import(TestcontainersConfiguration.class)` would reuse the nine seconds and the database of
the first. Give it another profile, or another class to import, and it builds a context, and a
container, of its own.

**A `static @Container` field is one container per class.** `BookRepositoryIT` started its own
PostgreSQL, a second one, because its container belongs to the class and not to any context. That is
right for a class that wants a database nobody else has touched, and a waste for ten classes that
would have been happy to share one. The bean style shares; the field style isolates.

## What it costs the first time

None of the figures above includes a download. The first run on a new machine pulls the images,
and they stay on the disk afterwards:

```
ana@vm:~/bookshop$ docker image ls --format '{{.Repository}}:{{.Tag}}  {{.Size}}' | grep -E 'postgres|ryuk'
postgres:16-alpine  420MB
testcontainers/ryuk:0.14.0  4.83MB
```

How long that takes depends on the connection, once. `docker image rm postgres:16-alpine` gives the
space back and makes the next run download it again.

## Which run, and when

A test suite people stop running protects nothing, and the split in this lesson is how it stays
quick enough to run. **Many unit tests, through `mvn test`, while you work**: a few seconds, no
Docker, the service's logic checked through mocks. **Fewer integration tests, through `mvn verify`,
before you commit**: the queries, the migrations and the configuration, against the database they
run on in production. Lesson 20 adds HTTP to the integration tests, and `testing-cicd` makes a build
server run `mvn verify` on every change, where nobody can forget it.
