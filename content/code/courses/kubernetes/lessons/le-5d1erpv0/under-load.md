---
title: Measuring under load, and choosing the numbers
version: 1
---

The `probe` pod now sends the shop a steady stream of requests, one after another, each asking for
200 milliseconds of work. After a minute and a quarter of it:

```
ana@laptop:~/shop$ kubectl top pods -l app=shop
NAME                   CPU(cores)   MEMORY(bytes)   
shop-c8d475877-qb528   227m         2Mi             
shop-c8d475877-t5vqk   355m         7Mi             
shop-c8d475877-zd49p   404m         1Mi             
ana@laptop:~/shop$ kubectl top pods -l app=shop --containers --sort-by=cpu | head -n 2
POD                    NAME   CPU(cores)   MEMORY(bytes)   
shop-c8d475877-zd49p   shop   404m         1Mi             
```

**Between 227m and 404m per copy, about one CPU in total**, which is what one client sending one
request at a time can keep busy. The memory barely moved. `--sort-by=cpu` puts the busiest first,
which is how to find the one pod in two hundred that matters.

Against those figures, the two requests were wrong in opposite amounts:

| | requested | used under load | verdict |
|---|---|---|---|
| CPU | 500m | 227m to 404m | about right, with some headroom |
| memory | 256 MiB | 1 to 7 MiB | thirty times too much |

A request should cover what the pod uses under its normal heavy load, with a margin; a memory limit
should sit above the highest value ever seen, because reaching it kills. For the shop that suggests
something like 400m of CPU and 32 MiB of memory. These are numbers for this laptop and this test, not
for the shop in production.

## What `kubectl top` cannot tell you

**It is one sample, a few seconds old.** metrics-server keeps no history, so a peak at three in the
morning is gone by the time anyone looks. Choosing requests needs the highest values over days, which
means a monitoring system that stores them; lesson 41 is about those. The Vertical Pod Autoscaler in
lesson 34 automates exactly this calculation and can apply it.

Underneath, `kubectl top` is an ordinary API read:

```
ana@laptop:~/shop$ kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes/shop-worker | head -c 300; echo
{"kind":"NodeMetrics","apiVersion":"metrics.k8s.io/v1beta1","metadata":{"name":"shop-worker","creationTimestamp":"2026-10-06T17:53:52Z","labels":{"beta.kubernetes.io/arch":"amd64","beta.kubernetes.io/os":"linux","kubernetes.io/arch":"amd64","kubernetes.io/hostname":"shop-worker","kubernetes.io/os":"
```

The first 300 characters are the node's identity and labels; the usage figures come later in the same
object. Anything that can read the API, an autoscaler included, reads the same numbers this way.
