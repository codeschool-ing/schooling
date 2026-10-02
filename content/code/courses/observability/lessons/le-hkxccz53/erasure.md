---
title: Taking it back
version: 1
---

The leak was found. Now the lines that already reached the stores have to go, and **this is where
logs are at their worst**. They are built to be appended to, not edited. A store designed for
millions of writes a minute was not designed for deleting one.

Loki accepts a **delete request**: a LogQL selector and filter, and a time range. It does not delete
on the spot. The request is queued, and the compactor rewrites the affected chunks on its next pass,
after a grace period:

```
ana@obs:~/shop$ curl -s -o /dev/null -w '%{http_code}\n' -X POST -G localhost:3100/loki/api/v1/delete --data-urlencode 'query={service_name="storefront"} |= "sk_live_9f8e7d6c5b4a"' --data-urlencode start=$(date -d '-1 hour' +%s)
204
ana@obs:~/shop$ curl -s localhost:3100/loki/api/v1/delete | jq -c '.[] | {query, status}'
{"query":"{service_name=\"storefront\"} |= \"sk_live_9f8e7d6c5b4a\"","status":"received"}
```

`204`, accepted, and the request sits as `received` until the compactor gets to it. Elasticsearch
deletes by query, immediately, every document that matches:

```
ana@obs:~/shop$ curl -s -X POST localhost:9200/logs-generic.otel-default/_delete_by_query -H 'Content-Type: application/json' -d '{"query": {"match_phrase": {"body.text": "sk_live_9f8e7d6c5b4a"}}}' | jq -c '{deleted, failures}'
{"deleted":1,"failures":[]}
```

**One document deleted**: the first checkout's line. The second leak never reached Elasticsearch,
because the filter in the code had masked it, and the third reached it already masked by the
Collector. Each defence shows up in the count.

And the copies nobody asked about are still there: the container's own log on the machine, any
backup taken of either store, any vendor the logs were exported to, and any person who copied a line
into a ticket. **Deleting a log line is never finished.** That turns the LGPD's right to deletion
into an argument about design rather than about tooling: the line that never held a person's data
needs no deletion. That is the rule this lesson ends on. Log identifiers that mean nothing outside
the system, keep lines only as long as they are useful, and treat a store full of personal data as
the incident it is.