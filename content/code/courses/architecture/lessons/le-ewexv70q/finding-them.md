---
title: Finding them
version: 1
---

Each fix in this lesson was a few lines. None of the problems would have been found by reading the
code, because each page was correct and each query, on its own, was fast. They are found by measuring,
and three measurements find most of them:

| measurement | what it shows | finds |
| --- | --- | --- |
| **queries per request** | how many times one page talks to the database | chatty I/O; a page with 40 queries is an N+1 |
| **bytes per request** | how much data one page moves | extraneous fetching |
| **database time per query, in total** | which statements the database spends its time on | the busy database; `pg_stat_statements` |

The first two come from **tracing**: an APM agent or OpenTelemetry instrumentation records every database
call as a span inside the request's trace, and an N+1 shows up as a comb of identical spans. Lesson 7 of
the `scale` course sets that up. Many ORMs can also count queries per request in development and fail a
test that goes over a budget, which catches the N+1 before it ships.

The catalogue has more entries than this lesson built, and each is the same kind of habit:

| antipattern | the habit |
| --- | --- |
| improper instantiation | a new HTTP client or connection pool for every request, paying the connection set-up every time |
| synchronous I/O | a thread blocked waiting on I/O it could have given up, lesson 12's thread pool again |
| no caching | the same unchanging answer recomputed for every request |
| retry storm | retries that multiply load on a struggling service, lesson 11 |
| noisy neighbour | one tenant or one workload using up a resource the others share, lesson 12's bulkheads |
| monolithic persistence | one database for every kind of data, whatever its access pattern |

When you are done, stop the lab:

```sh
docker compose down -v
```
