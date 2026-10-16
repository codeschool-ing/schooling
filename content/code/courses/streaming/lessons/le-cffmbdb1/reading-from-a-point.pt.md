---
title: Lendo a partir de um ponto escolhido
version: 1
---

**A posição de um grupo é um valor que o Kafka guarda, então ela pode ser ajustada.** Para ler de novo
desde o começo, a partir de um offset, ou a partir de um momento, você move os offsets commitados do
grupo, e o próximo membro que iniciar lê dali. A lição 2 chamou isso de **replay**; esta seção mostra
as duas ferramentas para isso, e a lição 16 as usa num consumidor que errou alguma coisa.

## Movendo um grupo com o kafka-consumer-groups.sh

A ferramenta de grupos reseta offsets, e insiste em duas coisas: o grupo não pode ter membros rodando,
e ela não muda nada a menos que mandem. O `--dry-run` mostra o que aconteceria:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group stock --topic sales --reset-offsets --to-earliest --dry-run

GROUP           TOPIC           PARTITION  NEW-OFFSET
stock           sales           2          0
stock           sales           1          0
stock           sales           0          0
```

O `--execute` faz. O alvo pode ser `--to-earliest`, `--to-latest`, `--to-offset`, `--shift-by` um
número, ou `--to-datetime` um momento, e `--topic sales:1` limita a uma partição. Volte o grupo
`stock` para o offset 3 só na partição 1:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group stock --topic sales:1 --reset-offsets --to-offset 3 --execute

GROUP           TOPIC           PARTITION  NEW-OFFSET
stock           sales           1          3
```

Depois inicie o `c1` de novo e pare-o quando tiver lido:

```
ubuntu@stream:~/work$ python consumer.py c1
c1: assigned [0, 1, 2]
c1: partition 2 offset 2 rec-000005
c1: partition 2 offset 3 rec-000010
c1: partition 1 offset 3 nat-000008
c1: partition 1 offset 4 car-000002
c1: partition 1 offset 5 nat-000003
c1: partition 1 offset 6 car-000007
c1: partition 1 offset 7 nat-000008
c1: partition 0 offset 4 oli-000001
c1: partition 0 offset 5 joa-000004
c1: partition 0 offset 6 oli-000006
c1: partition 0 offset 7 joa-000009
c1: revoked [0, 1, 2]
```

A partição 1 começou no 3, então a `nat-000008`, que o `c1` leu na primeira seção, voltou antes das
vendas novas. As partições 0 e 2 não foram tocadas e continuaram em 4 e 2, lendo só as dez vendas
mandadas enquanto o `c1` estava fora. **Um reset move o lugar, e o log fornece as mensagens**: nada
foi reenviado, e nenhum outro grupo percebeu.

## Lendo a partir de um momento, sem grupo

Um programa também pode escolher o próprio ponto de partida, sem posição de grupo nenhuma. O
`offsets_for_times` pergunta ao broker, para cada partição, o primeiro offset cujo timestamp é igual
ou posterior a um momento, usando o `.timeindex` da lição 3. Salve isto como `~/work/rewind.py`:

```schooling-example
{
  "language": "python",
  "file": "rewind.py",
  "parts": [
    {
      "code": "\"\"\"rewind.py: read a topic from a moment in time, outside any consumer group.\n\n    python rewind.py TOPIC 'YYYY-MM-DD HH:MM:SS' [--max N]\n\"\"\"\nimport argparse\nimport json\nfrom datetime import datetime\n\nfrom confluent_kafka import Consumer, TopicPartition\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"topic\")\nargs.add_argument(\"since\")\nargs.add_argument(\"--max\", type=int, default=5)\nargs = args.parse_args()\n",
      "note": "O que ele faz e como chamar: um tópico, uma data e hora locais, e quantas mensagens imprimir."
    },
    {
      "code": "since = int(datetime.strptime(args.since, \"%Y-%m-%d %H:%M:%S\").timestamp() * 1000)\nconsumer = Consumer({\"bootstrap.servers\": \"localhost:9092\", \"group.id\": \"rewind\",\n                     \"enable.auto.commit\": False})\n",
      "note": "O momento vira milissegundos desde 1970, a unidade do timestamp de um registro. O group id é exigido pelo cliente e nunca é usado para entrar em grupo, já que este consumidor não assina o tópico."
    },
    {
      "code": "partitions = consumer.list_topics(args.topic, timeout=10).topics[args.topic].partitions\nasked = [TopicPartition(args.topic, p, since) for p in sorted(partitions)]\nfound = consumer.offsets_for_times(asked, timeout=10)\nfor tp in found:\n    print(f\"partition {tp.partition}: offset {tp.offset}\")\n",
      "note": "**Uma pergunta por partição**: entra um `TopicPartition` cujo campo de offset leva o timestamp, e sai a mesma partição com o primeiro offset igual ou posterior àquele momento."
    },
    {
      "code": "consumer.assign(found)\nfor _ in range(args.max):\n    msg = consumer.poll(5)\n    if msg is None:\n        break\n    sale = json.loads(msg.value())\n    print(f\"partition {msg.partition()} offset {msg.offset()} {sale['sale']}\")\nconsumer.close()",
      "note": "O `assign` pega essas partições nesses offsets, e o laço lê a partir dali."
    }
  ]
}
```

Anote a hora, mande mais cinco vendas, e volte até aquela hora:

```
ubuntu@stream:~/work$ date "+%F %T"
2026-10-10 22:45:14
ubuntu@stream:~/work$ python producer.py --count 5
delivered per partition: {0: 2, 1: 2, 2: 1}
ubuntu@stream:~/work$ python rewind.py sales '2026-10-10 22:45:14'
partition 0: offset 8
partition 1: offset 8
partition 2: offset 4
partition 2 offset 4 rec-000005
partition 1 offset 8 car-000002
partition 1 offset 9 nat-000003
partition 0 offset 8 oli-000001
partition 0 offset 9 joa-000004
```

O broker respondeu os offsets 8, 8 e 4: exatamente os log-end offsets de antes das cinco vendas novas,
então o programa leu essas cinco e nada mais antigo. A sua hora vai ser outra; use a que o seu `date`
imprimiu. O timestamp que o broker consulta é o do registro, definido pelo produtor quando mandou a
mensagem, e não o `at` da própria venda; a lição 9 trata da diferença, e de produtores que o definem
como outra coisa.

O `rewind.py` usa `assign` em vez de `subscribe`. **Um consumidor com `assign` não é membro de grupo
nenhum**: lê as partições que indica, nenhum rebalanceamento as dá a outro, e não faz commit de nada,
porque o `enable.auto.commit` está desligado. É a ferramenta para olhar, enquanto um grupo resetado é
a ferramenta para reprocessar.
