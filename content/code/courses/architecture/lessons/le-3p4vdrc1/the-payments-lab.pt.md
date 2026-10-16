---
title: O laboratório de pagamentos
version: 1
---

O laboratório da aula é o pagamento da Quitanda, reduzido ao que importa para a entrega: uma fila de
pedidos de pagamento, e um consumidor que cobra cada um. "Cobrar" é uma linha gravada no banco SQLite do
próprio consumidor, que faz o papel da operadora de cartão, então uma cobrança feita duas vezes é algo
que dá para contar. Ele mora em `~/lab/delivery`:

```sh
mkdir -p ~/lab/delivery && cd ~/lab/delivery
```

`topology.py`, a disposição do broker, que todo script declara antes de usar:

```schooling-example
{"language": "python", "file": "topology.py", "parts": [{"code": "\"\"\"The exchanges and queues the lesson's scripts share.\"\"\"\nimport os\nimport pika\n\n\ndef connect():\n    conn = pika.BlockingConnection(pika.URLParameters(os.environ[\"RABBIT_URL\"]))\n    ch = conn.channel()\n    ch.exchange_declare(\"payments\", exchange_type=\"direct\", durable=True)", "note": "A disposição do broker, declarada por todo script antes de fazer qualquer coisa, então não importa qual roda primeiro. Pedidos de pagamento vão para a exchange direct `payments` com a chave `charge`, e esperam na fila `charges`."}, {"code": "    ch.exchange_declare(\"payments.dead\", exchange_type=\"fanout\", durable=True)\n    ch.queue_declare(\"charges.dead\", durable=True)\n    ch.queue_bind(\"charges.dead\", \"payments.dead\")\n    ch.queue_declare(\"charges\", durable=True, arguments={\"x-dead-letter-exchange\": \"payments.dead\"})\n    ch.queue_bind(\"charges\", \"payments\", routing_key=\"charge\")\n    return conn, ch", "note": "Uma mensagem que o consumidor rejeita vai para a exchange nomeada em `x-dead-letter-exchange`, e de lá para a fila `charges.dead`, onde espera uma pessoa em vez de voltar para sempre."}]}
```

`publish.py`, que pede um pagamento:

```schooling-example
{"language": "python", "file": "publish.py", "parts": [{"code": "\"\"\"Publish a payment request.\"\"\"\nimport json, sys\nimport pika\nfrom topology import connect\n\nmsg_id, cents = sys.argv[1], int(sys.argv[2])\nbody = \"{not json\" if \"--broken\" in sys.argv else json.dumps({\"order\": msg_id, \"cents\": cents})\nconn, ch = connect()", "note": "`python publish.py ID CENTS` pede um pagamento. A mensagem carrega o seu próprio id, ID, que é o que deixa um consumidor reconhecer uma mensagem que já viu. `--broken` manda um corpo que nem é JSON."}, {"code": "ch.confirm_delivery()\nkey = sys.argv[3] if len(sys.argv) > 3 and not sys.argv[3].startswith(\"--\") else \"charge\"\ntry:\n    ch.basic_publish(\"payments\", key, body, pika.BasicProperties(message_id=msg_id, delivery_mode=2),\n                     mandatory=True)\n    print(f\"confirmed by the broker: {msg_id}\")\nexcept pika.exceptions.UnroutableError:\n    print(f\"returned by the broker, no queue for key {key!r}: {msg_id}\")\nconn.close()", "note": "Confirmações do publicador: o broker responde a cada publicação quando assume a responsabilidade pela mensagem, e `mandatory=True` torna uma mensagem que não chega a nenhuma fila um erro em vez de um silêncio."}]}
```

`pay.py`, o consumidor que cobra:

```schooling-example
{"language": "python", "file": "pay.py", "parts": [{"code": "\"\"\"Charge payment requests from the queue `charges`.\"\"\"\nimport json, os, sqlite3, sys\nfrom topology import connect\n\nNAIVE = \"--naive\" in sys.argv\nCRASH = \"--crash-after-charge\" in sys.argv\ndb = sqlite3.connect(\"/data/payments.db\")\ndb.execute(\"CREATE TABLE IF NOT EXISTS charges (order_id TEXT, cents INTEGER)\")\ndb.execute(\"CREATE TABLE IF NOT EXISTS processed (message_id TEXT PRIMARY KEY)\")\n\nif \"--list\" in sys.argv:\n    for row in db.execute(\"SELECT order_id, cents FROM charges ORDER BY rowid\"):\n        print(\"charged\", *row)\n    sys.exit()\n\nconn, ch = connect()\nch.basic_qos(prefetch_count=1)\nfor method, props, body in ch.consume(\"charges\", inactivity_timeout=2):\n    if method is None:\n        break", "note": "O consumidor de pagamentos. Ele cobra cada pedido gravando uma linha no seu próprio banco SQLite, que faz o papel da operadora de cartão, e confirma a mensagem depois da cobrança."}, {"code": "    try:\n        req = json.loads(body)\n    except ValueError:\n        print(f\"rejected {props.message_id}: not JSON, sent to the dead-letter queue\")\n        ch.basic_reject(method.delivery_tag, requeue=False)\n        continue", "note": "Um corpo que não dá para interpretar nunca vai dar certo, por mais vezes que seja tentado, então é rejeitado sem voltar para a fila, e a configuração de mensagens mortas da fila o tira do caminho."}, {"code": "    try:\n        with db:\n            if not NAIVE:\n                db.execute(\"INSERT INTO processed VALUES (?)\", (props.message_id,))\n            db.execute(\"INSERT INTO charges VALUES (?, ?)\", (req[\"order\"], req[\"cents\"]))\n        print(f\"charged {req['order']}: {req['cents']} cents (redelivered: {method.redelivered})\")\n    except sqlite3.IntegrityError:\n        print(f\"skipped {props.message_id}: already charged (redelivered: {method.redelivered})\")", "note": "O caminho idempotente grava o id da mensagem e a cobrança numa ÚNICA transação. Uma segunda entrega da mesma mensagem falha na chave primária, e a cobrança é pulada. `--naive` deixa o registro de fora."}, {"code": "    if CRASH:\n        print(\"crashing before the acknowledgement\")\n        os._exit(1)\n    ch.basic_ack(method.delivery_tag)\nconn.close()", "note": "`--crash-after-charge` para o processo depois de a cobrança ser confirmada e antes da confirmação da mensagem, que é o momento que transforma pelo menos uma vez em duas."}]}
```

`outbox.py`, o lado da loja, que uma seção posterior usa:

```schooling-example
{"language": "python", "file": "outbox.py", "parts": [{"code": "\"\"\"The transactional outbox: the order and its message, committed together.\"\"\"\nimport json, sqlite3, sys\nimport pika\nfrom topology import connect\n\ndb = sqlite3.connect(\"/data/shop.db\")\ndb.execute(\"CREATE TABLE IF NOT EXISTS orders (id TEXT PRIMARY KEY, cents INTEGER)\")\ndb.execute(\"CREATE TABLE IF NOT EXISTS outbox (message_id TEXT PRIMARY KEY, body TEXT, sent INTEGER DEFAULT 0)\")\n\nif sys.argv[1] == \"order\":\n    order_id, cents = sys.argv[2], int(sys.argv[3])\n    with db:\n        db.execute(\"INSERT INTO orders VALUES (?, ?)\", (order_id, cents))\n        db.execute(\"INSERT INTO outbox (message_id, body) VALUES (?, ?)\",\n                   (order_id, json.dumps({\"order\": order_id, \"cents\": cents})))\n    print(f\"order {order_id} saved, its message waits in the outbox\")\n", "note": "O lado da loja num pagamento. `order` grava o pedido e a mensagem que o anuncia na mesma transação, na tabela `outbox`; nada é mandado ao broker ainda. `relay` manda o que está esperando ali e marca cada linha só depois de o broker confirmá-la."}, {"code": "elif sys.argv[1] == \"relay\":\n    pending = db.execute(\"SELECT message_id, body FROM outbox WHERE sent = 0\").fetchall()\n    try:\n        conn, ch = connect()\n    except (pika.exceptions.AMQPConnectionError, OSError):\n        sys.exit(f\"broker unreachable; {len(pending)} message(s) wait in the outbox\")\n    ch.confirm_delivery()\n    for message_id, body in pending:\n        ch.basic_publish(\"payments\", \"charge\", body,\n                         pika.BasicProperties(message_id=message_id, delivery_mode=2), mandatory=True)\n        with db:\n            db.execute(\"UPDATE outbox SET sent = 1 WHERE message_id = ?\", (message_id,))\n        print(f\"relayed {message_id}\")\n    conn.close()", "note": "O relay. Se o broker não pode ser alcançado, nada se perde: as linhas ficam no outbox e a próxima execução as manda. Se ele cair entre a confirmação e a atualização, a próxima execução manda essa mensagem de novo, e é por isso que o consumidor precisa ser idempotente."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nRUN pip install --no-cache-dir pika==1.4.4\nWORKDIR /app\nCOPY *.py .", "note": "A mesma imagem pequena da aula 6: Python e pika."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  rabbitmq:\n    image: rabbitmq:4.1-management\n    hostname: rabbit\n  tools:\n    build: .\n    profiles: [\"tools\"]\n    environment:\n      RABBIT_URL: amqp://guest:guest@rabbitmq:5672/\n      PYTHONUNBUFFERED: \"1\"\n    volumes:\n      - data:/data\n    depends_on:\n      - rabbitmq\nvolumes:\n  data:", "note": "Um broker, e a imagem dos scripts com um volume em /data, onde o consumidor de pagamentos e a loja guardam os seus arquivos SQLite entre execuções. `PYTHONUNBUFFERED` faz o Python escrever cada linha na hora, para um processo que cai deixar as últimas linhas na tela."}]}
```

Inicie o broker, dê a ele alguns segundos, e economize digitação com uma variável de shell para o
comando que roda um script na imagem `tools`:

```sh
docker compose up -d
R="docker compose --progress quiet run --rm tools python"
```

`$R pay.py --list` passa então a rodar `pay.py --list` num contêiner novo que divide o volume `/data` com
todas as outras execuções. Digite a variável de novo se abrir um shell novo.
