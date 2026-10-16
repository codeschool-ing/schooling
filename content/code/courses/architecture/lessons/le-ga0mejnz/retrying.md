---
title: A retry that works
version: 1
---

Make the service fail one answer in five, the way a service behind a flaky load balancer might, and call
it at a gentle 20 requests a second:

```
ana@vm:~/lab/resilience$ curl -s -X POST localhost:8001/fail/0.2
fail 0.2
ana@vm:~/lab/resilience$ $C --rate 20 --seconds 6
 second      ok  failed   calls
  0-2        34       6      40
  2-4        31       9      40
  4-6        30      10      40
the stock service answered 120 calls, 0 of them after the caller had given up
```

About one request in five failed, as expected. Now the same, with up to two retries:

```
ana@vm:~/lab/resilience$ $C --rate 20 --seconds 6 --retries 2
 second      ok  failed   calls
  0-2        39       1      55
  2-4        40       0      49
  4-6        40       0      48
the stock service answered 152 calls, 0 of them after the caller had given up
```

One failure in 120 instead of 25. A request now fails only if three calls in a row fail, and with
each failing one time in five that is 0.2 × 0.2 × 0.2, under one in a hundred. The cost is in the last
column: **152 calls for 120 requests**, about 27% more work for the service, which had capacity to spare.

That is the case retries are for: **failures that are independent of each other, on a service with room
to answer**. Each retry is a fresh draw, and the second draw usually wins. The next section breaks both
conditions at once.

Put the service back to normal before going on:

```sh
curl -s -X POST localhost:8001/fail/0
```
