---
title: Dois brokers no seu laboratório
version: 1
---

**Esta é uma das três aulas pesadas sobre as quais a aula 1 avisou**: um RabbitMQ e um Kafka rodam ao
mesmo tempo, e o Kafka roda na máquina virtual Java. Pare o que tiver sobrado de aulas anteriores antes
de começar; `docker ps` não deve listar nada.

A aula trabalha em `~/lab/brokers`:

```sh
mkdir -p ~/lab/brokers && cd ~/lab/brokers
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  rabbitmq:\n    image: rabbitmq:4.1-management\n    hostname: rabbit\n    ports:\n      - \"127.0.0.1:15672:15672\"", "note": "Dois brokers e uma imagem pequena com um cliente Python. A interface de gerenciamento do RabbitMQ é publicada no loopback da máquina, porta 15672, para uma olhada no navegador; o Kafka é usado só de dentro do próprio contêiner, com as ferramentas de linha de comando que vêm com ele."}, {"code": "  kafka:\n    image: apache/kafka:4.0.0\n    hostname: kafka\n    environment:\n      KAFKA_HEAP_OPTS: \"-Xms512m -Xmx512m\"\n  tools:\n    build: .\n    profiles: [\"tools\"]\n    environment:\n      RABBIT_URL: amqp://guest:guest@rabbitmq:5672/\n    depends_on:\n      - rabbitmq", "note": "Kafka no modo KRaft, um nó que é broker e controlador ao mesmo tempo, que é o que a imagem inicia por padrão. O heap fica em 512 MB para o laboratório caber em 8 GB."}]}
```

`Dockerfile`, para a imagem pequena onde rodam os scripts Python:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nRUN pip install --no-cache-dir pika==1.4.4\nWORKDIR /app\nCOPY *.py .", "note": "A imagem dos scripts: Python e pika, o cliente Python do RabbitMQ, numa versão fixa."}]}
```

`publish.py`, que publica eventos de pedido no RabbitMQ:

```schooling-example
{"language": "python", "file": "publish.py", "parts": [{"code": "\"\"\"Publish OrderPlaced events to RabbitMQ.\"\"\"\nimport json, os, sys\nimport pika\n\nconn = pika.BlockingConnection(pika.URLParameters(os.environ[\"RABBIT_URL\"]))\nch = conn.channel()\nch.exchange_declare(\"orders\", exchange_type=\"topic\", durable=True)\n\nfirst = int(sys.argv[2]) if len(sys.argv) > 2 else 1\nfor n in range(first, first + int(sys.argv[1])):\n    event = {\"type\": \"OrderPlaced\", \"order\": n, \"sku\": \"coffee\", \"qty\": n}\n    ch.basic_publish(\"orders\", \"order.placed\", json.dumps(event),\n                     pika.BasicProperties(delivery_mode=2, content_type=\"application/json\"))\n    print(\"published\", json.dumps(event))\nconn.close()", "note": "`python publish.py N FIRST` publica N eventos `OrderPlaced`, numerados a partir de FIRST (1 quando é omitido), na exchange `orders` com a chave de roteamento `order.placed`. A exchange é do tipo topic e durável; cada mensagem é marcada como persistente, para um reinício do broker não perder o que espera numa fila durável."}]}
```

`consume.py`, que os lê de uma fila:

```schooling-example
{"language": "python", "file": "consume.py", "parts": [{"code": "\"\"\"Consume OrderPlaced events from one RabbitMQ queue.\"\"\"\nimport json, os, socket, sys, time\nimport pika\n\nqueue = sys.argv[1]\nconn = pika.BlockingConnection(pika.URLParameters(os.environ[\"RABBIT_URL\"]))\nch = conn.channel()\nch.exchange_declare(\"orders\", exchange_type=\"topic\", durable=True)\nch.queue_declare(queue, durable=True)\nch.queue_bind(queue, \"orders\", routing_key=\"order.*\")\n", "note": "Consome de uma fila. Declara a fila como durável e a liga a `orders` para toda chave de roteamento que começa com `order.`, então rodá-lo uma vez também é como uma fila passa a existir."}, {"code": "ch.basic_qos(prefetch_count=1)\nfor method, props, body in ch.consume(queue, inactivity_timeout=2):\n    if method is None:\n        break\n    event = json.loads(body)\n    time.sleep(0.5)  # the work of handling it\n    print(f\"{queue} on {socket.gethostname()}: order {event['order']}\", flush=True)\n    ch.basic_ack(method.delivery_tag)\nconn.close()", "note": "`prefetch_count=1`: o broker manda a este consumidor uma mensagem por vez, e a próxima só depois da confirmação. Tratar uma mensagem leva meio segundo aqui, e ela só é confirmada depois disso; o laço termina depois de dois segundos sem nada para fazer."}]}
```

A seção sobre o RabbitMQ na prática, duas seções adiante, roda os dois. O serviço `tools` está num
**profile**, então `docker compose up` o deixa de lado e `docker compose run tools …` o constrói e roda
quando um script é necessário. Inicie os dois brokers:

```sh
docker compose up -d
```

A primeira execução baixa as imagens dos dois brokers, várias centenas de megabytes. Depois que estão de
pé, o Docker consegue dizer quanta memória cada um ocupa sem fazer nada:

```
ana@vm:~/lab/brokers$ docker compose ps --format "{{.Service}} {{.Image}} {{.Status}}"
kafka apache/kafka:4.0.0 Up 20 seconds
rabbitmq rabbitmq:4.1-management Up 20 seconds
ana@vm:~/lab/brokers$ docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}"
NAME                 MEM USAGE / LIMIT
brokers-rabbitmq-1   92.39MiB / 15.72GiB
brokers-kafka-1      267.5MiB / 15.72GiB
```

O RabbitMQ, escrito em Erlang, fica em torno de cem megabytes; o Kafka, na JVM com o heap limitado a
512 MB pelo `KAFKA_HEAP_OPTS`, já usa algumas centenas antes de receber uma única mensagem. **Essa base é
por nó de broker**, e um cluster de produção roda pelo menos três de cada, pelos motivos que a aula 10
dá.

## Olhando o RabbitMQ num navegador

A interface de gerenciamento é publicada no loopback da VM, porta 15672. Para abri-la no navegador do
seu próprio computador, a porta precisa chegar até ele: com o Multipass, `multipass info arch` dá o
endereço da VM, e um túnel SSH como `ssh -L 15672:127.0.0.1:15672 ubuntu@<endereço>` a traz para
`http://localhost:15672`, usuário e senha `guest`. A aula não precisa dela; tudo o que mostra vem da
linha de comando, que é também o que um script ou um pipeline usaria.
