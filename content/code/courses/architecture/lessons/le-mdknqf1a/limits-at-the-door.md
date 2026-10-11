---
title: Limits at the door
version: 1
---

The stock instances asked the gateway, through their tags, to limit each client to five requests a
second with a burst of five: lesson 12's token bucket, configured instead of written. Send twenty
requests as fast as `curl` can, and count the answers:

```
ana@vm:~/lab/gateway$ for i in $(seq 20); do curl -s -o /dev/null -w "%{http_code}\n" localhost:8080/stock/coffee; done | sort | uniq -c
      6 200
     14 429
```

Six got through, the burst of five and one more token that dripped in while `curl` was running, and
fourteen were refused by the gateway with `429`, without any stock instance being asked. That is the point of putting the limit at the door: a client that misbehaves costs
the gateway a few microseconds per refused request, and costs the services nothing.

Two details matter in production. The gateway identifies "a client" by something, here the caller's
address, which is wrong behind a proxy that makes every customer look like one address; a real
configuration limits by an API key or a user id from a verified token. And with several gateway
instances, each keeps its own buckets unless they share them, in Redis for example, so five a second per
instance across four instances is twenty a second, as lesson 12 warned.
