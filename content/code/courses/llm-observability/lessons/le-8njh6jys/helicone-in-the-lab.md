---
title: Helicone in the lab, and the request it refused
version: 1
---

Helicone is open source, and publishes a single image that runs all of it in one container: the
gateway and API (called `jawn`), the web screens, PostgreSQL, ClickHouse and MinIO. `sudo bash lab.sh
helicone` starts it from that image at a pinned digest. It is a 14 GB image, which says something about
what one container holding five services costs. Its gateway answers on port 8585:

```
ana@lab:~/obs$ curl -s http://127.0.0.1:8585/healthcheck; echo
{"status":"healthy :)"}
ana@lab:~/obs$ python via_gateway.py
InternalServerError: Invalid API base "http://127.0.0.1:8600"
```

**Helicone refused to forward to labobs.** The gateway keeps a list of the providers' domains it will
forward to, and `http://127.0.0.1:8600` is not on it. That was the end of what the lab could do with
Helicone: with no real provider's key to forward to, there was nothing for it to record, and no reply
in this lesson came through it.

The refusal is worth a paragraph, because it is right. A gateway that forwarded to any URL in a
header would be an open relay: anybody able to send it a request could make it call any address it
can reach, including the internal services behind it, the attack called **server-side request
forgery**. Allowing only known provider domains is the defence, and it is the setting to look for in
any gateway, bought or built. An internal model server would be added to that list by whoever runs
the gateway, which is a change somebody has to make on purpose.

## What was not run

The hosted Helicone, where most teams use it, was not reached from the lab, and no request went
through the self-hosted gateway to a real provider. What the documentation describes and this course
did not verify: the dashboards of requests, cost and latency by user and property; the cache and rate
limits configured by headers; and sessions that group a chain of calls. Each behaves as a gateway's
version of something lessons 3 to 5 built from spans, and the honest comparison is the one in the last
section, not a list of features.
