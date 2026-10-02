---
title: What the outside can see
version: 1
---

Start where a customer stands. `checkout.json` is one checkout: a kettle, one of it, and a card
number that payment systems reserve for tests and that charges nobody:

```json
{"sku": "kettle", "qty": 1, "card": "4111 1111 1111 1111"}
```

Sent to the storefront, it comes back as an order:

```
ana@obs:~/shop$ curl -s -X POST localhost:8080/checkout -H 'Content-Type: application/json' -d @checkout.json
{"id":1,"qty":1,"sku":"kettle","status":"paid"}
ana@obs:~/shop$ curl -s -o /dev/null -w '%{http_code} in %{time_total} s\n' -X POST localhost:8080/checkout -H 'Content-Type: application/json' -d @checkout.json
201 in 0.036398 s
```

`-w` asks `curl` to print the status code and the total time instead of the body: `201 Created`,
in 36 milliseconds. Now payments is told to be slow. The lab reads `faults/payments.json` on every
charge, and this file makes each one wait a second and a half before answering:

```
ana@obs:~/shop$ echo '{"latency_ms": 1500}' > faults/payments.json
ana@obs:~/shop$ curl -s -o /dev/null -w '%{http_code} in %{time_total} s\n' -X POST localhost:8080/checkout -H 'Content-Type: application/json' -d @checkout.json
201 in 1.536103 s
```

**Still a `201`, and now 1.54 seconds.** Nothing failed: the order was stored, the card was charged,
the confirmation went out. A check that asks *did it answer, and with a success code?* passes this
request exactly as it passed the first. A customer waiting a second and a half to be told they had
paid does not pass it.

That is everything the outside can tell you. The checkout crossed four services, a database and a
queue, and from here it is one number. **Which of them spent the time is not in the answer**, and
no amount of staring at the answer will put it there. What follows is the same checkout as seen by
three signals that the shop was built to emit. Each one exists because a few lines of code in
the shop produce it. The lab then ran one minute of simulated customers, two requests a second, so
that the signals have more than one request in them.
