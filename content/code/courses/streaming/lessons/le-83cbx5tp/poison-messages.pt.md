---
title: Uma mensagem venenosa, e o tópico de cartas mortas
version: 1
---

**Um consumidor lê uma partição em ordem, e não consegue pular uma mensagem em que falha.** A
posição dele é o offset da próxima mensagem a tratar; se tratá-la lança uma exceção, a posição não
se move, e quando o programa reinicia ele lê a mesma mensagem e falha de novo. Um registro que o
programa não consegue tratar, chamado **mensagem venenosa** (poison message), para a partição
inteira, incluindo toda chave que por acaso a divida. E quando o programa morre nela, toda outra
partição que ele lia para junto.

A origem comum não é malícia. É um caixa que perdeu uma atualização de software e ainda manda o
formato antigo, um campo que era número no mês passado e agora é texto (a lição 6 é sobre evitar
isso), uma mensagem cortada, ou um valor que nenhum caminho do código esperava.

## Uma venda ruim

Este consumidor conta os livros vendidos, e confirma depois de cada venda que conta, então a posição
dele é exatamente a próxima mensagem de que ainda não cuidou. Sem `--dead-letter`, qualquer coisa que
não seja uma venda o derruba. Salve como `~/work/sturdy_consumer.py`:

```schooling-example
{
  "language": "python",
  "file": "sturdy_consumer.py",
  "parts": [
    {
      "code": "\"\"\"sturdy_consumer.py: counts the books sold, and decides what a bad message costs.\n\n    python sturdy_consumer.py [--group G] [--dead-letter TOPIC]\n\nWithout --dead-letter, a message that is not a sale stops the program.\nWith it, the message is copied to TOPIC with the reason, and skipped.\nIt stops by itself after ten seconds with nothing to read.\n\"\"\"\nimport argparse\nimport json\n\nfrom confluent_kafka import Consumer, Producer\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"--group\", default=\"stock-count\")\nargs.add_argument(\"--dead-letter\")\nargs = args.parse_args()\n",
      "note": "O que ele faz, e a única escolha que oferece: quanto custa uma mensagem que ele não consegue tratar."
    },
    {
      "code": "consumer = Consumer({\n    \"bootstrap.servers\": \"localhost:9092\",\n    \"group.id\": args.group,\n    \"auto.offset.reset\": \"earliest\",\n    \"enable.auto.commit\": False,\n})\nconsumer.subscribe([\"sales\"])\ndead = Producer({\"bootstrap.servers\": \"localhost:9092\"}) if args.dead_letter else None\n",
      "note": "**Os commits são manuais**, depois de cada mensagem, para que a posição do grupo nunca passe à frente do que foi realmente contado."
    },
    {
      "code": "books = sales = letters = 0\ntry:\n    while True:\n        msg = consumer.poll(10)\n        if msg is None:\n            break\n        if msg.error():\n            raise SystemExit(msg.error().str())\n        try:\n            sale = json.loads(msg.value())\n            books += sale[\"qty\"]\n            sales += 1\n",
      "note": "O trabalho. Uma mensagem que não é JSON, ou que não tem `qty`, lança uma exceção aqui, e sem tópico de cartas mortas nada a captura."
    },
    {
      "code": "        except (ValueError, KeyError, TypeError) as e:\n            if dead is None:\n                raise\n            where = f\"{msg.topic()}/{msg.partition()}/{msg.offset()}\"\n            dead.produce(args.dead_letter, key=msg.key(), value=msg.value(),\n                         headers={\"error\": repr(e), \"from\": where})\n            dead.flush()\n            letters += 1\n            print(\"dead letter:\", where, repr(e))\n",
      "note": "Com um tópico de cartas mortas, a mensagem ruim é copiada para lá inteira, **com o motivo e a origem em cabeçalhos**, e o consumidor segue em frente."
    },
    {
      "code": "        consumer.commit(msg, asynchronous=False)\nfinally:\n    consumer.close()\nprint(f\"{sales} sales, {books} books, {letters} dead letters\")",
      "note": "O commit vem depois de a mensagem ter sido tratada, de um jeito ou de outro. Essa ordem é o at-least-once da lição 7."
    }
  ]
}
```

O tópico tem as 600 vendas das seções anteriores. Conte-as uma vez, para que o grupo `stock-count`
tenha uma posição confirmada em toda partição que tem vendas; ele para sozinho dez segundos depois da
última:

```
ubuntu@stream:~/work$ python sturdy_consumer.py
600 sales, 999 books, 0 dead letters
```

Agora um caixa do Recife com o software antigo manda uma venda no formato antigo, uma linha de campos
separados por ponto e vírgula, e trinta vendas comuns vêm depois dela. O `kafka-console-producer.sh`
manda a ruim com a chave `recife`:

```
ubuntu@stream:~/work$ echo 'recife|bk-03;1;2990' | kafka-console-producer.sh --bootstrap-server localhost:9092 --topic sales --reader-property parse.key=true --reader-property key.separator='|'
ubuntu@stream:~/work$ python tills.py --count 30 --rate 0 --seed 5
sent 30 sales to sales, the last one at 09:04:14
```

Conte de novo:

```
ubuntu@stream:~/work$ python sturdy_consumer.py
Traceback (most recent call last):
  File "/home/ubuntu/work/sturdy_consumer.py", line 37, in <module>
    sale = json.loads(msg.value())
           ^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/json/__init__.py", line 346, in loads
    return _default_decoder.decode(s)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/json/decoder.py", line 337, in decode
    obj, end = self.raw_decode(s, idx=_w(s, 0).end())
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/json/decoder.py", line 355, in raw_decode
    raise JSONDecodeError("Expecting value", s, err.value) from None
json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)
```

Ele morre no `json.loads`. Onde parou?

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock-count

Consumer group 'stock-count' has no active members.

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
stock-count     sales           0          139             139             0               -               -               -
stock-count     sales           1          491             491             0               -               -               -
```

As partições 0 e 1 foram lidas até o fim, incluindo as trinta vendas novas, e mostram lag zero. **A
partição 2 nem aparece na lista.** O console producer é um programa Java, e o cliente Java calcula o
hash de uma chave de um jeito diferente do cliente Python (lição 3), então este `recife` caiu na
partição 2, onde nenhuma venda dos caixas em Python vai parar. A venda ruim é a primeira e única
mensagem ali, o grupo nunca confirmou posição nenhuma nessa partição, e a ferramenta não tem nada para
imprimir sobre ela. Rode o contador de novo, como faria um supervisor que reinicia programas que caem:

```
ubuntu@stream:~/work$ python sturdy_consumer.py
Traceback (most recent call last):
  File "/home/ubuntu/work/sturdy_consumer.py", line 37, in <module>
    sale = json.loads(msg.value())
           ^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/json/__init__.py", line 346, in loads
    return _default_decoder.decode(s)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/json/decoder.py", line 337, in decode
    obj, end = self.raw_decode(s, idx=_w(s, 0).end())
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/json/decoder.py", line 355, in raw_decode
    raise JSONDecodeError("Expecting value", s, err.value) from None
json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)
```

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock-count

Consumer group 'stock-count' has no active members.

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
stock-count     sales           0          139             139             0               -               -               -
stock-count     sales           1          491             491             0               -               -               -
```

**A mesma mensagem, o mesmo erro, e nada se moveu.** Um supervisor o reiniciaria para sempre. E veja
o que um painel de lag diria: zero em toda partição que ele conhece. **Uma mensagem venenosa pode
parar um consumidor enquanto o lag marca zero**, porque o lag é medido a partir de commits e a
partição travada não tem nenhum. Um consumidor que reinicia sem parar, ou um grupo sem membros, é o
sinal aqui, e a última seção desta lição põe os dois na lista de alertas. Se a mensagem ruim tivesse
chegado depois de algumas boas na partição 2, o lag ali cresceria a cada venda atrás dela.

## O tópico de cartas mortas

A saída é decidir de antemão quanto vale uma mensagem que o programa não consegue tratar. **Um tópico
de cartas mortas (dead-letter topic) é a resposta usual: copie a mensagem para lá, com o motivo da
falha e de onde ela veio, e siga em frente.** Nada se perde, a partição anda, e alguém pode olhar as
cartas mortas depois, corrigir o programa ou os dados, e mandá-las de volta.

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales.dlq --partitions 1
WARNING: Due to limitations in metric names, topics with a period ('.') or underscore ('_') could collide. To avoid issues it is best to use either, but not both.
Created topic sales.dlq.
ubuntu@stream:~/work$ python sturdy_consumer.py --dead-letter sales.dlq
dead letter: sales/2/0 JSONDecodeError('Expecting value: line 1 column 1 (char 0)')
0 sales, 0 books, 1 dead letters
```

O Kafka reclama do ponto no nome porque os nomes de métricas transformam pontos em sublinhados, então
`sales.dlq` e `sales_dlq` colidiriam; usar só um dos dois caracteres nos nomes dos seus tópicos evita
isso. O contador, com um lugar para pôr o que não consegue contar, passa da venda ruim na hora: não
contou mais nada nesta execução porque todo o resto já estava contado. A carta morta, com os
cabeçalhos antes do tab e o valor original depois dele:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales.dlq --from-beginning --max-messages 1 --formatter-property print.headers=true
The consumer rebalance protocol (KIP-848) is production-ready! Set group.protocol=consumer to try it out. See https://kafka.apache.org/documentation/#consumer_rebalance_protocol
error:JSONDecodeError('Expecting value: line 1 column 1 (char 0)'),from:sales/2/0	bk-03;1;2990
Processed a total of 1 messages
```

Três regras impedem que um tópico de cartas mortas vire um segundo problema:

- **Só para erros que não somem tentando de novo.** Uma mensagem que falhou porque um banco ficou
  fora do ar por um segundo não é venenosa; mandá-la para as cartas mortas põe de lado uma venda
  comum. Tente de novo as passageiras, algumas vezes com uma pausa, e mande para as cartas mortas só o
  que falha do mesmo jeito toda vez.
- **Alguém lê.** Um tópico de cartas mortas que ninguém vigia é um jeito mais lento de descartar
  dados. O tamanho dele é um número para alertar, e a última seção desta lição diz isso.
- **A ordem é abandonada.** Uma venda posta de lado e reprocessada depois chega depois de vendas que
  aconteceram depois dela. Para contar livros isso é inofensivo; para o saldo de uma conta não é, e
  ali a escolha é parar a partição de propósito.
