---
title: Exatamente uma vez dentro do Kafka: ler, escrever e confirmar numa transação
version: 1
---

**Um programa cuja entrada e saída são tópicos do Kafka pode ser exatamente uma vez, porque o offset
que ele confirma pode ser gravado dentro da mesma transação que a saída.** O commit do consumidor é uma
gravação em `__consumer_offsets`, um tópico comum, e `send_offsets_to_transaction` o acrescenta à
transação do produtor. Então a saída e o registro de tê-la produzido são confirmados juntos, ou
abortados juntos, e uma queda em qualquer ponto deixa um de dois estados: o lote feito e lembrado, ou
nenhum dos dois.

É o padrão que o Kafka Streams roda com `processing.guarantee=exactly_once_v2`, e o sink Kafka do
Flink no modo exatamente uma vez; a lição 13 apresenta os dois. Aqui está ele à mão, em Python.

## Uma cópia que sobrevive a uma queda

O trabalho é pequeno de propósito: ler `sales` e copiar toda venda de 100,00 ou mais para um tópico
`big-sales`. Cada lote de até dez vendas é uma transação. Salve como `~/work/eos_copy.py`:

```schooling-example
{
  "language": "python",
  "file": "eos_copy.py",
  "parts": [
    {
      "code": "\"\"\"eos_copy.py: copy the sales of 100.00 or more from `sales` to `big-sales`, exactly once.\n\n    python eos_copy.py [--crash-after N]\n\"\"\"\nimport argparse\nimport json\nimport os\n\nfrom confluent_kafka import Consumer, Producer\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"--crash-after\", type=int, default=0)\nargs = args.parse_args()\n",
      "note": "`--crash-after N` encerra o processo de repente depois de ler N vendas, no meio de uma transação."
    },
    {
      "code": "consumer = Consumer({\"bootstrap.servers\": \"localhost:9092\",\n                     \"group.id\": \"eos-copy\",\n                     \"auto.offset.reset\": \"earliest\",\n                     \"enable.auto.commit\": False,\n                     \"isolation.level\": \"read_committed\",\n                     \"session.timeout.ms\": 6000})",
      "note": "**O consumidor nunca confirma sozinho**: o commit automático está desligado e o programa nunca chama `commit`. Ele lê com `read_committed`, então não copiaria nada que uma execução anterior abortou, se a entrada dele fosse também gravada em transações."
    },
    {
      "code": "producer = Producer({\"bootstrap.servers\": \"localhost:9092\",\n                     \"transactional.id\": \"eos-copy\"})\nproducer.init_transactions()\nconsumer.subscribe([\"sales\"])\n",
      "note": "O `transactional.id` é fixo, então uma cópia reiniciada é reconhecida como o mesmo produtor. **`init_transactions` aborta o que a execução que caiu deixou aberto.**"
    },
    {
      "code": "read = copied = 0\nwhile batch := consumer.consume(num_messages=10, timeout=15):\n    producer.begin_transaction()\n    for msg in batch:\n        read += 1\n        if json.loads(msg.value())[\"cents\"] >= 10000:\n            producer.produce(\"big-sales\", key=msg.key(), value=msg.value())\n            copied += 1",
      "note": "Uma transação por lote. As cópias saem como chamadas comuns de `produce`; chegam ao log na hora, e só ficam visíveis para um leitor `read_committed` no commit."
    },
    {
      "code": "        if read == args.crash_after:\n            producer.flush()\n            print(f\"crashed after reading {read} sales, {copied} of them copied\", flush=True)\n            os._exit(1)",
      "note": "A queda faz flush antes, para que as cópias do lote interrompido estejam mesmo no log e o abort tenha o que esconder."
    },
    {
      "code": "    producer.send_offsets_to_transaction(consumer.position(consumer.assignment()),\n                                         consumer.consumer_group_metadata())\n    producer.commit_transaction()\nconsumer.close()\nprint(f\"read {read} sales, copied {copied}\")",
      "note": "**A posição do consumidor entra na transação do produtor**, sob o grupo do consumidor. Confirmar a transação confirma as cópias e os offsets num passo só."
    }
  ]
}
```

O tópico `sales` das seções anteriores ainda tem as cinquenta vendas, e as cinco do `idempotent.py`.
Crie o tópico de saída, derrube a cópia depois de 25 vendas e rode de novo:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic big-sales --partitions 1
Created topic big-sales.
ubuntu@stream:~/work$ python eos_copy.py --crash-after 25
crashed after reading 25 sales, 13 of them copied
ubuntu@stream:~/work$ python eos_copy.py
%4|1792111588.861|GETPID|rdkafka#producer-2| [thrd:main]: Failed to acquire transactional PID from broker TxnCoordinator/1: Broker: Producer attempted to update a transaction while another concurrent operation on the same transaction was ongoing: retrying
read 35 sales, copied 9
```

A execução que caiu leu 25 vendas e copiou 13 das grandes: 11 nos dois lotes que confirmou, e 2 no
terceiro, que tinha enviado mas não confirmado. O reinício imprimiu o cliente tentando de novo
enquanto o coordenador terminava de abortar aquela transação aberta, depois começou do offset
confirmado com o segundo lote, 20, e leu as 35 vendas restantes, copiando 9.

Agora conte a saída dos dois jeitos, e a origem:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic big-sales --from-beginning --timeout-ms 5000 --isolation-level read_committed 2>/dev/null | wc -l
20
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic big-sales --from-beginning --timeout-ms 5000 2>/dev/null | wc -l
22
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales --from-beginning --timeout-ms 5000 2>/dev/null | jq -c "select(.cents >= 10000)" | wc -l
20
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group eos-copy 2>/dev/null

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
eos-copy        sales           0          55              55              0               -               -               -
```

**Um leitor `read_committed` vê 20 cópias, e a origem tem exatamente 20 vendas grandes.** Nada
perdido, nada duplicado. O log em si tem 22 registros: as duas cópias do lote abortado continuam nele,
e um leitor `read_uncommitted` as conta. O offset confirmado do grupo é 55, o fim de `sales`, e ele
chegou lá só pelas transações: o programa nunca chamou `commit`.

Então a garantia tem um formato preciso. **Exatamente uma vez vale para leitores que leem dados
confirmados**, e vale porque a saída e os offsets andaram juntos. Um consumidor lá na frente deixado
no padrão do consumidor de console veria as duas cópias abortadas, que é o jeito mais comum de uma
equipe descobrir que exatamente uma vez é uma propriedade da cadeia inteira e não de um programa.
