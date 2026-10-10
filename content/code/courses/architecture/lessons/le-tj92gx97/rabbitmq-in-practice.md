---
title: RabbitMQ in practice
version: 1
---

The scripts run in the `tools` image, started with `docker compose run --rm`, which builds the image
the first time. `--progress quiet` keeps Compose's own messages about creating the container out of the
way, so only the script's output shows.

## Publishing to nobody

Publish two orders before any service has declared a queue, then ask RabbitMQ what queues it has:

```
ana@vm:~/lab/brokers$ docker compose --progress quiet run --rm tools python publish.py 2
published {"type": "OrderPlaced", "order": 1, "sku": "coffee", "qty": 1}
published {"type": "OrderPlaced", "order": 2, "sku": "coffee", "qty": 2}
ana@vm:~/lab/brokers$ docker compose exec rabbitmq rabbitmqctl list_queues name messages --quiet
```

`publish.py` printed both messages as published, and nothing raised an error, **and the broker holds
neither of them**: the list of queues is empty. The exchange `orders` existed, no queue was bound to it, so both messages matched no
binding and were dropped. That is the case the previous section warned about, and it happens for real
whenever a publisher starts before its consumers have ever run.

## Queues declared, messages kept

Running each consumer once declares its queue and binds it. With nothing to read yet, each waits two
seconds and stops:

```
ana@vm:~/lab/brokers$ docker compose --progress quiet run --rm tools python consume.py email
ana@vm:~/lab/brokers$ docker compose --progress quiet run --rm tools python consume.py warehouse
```

Publish four orders now, numbered from 3 so that every order in the lesson has its own number, and
look again:

```
ana@vm:~/lab/brokers$ docker compose --progress quiet run --rm tools python publish.py 4 3
published {"type": "OrderPlaced", "order": 3, "sku": "coffee", "qty": 3}
published {"type": "OrderPlaced", "order": 4, "sku": "coffee", "qty": 4}
published {"type": "OrderPlaced", "order": 5, "sku": "coffee", "qty": 5}
published {"type": "OrderPlaced", "order": 6, "sku": "coffee", "qty": 6}
ana@vm:~/lab/brokers$ docker compose exec rabbitmq rabbitmqctl list_queues name messages --quiet
name	messages
warehouse	4
email	4
```

**Each queue has its own copy of all four**: one message published, two bindings matched, two copies
stored. The e-mail service can read its four at once and the warehouse's can stay there, untouched,
until the warehouse is ready. Read the e-mail queue:

```
ana@vm:~/lab/brokers$ docker compose --progress quiet run --rm tools python consume.py email
email on c34db0ff8c7f: order 3
email on c34db0ff8c7f: order 4
email on c34db0ff8c7f: order 5
email on c34db0ff8c7f: order 6
```

## Competing consumers

The warehouse has more work per order, so it runs two consumers on the same queue. Publish six more
orders, 7 to 12, so that the warehouse queue holds ten, and start two consumers at the same time, each in its own
container:

```
ana@vm:~/lab/brokers$ docker compose --progress quiet run --rm tools python publish.py 6 7 > /dev/null
ana@vm:~/lab/brokers$ docker compose exec rabbitmq rabbitmqctl list_queues name messages --quiet
name	messages
warehouse	10
email	6
ana@vm:~/lab/brokers$ for i in 1 2; do docker compose --progress quiet run --rm tools python consume.py warehouse & done; wait
warehouse on f1397d7a1ff4: order 3
warehouse on 0bc3105ee4db: order 4
warehouse on f1397d7a1ff4: order 5
warehouse on 0bc3105ee4db: order 6
warehouse on f1397d7a1ff4: order 7
warehouse on 0bc3105ee4db: order 8
warehouse on 0bc3105ee4db: order 10
warehouse on f1397d7a1ff4: order 9
warehouse on 0bc3105ee4db: order 12
warehouse on f1397d7a1ff4: order 11
```

The two containers, with different hostnames, **shared the ten messages between them**, each handling
some and neither handling any twice. That is how a queue scales its consumers: add more on the same
queue, and the broker spreads the messages among them. `prefetch_count=1` matters here: without it,
RabbitMQ may push a large batch to whichever consumer connected first, and the second sits idle while
the first works through a backlog it does not have to hold. The order of the lines is the order the two
finished, which already shows that **competing consumers do not keep the order of the queue**; lesson 7
comes back to that.

Afterwards the warehouse queue is empty, and the e-mail queue holds orders 7 to 12, waiting for an
e-mail consumer that is not running:

```
ana@vm:~/lab/brokers$ docker compose exec rabbitmq rabbitmqctl list_queues name messages --quiet
name	messages
warehouse	0
email	6
```
