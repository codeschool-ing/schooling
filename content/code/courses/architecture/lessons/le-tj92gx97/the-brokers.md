---
title: Two brokers in your lab
version: 1
---

**This is one of the three heavy lessons lesson 1 warned about**: a RabbitMQ and a Kafka run at the
same time, and Kafka runs on the Java virtual machine. Stop anything left over from earlier lessons
before starting; `docker ps` should list nothing.

The lesson works in `~/lab/brokers`:

```sh
mkdir -p ~/lab/brokers && cd ~/lab/brokers
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  rabbitmq:\n    image: rabbitmq:4.1-management\n    hostname: rabbit\n    ports:\n      - \"127.0.0.1:15672:15672\"", "note": "Two brokers and a small image with a Python client. RabbitMQ's management interface is published on the machine's loopback, port 15672, for a look in the browser; Kafka is used only from inside its own container, with the command-line tools it ships with."}, {"code": "  kafka:\n    image: apache/kafka:4.0.0\n    hostname: kafka\n    environment:\n      KAFKA_HEAP_OPTS: \"-Xms512m -Xmx512m\"\n  tools:\n    build: .\n    profiles: [\"tools\"]\n    environment:\n      RABBIT_URL: amqp://guest:guest@rabbitmq:5672/\n    depends_on:\n      - rabbitmq", "note": "Kafka in KRaft mode, one node that is both broker and controller, which is what the image starts by default. The heap is held to 512 MB so the lab fits in 8 GB."}]}
```

`Dockerfile`, for the small image the Python scripts run in:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nRUN pip install --no-cache-dir pika==1.4.4\nWORKDIR /app\nCOPY *.py .", "note": "The scripts' image: Python and pika, RabbitMQ's Python client, at a fixed version."}]}
```

`publish.py`, which publishes order events to RabbitMQ:

```schooling-example
{"language": "python", "file": "publish.py", "parts": [{"code": "\"\"\"Publish OrderPlaced events to RabbitMQ.\"\"\"\nimport json, os, sys\nimport pika\n\nconn = pika.BlockingConnection(pika.URLParameters(os.environ[\"RABBIT_URL\"]))\nch = conn.channel()\nch.exchange_declare(\"orders\", exchange_type=\"topic\", durable=True)\n\nfirst = int(sys.argv[2]) if len(sys.argv) > 2 else 1\nfor n in range(first, first + int(sys.argv[1])):\n    event = {\"type\": \"OrderPlaced\", \"order\": n, \"sku\": \"coffee\", \"qty\": n}\n    ch.basic_publish(\"orders\", \"order.placed\", json.dumps(event),\n                     pika.BasicProperties(delivery_mode=2, content_type=\"application/json\"))\n    print(\"published\", json.dumps(event))\nconn.close()", "note": "`python publish.py N FIRST` publishes N `OrderPlaced` events, numbered from FIRST (1 when it is left out), to the `orders` exchange with the routing key `order.placed`. The exchange is a topic exchange and durable; each message is marked persistent, so a broker restart does not lose what is waiting in a durable queue."}]}
```

`consume.py`, which reads them from one queue:

```schooling-example
{"language": "python", "file": "consume.py", "parts": [{"code": "\"\"\"Consume OrderPlaced events from one RabbitMQ queue.\"\"\"\nimport json, os, socket, sys, time\nimport pika\n\nqueue = sys.argv[1]\nconn = pika.BlockingConnection(pika.URLParameters(os.environ[\"RABBIT_URL\"]))\nch = conn.channel()\nch.exchange_declare(\"orders\", exchange_type=\"topic\", durable=True)\nch.queue_declare(queue, durable=True)\nch.queue_bind(queue, \"orders\", routing_key=\"order.*\")\n", "note": "Consumes from one queue. It declares the queue durable and binds it to `orders` for every routing key that starts with `order.`, so running it once is also how a queue comes to exist."}, {"code": "ch.basic_qos(prefetch_count=1)\nfor method, props, body in ch.consume(queue, inactivity_timeout=2):\n    if method is None:\n        break\n    event = json.loads(body)\n    time.sleep(0.5)  # the work of handling it\n    print(f\"{queue} on {socket.gethostname()}: order {event['order']}\", flush=True)\n    ch.basic_ack(method.delivery_tag)\nconn.close()", "note": "`prefetch_count=1`: the broker sends this consumer one message at a time and the next only after the acknowledgement. Handling a message takes half a second here, and it is acknowledged only after that; the loop ends after two seconds with nothing to do."}]}
```

The section on RabbitMQ in practice, two sections on, runs both. The `tools` service is in a
**profile**, so `docker compose up` leaves it alone and `docker compose run tools …` builds and runs it
when a script is needed. Start the two brokers:

```sh
docker compose up -d
```

The first run downloads both brokers' images, several hundred megabytes. Once they are up, Docker can
say how much memory each takes doing nothing:

```
ana@vm:~/lab/brokers$ docker compose ps --format "{{.Service}} {{.Image}} {{.Status}}"
kafka apache/kafka:4.0.0 Up 20 seconds
rabbitmq rabbitmq:4.1-management Up 20 seconds
ana@vm:~/lab/brokers$ docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}"
NAME                 MEM USAGE / LIMIT
brokers-rabbitmq-1   92.39MiB / 15.72GiB
brokers-kafka-1      267.5MiB / 15.72GiB
```

RabbitMQ, written in Erlang, sits at around a hundred megabytes; Kafka, on the JVM with its heap held
to 512 MB by `KAFKA_HEAP_OPTS`, already uses a few hundred before it has received a single message.
**That baseline is per broker node**, and a production cluster runs three of each at least, for the
reasons lesson 10 gives.

## Looking at RabbitMQ in a browser

The management interface is published on the VM's loopback, port 15672. To open it from your own
computer's browser, the port has to reach your computer: with Multipass, `multipass info arch` gives
the VM's address, and an SSH tunnel such as `ssh -L 15672:127.0.0.1:15672 ubuntu@<address>` brings it
to `http://localhost:15672`, user and password `guest`. The lesson does not need it; everything it
shows comes from the command line, which is also what a script or a pipeline would use.
