---
title: O produtor idempotente
version: 1
---

**Um produtor idempotente numera as mensagens, e o broker recusa um número que já gravou, então uma
nova tentativa depois de uma confirmação perdida não consegue gravar uma venda duas vezes.** Ele fecha
o primeiro dos dois vãos, o que fica entre uma gravação e a confirmação dela, e custa quase nada:
dois números em cada lote, que o broker guarda por partição.

O mecanismo tem duas partes:

- **um id de produtor**: quando um produtor idempotente começa, o cluster dá a ele um número próprio,
  o PID, com uma **época** ao lado;
- **um número de sequência** para cada lote, por partição, começando em 0 e crescendo pelo número de
  mensagens do lote.

O líder lembra os últimos números de sequência que aceitou de cada PID em cada partição. Um lote
reenviado chega com uma sequência que ele já gravou: o líder responde *sucesso*, porque os dados estão
lá, e não grava de novo. Um lote que chega com uma sequência **à frente** da esperada quer dizer que
algum se perdeu no meio, e é recusado, então a ordem dentro de uma partição se mantém mesmo com vários
lotes em trânsito.

## Está ligado?

No cliente Java, a idempotência vem ligada por padrão desde o Kafka 3.0. O cliente Python é um
invólucro sobre a librdkafka, que tem os próprios padrões, e **na librdkafka `enable.idempotence` é
`false` a não ser que você mude**. O log do broker mostra que tipo de produtor gravou um lote. Todo
lote em disco carrega o id do produtor e a primeira sequência do lote, e um produtor sem idempotência
escreve `-1` nos dois. O `tills.py` não define nada:

```
ubuntu@stream:~/work$ kafka-dump-log.sh --files ~/kafka-data/node1/log/sales-0/00000000000000000000.log | head -4
Dumping /home/ubuntu/kafka-data/node1/log/sales-0/00000000000000000000.log
Log starting offset: 0
baseOffset: 0 lastOffset: 49 count: 50 baseSequence: -1 lastSequence: -1 producerId: -1 producerEpoch: -1 partitionLeaderEpoch: 0 isTransactional: false isControl: false deleteHorizonMs: OptionalLong.empty position: 0 CreateTime: 1792111518493 size: 6777 magic: 2 compresscodec: none crc: 855803453 isvalid: true
```

Sem `--print-data-log` a ferramenta imprime uma linha por lote, e o `tills.py` mandou as cinquenta
vendas num lote só. **`producerId: -1` e `baseSequence: -1`**: o broker não tinha como distinguir uma
nova tentativa desse lote de um lote novo.

Agora cinco vendas de um produtor com uma configuração mudada. Salve como `~/work/idempotent.py`:

```python
"""idempotent.py: five sales from a producer with idempotence switched on."""
import json

from confluent_kafka import Producer

producer = Producer({"bootstrap.servers": "localhost:9092", "enable.idempotence": True})
for n in range(1, 6):
    sale = {"sale": f"idm-{n:06d}", "shop": "recife", "book": "bk-01", "qty": 1, "cents": 3990}
    producer.produce("sales", key="recife", value=json.dumps(sale))
producer.flush()
print("sent 5 sales with enable.idempotence=true")
```

```
ubuntu@stream:~/work$ python idempotent.py
%4|1792111564.419|GETPID|rdkafka#producer-1| [thrd:main]: Failed to acquire idempotence PID from broker localhost:9092/1: Broker: Coordinator load in progress: retrying
sent 5 sales with enable.idempotence=true
ubuntu@stream:~/work$ kafka-dump-log.sh --files ~/kafka-data/node1/log/sales-0/00000000000000000000.log | tail -1
baseOffset: 50 lastOffset: 54 count: 5 baseSequence: 0 lastSequence: 4 producerId: 0 producerEpoch: 0 partitionLeaderEpoch: 0 isTransactional: false isControl: false deleteHorizonMs: OptionalLong.empty position: 6777 CreateTime: 1792111563909 size: 546 magic: 2 compresscodec: none crc: 3146156970 isvalid: true
```

A primeira linha é o cliente esperando enquanto um cluster novo prepara o tópico interno onde guarda
os ids de produtor; ele tenta de novo sozinho, e a linha é um aviso, não uma falha. O lote que ele
gravou fica nos offsets 50 a 54 com **`producerId: 0`, `producerEpoch: 0` e sequências de 0 a 4**.
Uma nova tentativa desse lote chegaria com o mesmo id de produtor e sequência base 0, e o líder
responderia sucesso sem gravar de novo.

## O que muda, e o que não muda

Ligar a idempotência também define outras três coisas, e a librdkafka recusa uma configuração que as
contradiga: **`acks=all`**, porque só vale conferir uma sequência numa gravação segura; novas
tentativas sem limite dentro de `message.timeout.ms`; e no máximo cinco requisições em trânsito por
conexão, o número para o qual o broker guarda sequências.

O que ela não faz é tão importante quanto:

- **Ela vale por sessão do produtor.** Um programa que cai e começa de novo recebe um PID novo, então
  uma venda que ele reenvia depois do reinício é uma mensagem nova para o broker. A idempotência
  protege uma nova tentativa dentro de uma execução, não um reenvio de um programa que esqueceu o que
  tinha mandado.
- **Ela vale por partição.** As sequências são contadas por partição; nada liga uma gravação numa
  partição a uma gravação em outra.
- **Ela não faz nada pelo vão do consumidor.** Um consumidor que processa duas vezes continua
  processando duas vezes.

Então ligue-a em todo produtor, a não ser que haja um motivo para não ligar: não há custo que valha
pesar. O reinício e o consumidor precisam das duas próximas seções.
