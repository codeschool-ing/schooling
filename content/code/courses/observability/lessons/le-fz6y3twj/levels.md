---
title: Levels, and who decides which are written
version: 1
---

A level says how much an event matters, and it is the first thing used to decide what is written
at all. Python's five, which are the same five almost everywhere under slightly different names:

| level | what it is for | in the shop |
|---|---|---|
| `DEBUG` | detail for whoever is developing this code | off in production |
| `INFO` | a normal event worth a record | *checkout finished*, *order stored* |
| `WARNING` | something unexpected that the service handled | *rabbitmq not reachable, retrying* |
| `ERROR` | an operation failed | *orders unreachable* |
| `CRITICAL` | the service itself cannot go on | none so far |

`levels.py` logs one event at each of the first four, through the shop's formatter:

```python
import logging
import os

from common import logs

log = logs.setup()
log.debug("cache lookup", extra={"fields": {"key": "price:kettle"}})
log.info("checkout finished", extra={"fields": {"order_id": 7}})
log.warning("payments slow", extra={"fields": {"took_ms": 1500}})
log.error("payments unreachable", extra={"fields": {"attempt": 3}})
```

Run three times with a different `LOG_LEVEL` in its environment:

```
ana@obs:~/shop$ docker compose run --rm -e PYTHONPATH=/app sandbox python levels.py 2>/dev/null | jq -c '{level, message}'
{"level":"INFO","message":"checkout finished"}
{"level":"WARNING","message":"payments slow"}
{"level":"ERROR","message":"payments unreachable"}
ana@obs:~/shop$ docker compose run --rm -e PYTHONPATH=/app -e LOG_LEVEL=DEBUG sandbox python levels.py 2>/dev/null | jq -c '{level, message}'
{"level":"DEBUG","message":"cache lookup"}
{"level":"INFO","message":"checkout finished"}
{"level":"WARNING","message":"payments slow"}
{"level":"ERROR","message":"payments unreachable"}
ana@obs:~/shop$ docker compose run --rm -e PYTHONPATH=/app -e LOG_LEVEL=ERROR sandbox python levels.py 2>/dev/null | jq -c '{level, message}'
{"level":"ERROR","message":"payments unreachable"}
```

**The level set is a floor**: `INFO` writes INFO and everything above it, and `DEBUG` adds the cache
lookup. `ERROR` leaves one line. The code did not change between the three runs; the environment
did. That is what lets a service in trouble be made more talkative without a release, and turned
back once the cause is found.

Two habits keep levels useful. **An `ERROR` should mean that somebody may need to do something.**
A declined card is not an error of the service. It is a normal outcome logged at `INFO`, exactly as
lesson 2 left a span's status alone for a `404`. And **`WARNING` is for what the service survived**,
a retry or a fallback. If nobody would ever act on a warning, it is `INFO` with a louder voice.
