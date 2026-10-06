---
title: Rotation, and the first hour after a leak
version: 1
---

**Rotating** a secret means replacing it with a new value and making the old one stop working. Done
routinely, it limits how long any copy of a secret stays useful. Done after a leak, it is the step
that matters most, and doing it in the wrong order causes an outage of your own.

Here the carrier rotates the production token: the stand-in is restarted accepting only
`lab-live-token-2`, and `shipquote` still presents the old one.

```
ana@laptop:~/shipquote$ curl -s "http://127.0.0.1:8300/quote?cep=01310-100&weight=1200&subtotal=5000"; echo
{"cep": "01310-100", "zone": "SP", "cents": 2190, "price": "R$ 21,90"}
ana@laptop:~/shipquote$ tail -2 ~/envs/production/app.log
carrier unavailable, using the table: HTTP Error 401: Unauthorized
GET /quote?cep=01310-100&weight=1200&subtotal=5000 200 2.2ms v=1.5.0
ana@laptop:~/shipquote$ ops/restart.sh production && curl -s "http://127.0.0.1:8300/quote?cep=01310-100&weight=1200&subtotal=5000"; echo
{"cep": "01310-100", "zone": "SP", "cents": 1860, "price": "R$ 18,60"}
```

The first quote came back at **R$ 21,90**, the table's price, instead of the carrier's R$ 18,60, and
the log says why: `carrier unavailable, using the table: HTTP Error 401: Unauthorized`. The fallback
of lesson 2 kept the shop answering, and the log line lesson 2's spy test protects is the only
visible symptom. Then the configuration is updated, the process restarted, and the next quote comes
from the carrier again.

## Rotating without the outage

The gap between those two quotes is the outage a careless rotation causes. Providers avoid it by
allowing **two valid secrets at once** for a while:

1. create the new secret, while the old one keeps working;
2. deploy the new one to every place that uses it;
3. confirm every consumer has switched, from the provider's logs or the program's;
4. revoke the old one.

The lab's stand-in accepts one token at a time, so it can only show the version with the gap.

## After a leak

When a secret has leaked, by a commit, a log or a laptop, the order is different, because the old
value is now in somebody else's hands:

1. **Revoke or rotate it first**, accepting a short outage if the provider cannot overlap two keys.
   Every minute the leaked value works is a minute somebody else can use it.
2. **Check whether it was used**: the provider's access logs, the unusual shipments, the bill.
3. **Find how it leaked** and close that path: the commit, the log line, the permission.
4. **Clean up** the copies you control, such as the history of section 03, knowing that copies you do
   not control are already out of reach.

Cleaning the history first and rotating later, the intuitive order, leaves the secret working
throughout. The repository's own policy for its deploy credential takes the problem away instead: a
federated credential expires within the hour, so a leaked one stops working on its own.
