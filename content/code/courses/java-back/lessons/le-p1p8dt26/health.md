---
title: Health, liveness and readiness
version: 1
---

`/actuator/health` answers one question, **is this application fit to work?**, with a word and an
HTTP status. Underneath the word is a list of **health indicators**, one per thing Boot found worth
checking, and the overall status is the worst of theirs. `UP` comes with `200`; `DOWN` and
`OUT_OF_SERVICE` come with `503`, so a load balancer or a monitoring probe that reads only the status
code still gets the verdict right.

## What it checks

```
ana@vm:~/bookshop$ curl -s localhost:8081/actuator/health | python3 -m json.tool
{
    "components": {
        "db": {
            "details": {
                "database": "PostgreSQL",
                "validationQuery": "isValid()"
            },
            "status": "UP"
        },
        "diskSpace": {
            "details": {
                "total": 270553174016,
                "free": 24556486656,
                "threshold": 10485760,
                "path": "/home/ana/bookshop/.",
                "exists": true
            },
            "status": "UP"
        },
        "livenessState": {
            "status": "UP"
        },
        "ping": {
            "status": "UP"
        },
        "readinessState": {
            "status": "UP"
        },
        "ssl": {
            "details": {
                "expiringChains": [],
                "invalidChains": [],
                "validChains": []
            },
            "status": "UP"
        }
    },
    "groups": [
        "liveness",
        "readiness"
    ],
    "status": "UP"
}
```

Nobody wrote any of these checks; each one arrived with a dependency. **`db`** came with the
datasource: it borrows a connection from the pool and asks the driver whether it is still valid,
which is what `isValid()` means. **`diskSpace`** reports `DOWN` when the free space under the working
directory falls below `threshold`, ten megabytes, because an application that cannot write its logs
is about to fail in stranger ways. `ping` is always `UP`; it proves only that something answered. `ssl`
watches certificates the application serves itself, and the bookshop serves none, so its three lists
are empty. The two `State` indicators belong to the groups at the end of this section.

The details are there because of `show-details=always`. They help whoever reads them, and they also
tell a stranger which database you run and how much disk is left, which is why the default is
`never`. On a port only the machine can reach, `always` costs nothing. If the endpoints shared the
public port, `when-authorized` would show the details to an authenticated caller only.

## Taking the database away

The way to trust a health check is to watch it fail. PostgreSQL must keep running for everything else
on the machine, so instead of stopping it, forbid the `bookshop` role to log in, and close the
connections it already holds. In the second
statement, `pg_stat_activity` lists the server processes and `pg_terminate_backend` ends one.

```
ana@vm:~/bookshop$ sudo -u postgres psql -c 'ALTER ROLE bookshop NOLOGIN'
ALTER ROLE
ana@vm:~/bookshop$ sudo -u postgres psql -c "SELECT count(pg_terminate_backend(pid)) FROM pg_stat_activity WHERE usename = 'bookshop'"
 count 
-------
    10
(1 row)
```

Ten connections, the pool's whole `maximum-pool-size` from lesson 14. Now ask again:

```
ana@vm:~/bookshop$ curl -s -w "%{http_code} after %{time_total} s\n" -o health.json localhost:8081/actuator/health
503 after 0.015768 s
ana@vm:~/bookshop$ python3 -m json.tool health.json | head -9
{
    "components": {
        "db": {
            "details": {
                "database": "PostgreSQL",
                "validationQuery": "isValid()"
            },
            "status": "DOWN"
        },
ana@vm:~/bookshop$ curl -s -w " %{http_code}\n" localhost:8081/actuator/health/liveness
{"status":"UP"} 200
ana@vm:~/bookshop$ curl -s -w " %{http_code}\n" localhost:8081/actuator/health/readiness
{"status":"UP"} 200
```

The full report turned `DOWN` and its status code `503`, in 16 milliseconds: the check took a pooled
connection, found it dead, and said so. The two groups still answer `UP`, and that is deliberate, as
the next part explains. The API fared worse. `GET /books` waited the pool's five-second
`connection-timeout` for a connection that never came, and then answered `401`. That last number is a
defect of its own rather than a verdict on the token: the failed request is forwarded to Spring's
`/error` page, which the API's rules do not open to anonymous callers. The metrics, which the next section
reads properly, saw the request before that rewrite:

```
ana@vm:~/bookshop$ curl -s -o /dev/null -w "%{http_code} after %{time_total} s\n" localhost:8080/books
401 after 5.018283 s
ana@vm:~/bookshop$ curl -s localhost:8081/actuator/prometheus | grep "^http_server_requests_seconds_count"
http_server_requests_seconds_count{error="CannotCreateTransactionException",exception="CannotCreateTransactionException",method="GET",outcome="SERVER_ERROR",status="500",uri="/books"} 1
http_server_requests_seconds_count{error="none",exception="none",method="GET",outcome="CLIENT_ERROR",status="401",uri="UNKNOWN"} 1
http_server_requests_seconds_count{error="none",exception="none",method="GET",outcome="CLIENT_ERROR",status="404",uri="/**"} 1
http_server_requests_seconds_count{error="none",exception="none",method="GET",outcome="SUCCESS",status="200",uri="/books"} 2
http_server_requests_seconds_count{error="none",exception="none",method="POST",outcome="SUCCESS",status="200",uri="/auth/token"} 1
```

The first line is the outage: `GET /books`, status `500`, `SERVER_ERROR`, and the exception that
caused it. The client was told 401; the timer recorded what the handler did. The other lines are this
lesson's earlier requests, the anonymous 401 and the 404 with a token among them. The second terminal
tells the same story from the inside:

```
2026-10-22T20:34:36.781-03:00  WARN 13286 --- [bookshop] [nio-8080-exec-8] [cfd409dc] org.hibernate.orm.jdbc.error             : HHH000247: ErrorCode: 0, SQLState: 28000
2026-10-22T20:34:36.781-03:00  WARN 13286 --- [bookshop] [nio-8080-exec-8] [cfd409dc] org.hibernate.orm.jdbc.error             : bookshop-pool - Connection is not available, request timed out after 5000ms (total=0, active=0, idle=0, waiting=0)
2026-10-22T20:34:36.785-03:00 ERROR 13286 --- [bookshop] [nio-8080-exec-8] [] o.a.c.c.C.[.[.[/].[dispatcherServlet]    : Servlet.service() for servlet [dispatcherServlet] in context with path [] threw exception [Request processing failed: org.springframework.transaction.CannotCreateTransactionException: Could not open JPA EntityManager for transaction] with root cause
```

Give the role its login back, and the pool reconnects on the next request. A single indicator has a
path of its own:

```
ana@vm:~/bookshop$ sudo -u postgres psql -c 'ALTER ROLE bookshop LOGIN'
ALTER ROLE
ana@vm:~/bookshop$ curl -s -w "\n" localhost:8081/actuator/health/db
{"details":{"database":"PostgreSQL","validationQuery":"isValid()"},"status":"UP"}
```

## Two questions for an orchestrator

When something else runs the application, Kubernetes or a container platform, it asks two different
questions, and the cost of a wrong answer is different for each:

| group | the question | what a failure makes the platform do |
|---|---|---|
| `liveness` | is this process broken beyond repair? | kill it and start a new one |
| `readiness` | should requests be sent here right now? | stop routing traffic to it, and leave it running |

The common wrong picture is that both should report the database. Put `db` in **liveness** and a
database outage makes the platform restart every copy of the bookshop at once. No restart fixes
PostgreSQL, and every copy now pays a full start-up, with Flyway and Hibernate, and comes back to the
same outage. Put it in **readiness** and every copy leaves the load balancer together, so a slow
database becomes a total outage, even for requests that never touch it. So Boot keeps
both groups to the application's own state, and the outage above showed exactly that: the report was
`DOWN`, and neither group moved. A group can include more indicators, with
`management.endpoint.health.group.readiness.include`, and that is a decision to make on purpose,
against the paragraph above.

What does move readiness is the application's own life cycle. Start a loop in a third terminal that
asks all three, as fast as curl can, and then start the bookshop in the second terminal:

```
ana@vm:~/bookshop$ for i in $(seq 1500); do echo $(for p in health/liveness health/readiness health; do curl -s -o /dev/null -w '%{http_code} ' localhost:8081/actuator/$p; done); done | uniq -c
    733 000 000 000
      1 200 503 503
    766 200 200 200
```

`uniq -c` folds identical lines, so 1,500 rounds came out as three lines. For the first 733 rounds
nothing listened on 8081, and curl's `000` means no connection at all. Then one round answered
`200 503 503`: the process was alive, and readiness and the full report said it was not ready. Every
round after that answered `200` three times. The window is short, and a loop can miss it; if yours
shows no `503`, start the application again. The second terminal, started with
`--logging.level.org.springframework.boot.availability=debug`, says what the window was:

```
2026-10-22T20:34:48.964-03:00  INFO 14179 --- [bookshop] [           main] [] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 9.799 seconds (process running for 10.494)
2026-10-22T20:34:49.075-03:00 DEBUG 14179 --- [bookshop] [           main] [] o.s.b.a.ApplicationAvailabilityBean      : Application availability state LivenessState changed to CORRECT
2026-10-22T20:34:49.201-03:00  INFO 14179 --- [bookshop] [           main] [] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 6 books
2026-10-22T20:34:49.202-03:00 DEBUG 14179 --- [bookshop] [           main] [] o.s.b.a.ApplicationAvailabilityBean      : Application availability state ReadinessState changed to ACCEPTING_TRAFFIC
```

`Started BookshopApplication` is not the end of a start-up. Right after it, liveness turns `CORRECT`.
Then the application's runners run, here lesson 5's `CatalogueReport`, and only when the last one
returns does readiness turn `ACCEPTING_TRAFFIC`. In between, about a quarter of a second in this run,
the process is alive and still preparing, and that is the moment readiness exists for. The same
two instants are kept as metrics:

```
ana@vm:~/bookshop$ curl -s localhost:8081/actuator/prometheus | grep -E "^application_(started|ready)_time"
application_ready_time_seconds{main_application_class="com.example.bookshop.BookshopApplication"} 10.038
application_started_time_seconds{main_application_class="com.example.bookshop.BookshopApplication"} 9.799
```

So work that has to finish before the first request, warming a cache or loading a file, belongs in a
runner: readiness waits for it, and a platform that respects readiness sends nothing until it is done.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 214\" role=\"img\" aria-label=\"Three health URLs at four moments. While the bookshop starts, port 8081 is closed and none answers. While the start-up runners work, liveness answers 200 and readiness and the full health answer 503. While it serves, all three answer 200. With the database refusing the bookshop, liveness and readiness still answer 200 and the full health 503.\"><text x=\"190.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">starting</text><text x=\"330.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">runners</text><text x=\"470.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">serving</text><text x=\"610.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">database gone</text><text x=\"108\" y=\"63.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">liveness</text><rect x=\"126\" y=\"40\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"190.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no answer</text><rect x=\"266\" y=\"40\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"330.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200</text><rect x=\"406\" y=\"40\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200</text><rect x=\"546\" y=\"40\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UP 200</text><text x=\"108\" y=\"119.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">readiness</text><rect x=\"126\" y=\"96\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"190.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no answer</text><rect x=\"266\" y=\"96\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"330.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">503</text><rect x=\"406\" y=\"96\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200</text><rect x=\"546\" y=\"96\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UP 200</text><text x=\"108\" y=\"175.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">health</text><rect x=\"126\" y=\"152\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"190.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no answer</text><rect x=\"266\" y=\"152\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"330.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">503</text><rect x=\"406\" y=\"152\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200</text><rect x=\"546\" y=\"152\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">DOWN 503</text></svg>", "caption": "Readiness waits for the start-up work to finish. Neither group looks at the database, so losing it changes only the full report."}
```
