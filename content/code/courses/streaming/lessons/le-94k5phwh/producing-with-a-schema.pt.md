---
title: Produzindo e lendo com um esquema
version: 1
---

**Com um registro, o produtor não manda JSON e o consumidor não o interpreta: cada lado entrega os
seus dicionários a um serializador, que os transforma no cabeçalho de cinco bytes e num corpo Avro,
e de volta.** A parte Kafka do programa não muda nada. `produce` continua recebendo bytes; eles só
vêm de outra função.

## O caixa, em Avro

Este é o caixa da lição 1 sem o JSON. As lojas, os livros e o relógio são os mesmos, e a mesma
semente dá as mesmas vendas. Salve como `~/work/avro_tills.py`:

```schooling-example
{
  "language": "python",
  "file": "avro_tills.py",
  "parts": [
    {
      "code": "\"\"\"avro_tills.py: Ponto Final's sales into Kafka as Avro, under a registered schema.\n\n    python avro_tills.py [--count N] [--schema FILE] [--topic T] [--seed S]\n\"\"\"\nimport argparse\nimport random\nfrom datetime import datetime, timedelta, timezone\n\nfrom confluent_kafka import Producer\nfrom confluent_kafka.schema_registry import SchemaRegistryClient\nfrom confluent_kafka.schema_registry.avro import AvroSerializer\nfrom confluent_kafka.serialization import MessageField, SerializationContext\n",
      "note": "O serializador mora em `confluent_kafka.schema_registry`, que o extra `[avro]` instalou."
    },
    {
      "code": "SHOPS = [\"recife\", \"olinda\", \"caruaru\", \"natal\", \"joao-pessoa\"]\nBOOKS = {\"bk-01\": 3990, \"bk-02\": 5490, \"bk-03\": 2990, \"bk-04\": 7900,\n         \"bk-05\": 4490, \"bk-06\": 6200, \"bk-07\": 3500, \"bk-08\": 8990}\nOPEN = datetime(2026, 3, 2, 9, 0, tzinfo=timezone(timedelta(hours=-3)))\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"--count\", type=int, default=10)\nargs.add_argument(\"--schema\", default=\"sale.avsc\")\nargs.add_argument(\"--topic\", default=\"sales-avro\")\nargs.add_argument(\"--seed\", type=int, default=1)\nargs = args.parse_args()\n",
      "note": "As mesmas lojas, livros e hora de abertura do `tills.py`."
    },
    {
      "code": "registry = SchemaRegistryClient({\"url\": \"http://localhost:8080/apis/ccompat/v7\"})\nto_avro = AvroSerializer(registry, open(args.schema).read(),\n                         conf={\"auto.register.schemas\": False})\nproducer = Producer({\"bootstrap.servers\": \"localhost:9092\"})\n",
      "note": "**`auto.register.schemas` está desligado.** Por padrão o serializador registra qualquer esquema que receber, o que transforma todo produtor em alguém capaz de mudar o esquema do tópico. Desligado, ele só procura o esquema, e se recusa a enviar se o registro não o tiver."
    },
    {
      "code": "rng, clock = random.Random(args.seed), OPEN\nfor n in range(1, args.count + 1):\n    clock += timedelta(seconds=rng.randint(1, 20))\n    shop, book = rng.choice(SHOPS), rng.choice(list(BOOKS))\n    qty = rng.choice([1, 1, 1, 2, 3])\n    sale = {\"sale\": f\"{shop[:3]}-{n:06d}\", \"shop\": shop, \"book\": book, \"qty\": qty,\n            \"cents\": BOOKS[book] * qty, \"at\": clock.isoformat(), \"till\": f\"{shop}-1\"}",
      "note": "Cada venda é um dicionário como antes. Ela também leva `till`, que o esquema em `sale.avsc` não tem: **o serializador escreve os campos que o seu esquema nomeia e ignora o resto**, o que deixa o mesmo programa escrever uma versão posterior."
    },
    {
      "code": "    value = to_avro(sale, SerializationContext(args.topic, MessageField.VALUE))\n    producer.produce(args.topic, key=shop, value=value)\nproducer.flush()\nprint(f\"sent {args.count} sales to {args.topic} as Avro\")",
      "note": "O serializador precisa saber o tópico e que se trata de um valor, porque juntos eles dão o nome do subject: `sales-avro` e valor dão `sales-avro-value`."
    }
  ]
}
```

Crie o tópico e mande dez vendas:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales-avro --partitions 3
Created topic sales-avro.
ubuntu@stream:~/work$ python avro_tills.py --count 10
sent 10 sales to sales-avro as Avro
```

## O que passou pelo fio

O consumidor de console imprime o valor de uma mensagem como ele é, e o `od` mostra os bytes. Uma
mensagem, do começo da partição 0:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales-avro --partition 0 --offset 0 --max-messages 1 2>/dev/null | od -A d -t x1z
0000000 00 00 00 00 01 14 63 61 72 2d 30 30 30 30 31 30  >......car-000010<
0000016 0e 63 61 72 75 61 72 75 0a 62 6b 2d 30 34 02 b8  >.caruaru.bk-04..<
0000032 7b 32 32 30 32 36 2d 30 33 2d 30 32 54 30 39 3a  >{22026-03-02T09:<
0000048 30 31 3a 30 37 2d 30 33 3a 30 30 0a              >01:07-03:00.<
0000060
```

O `od` imprime à esquerda a posição de cada linha, dezesseis bytes em hexadecimal, e os imprimíveis
entre `>` e `<`. O primeiro byte é o mágico `00`, os quatro seguintes são `00 00 00 01`, o id; e de
`14` em diante é um corpo Avro como o da seção sobre Avro: `car-000010`, `caruaru`, `bk-04`. O
último byte, `0a`, não faz parte da mensagem: é a quebra de linha que o consumidor de console
imprime depois de cada valor.

Nada nesses bytes diz *sale*, *shop* ou *cents*. Um programa que tem o id e alcança o registro
consegue lê-los, e um que não alcança tem 59 bytes de ruído, e é por isso que o registro faz parte
do pipeline tanto quanto os brokers.

## O leitor

O consumidor é a imagem no espelho. Ele recebe um esquema próprio, o **esquema do leitor** da seção
sobre Avro, e o desserializador busca no registro o esquema de quem escreveu, pelo id em cada
mensagem. Salve como `~/work/avro_read.py`:

```schooling-example
{
  "language": "python",
  "file": "avro_read.py",
  "parts": [
    {
      "code": "\"\"\"avro_read.py: read every Avro sale as the schema in one file, whatever it was written with.\n\n    python avro_read.py [SCHEMA]      (sale.avsc if not given)\n\"\"\"\nimport sys\nimport uuid\nfrom collections import Counter\n\nfrom confluent_kafka import Consumer\nfrom confluent_kafka.schema_registry import SchemaRegistryClient\nfrom confluent_kafka.schema_registry.avro import AvroDeserializer\nfrom confluent_kafka.serialization import MessageField, SerializationContext\n",
      "note": "O esquema que o leitor quer vem de um arquivo, `sale.avsc` se nenhum outro for indicado."
    },
    {
      "code": "schema = sys.argv[1] if len(sys.argv) > 1 else \"sale.avsc\"\nregistry = SchemaRegistryClient({\"url\": \"http://localhost:8080/apis/ccompat/v7\"})\nfrom_avro = AvroDeserializer(registry, open(schema).read())\nconsumer = Consumer({\"bootstrap.servers\": \"localhost:9092\",\n                     \"group.id\": f\"avro-read-{uuid.uuid4()}\",\n                     \"auto.offset.reset\": \"earliest\"})\nconsumer.subscribe([\"sales-avro\"])\n",
      "note": "**O desserializador recebe o esquema do leitor**, e resolve cada mensagem do esquema de quem escreveu para este."
    },
    {
      "code": "cents, written_with, fields = Counter(), Counter(), None\nwhile (msg := consumer.poll(10)) is not None:\n    written_with[int.from_bytes(msg.value()[1:5], \"big\")] += 1\n    sale = from_avro(msg.value(), SerializationContext(\"sales-avro\", MessageField.VALUE))\n    cents[sale[\"shop\"]] += sale[\"cents\"]\n    fields = fields or list(sale)\nconsumer.close()\n\nprint(\"schema ids:\", dict(written_with))\nprint(\"fields read:\", \", \".join(fields))\nfor shop, total in sorted(cents.items()):\n    print(f\"{shop:12} {total / 100:10.2f}\")",
      "note": "Os bytes 1 a 4 de cada valor são o id do esquema de quem escreveu, contados aqui para você ver que versões estão no tópico. Os campos da primeira venda lida são guardados para mostrar o que o esquema do leitor produziu."
    }
  ]
}
```

```
ubuntu@stream:~/work$ python avro_read.py
schema ids: {1: 10}
fields read: sale, shop, book, qty, cents, at
caruaru           79.00
joao-pessoa       54.90
natal            719.10
olinda           109.80
recife           141.80
```

As dez vendas foram escritas com o esquema 1, o leitor pediu os mesmos campos, e os totais saem de
um tópico Avro como saíam do JSON. A diferença aqui é invisível, e aparece na primeira vez que
alguém muda o esquema, o que a próxima seção faz de propósito.
