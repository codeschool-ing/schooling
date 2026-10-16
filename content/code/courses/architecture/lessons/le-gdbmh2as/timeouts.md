---
title: Timeouts, and a chain that waits for ever
version: 1
---

A service that is down fails fast: the name does not resolve or the connection is refused, and the
error is back in milliseconds. **A service that is up and slow is worse**, because nothing fails at
all; every caller simply waits.

Make stock take five seconds per request. `STOCK_DELAY_MS` is read by `compose.yaml`, and
`docker compose up -d stock` recreates only that service with the new value:

```
ana@vm:~/lab/chain$ STOCK_DELAY_MS=5000 docker compose up -d stock
 Container chain-stock-1 Recreate 
 Container chain-stock-1 Recreated 
 Container chain-stock-1 Starting 
 Container chain-stock-1 Started 
ana@vm:~/lab/chain$ curl -s -w "%{http_code} after %{time_total} s\n" localhost:8000/
{"name": "checkout", "next": {"name": "pricing", "next": {"name": "stock", "took_ms": 5000}, "took_ms": 5104}, "took_ms": 5207}
200 after 5.208926 s
```

The checkout answered `200`, correctly, after more than five seconds. Pricing waited for stock, and the
checkout waited for pricing, and the client waited for all of them. `hop.py` sets no timeout unless
`TIMEOUT_S` is given, so **a stock service that never answered would have held every link of the chain
for ever**, each with an open connection and a thread.

## Giving pricing a limit

Set `PRICING_TIMEOUT_S` to one second and recreate pricing, with stock still slow:

```
ana@vm:~/lab/chain$ PRICING_TIMEOUT_S=1 STOCK_DELAY_MS=5000 docker compose up -d pricing
 Container chain-pricing-1 Recreate 
 Container chain-pricing-1 Recreated 
 Container chain-pricing-1 Starting 
 Container chain-pricing-1 Started 
ana@vm:~/lab/chain$ curl -s -w "%{http_code} after %{time_total} s\n" localhost:8000/
{"name": "checkout", "error": "http://pricing:8000/ answered 504", "next": {"name": "pricing", "error": "http://stock:8000/ did not answer within 1.0 s", "took_ms": 1128}, "took_ms": 1232}
502 after 1.233608 s
```

Now pricing gives up on stock after one second and says so with `504 Gateway Timeout`; the checkout
passes that up as a `502`, and the client has an answer after about a second and a quarter instead of
five. **The answer is a failure, and a fast one**, which is what the caller can work with: show an
error, try a fallback, or try again later.

## How long to wait

There is no universal number, but there is a method. A timeout should be a little above what the
slow end of normal looks like for that call, the time within which, say, 99 requests in 100 complete,
and well below what the caller's own caller will wait. **Timeouts have to shrink as you go down a
chain**: if the checkout gives up after two seconds and pricing waits five for stock, pricing goes on
working on requests nobody is waiting for any more.

That last point has a name. **Deadline propagation** passes the time left with the request, so each
link knows how long it may spend, and gRPC does it with a deadline that travels with every call. With
plain HTTP a service can send a header with the remaining budget, and each link subtracts what it used
before calling the next.

Put stock back to normal and pricing back to no timeout:

```
ana@vm:~/lab/chain$ docker compose up -d pricing stock
 Container chain-pricing-1 Recreate 
 Container chain-stock-1 Recreate 
 Container chain-pricing-1 Recreated 
 Container chain-stock-1 Recreated 
 Container chain-stock-1 Starting 
 Container chain-pricing-1 Starting 
 Container chain-stock-1 Started 
 Container chain-pricing-1 Started 
ana@vm:~/lab/chain$ curl -s -w "%{http_code} after %{time_total} s\n" localhost:8000/
{"name": "checkout", "next": {"name": "pricing", "next": {"name": "stock", "took_ms": 100}, "took_ms": 228}, "took_ms": 332}
200 after 0.334787 s
```

A timeout turns a slow failure into a fast one. What to do next, retry or stop asking, is lesson 11,
and it has its own way of making things worse.
