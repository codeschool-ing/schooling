---
title: Correlation: the trace id in every line
version: 1
---

Lesson 1 found a slow checkout's log lines in three services by searching for its trace id. That
works because the formatter adds the current span's ids to every line written while a span is
current, which in a service handling requests is nearly every line. **Nearly**, and the exceptions
are worth knowing. The mailer's first line after a reset:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix mailer | head -1 | jq -c .
{"time":"2026-10-02T10:41:29.824Z","level":"WARNING","service":"mailer","logger":"mailer","message":"rabbitmq not reachable, retrying in 2 s"}
```

No `trace_id`, and correctly so: the mailer was trying to connect to RabbitMQ at start-up, and no
request was being handled. Counting every line across the four services that has no trace id:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix storefront orders payments mailer | jq -r 'select(has("trace_id") | not) | .message' | sort | uniq -c
      2 rabbitmq not reachable, retrying in 2 s
      1 waiting for orders
```

Three lines out of thousands, all from start-up. **Every line written while serving a request has
the id**, which is the property that matters, and it holds without anybody remembering to pass the
id to the logger, because the formatter reads it from the same current span the traces use.

That is the advantage of taking the id from tracing over inventing a request id of one's own. A
home-made `request_id` has to be generated at the edge, put in a header, read in every service and
passed to every log call, and it is one more thing lesson 4's propagation has to carry. The trace id
is already carried. **Where a service does not trace**, a request id is still far better than
nothing, and the rule is the same: generate it once at the edge, propagate it on every call, write
it in every line.
