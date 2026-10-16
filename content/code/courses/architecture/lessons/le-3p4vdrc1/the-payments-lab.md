---
title: The payments lab
version: 1
---

The lesson's lab is Quitanda's payments, reduced to what delivery is about: a queue of payment
requests, and a consumer that charges each one. "Charging" is a row written to the consumer's own
SQLite database, which stands in for the card processor, so a charge made twice is something you can
count. It lives in `~/lab/delivery`:

```sh
mkdir -p ~/lab/delivery && cd ~/lab/delivery
```

`topology.py`, the layout of the broker, which every script declares before using it:

```schooling-example
{"language": "python", "file": "topology.py", "parts": [{"code": "\"\"\"The exchanges and queues the lesson's scripts share.\"\"\"\nimport os\nimport pika\n\n\ndef connect():\n    conn = pika.BlockingConnection(pika.URLParameters(os.environ[\"RABBIT_URL\"]))\n    ch = conn.channel()\n    ch.exchange_declare(\"payments\", exchange_type=\"direct\", durable=True)", "note": "The broker's layout, declared by every script before it does anything, so it does not matter which runs first. Payment requests go to the direct exchange `payments` with the key `charge`, and wait in the queue `charges`."}, {"code": "    ch.exchange_declare(\"payments.dead\", exchange_type=\"fanout\", durable=True)\n    ch.queue_declare(\"charges.dead\", durable=True)\n    ch.queue_bind(\"charges.dead\", \"payments.dead\")\n    ch.queue_declare(\"charges\", durable=True, arguments={\"x-dead-letter-exchange\": \"payments.dead\"})\n    ch.queue_bind(\"charges\", \"payments\", routing_key=\"charge\")\n    return conn, ch", "note": "A message the consumer rejects goes to the exchange named in `x-dead-letter-exchange`, and from there to the queue `charges.dead`, where it waits for a person instead of coming back for ever."}]}
```

`publish.py`, which asks for a payment:

```schooling-example
{"language": "python", "file": "publish.py", "parts": [{"code": "\"\"\"Publish a payment request.\"\"\"\nimport json, sys\nimport pika\nfrom topology import connect\n\nmsg_id, cents = sys.argv[1], int(sys.argv[2])\nbody = \"{not json\" if \"--broken\" in sys.argv else json.dumps({\"order\": msg_id, \"cents\": cents})\nconn, ch = connect()", "note": "`python publish.py ID CENTS` asks for a payment. The message carries its own id, ID, which is what lets a consumer recognise a message it has seen before. `--broken` sends a body that is not JSON at all."}, {"code": "ch.confirm_delivery()\nkey = sys.argv[3] if len(sys.argv) > 3 and not sys.argv[3].startswith(\"--\") else \"charge\"\ntry:\n    ch.basic_publish(\"payments\", key, body, pika.BasicProperties(message_id=msg_id, delivery_mode=2),\n                     mandatory=True)\n    print(f\"confirmed by the broker: {msg_id}\")\nexcept pika.exceptions.UnroutableError:\n    print(f\"returned by the broker, no queue for key {key!r}: {msg_id}\")\nconn.close()", "note": "Publisher confirms: the broker answers each publish once it has taken responsibility for the message, and `mandatory=True` makes a message that reaches no queue an error instead of a silence."}]}
```

`pay.py`, the consumer that charges:

```schooling-example
{"language": "python", "file": "pay.py", "parts": [{"code": "\"\"\"Charge payment requests from the queue `charges`.\"\"\"\nimport json, os, sqlite3, sys\nfrom topology import connect\n\nNAIVE = \"--naive\" in sys.argv\nCRASH = \"--crash-after-charge\" in sys.argv\ndb = sqlite3.connect(\"/data/payments.db\")\ndb.execute(\"CREATE TABLE IF NOT EXISTS charges (order_id TEXT, cents INTEGER)\")\ndb.execute(\"CREATE TABLE IF NOT EXISTS processed (message_id TEXT PRIMARY KEY)\")\n\nif \"--list\" in sys.argv:\n    for row in db.execute(\"SELECT order_id, cents FROM charges ORDER BY rowid\"):\n        print(\"charged\", *row)\n    sys.exit()\n\nconn, ch = connect()\nch.basic_qos(prefetch_count=1)\nfor method, props, body in ch.consume(\"charges\", inactivity_timeout=2):\n    if method is None:\n        break", "note": "The payments consumer. It charges each request by writing a row to its own SQLite database, which stands in for the card processor, and acknowledges the message after the charge."}, {"code": "    try:\n        req = json.loads(body)\n    except ValueError:\n        print(f\"rejected {props.message_id}: not JSON, sent to the dead-letter queue\")\n        ch.basic_reject(method.delivery_tag, requeue=False)\n        continue", "note": "A body that cannot be parsed will never succeed, however often it is retried, so it is rejected without requeueing, and the queue's dead-letter setting moves it aside."}, {"code": "    try:\n        with db:\n            if not NAIVE:\n                db.execute(\"INSERT INTO processed VALUES (?)\", (props.message_id,))\n            db.execute(\"INSERT INTO charges VALUES (?, ?)\", (req[\"order\"], req[\"cents\"]))\n        print(f\"charged {req['order']}: {req['cents']} cents (redelivered: {method.redelivered})\")\n    except sqlite3.IntegrityError:\n        print(f\"skipped {props.message_id}: already charged (redelivered: {method.redelivered})\")", "note": "The idempotent path records the message id and the charge in ONE transaction. A second delivery of the same message fails on the primary key, and the charge is skipped. `--naive` leaves the record out."}, {"code": "    if CRASH:\n        print(\"crashing before the acknowledgement\")\n        os._exit(1)\n    ch.basic_ack(method.delivery_tag)\nconn.close()", "note": "`--crash-after-charge` stops the process after the charge is committed and before the acknowledgement, which is the moment that turns at-least-once into twice."}]}
```

`outbox.py`, the shop's side, which a later section uses:

```schooling-example
{"language": "python", "file": "outbox.py", "parts": [{"code": "\"\"\"The transactional outbox: the order and its message, committed together.\"\"\"\nimport json, sqlite3, sys\nimport pika\nfrom topology import connect\n\ndb = sqlite3.connect(\"/data/shop.db\")\ndb.execute(\"CREATE TABLE IF NOT EXISTS orders (id TEXT PRIMARY KEY, cents INTEGER)\")\ndb.execute(\"CREATE TABLE IF NOT EXISTS outbox (message_id TEXT PRIMARY KEY, body TEXT, sent INTEGER DEFAULT 0)\")\n\nif sys.argv[1] == \"order\":\n    order_id, cents = sys.argv[2], int(sys.argv[3])\n    with db:\n        db.execute(\"INSERT INTO orders VALUES (?, ?)\", (order_id, cents))\n        db.execute(\"INSERT INTO outbox (message_id, body) VALUES (?, ?)\",\n                   (order_id, json.dumps({\"order\": order_id, \"cents\": cents})))\n    print(f\"order {order_id} saved, its message waits in the outbox\")\n", "note": "The shop's side of a payment. `order` writes the order and the message announcing it in the same transaction, into the table `outbox`; nothing is sent to the broker yet. `relay` sends what is waiting there and marks each row only after the broker has confirmed it."}, {"code": "elif sys.argv[1] == \"relay\":\n    pending = db.execute(\"SELECT message_id, body FROM outbox WHERE sent = 0\").fetchall()\n    try:\n        conn, ch = connect()\n    except (pika.exceptions.AMQPConnectionError, OSError):\n        sys.exit(f\"broker unreachable; {len(pending)} message(s) wait in the outbox\")\n    ch.confirm_delivery()\n    for message_id, body in pending:\n        ch.basic_publish(\"payments\", \"charge\", body,\n                         pika.BasicProperties(message_id=message_id, delivery_mode=2), mandatory=True)\n        with db:\n            db.execute(\"UPDATE outbox SET sent = 1 WHERE message_id = ?\", (message_id,))\n        print(f\"relayed {message_id}\")\n    conn.close()", "note": "The relay. If the broker cannot be reached, nothing is lost: the rows stay in the outbox and the next run sends them. If it crashes between the confirm and the update, the next run sends that message again, which is why the consumer has to be idempotent."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nRUN pip install --no-cache-dir pika==1.4.4\nWORKDIR /app\nCOPY *.py .", "note": "The same small image as lesson 6: Python and pika."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  rabbitmq:\n    image: rabbitmq:4.1-management\n    hostname: rabbit\n  tools:\n    build: .\n    profiles: [\"tools\"]\n    environment:\n      RABBIT_URL: amqp://guest:guest@rabbitmq:5672/\n      PYTHONUNBUFFERED: \"1\"\n    volumes:\n      - data:/data\n    depends_on:\n      - rabbitmq\nvolumes:\n  data:", "note": "One broker, and the scripts' image with a volume at /data, where the payments consumer and the shop keep their SQLite files between runs. `PYTHONUNBUFFERED` makes Python write each line at once, so a process that crashes leaves its last lines on the screen."}]}
```

Start the broker, give it a few seconds, and save typing with a shell variable for the command that
runs a script in the `tools` image:

```sh
docker compose up -d
R="docker compose --progress quiet run --rm tools python"
```

`$R pay.py --list` then runs `pay.py --list` in a fresh container that shares the `/data` volume with
every other run. Type the variable again if you open a new shell.
