---
title: Um consumidor, e o laço em que ele vive
version: 1
---

**Um consumidor pede mensagens; o Kafka nunca as empurra.** O programa chama `poll` num laço, e cada
chamada devolve a próxima mensagem de uma das partições que ele recebeu, ou nada se nenhuma chegou
dentro do timeout. Todo o resto que um consumidor faz, entrar num grupo, receber partições e registrar
até onde leu, acontece dentro dessas chamadas, então um consumidor que para de chamar `poll` deixa de
ser consumidor, como a lição 16 mostra.

Todo consumidor deste curso pertence a um **consumer group**, nomeado pelo `group.id`. O grupo é para
quem o Kafka guarda a posição de leitura, e entre quem ele divide as partições, que é a próxima seção.
Salve isto como `~/work/consumer.py`:

```schooling-example
{
  "language": "python",
  "file": "consumer.py",
  "parts": [
    {
      "code": "\"\"\"consumer.py: read sales as one member of a consumer group.\n\n    python consumer.py NAME [--group G] [--topic T] [--protocol classic|consumer]\n                            [--strategy S] [--manual]\n\"\"\"\nimport argparse\nimport json\n\nfrom confluent_kafka import Consumer\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"name\")\nargs.add_argument(\"--group\", default=\"stock\")\nargs.add_argument(\"--topic\", default=\"sales\")\nargs.add_argument(\"--protocol\", default=\"classic\")\nargs.add_argument(\"--strategy\", default=\"range\")\nargs.add_argument(\"--manual\", action=\"store_true\")\nargs = args.parse_args()\n",
      "note": "O que ele faz. O nome só é impresso, para distinguir as cópias; `--group`, `--protocol`, `--strategy` e `--manual` são o que as seções seguintes mudam."
    },
    {
      "code": "config = {\n    \"bootstrap.servers\": \"localhost:9092\",\n    \"group.id\": args.group,\n    \"auto.offset.reset\": \"earliest\",\n    \"group.protocol\": args.protocol,\n    \"enable.auto.commit\": not args.manual,\n}\nif args.protocol == \"classic\":\n    config[\"partition.assignment.strategy\"] = args.strategy\nconsumer = Consumer(config)\n",
      "note": "A configuração. **`group.id` é a única configuração sem a qual um consumidor que assina um tópico não funciona.** `auto.offset.reset` diz onde começa um grupo sem posição salva; a estratégia só existe no protocolo classic."
    },
    {
      "code": "\n\ndef show(event):\n    def callback(consumer, partitions):\n        print(f\"{args.name}: {event} {[p.partition for p in partitions]}\", flush=True)\n    return callback\n\n\nconsumer.subscribe([args.topic], on_assign=show(\"assigned\"), on_revoke=show(\"revoked\"))",
      "note": "O `subscribe` dá o tópico e deixa o grupo decidir quais partições esta cópia recebe. Os dois callbacks imprimem toda mudança, e é assim que as próximas seções veem os rebalanceamentos."
    },
    {
      "code": "try:\n    while True:\n        msg = consumer.poll(1.0)\n        if msg is None:\n            continue\n        if msg.error():\n            print(f\"{args.name}: {msg.error()}\", flush=True)\n            continue\n        sale = json.loads(msg.value())\n        print(f\"{args.name}: partition {msg.partition()} offset {msg.offset()} {sale['sale']}\",\n              flush=True)\n        if args.manual:\n            consumer.commit(message=msg, asynchronous=False)",
      "note": "**O laço de poll.** Cada chamada devolve uma mensagem, um erro, ou `None` depois de um segundo sem nada. Com `--manual` o programa faz o commit do offset de cada mensagem por conta própria, e espera o broker confirmar."
    },
    {
      "code": "except KeyboardInterrupt:\n    pass\nfinally:\n    consumer.close()",
      "note": "Ctrl+C encerra o laço, e o `close` sai do grupo de forma limpa: faz o commit do que foi lido, a menos que os commits sejam manuais, e devolve as partições na hora em vez de deixar o grupo esperar um timeout."
    }
  ]
}
```

Rode-o no seu segundo shell. Ele lê as dez vendas da seção anterior e espera por mais; pare-o com
Ctrl+C quando tiver lido:

```
ubuntu@stream:~/work$ python consumer.py c1
c1: assigned [0, 1, 2]
c1: partition 2 offset 0 rec-000005
c1: partition 2 offset 1 rec-000010
c1: partition 1 offset 0 car-000002
c1: partition 1 offset 1 nat-000003
c1: partition 1 offset 2 car-000007
c1: partition 1 offset 3 nat-000008
c1: partition 0 offset 0 oli-000001
c1: partition 0 offset 1 joa-000004
c1: partition 0 offset 2 oli-000006
c1: partition 0 offset 3 joa-000009
c1: revoked [0, 1, 2]
```

A primeira linha é a atribuição: sozinho no grupo `stock`, o `c1` recebeu as três partições. Depois,
as dez vendas, numa ordem que vale a pena ler. **Dentro de cada partição elas estão em ordem de
offset**: as duas vendas do Recife da partição 2, depois as quatro da partição 1, depois as quatro da
partição 0. Entre partições não há ordem nenhuma; o cliente por acaso buscou a partição 2 primeiro, e
a venda `oli-000001` de Olinda, a primeira produzida, saiu em oitavo. A promessa da lição 2 era ordem
por chave, e foi exatamente isso que chegou.

O Ctrl+C encerrou o laço, e o `close` devolveu as partições, que é a linha `revoked`. Ele também
registrou até onde o `c1` tinha lido. Pergunte ao Kafka o que ele sabe do grupo:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock

Consumer group 'stock' has no active members.

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
stock           sales           0          4               4               0               -               -               -
stock           sales           1          4               4               0               -               -               -
stock           sales           2          2               2               0               -               -               -
```

O grupo não tem membros agora, e o Kafka ainda se lembra dele. Para cada partição, **`CURRENT-OFFSET` é
o offset que o grupo vai ler em seguida**, `LOG-END-OFFSET` é o offset que a próxima mensagem produzida
vai receber, e **`LAG`** é a diferença: mensagens escritas e ainda não lidas por este grupo. Os três
são 0, porque o `c1` leu tudo. O grupo continua em 4, 4 e 2, então o `c1` iniciado de novo não teria
nada para ler até chegarem mais vendas.

## Onde um grupo novo começa

Um grupo que nunca fez commit de um offset não tem de onde continuar, e o **`auto.offset.reset`**
decide: `earliest` começa no início de cada partição, e `latest`, o padrão, começa no fim, então o
grupo só vê mensagens produzidas depois que entrou. O console consumer da lição 1 começava no fim pelo
mesmo motivo. O `consumer.py` configura `earliest`, então um nome de grupo novo lê tudo o que existe,
e as próximas seções contam com isso.
