---
title: Retries and timeouts, and what they hide
version: 1
---

Envoy's second listener sits between `orders` and payments, on port 10001. An override points `orders`
at it:

```
ana@obs:~/shop$ cat compose.override.yaml
services:
  orders:
    environment:
      PAYMENTS_URL: http://envoy:10001
```

Its route has a two-second timeout and a retry policy: a 5xx from payments is tried again, up to twice.

```
ana@obs:~/shop$ sed -n '/cluster: payments$/,/num_retries/p' envoy/envoy.yaml
                            cluster: payments
                            timeout: 2s
                            retry_policy:
                              retry_on: 5xx
                              num_retries: 2
```

Then payments is told to fail one charge in ten, the fault lesson 16 paged on. Ninety seconds later,
the rates by service and status:

```
ana@obs:~/shop$ ./promq 'sum by (job, code) (rate(http_server_requests_total{job=~"storefront|payments",route=~"/checkout|/charge"}[1m]))'
code=200 job=payments  8.999999999999998
code=201 job=storefront  8.488888888888887
code=402 job=storefront  0.5111111111111111
code=503 job=payments  0.9999999999999999
code=503 job=storefront  0
```

Payments answers about nine charges a second with 200 and one with 503, so the fault is working. The storefront answers 201, and 402 for the cards the simulated customers get declined; its 503 series is zero. **No customer saw the failure.**

```
ana@obs:~/shop$ curl -s localhost:9901/stats | grep -E '^cluster\.payments\.upstream_rq_(total|retry|retry_success|5xx|503):'
cluster.payments.upstream_rq_retry: 90
cluster.payments.upstream_rq_retry_success: 90
cluster.payments.upstream_rq_total: 905
```

Envoy retried 90 of the 905 requests it sent to payments, and all 90 retries succeeded: payments fails every tenth charge, and the retry arrives as the next one. One retried charge, from the access log:

```
ana@obs:~/shop$ docker logs shop-envoy-1 2>&1 | grep '"listener":"payments"' | grep -m1 '"attempts":2' | jq -c .
{"attempts":2,"code":200,"flags":"-","listener":"payments","method":"POST","ms":25,"path":"/charge"}
```

**The mesh made a failure invisible to customers, and that is both its use and its danger.** Three
consequences follow:

- **The two sides now disagree.** Payments' own metrics say one charge in ten fails; the storefront's
  say none do. Both are right, and an alert on payments' error ratio would page somebody for a problem
  no customer has. Lesson 16's rule is the answer again: page on the symptom at the edge, keep causes
  as tickets.
- **Retries cost capacity.** Every failed charge became two requests to payments. A service failing
  because it is overloaded receives more load from every retrying caller, which is how a small problem
  becomes an outage. Envoy has retry budgets and circuit breakers for that reason.
- **A retry is only safe if the request is.** Charging a card twice is the classic case. Payments here
  fails before it charges anything, so a retry is harmless; a real payment API needs an idempotency key
  so that a repeated request is recognised as the same one.

Then the timeout. Payments is told to take 2.5 seconds per charge, longer than the route allows:

```
ana@obs:~/shop$ docker logs shop-envoy-1 2>&1 | grep '"listener":"payments"' | tail -1 | jq -c .
{"attempts":1,"code":504,"flags":"UT","listener":"payments","method":"POST","ms":1999,"path":"/charge"}
```

Envoy gave up at 1999 milliseconds and answered 504 itself; the flag `UT` means upstream request timeout. It did not retry, because the route's timeout covers every attempt together and it had run out.

```
ana@obs:~/shop$ curl -s -X POST localhost:8080/checkout -H 'Content-Type: application/json' -d '{"sku": "kettle", "qty": 1, "card": "4111 1111 1111 1111"}' -w ' %{http_code}\n'
{"error":"try again later"}
 502
```

The customer sees the same `try again later` as in lesson 14. The proxy turned a slow dependency into a
fast failure, which is usually the right trade: a two-second answer is better than a ten-second one, and
a waiting request holds a thread that the next customer needs.
