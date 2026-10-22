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
[INFO] Total time:  2.461 s
```

```
ana@vm:~/bookshop$ mvn -B verify 2>&1 | grep -E 'Skipped: 0$|Total time|started in PT|Started .*IT in'
[INFO] Tests run: 17, Failures: 0, Errors: 0, Skipped: 0
2026-10-22T20:30:14.184-03:00  INFO 31645 --- [bookshop] [           main] [] tc.testcontainers/ryuk:0.14.0            : Container testcontainers/ryuk:0.14.0 started in PT0.340325083S
2026-10-22T20:30:15.522-03:00  INFO 31645 --- [bookshop] [           main] [] tc.postgres:16-alpine                    : Container postgres:16-alpine started in PT1.332489607S
2026-10-22T20:30:18.253-03:00  INFO 31645 --- [bookshop] [           main] [] c.e.bookshop.BookshopApplicationIT       : Started BookshopApplicationIT in 6.186 seconds (process running for 7.01)
2026-10-22T20:30:19.854-03:00  INFO 31645 --- [bookshop] [           main] [] tc.postgres:16-alpine                    : Container postgres:16-alpine started in PT1.358918883S
2026-10-22T20:30:20.241-03:00  INFO 31645 --- [bookshop] [           main] [] c.e.bookshop.catalogue.BookRepositoryIT  : Started BookRepositoryIT in 0.38 seconds (process running for 8.998)
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
[INFO] Total time:  14.530 s
```

Two and a half seconds of Maven for the seventeen unit tests, and fourteen and a half for the same
seventeen plus three integration tests: about six times as long, for three tests. Timings move from
one run to the next (the same `mvn verify` in the section before this one took 14.740 s), so read the
proportions rather than the digits.

## Where the seconds went

Read the second run's lines against each other. **The containers are not the expensive part.** Ryuk
started in about a third of a second and each PostgreSQL in about 1.3 seconds, including the wait
until it accepted connections. What took most of the time was Spring: the whole application context,
for `BookshopApplicationIT`, needed 6.2 seconds, while the persistence slice of `BookRepositoryIT` was
ready in under 0.4. Packaging the jar is in the total too, because `verify` comes after
`package`.

So the cost of an integration test is mostly the context it starts, and two habits follow from that.

**Share a context, and the container comes with it.** Spring's test framework keeps a context once
it is built and hands it to every later test class with the same configuration: the same annotations,
the same profiles, the same imports. A second `@SpringBootTest` class with `@ActiveProfiles("test")`
and `@Import(TestcontainersConfiguration.class)` would reuse the six seconds and the database of
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
