---
title: Transações, e leitores que só veem o que foi confirmado
version: 1
---

**Uma transação do Kafka faz várias gravações, em quantas partições e tópicos forem, ficarem visíveis
juntas ou nenhuma.** O produtor abre uma transação, grava, e depois a confirma ou aborta. As gravações
chegam aos logs na hora, num caso ou no outro; o que o commit acrescenta é um **marcador** em cada
partição dizendo que a transação terminou, e como. Um consumidor que pede para ler só dados
confirmados segura a leitura até ver o marcador, e descarta o que um abort marcou.

Essa última frase corrige a ideia comum, em que uma gravação abortada nunca é gravada. Ela é gravada,
ocupa os seus offsets e fica no log até a retenção removê-la. Se alguém a vê é uma propriedade do
**leitor**, escolhida com `isolation.level`:

| `isolation.level` | o que o consumidor recebe |
|---|---|
| `read_uncommitted` | tudo o que está no log, confirmado, abortado ou ainda aberto |
| `read_committed` | transações confirmadas, e mensagens gravadas fora de qualquer transação |

Os consumidores Java e Python têm padrões opostos: o cliente Python, pela librdkafka, usa
`read_committed`, enquanto o cliente Java e o consumidor de console construído sobre ele usam
`read_uncommitted`. A execução abaixo usa o consumidor de console, então o padrão que você vê ali é o
do Java.

## Um produtor com transactional id

Um produtor transacional precisa de um **`transactional.id`**, um nome que fica igual entre
reinícios. É assim que o cluster reconhece o mesmo produtor voltando: no `init_transactions` a nova
instância recebe o id de produtor da antiga com uma época maior, qualquer transação que a antiga
deixou aberta é abortada, e a antiga, se por acaso ainda estiver viva, é **cercada** (fenced): recusada
na próxima gravação. Este programa grava duas transações de cinco vendas; a primeira é confirmada e a
segunda abortada. Salve como `~/work/txn.py`:

```python
"""txn.py: two transactions of five sales each; the first is committed, the second aborted."""
import json

from confluent_kafka import Producer

producer = Producer({"bootstrap.servers": "localhost:9092", "transactional.id": "txn-demo"})
producer.init_transactions()

for t, outcome in ((1, "committed"), (2, "aborted")):
    producer.begin_transaction()
    for n in range(1, 6):
        sale = {"sale": f"txn-{t}-{n}", "shop": "olinda", "book": "bk-03", "qty": 1, "cents": 2990}
        producer.produce("ledger", key="olinda", value=json.dumps(sale))
    producer.flush()
    if outcome == "committed":
        producer.commit_transaction()
    else:
        producer.abort_transaction()
    print(f"transaction {t}: 5 sales written, {outcome}")
```

O `flush` antes do abort está ali para a demonstração: garante que as cinco vendas abortadas chegaram
mesmo ao log, para você conseguir vê-las. Um programa de verdade aborta porque algo falhou, e o que
tinha sido enviado até ali está no log do mesmo jeito.

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic ledger --partitions 1
Created topic ledger.
ubuntu@stream:~/work$ python txn.py
transaction 1: 5 sales written, committed
transaction 2: 5 sales written, aborted
```

## Dois leitores do mesmo log

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic ledger --from-beginning --timeout-ms 5000 2>/dev/null
{"sale": "txn-1-1", "shop": "olinda", "book": "bk-03", "qty": 1, "cents": 2990}
{"sale": "txn-1-2", "shop": "olinda", "book": "bk-03", "qty": 1, "cents": 2990}
{"sale": "txn-1-3", "shop": "olinda", "book": "bk-03", "qty": 1, "cents": 2990}
{"sale": "txn-1-4", "shop": "olinda", "book": "bk-03", "qty": 1, "cents": 2990}
{"sale": "txn-1-5", "shop": "olinda", "book": "bk-03", "qty": 1, "cents": 2990}
{"sale": "txn-2-1", "shop": "olinda", "book": "bk-03", "qty": 1, "cents": 2990}
{"sale": "txn-2-2", "shop": "olinda", "book": "bk-03", "qty": 1, "cents": 2990}
{"sale": "txn-2-3", "shop": "olinda", "book": "bk-03", "qty": 1, "cents": 2990}
{"sale": "txn-2-4", "shop": "olinda", "book": "bk-03", "qty": 1, "cents": 2990}
{"sale": "txn-2-5", "shop": "olinda", "book": "bk-03", "qty": 1, "cents": 2990}
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic ledger --from-beginning --timeout-ms 5000 --isolation-level read_committed 2>/dev/null
{"sale": "txn-1-1", "shop": "olinda", "book": "bk-03", "qty": 1, "cents": 2990}
{"sale": "txn-1-2", "shop": "olinda", "book": "bk-03", "qty": 1, "cents": 2990}
{"sale": "txn-1-3", "shop": "olinda", "book": "bk-03", "qty": 1, "cents": 2990}
{"sale": "txn-1-4", "shop": "olinda", "book": "bk-03", "qty": 1, "cents": 2990}
{"sale": "txn-1-5", "shop": "olinda", "book": "bk-03", "qty": 1, "cents": 2990}
ubuntu@stream:~/work$ kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic ledger
ledger:0:12
ubuntu@stream:~/work$ kafka-dump-log.sh --files ~/kafka-data/node1/log/ledger-0/00000000000000000000.log
Dumping /home/ubuntu/kafka-data/node1/log/ledger-0/00000000000000000000.log
Log starting offset: 0
baseOffset: 0 lastOffset: 4 count: 5 baseSequence: 0 lastSequence: 4 producerId: 1 producerEpoch: 0 partitionLeaderEpoch: 0 isTransactional: true isControl: false deleteHorizonMs: OptionalLong.empty position: 0 CreateTime: 1792111568970 size: 531 magic: 2 compresscodec: none crc: 15249745 isvalid: true
baseOffset: 5 lastOffset: 5 count: 1 baseSequence: -1 lastSequence: -1 producerId: 1 producerEpoch: 0 partitionLeaderEpoch: 0 isTransactional: true isControl: true deleteHorizonMs: OptionalLong.empty position: 531 CreateTime: 1792111569014 size: 78 magic: 2 compresscodec: none crc: 1596816661 isvalid: true
baseOffset: 6 lastOffset: 10 count: 5 baseSequence: 5 lastSequence: 9 producerId: 1 producerEpoch: 0 partitionLeaderEpoch: 0 isTransactional: true isControl: false deleteHorizonMs: OptionalLong.empty position: 609 CreateTime: 1792111568999 size: 531 magic: 2 compresscodec: none crc: 1806690553 isvalid: true
baseOffset: 11 lastOffset: 11 count: 1 baseSequence: -1 lastSequence: -1 producerId: 1 producerEpoch: 0 partitionLeaderEpoch: 0 isTransactional: true isControl: true deleteHorizonMs: OptionalLong.empty position: 1140 CreateTime: 1792111569035 size: 78 magic: 2 compresscodec: none crc: 2943571995 isvalid: true
```

O consumidor de console lê `read_uncommitted` a não ser que alguém diga o contrário, e imprime as dez
vendas, as abortadas inclusive. Com `--isolation-level read_committed` o mesmo comando imprime as
cinco da transação confirmada e **as cinco abortadas não estão lá**.

Os offsets mostram onde as transações deixaram as marcas. O offset final da partição é 12 para dez
vendas, e o dump mostra por quê: os offsets 5 e 11 são lotes com **`isControl: true`**, os marcadores,
o primeiro dizendo commit e o segundo abort. As vendas abortadas estão em disco nos offsets 6 a 10 com
o mesmo id de produtor das confirmadas. Um leitor que não pede dados confirmados as lê como se nada
tivesse acontecido, e é por isso que um consumidor de um tópico transacional precisa escolher o nível
de isolamento de propósito.
