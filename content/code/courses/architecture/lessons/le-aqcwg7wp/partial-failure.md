---
title: When half of the system is down
version: 1
---

A monolith is up or down. A system of services has a third state, and it is the normal one at
scale: **some services up, some down, some slow**. Lamport put it in one sentence in 1987: a
distributed system is one in which the failure of a computer you did not even know existed can
render your own computer unusable.

Stop the stock service and ask for the catalogue:

```
ana@vm:~/lab/split$ docker compose stop stock
 Container split-stock-1 Stopping 
 Container split-stock-1 Stopped 
ana@vm:~/lab/split$ curl -s -i -w "took %{time_total}s\n" localhost:8000/products
HTTP/1.0 503 Service Unavailable
Server: BaseHTTP/0.6 Python/3.12.15
Date: Sat, 10 Oct 2026 04:24:04 GMT
Content-Type: application/json
Content-Length: 31
X-Request-Id: 29547aa9

{"error": "stock unavailable"}
took 0.004912s
```

The shop is running and answers in a few milliseconds, with `503 Service Unavailable` and a body
that says why. That is a decent failure: fast, explicit, and the shop itself stays up. It is decent
because `stock_call` failed quickly. When the container is stopped, the name `stock` no longer
resolves, and the error is immediate. A stock service that was running but hung would have held
every catalogue request for the full two-second timeout, and without a timeout, for ever. Lesson 11
is about that case, and lesson 12 about stopping one slow dependency from tying up everything that
calls it.

Start it again before going on:

```
ana@vm:~/lab/split$ docker compose start stock
 Container split-stock-1 Starting 
 Container split-stock-1 Started 
```

## The order that is half done

The worse failure is the one that returns an answer. In the monolith, a declined card rolled back
the order and the stock together, in one transaction. Here the stock was taken by another program
and committed in another database before the card was tried. Watch the coffee:

```
ana@vm:~/lab/split$ curl -s localhost:8000/products | grep coffee
{"sku": "coffee", "name": "Coffee beans, 500 g", "price_cents": 3290, "units": 12},
ana@vm:~/lab/split$ curl -s -X POST localhost:8000/orders -d '{"sku": "coffee", "qty": 1, "card": "4000000000000002"}'
{"error": "card declined"}
ana@vm:~/lab/split$ curl -s localhost:8000/products | grep coffee
{"sku": "coffee", "name": "Coffee beans, 500 g", "price_cents": 3290, "units": 11},
```

The card was declined and the customer got a `402`. No order exists, no payment exists, and **one
bag of coffee has left the stock anyway**: the count went from 12 to 11. Nothing failed loudly. Every
service did exactly what it was told, and together they lost a unit.

This is not a bug in the split that a more careful line would fix. `with con:` can only roll back
the database it belongs to, and the stock is in another one. There are three ways out, and the rest
of the course takes each in turn:

| approach | where it is |
| --- | --- |
| undo the take with a second call, a **compensation**, when the payment fails | lesson 14, the saga |
| reserve the units first and confirm them only after payment, so a failure only releases a reservation | lesson 14 as well, as a semantic lock |
| put the stock and the payment back in one service, because they must agree at the same instant | the third question of the section on boundaries |

**The third is a legitimate answer.** If the business cannot tolerate this window at all, the
boundary is in the wrong place, and moving it back is cheaper than building the machinery to live
with it.
