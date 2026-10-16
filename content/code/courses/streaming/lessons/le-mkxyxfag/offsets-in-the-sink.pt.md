---
title: Guardando o offset no banco
version: 1
---

**Se o banco guarda, na mesma transação de cada efeito, o offset da próxima mensagem a ler, então o
banco e o stream não têm como discordar sobre até onde o consumidor chegou.** Ao começar, o
consumidor lê esse offset e faz seek para ele. Uma queda em qualquer ponto deixa o efeito e o
offset dele, ou nenhum dos dois, e o reinício continua exatamente depois do último efeito. Nenhuma
venda é aplicada duas vezes, e não é preciso tabela de ids.

Isso muda o que o commit do grupo de consumidores significa. Ele era o registro do progresso; agora
não é usado, ou é usado só como uma **dica** para ferramentas como `kafka-consumer-groups.sh`
mostrarem o lag. O banco é o registro, porque é o único lugar que sabe o que foi de fato aplicado.

## O mesmo destino, guardando o próprio lugar

Esta variante mantém o estoque em `stock2.db` e acrescenta uma tabela `offsets` com uma linha por
partição. Ela nunca chama `commit`. Salve como `~/work/offset_sink.py`:

```schooling-example
{
  "language": "python",
  "file": "offset_sink.py",
  "parts": [
    {
      "code": "\"\"\"offset_sink.py: the stock in SQLite, with Kafka's offsets kept in the same database.\n\n    python offset_sink.py [--crash-after N]\n\nThe offset of the next sale to read is written in the transaction that applies\na sale, and read back when partitions are assigned. Kafka's group commit is\nnever used, so the database is the only record of how far this sink has got.\n\"\"\"\nimport argparse\nimport json\nimport os\nimport sqlite3\n\nfrom confluent_kafka import OFFSET_BEGINNING, Consumer\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"--crash-after\", type=int, default=0)\nargs = args.parse_args()\n",
      "note": "A docstring diz o desenho em três frases."
    },
    {
      "code": "db = sqlite3.connect(\"stock2.db\")\ndb.executescript(\"\"\"\n    CREATE TABLE IF NOT EXISTS stock (book TEXT PRIMARY KEY, qty INTEGER NOT NULL);\n    CREATE TABLE IF NOT EXISTS offsets (part INTEGER PRIMARY KEY, next INTEGER NOT NULL);\n    INSERT OR IGNORE INTO stock VALUES ('bk-01', 100), ('bk-02', 100), ('bk-03', 100),\n        ('bk-04', 100), ('bk-05', 100), ('bk-06', 100), ('bk-07', 100), ('bk-08', 100);\n\"\"\")\n\n",
      "note": "`offsets` guarda, por partição, **o offset da próxima venda a ler**: a última aplicada mais um."
    },
    {
      "code": "def resume(consumer, partitions):\n    for p in partitions:\n        row = db.execute(\"SELECT next FROM offsets WHERE part = ?\", (p.partition,)).fetchone()\n        p.offset = row[0] if row else OFFSET_BEGINNING\n        print(f\"partition {p.partition}: starting at {'the beginning' if row is None else row[0]}\")\n    consumer.assign(partitions)\n\n\nconsumer = Consumer({\"bootstrap.servers\": \"localhost:9092\", \"group.id\": \"offset-sink\",\n                     \"enable.auto.commit\": False, \"session.timeout.ms\": 6000})\nconsumer.subscribe([\"sales\"], on_assign=resume)\n",
      "note": "**Quando o grupo entrega as partições a este consumidor, ele define o offset inicial de cada uma a partir do banco**, e o início para uma partição que nunca viu."
    },
    {
      "code": "applied = 0\nwhile (msg := consumer.poll(15)) is not None:\n    sale = json.loads(msg.value())\n    with db:\n        db.execute(\"UPDATE stock SET qty = qty - ? WHERE book = ?\", (sale[\"qty\"], sale[\"book\"]))\n        db.execute(\"INSERT OR REPLACE INTO offsets VALUES (?, ?)\", (msg.partition(), msg.offset() + 1))\n    applied += 1\n    if applied == args.crash_after:\n        print(f\"crashed after {applied} sales\", flush=True)\n        os._exit(1)\nconsumer.close()\nprint(f\"applied {applied} sales\")",
      "note": "O estoque e o offset mudam em **uma transação**. Não há commit no Kafka antes do qual cair, então a queda pode vir em qualquer ponto."
    }
  ]
}
```

Derrube-o depois de quinze vendas e comece de novo:

```
ubuntu@stream:~/work$ python offset_sink.py --crash-after 15
partition 0: starting at the beginning
partition 1: starting at the beginning
partition 2: starting at the beginning
crashed after 15 sales
ubuntu@stream:~/work$ python offset_sink.py
partition 0: starting at the beginning
partition 1: starting at 15
partition 2: starting at the beginning
applied 25 sales
ubuntu@stream:~/work$ python -m sqlite3 stock2.db "SELECT sum(qty) FROM stock"
(729,)
ubuntu@stream:~/work$ python -m sqlite3 stock2.db "SELECT * FROM offsets"
(0, 7)
(1, 33)
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group offset-sink

Consumer group 'offset-sink' has no active members.
```

As quinze vendas da primeira execução vieram todas da partição 1, então depois da queda o banco
tinha uma linha em `offsets`, dizendo que a partição 1 deveria continuar em 15. **O reinício leu
isso e começou a partição 1 em 15**, e as outras duas do início. Ele aplicou as 25 restantes, e o
estoque é 729, como no destino com deduplicação, sem tabela de ids.

`offsets` agora diz onde continuar em cada partição que teve vendas: 7 para a partição 0 e 33 para
a partição 1; a partição 2 não recebeu nenhuma das quarenta. E o grupo de consumidores **não tem
offset confirmado nenhum**: `kafka-consumer-groups.sh` não tem nada a mostrar além de que ninguém
está conectado. Toda ferramenta que lê o lag pelo grupo não vê nada, que é o preço deste desenho, e
o motivo de algumas equipes também confirmarem no grupo, depois do banco, só como dica para
monitoramento. Uma dica errada depois de uma queda não faz mal, porque nada a lê ao começar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Três desenhos lado a lado. Primeiro, pelo menos uma vez: o banco confirma o efeito, depois o Kafka recebe o offset; uma queda entre os dois repete a venda. Segundo, deduplicação: o efeito e o id da venda são confirmados juntos no banco, e uma venda repetida é pulada porque o id está lá. Terceiro, offsets no destino: o efeito e o próximo offset são confirmados juntos no banco, o consumidor começa desse offset, e o offset do grupo no Kafka não é usado.\" data-fig=\"l8-offsets\"><defs><marker id=\"l8-offsets-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"120\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pelo menos uma vez</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">deduplicação por id</text><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">offset no destino</text><rect x=\"20\" y=\"40\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">banco: stock - 2</text><rect x=\"20\" y=\"120\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Kafka: commit do offset</text><line x1=\"120\" y1=\"76\" x2=\"120\" y2=\"118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l8-offsets-ah-8343)\"></line><text x=\"128\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">queda aqui repete a venda</text><text x=\"120\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dois commits</text><rect x=\"260\" y=\"40\" width=\"200\" height=\"70\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">uma transação</text><rect x=\"270\" y=\"64\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">banco: stock - 2, id</text><text x=\"360\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">repetida: id encontrado, pulada</text><rect x=\"500\" y=\"40\" width=\"200\" height=\"70\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"600\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">uma transação</text><rect x=\"510\" y=\"64\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">banco: stock - 2, próximo offset</text><text x=\"600\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">início: seek ao offset guardado</text></svg>", "caption": "Dois commits deixam um vão; pôr o registro do progresso na mesma transação que o efeito o fecha, seja como o id do evento, seja como o offset."}
```
