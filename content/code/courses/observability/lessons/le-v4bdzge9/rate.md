---
title: rate(), and the counter that went back to zero
version: 1
---

`rate()` takes a counter over a window and answers **how much it grew per second**, on average,
across that window. The window goes in square brackets, and `[1m]` means the last minute of
scrapes:

```
ana@obs:~/shop$ ./promq 'rate(http_server_requests_total{job="storefront", route="/checkout"}[1m])'
code=201 instance=storefront:8080 job=storefront method=POST route=/checkout  4.222222222222221
code=402 instance=storefront:8080 job=storefront method=POST route=/checkout  0.2666666666666666
```

About 4.2 checkouts a second answered `201` and 0.27 answered `402`, a declined card. The simulated
customers send five requests a second, one in ten of them a product listing, so 4.5 checkouts a
second is the whole of it, and adding the two lines gives 4.49. To get that sum from Prometheus, the
series are **aggregated**: `sum by (route)` adds every series that shares a route and keeps only that
label:

```
ana@obs:~/shop$ ./promq 'sum by (route) (rate(http_server_requests_total{job="storefront"}[1m]))'
route=/health  0.06666666666666665
route=/products  0.5111111111111111
route=/checkout  4.488888888888888
```

`increase()` is the same calculation expressed as a count over the window instead of a rate per
second, which reads better on a dashboard that says *requests in the last minute*:

```
ana@obs:~/shop$ ./promq 'sum(increase(http_server_requests_total{job="storefront"}[1m]))'
  304
```

304, close to 60 seconds times the 5.07 requests a second the three routes add up to. **Both are
estimates**, worked out from the scrapes that fell inside the window and stretched to cover all of
it, which is why `increase()` can return a number that is not a whole count.

The reason to always go through `rate()` rather than subtracting two values yourself is what happens
when a process restarts. The storefront is restarted, and its counter is read before and after:

```
ana@obs:~/shop$ ./promq 'sum(http_server_requests_total{job="storefront"})'
  339
ana@obs:~/shop$ docker compose restart storefront 2>&1 | tail -1
 Container shop-storefront-1 Started 
ana@obs:~/shop$ ./promq 'sum(http_server_requests_total{job="storefront"})'
  123
```

**The counter went from 339 to 123.** A restarted process starts every counter from zero, and a
naive *value now minus value a minute ago* would say the storefront answered minus two hundred
requests. `rate()` and `increase()` know a counter can only grow, so any drop is treated as a reset
and the count simply continues from zero:

```
ana@obs:~/shop$ ./promq 'sum(rate(http_server_requests_total{job="storefront"}[2m]))'
  4.79047619047619
ana@obs:~/shop$ ./promq 'resets(http_server_requests_total{job="storefront", route="/checkout", code="201"}[5m])'
code=201 instance=storefront:8080 job=storefront method=POST route=/checkout  1
```

The rate across the restart is still about five a second, and `resets()` counts the restart it saw
in the window. That is the rule for counters: **never read a counter's raw value as information;
ask its rate.**
