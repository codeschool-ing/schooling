---
title: Choosing, and combining with lesson 11
version: 1
---

Lessons 11 and 12 are one toolkit, and each tool answers a different question:

| the question | the tool | the lesson |
| --- | --- | --- |
| how long do I wait for an answer? | a timeout | 5 |
| is this failure worth another try? | a retry, with backoff, jitter and a budget | 11 |
| should I stop calling a service that is clearly down? | a circuit breaker | 11 |
| how much of my capacity may one dependency hold? | a bulkhead | 12 |
| how often may one client ask? | a rate limit, answered with `429` | 12 |
| what happens to work I cannot do yet? | a bounded queue, and back pressure | 12 |

For a call from Quitanda's checkout to the stock service, they nest. The **retry** is outermost and
decides whether to make another attempt. Each attempt then passes through the rest: the **breaker**
decides whether it is worth making, the **bulkhead** whether there is room for it, and the **timeout**
how long it may take. Resilience4j's default arrangement is that one, with the retry on the outside and
the bulkhead next to the call, so that a retry is subject to every limit the first attempt was.

The common thread of the whole lesson is that **every one of them says no**, early and cheaply, to some
of the work, so that the rest gets done. A system that accepts everything does not serve more people. It
serves everybody badly, and then nobody.

When you are done, stop the lab:

```sh
docker compose down
```
