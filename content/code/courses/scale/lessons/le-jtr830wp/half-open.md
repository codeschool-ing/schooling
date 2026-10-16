---
title: Half-open, and closing again
version: 1
---

An open breaker has to find out, sooner or later, whether the dependency is back. It cannot do that
without calling it, and calling it with every request would undo the point of opening. So after its
cooldown the breaker goes **half-open**: it lets **one** call through as a test, and refuses the rest
until that call returns. If the test works, the breaker closes; if not, it opens again for another
cooldown.

Ten seconds after it opened, with payments still slow, and then with payments back to normal:

```
ana@lab:~/tickets$ sleep 10
ana@lab:~/tickets$ curl -s -w ' %{http_code} in %{time_total} s\n' -X POST -H 'X-Buyer: fan-10' localhost:8080/events/1/tickets
{"error": "payment failed"} 502 in 1.006760 s
ana@lab:~/tickets$ curl -s -w ' %{http_code} in %{time_total} s\n' -X POST -H 'X-Buyer: fan-11' localhost:8080/events/1/tickets
{"error": "payments unavailable"} 503 in 0.002606 s
ana@lab:~/tickets$ docker compose up -d payments
 Container tickets-payments-1 Recreate 
 Container tickets-payments-1 Recreated 
 Container tickets-payments-1 Starting 
 Container tickets-payments-1 Started 
ana@lab:~/tickets$ sleep 10
ana@lab:~/tickets$ curl -s -w ' %{http_code} in %{time_total} s\n' -X POST -H 'X-Buyer: fan-12' localhost:8080/events/1/tickets
{"event": 1, "seat": 56, "code": "395c51a230ea1282"} 201 in 0.053180 s
ana@lab:~/tickets$ curl -s -w ' %{http_code} in %{time_total} s\n' -X POST -H 'X-Buyer: fan-13' localhost:8080/events/1/tickets
{"event": 1, "seat": 57, "code": "2abf4d857699c3df"} 201 in 0.039834 s
ana@lab:~/tickets$ curl -s localhost:8080/metrics | grep ^tickets_breaker
tickets_breaker_open 0.0
```

Read it in pairs:

- **The first sale after the cooldown was the test, and it failed** after a second, because payments
  was still slow. The breaker opened again at once, so **the next sale was refused in 2.6 ms**
  without a second test.
- Payments recreated with its normal delay, ten more seconds, and **the next sale was the test
  again, and it succeeded**: a ticket, in 53 ms. The breaker closed, the sale after it went through
  normally in 40 ms, and the gauge went back to 0.

Nobody had to notice that payments was back. That is the second half of what a breaker is for: it
recovers on its own, at the pace of one test per cooldown, rather than all at once.

## Tuning it

- **Five in a row** is the simplest rule and the easiest to read. Busy services usually use a
  **failure rate over a window** instead, say more than 50% of at least 20 calls in the last ten
  seconds, so one unlucky call among thousands does not count for much and a steady 30% failure rate
  is still noticed.
- **The cooldown** trades recovery time against load on a sick service. Ten seconds here; some
  libraries double it after each failed test, up to a maximum.
- **One breaker per dependency, per copy.** The box office keeps its breaker in memory, so each of
  three copies opens on its own after five failures of its own. Unlike the rate limit, that is
  fine: each copy is protecting itself, and needs no agreement with the others.
