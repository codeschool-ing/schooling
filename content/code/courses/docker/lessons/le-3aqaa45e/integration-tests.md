---
title: Integration tests with a real database
version: 1
---

**A unit test checks the program against itself. An integration test checks it against the things it
really talks to**, and for `shelf` that is Postgres. Its test is in `postgres_test.go`, behind the
build tag `integration`, so a plain `go test` skips it; it needs `DATABASE_URL`, and it fails, loudly,
without one.

Compose provides the database for the length of a test run:

```yaml
services:
  db:
    image: postgres:17
    environment:
      POSTGRES_USER: shelf
      POSTGRES_PASSWORD: test-only
      POSTGRES_DB: shelf
    tmpfs:
      - /var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready", "-h", "127.0.0.1", "-U", "shelf", "-d", "shelf"]
      interval: 2s
      retries: 15

  tests:
    image: golang:1.25
    working_dir: /src
    volumes:
      - .:/src
    environment:
      DATABASE_URL: postgres://shelf:test-only@db:5432/shelf
    command: ["go", "test", "-tags", "integration", "-count=1", "-v", "./..."]
    depends_on:
      db:
        condition: service_healthy
```

Three choices in it are about tests rather than about running `shelf`:

- **The data lives on a `tmpfs`**, in memory: every run starts from an empty database, nothing is left
  on disk, and it is faster.
- **The password is a fixed test value**, in the file. It protects nothing, since the database exists
  only for the run and is not published on any port.
- **The test runner is a service** in the `golang` image, with the source mounted, and it waits for the
  database to be healthy, with lesson 19's `pg_isready -h`.

```
ana@vm:~/shelf$ docker compose -f compose.test.yaml run --rm tests > it.log 2>&1; echo "exit $?"
exit 0
ana@vm:~/shelf$ grep -vE "^ *(Container|Network|Volume) " it.log
=== RUN   TestBooksAnswersWithTheCatalogue
--- PASS: TestBooksAnswersWithTheCatalogue (0.00s)
=== RUN   TestHealthIsOK
--- PASS: TestHealthIsOK (0.00s)
=== RUN   TestPostgresServesTheSeededCatalogue
--- PASS: TestPostgresServesTheSeededCatalogue (0.02s)
PASS
ok  	example.com/shelf	0.021s
?   	example.com/shelf/probe	[no test files]
ana@vm:~/shelf$ docker compose -f compose.test.yaml down 2>&1 | grep -c Removed
2
```

`docker compose run` starts `tests` and what it depends on, and **exits with the status of the
tests**: 0 here, after all three passed, the Postgres one included. That status is what a pipeline
reads. `down` removes the database container and the network, and the `tmpfs` goes with them.

## A failure that reaches the pipeline

The same run with a wrong password in `DATABASE_URL`:

```
ana@vm:~/shelf$ docker compose -f compose.test.yaml run --rm -e DATABASE_URL=postgres://shelf:wrong@db:5432/shelf tests > it.log 2>&1; echo "exit $?"
exit 1
ana@vm:~/shelf$ grep -E "^(---|FAIL)|password" it.log | head -4
--- PASS: TestBooksAnswersWithTheCatalogue (0.00s)
--- PASS: TestHealthIsOK (0.00s)
        	172.18.0.2:5432 (db): failed SASL auth: FATAL: password authentication failed for user "shelf" (SQLSTATE 28P01)
--- FAIL: TestPostgresServesTheSeededCatalogue (0.01s)
ana@vm:~/shelf$ docker compose -f compose.test.yaml down 2>&1 | grep -c Removed
2
```

**Exit status 1, and Postgres's own message in the log**: `password authentication failed`. A unit test
could not have found this; it is a disagreement between `shelf`'s configuration and the database, and
only a real database could report it.

`docker compose up --abort-on-container-exit --exit-code-from tests` does the same with `up` instead of
`run`, for files that start several services at once. Either way, lesson 26 puts these commands in a
pipeline, unchanged, which is what "exactly like the pipeline" means: the pipeline runs what Ana runs.
