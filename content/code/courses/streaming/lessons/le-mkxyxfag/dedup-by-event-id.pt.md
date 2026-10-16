---
title: Lembrando quais eventos foram aplicados
version: 1
---

**Um consumidor consegue transformar duplicatas em nada registrando o id de cada evento que aplica,
na mesma transação de banco do efeito, e pulando um evento cujo id já está registrado.** As duas
gravações têm de dividir a transação. Com o id gravado primeiro e o efeito depois, uma queda no meio
marca como aplicada uma venda que nunca foi; ao contrário, uma queda deixa uma venda aplicada e não
marcada, e a próxima entrega a aplica de novo.

O id tem de vir do evento, que é o que a lição 2 quis dizer ao dar a cada evento um id próprio: aqui é
o campo `sale`, `nat-000002` e assim por diante, dado pelo caixa. Um id inventado pelo consumidor, ou
o offset no Kafka, não serviriam, porque a mesma venda gravada duas vezes por um produtor que tentou
de novo fica em dois offsets.

## Um destino para o estoque

Este consumidor mantém o estoque de cada livro em `stock.db`, começando com cem cópias de cada, e
subtrai cada venda. Com `--dedup` ele também guarda os ids das vendas numa tabela `processed`. Ele
confirma no Kafka o offset de cada venda depois de o banco confirmar, então entrega pelo menos uma
vez, e `--crash-after` o derruba entre os dois commits. Salve como
`~/work/stock_sink.py`:

```schooling-example
{
  "language": "python",
  "file": "stock_sink.py",
  "parts": [
    {
      "code": "\"\"\"stock_sink.py: the stock of each book in SQLite, kept from the sales in Kafka.\n\n    python stock_sink.py [--dedup] [--replay] [--crash-after N]\n\n--dedup        remember each sale's id, in the same transaction as the stock\n--replay       read the topic from the beginning again, as a reprocessing would\n--crash-after  stop dead after N sales, between the database's commit and Kafka's\n\"\"\"\nimport argparse\nimport json\nimport os\nimport sqlite3\n\nfrom confluent_kafka import OFFSET_BEGINNING, Consumer\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"--dedup\", action=\"store_true\")\nargs.add_argument(\"--replay\", action=\"store_true\")\nargs.add_argument(\"--crash-after\", type=int, default=0)\nargs = args.parse_args()\n",
      "note": "Três opções, cada uma usada por uma seção desta lição."
    },
    {
      "code": "db = sqlite3.connect(\"stock.db\")\ndb.executescript(\"\"\"\n    CREATE TABLE IF NOT EXISTS stock (book TEXT PRIMARY KEY, qty INTEGER NOT NULL);\n    CREATE TABLE IF NOT EXISTS processed (sale TEXT PRIMARY KEY);\n    INSERT OR IGNORE INTO stock VALUES ('bk-01', 100), ('bk-02', 100), ('bk-03', 100),\n        ('bk-04', 100), ('bk-05', 100), ('bk-06', 100), ('bk-07', 100), ('bk-08', 100);\n\"\"\")\n\n",
      "note": "Duas tabelas: o estoque, e **os ids já aplicados, como chave primária**, para o próprio banco recusar uma segunda cópia. Um arquivo novo começa cada livro em 100."
    },
    {
      "code": "def from_the_start(consumer, partitions):\n    if args.replay:\n        for p in partitions:\n            p.offset = OFFSET_BEGINNING\n    consumer.assign(partitions)\n\n\nconsumer = Consumer({\"bootstrap.servers\": \"localhost:9092\", \"group.id\": \"stock-sink\",\n                     \"auto.offset.reset\": \"earliest\", \"enable.auto.commit\": False,\n                     \"session.timeout.ms\": 6000})\nconsumer.subscribe([\"sales\"], on_assign=from_the_start)\n",
      "note": "`--replay` volta cada partição ao primeiro offset quando o grupo as entrega, que é como reprocessar um tópico parece para um consumidor. Uma sessão de seis segundos, o mínimo do broker, deixa um reinício depois de uma queda assumir rápido as partições do membro que caiu, como na lição 7."
    },
    {
      "code": "applied = skipped = 0\nwhile (msg := consumer.poll(15)) is not None:\n    sale = json.loads(msg.value())\n    with db:\n        first_time = not args.dedup or db.execute(\n            \"INSERT OR IGNORE INTO processed VALUES (?)\", (sale[\"sale\"],)).rowcount == 1\n        if first_time:\n            db.execute(\"UPDATE stock SET qty = qty - ? WHERE book = ?\", (sale[\"qty\"], sale[\"book\"]))\n    applied, skipped = applied + first_time, skipped + (not first_time)",
      "note": "**`with db:` é uma transação**: confirma quando o bloco termina e desfaz se qualquer coisa dentro dele levantar uma exceção. `INSERT OR IGNORE` muda uma linha para um id novo e nenhuma para um conhecido, e `rowcount` diz qual."
    },
    {
      "code": "    if applied + skipped == args.crash_after:\n        print(f\"crashed after {args.crash_after} sales, before committing the offset\", flush=True)\n        os._exit(1)\n    consumer.commit(msg, asynchronous=False)\nconsumer.close()\nprint(f\"applied {applied} sales, skipped {skipped} already seen\")",
      "note": "A queda acontece **depois do commit do banco e antes do commit do Kafka**, o vão da lição 7 em que pelo menos uma vez repete uma mensagem."
    }
  ]
}
```

O estoque dos oito livros começa com 800 cópias ao todo, então a soma de `stock` depois de o
consumidor rodar é 800 menos as cópias vendidas. Crie um tópico novo com quarenta vendas:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3
Created topic sales.
ubuntu@stream:~/work$ python tills.py --count 40 --rate 0
sent 40 sales to sales, the last one at 09:06:58
```

Como na lição 7, um tópico `sales` que sobrou de uma lição anterior quer dizer começar de um cluster
novo.

## Sem os ids

Rode uma vez, depois releia o tópico, do jeito que uma equipe faz depois de corrigir um bug em outro
consumidor do mesmo tópico, ou depois de restaurar este banco do backup da noite anterior:

```
ubuntu@stream:~/work$ python stock_sink.py
applied 40 sales, skipped 0 already seen
ubuntu@stream:~/work$ python -m sqlite3 stock.db "SELECT sum(qty) FROM stock"
(729,)
ubuntu@stream:~/work$ python stock_sink.py --replay
applied 40 sales, skipped 0 already seen
ubuntu@stream:~/work$ python -m sqlite3 stock.db "SELECT sum(qty) FROM stock"
(658,)
```

As quarenta vendas tiraram 71 cópias das prateleiras: 800 viraram 729. **A releitura tirou de novo**,
para 658, e a contagem de cada livro agora está errada pelas cópias das próprias vendas. As duas
execuções imprimiram a mesma linha honesta; nada em nenhuma delas parece um erro.

## Com eles

Comece o banco de novo e faça o mesmo com `--dedup`:

```
ubuntu@stream:~/work$ rm stock.db
ubuntu@stream:~/work$ python stock_sink.py --dedup --replay
applied 40 sales, skipped 0 already seen
ubuntu@stream:~/work$ python -m sqlite3 stock.db "SELECT sum(qty) FROM stock"
(729,)
ubuntu@stream:~/work$ python stock_sink.py --dedup --replay
applied 0 sales, skipped 40 already seen
ubuntu@stream:~/work$ python -m sqlite3 stock.db "SELECT sum(qty) FROM stock"
(729,)
```

A primeira execução aplicou as quarenta e guardou os ids; a releitura encontrou todos os ids já lá,
**pulou as quarenta, e o estoque ficou em 729**.

## E a queda para a qual ele foi feito

A releitura foi uma duplicata de propósito. A comum vem de uma queda entre os dois commits. Apague o
banco e os offsets do grupo, derrube o destino depois de quinze vendas e comece de novo:

```
ubuntu@stream:~/work$ rm stock.db
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --delete --group stock-sink
Deletion of requested consumer groups ('stock-sink') was successful.
ubuntu@stream:~/work$ python stock_sink.py --dedup --crash-after 15
crashed after 15 sales, before committing the offset
ubuntu@stream:~/work$ python stock_sink.py --dedup
applied 25 sales, skipped 1 already seen
ubuntu@stream:~/work$ python -m sqlite3 stock.db "SELECT sum(qty) FROM stock"
(729,)
```

A queda veio depois de a transação de banco da décima quinta venda ter sido confirmada e antes de o
offset dela ser confirmado no Kafka. Então o reinício recebeu essa venda de novo, encontrou o id dela
em `processed` e a pulou: **25 aplicadas, 1 pulada, e o estoque em 729**, igual a uma execução que
nunca caiu. Sem `--dedup`, essa venda teria sido subtraída duas vezes.
