---
title: Retention: an expiry date for every line
version: 1
---

Every store keeps lines until something deletes them, and the default is often *forever*. **A
retention period is a decision about how far back an investigation can look**, weighed against cost
and against the risk of holding data longer than it is needed. The LGPD counts that as a risk in
itself.

Loki's is one line in its configuration, applied by its compactor, which deletes chunks older than
the period:

```
ana@obs:~/shop$ grep -A3 limits_config loki/loki.yaml
limits_config:
  allow_structured_metadata: true
  retention_period: 168h

```

Seven days in the lab. Elasticsearch does it with an **index lifecycle policy**: a data stream
rolls its writing over to a new backing index on a schedule, and each index moves through phases
until the last one deletes it. A policy that rolls over daily and deletes after a week:

```
ana@obs:~/shop$ curl -s -X PUT localhost:9200/_ilm/policy/shop-logs -H 'Content-Type: application/json' -d '{"policy": {"phases": {"hot": {"actions": {"rollover": {"max_age": "1d"}}}, "delete": {"min_age": "7d", "actions": {"delete": {}}}}}}'; echo
{"acknowledged":true}
ana@obs:~/shop$ curl -s localhost:9200/_ilm/policy/shop-logs | jq -c '."shop-logs".policy.phases | map_values(.min_age)'
{"hot":"0ms","delete":"7d"}
```

`hot` from the moment an index is created, `delete` seven days later. In a real deployment the
policy is attached to the data stream's index template, and phases in between, `warm` and `cold`,
move older indices to cheaper disks before they go.

**How long is right is not a technical question**, and three facts usually decide it:

- the longest an incident takes to be noticed and investigated: a week is often enough for
  operational logs;
- what a law or a contract demands be kept, which is usually *audit* data, a separate stream with
  its own store and access rules, and not the debug lines of a web service;
- the cost per day kept, from the previous section, multiplied out.

Different logs can and should have different periods. An application's `INFO` lines for seven days,
its errors for thirty, and its audit trail for as long as the law says, are three policies, not one.
