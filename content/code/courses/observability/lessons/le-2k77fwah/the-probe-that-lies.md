---
title: The probe that lies
version: 1
---

Every service in the shop has had a `/health` since lesson 1, and every one of them is three lines
that return `{"status": "ok"}`. The blackbox exporter has been asking the storefront's every fifteen
seconds since lesson 5. Here is what it is worth. Postgres is stopped, with customers still
buying:

```
ana@obs:~/shop$ docker compose stop postgres 2>&1 | tail -1
 Container shop-postgres-1 Stopped 
ana@obs:~/shop$ curl -s -X POST localhost:8080/checkout -H 'Content-Type: application/json' -d '{"sku": "kettle", "qty": 1, "card": "4111 1111 1111 1111"}' -w ' %{http_code}\n'
{"error":"try again later"}
 502
```

The checkout fails: `orders` cannot store the order, and the storefront passes the failure on as a
502 with a polite body. And the health endpoint of the same storefront, a second later:

```
ana@obs:~/shop$ curl -s localhost:8080/health
{"status":"ok"}
```

Forty-five seconds on, the outside probe and the ratio from lesson 5:

```
ana@obs:~/shop$ ./promq 'probe_success'
__name__=probe_success instance=http://storefront:8080/health job=blackbox  1
ana@obs:~/shop$ ./promq 'sum(rate(http_server_requests_total{job="storefront",route="/checkout",code=~"5.."}[1m])) / sum(rate(http_server_requests_total{job="storefront",route="/checkout"}[1m]))'
  1
```

**The probe says the storefront is up, and every checkout of the last minute failed.** Both numbers
are correct. The probe answered the question it was asked, *does the storefront's process answer HTTP?*,
and the answer is yes. Nobody asked it whether a customer can buy a kettle.

That is the probe that lies, and it is the most common health check there is: a route that proves
the web framework is running. It is not useless, as the next sections show: it is exactly what a
liveness probe should be. **What it must never be is the thing that decides whether the shop is
working**, on a status page, in an alert, or in a load balancer's choice of where to send an order.
