---
title: Logs a program can read
version: 1
---

Metrics say how many and how fast. When a number looks wrong, the next question is about
particular requests: which ones failed, with what error, on which copy. That is a log's job, and a
log is only useful if it can be **searched by its fields**, which means writing it for a program to
read rather than a person.

The box office writes one JSON object per line, to standard output. Docker keeps what each container
writes there, and `docker compose logs` reads it; `--no-log-prefix` leaves out the container's name
at the start of each line, so that the line is pure JSON:

```
ana@lab:~/tickets$ docker compose logs app --no-log-prefix | tail -3
{"time": "2026-10-10T06:10:17.822+00:00", "level": "info", "message": "request", "host": "9c46e3d34a31", "method": "POST", "route": "/events/{id}/tickets", "status": 201, "ms": 29.6}
{"time": "2026-10-10T06:10:17.823+00:00", "level": "info", "message": "request", "host": "9c46e3d34a31", "method": "POST", "route": "/events/{id}/tickets", "status": 201, "ms": 43.2}
{"time": "2026-10-10T06:10:17.823+00:00", "level": "info", "message": "request", "host": "9c46e3d34a31", "method": "POST", "route": "/events/{id}/tickets", "status": 201, "ms": 26.0}
```

Every line has the same keys in the same form: the time in UTC to the millisecond, a level, a
message, the copy that wrote it, and the request's own fields. A line like
`POST /events/7/tickets took 43 ms` reads well and has to be taken apart with a pattern to be
counted; a JSON line is already taken apart, and every log system indexes JSON fields directly.

## When something breaks

The replica is stopped, as if it had crashed, and a show's page is asked for:

```
ana@lab:~/tickets$ docker compose stop replica
 Container tickets-replica-1 Stopping 
 Container tickets-replica-1 Stopped 
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"error": "internal error"}
ana@lab:~/tickets$ docker compose logs app --no-log-prefix | grep '"level": "error"' | tail -1
{"time": "2026-10-10T06:10:28.856+00:00", "level": "error", "message": "request failed", "host": "e8f493cffbb3", "method": "GET", "route": "/events/{id}", "error": "AdminShutdown: terminating connection due to administrator command"}
ana@lab:~/tickets$ docker compose exec prometheus promtool query instant http://localhost:9090 'sum by (route, status) (tickets_requests_total{status="500"})'
{route="/events/{id}", status="500"} => 1 @[1791612635.399]
ana@lab:~/tickets$ docker compose start replica
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Starting 
 Container tickets-replica-1 Started 
```

Three views of one failure. The **client** got a 500 with a short message, and nothing about the
internals: an error message for users should not describe the database. The **log** says exactly
what happened: a `GET` of `/events/{id}` failed with `AdminShutdown`, PostgreSQL's way of saying the
server on the other end of the connection was shut down. The **metric** counted it: one request with
status 500 on that route, which is what an alert on the error rate would fire on.

Without the `try` in `observe`, the exception would have closed the connection with no answer,
nginx would have answered 502, and nothing in the box office would have recorded anything. **An
error the program does not catch is an error its own metrics cannot see.**

## What goes in a log, and what does not

- **One line per event worth finding later**, with the fields that identify it: route, status,
  duration, and in lesson 8 the trace it belongs to.
- **Levels used for what they mean.** `error` is something that needs a person; `info` is the
  record of normal work. A system that logs errors for normal events trains people to ignore them.
- **No secrets and no personal data.** Passwords, tokens, card numbers, a buyer's e-mail. Logs are
  copied to more places and kept longer than anything else a system writes, and a field logged by
  accident is a leak that lasts as long as the logs do.
- **Not as a substitute for a metric.** Counting log lines to know the request rate works, and costs
  storage in proportion to the traffic; a counter costs the same at any traffic. At 800 requests a
  second, the box office's request log is about 70 million lines a day.
