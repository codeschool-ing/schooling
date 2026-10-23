---
title: Metrics with Micrometer
version: 1
---

Health is a verdict for this instant. A **metric** is a number the application keeps over time: how
many requests so far, how long they took, how many connections are busy now. Lesson 16 met SLF4J, a
facade that the code logs through while a backend decides where the lines go. **Micrometer** is the
same arrangement for numbers. The bookshop's code, and every library Boot configures, records into a
`MeterRegistry`; which system eventually reads the numbers is a dependency in the pom, and the code
does not change when it does.

Every number is held by a **meter**, and three kinds cover nearly everything:

- a **counter** only goes up: requests served, orders placed. Its value since start-up is rarely the
  point; how fast it grows is;
- a **gauge** is a reading of something at this moment, which can go up or down: connections in use,
  memory used;
- a **timer** counts events and adds up how long they took, so it gives a count, a total and a
  maximum at once.

A meter has a name and **tags**, pairs of key and value. One name with different tag values is a
family of separate series, which is what lets the same meter answer "all requests" and "only the 404s
on `/books/{id}`".

## What is already measured

The bookshop's own code registers one meter, the counter of the next section. Ask for the list of
names anyway, and in this run there are 98:

```
ana@vm:~/bookshop$ curl -s localhost:8081/actuator/metrics | python3 -c 'import json,sys; print(len(json.load(sys.stdin)["names"]))'
98
ana@vm:~/bookshop$ curl -s localhost:8081/actuator/metrics | python3 -c 'import json,sys; print(*json.load(sys.stdin)["names"], sep="\n")' | grep -E '^(http|hikaricp|jvm.memory|bookshop)'
bookshop.orders
hikaricp.connections
hikaricp.connections.acquire
hikaricp.connections.active
hikaricp.connections.creation
hikaricp.connections.idle
hikaricp.connections.max
hikaricp.connections.min
hikaricp.connections.pending
hikaricp.connections.timeout
hikaricp.connections.usage
jvm.memory.committed
jvm.memory.max
jvm.memory.usage.after.gc
jvm.memory.used
```

The second command prints the names one per line and keeps the families of the HTTP server, the
connection pool, memory and the bookshop. The HTTP server's is missing: a timer is created by the
first request it times, and since this start nobody has asked port 8080 anything. `bookshop.orders`
is there before any order, because `OrderService` registers it in its constructor. The names left
out cover the JVM's threads and garbage
collector, the process, Tomcat's sessions, Logback, which counts log lines by level, and Spring
Security, which times every filter in lesson 15's chain.

## A timer, read through its tags

Make a few requests, including one for a book that does not exist, and ask for the timer behind them:

```
ana@vm:~/bookshop$ for path in /books /books /books/1 /books/2 /books/99; do curl -s -o /dev/null -w "%{http_code} $path\n" localhost:8080$path; done
200 /books
200 /books
200 /books/1
200 /books/2
404 /books/99
ana@vm:~/bookshop$ curl -s localhost:8081/actuator/metrics/http.server.requests | python3 -m json.tool
{
    "availableTags": [
        {
            "tag": "exception",
            "values": [
                "none"
            ]
        },
        {
            "tag": "method",
            "values": [
                "GET"
            ]
        },
        {
            "tag": "error",
            "values": [
                "none"
            ]
        },
        {
            "tag": "uri",
            "values": [
                "/books/{id}",
                "/books"
            ]
        },
        {
            "tag": "outcome",
            "values": [
                "CLIENT_ERROR",
                "SUCCESS"
            ]
        },
        {
            "tag": "status",
            "values": [
                "404",
                "200"
            ]
        }
    ],
    "baseUnit": "seconds",
    "measurements": [
        {
            "statistic": "COUNT",
            "value": 5.0
        },
        {
            "statistic": "TOTAL_TIME",
            "value": 0.187019944
        },
        {
            "statistic": "MAX",
            "value": 0.12685655
        }
    ],
    "name": "http.server.requests"
}
```

`COUNT` is five, one per request. `TOTAL_TIME` adds their durations, in the `baseUnit`, seconds, and
`MAX` is the longest single request. That maximum covers a recent window rather than the whole uptime,
so one slow request this morning does not sit at the top all day. `availableTags` lists every value
each tag has taken: two routes, two statuses, two outcomes. `exception` stays `none` even for the
404, because lesson 7's handler turned `BookNotFoundException` into an answer before it could escape.

The `uri` tag is the line that matters most. It holds the **route template**, `/books/{id}`, and never
the path that was asked for. If it held `/books/1`, `/books/2` and every id anybody ever typed, the
family would grow by a series for every new path, and a registry that keeps every series in memory
would grow with it until the process ran out. A request that matched no route at all, like the
anonymous one to `/actuator/health` on 8080 in the first section, is filed under `UNKNOWN` for the
same reason.

Tags can be chosen in the query, as `tag=key:value`, once per tag. The braces of the template are
written `%7B` and `%7D`, because a URL may not carry them raw:

```
ana@vm:~/bookshop$ curl -s "localhost:8081/actuator/metrics/http.server.requests?tag=uri:/books/%7Bid%7D&tag=status:404" | python3 -m json.tool | tail -n 16
    "measurements": [
        {
            "statistic": "COUNT",
            "value": 1.0
        },
        {
            "statistic": "TOTAL_TIME",
            "value": 0.015200056
        },
        {
            "statistic": "MAX",
            "value": 0.015200056
        }
    ],
    "name": "http.server.requests"
}
```

## The pool, as lesson 14 promised

Lesson 14 ended on a pool that runs out. HikariCP publishes its own state, and each of these is a
gauge:

```
ana@vm:~/bookshop$ for m in active idle pending max; do printf "%-8s" $m; curl -s localhost:8081/actuator/metrics/hikaricp.connections.$m | python3 -c "import json,sys; print(json.load(sys.stdin)[\"measurements\"][0][\"value\"])"; done
active  0.0
idle    10.0
pending 0.0
max     10.0
```

At rest, all ten connections are idle and nobody waits. **`hikaricp.connections.pending`** is the one
to watch: it counts threads queuing for a connection, and a request that waits there long enough fails
after `connection-timeout`, as `GET /books` did in the previous section. A pending count that stays
above zero, with `active` pinned at `max`, is the shape of lesson 14's exhaustion, seen from outside
and before the first request times out.
