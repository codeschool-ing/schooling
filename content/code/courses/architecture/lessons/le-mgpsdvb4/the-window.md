---
title: The window, and what makes it longer
version: 1
---

The time between the owner changing and a copy hearing about it is the **inconsistency window**. Watch
it from outside: set the coffee to 11, then read shop `b` every half second:

```
ana@vm:~/lab/eventual$ curl -s -X PUT localhost:8001/stock/coffee -d 11; for i in $(seq 6); do curl -s localhost:8003/product/coffee; sleep 0.5; done
coffee: 11 in stock, version 2
shop-b: coffee: 12 left, version 1
shop-b: coffee: 12 left, version 1
shop-b: coffee: 12 left, version 1
shop-b: coffee: 12 left, version 1
shop-b: coffee: 11 left, version 2
shop-b: coffee: 11 left, version 2
```

Shop `b` answered 12 for about two seconds after the stock service said 11, and then caught up. That is
its `LAG`, the time it spends on each event, and on an idle system the window is about that long.

## The window is not a setting

Now change the coffee ten times in a row, as a busy afternoon would, and look at the owner, both shops
and the broker's queues straight afterwards:

```
ana@vm:~/lab/eventual$ for n in $(seq 10 -1 1); do curl -s -X PUT localhost:8001/stock/coffee -d $n > /dev/null; done
ana@vm:~/lab/eventual$ curl -s localhost:8001/stock/coffee; curl -s localhost:8002/product/coffee; curl -s localhost:8003/product/coffee
coffee: 1 in stock, version 12
shop-a: coffee: 10 left, version 3
shop-b: coffee: 11 left, version 2
ana@vm:~/lab/eventual$ docker compose exec rabbitmq rabbitmqctl list_queues name messages
Timeout: 60.0 seconds ...
Listing queues for vhost / ...
name	messages
shop-a	3
shop-b	10
```

The owner is at version 12 and shop `b` is still at version 2, because the events are **waiting in its
queue**, and it handles them one at a time, two seconds each. The window for the last change is now
the whole queue: ten events times two seconds, twenty seconds in which shop `b` shows a number the
stock service has already replaced ten times. Shop `a` handles one in a fifth of a second and is
behind as well, just less. Wait, and both empty their queues:

```
ana@vm:~/lab/eventual$ sleep 25; docker compose exec rabbitmq rabbitmqctl list_queues name messages
Timeout: 60.0 seconds ...
Listing queues for vhost / ...
name	messages
shop-a	0
shop-b	0
ana@vm:~/lab/eventual$ curl -s localhost:8002/product/coffee; curl -s localhost:8003/product/coffee
shop-a: coffee: 1 left, version 12
shop-b: coffee: 1 left, version 12
```

**The window is the queue's length times the time per event**, so it grows exactly when the system is
busiest, which is when the most people are looking. And if the consumer stops, crashes or is deployed
badly, the window has no end: the queue keeps the events (it is durable) and the copy stays where it
was until somebody notices.

## Measure it, because nobody will notice it

A copy that is behind does not fail. Every request succeeds, every page draws, and the numbers are
plausible. So the window has to be measured, and there are two ways to see it:

- **The queue's depth**, which the broker already reports, as above. Most monitoring can alert on it,
  and a queue that only grows is a consumer that has stopped keeping up.
- **The age of what the copy holds**, which is the better number, because it is in time rather than in
  messages: if each event carries the moment it was created, the copy knows how old its newest one is.
  Kafka reports the same thing as **consumer lag**, the distance between the end of a partition and a
  consumer's position in it.

The question to ask of any copy is not "is it consistent?", which it is not, but **"how far behind is it
right now, and who would find out?"** Lesson 12 comes back to the queue that fills faster than it
drains, from the other side: what to do when it will not stop growing.
