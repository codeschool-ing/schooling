---
title: Em que partição cai uma chave
version: 1
---

**Um produtor manda uma mensagem com chave para a partição indicada pelo hash da chave, e toda
mensagem com aquela chave vai para a mesma.** É a regra que a lição 2 pediu: uma chave, um log, para
que os eventos de uma loja fiquem na ordem em que a loja os escreveu. Mensagens sem chave são
espalhadas pelas partições, e não mantêm ordem nenhuma entre si.

A crença comum é que o broker faz isso. Não faz. **O produtor escolhe a partição, na biblioteca
cliente, antes de a mensagem sair do programa**, e o broker guarda o que recebe. Isso põe a função de
hash no cliente, e clientes diferentes trazem funções diferentes.

Um produtor pequeno deixa isso visível. Ele manda os pares `KEY=VALUE` que receber e imprime a
partição e o offset em que cada um foi guardado, que o broker informa assim que tem a mensagem. Salve
isto como `~/work/keys.py`:

```schooling-example
{
  "language": "python",
  "file": "keys.py",
  "parts": [
    {
      "code": "\"\"\"keys.py: send KEY=VALUE messages to a topic and say where each one landed.\n\n    python keys.py [--partitioner NAME] TOPIC KEY=VALUE...\n\nA VALUE of - sends a message with no value at all.\n\"\"\"\nimport argparse\n\nfrom confluent_kafka import Producer\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"--partitioner\")\nargs.add_argument(\"topic\")\nargs.add_argument(\"pairs\", nargs=\"+\")\nargs = args.parse_args()\n",
      "note": "O que ele faz. Manda os pares que você der, então o mesmo programa serve a esta seção e à de compactação."
    },
    {
      "code": "config = {\"bootstrap.servers\": \"localhost:9092\"}\nif args.partitioner:\n    config[\"partitioner\"] = args.partitioner\nproducer = Producer(config)\n",
      "note": "O produtor, e a única configuração de que esta seção trata. **Se ela fica de fora, o cliente usa o próprio particionador padrão.**"
    },
    {
      "code": "\ndef landed(err, msg):\n    if err:\n        print(f\"{msg.key().decode()}: {err}\")\n    else:\n        print(f\"{msg.key().decode():<12} partition {msg.partition()}  offset {msg.offset()}\")\n",
      "note": "O relatório de entrega. O cliente o chama uma vez por mensagem, depois que o broker respondeu, com a partição e o offset que a mensagem recebeu."
    },
    {
      "code": "\nfor pair in args.pairs:\n    key, value = pair.split(\"=\", 1)\n    producer.produce(args.topic, key=key, value=None if value == \"-\" else value,\n                     on_delivery=landed)\nproducer.flush()",
      "note": "Uma mensagem por par. O `flush` espera todos os relatórios antes de o programa terminar."
    }
  ]
}
```

Crie um tópico de três partições e mande uma mensagem por loja:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic shops --partitions 3
Created topic shops.
ubuntu@stream:~/work$ python keys.py shops recife=py olinda=py caruaru=py natal=py joao-pessoa=py
recife       partition 1  offset 0
olinda       partition 1  offset 1
natal        partition 1  offset 2
joao-pessoa  partition 1  offset 3
caruaru      partition 0  offset 0
```

Quatro das cinco lojas caíram na partição 1, Caruaru na partição 0, e **nada na partição 2**. Isso
não é defeito: cinco chaves distribuídas por hash em três baldes é uma amostra pequena, e uma divisão
desigual é o que uma amostra pequena dá. Mas quer dizer que um tópico de três partições é, para essas
chaves, um tópico de duas. Os offsets contam dentro de cada partição, e é por isso que a mensagem de
Caruaru está no offset 0 enquanto a de Natal está no 2.

**A mesma chave vai para a mesma partição enquanto o número de partições não mudar**, e essa é a
promessa inteira. Quem fez o hash foi o cliente: o cliente Python é construído sobre o librdkafka,
uma biblioteca em C, e o particionador padrão dele, `consistent_random`, calcula um CRC32 da chave.

## As ferramentas do próprio Kafka fazem outro hash

Agora mande as mesmas cinco chaves com o console producer do Kafka, que é escrito em Java, e leia o
tópico de volta com a partição e a chave de cada mensagem impressas. `parse.key=true` diz ao produtor
que cada linha é uma chave, um `:` e um valor:

```
ubuntu@stream:~/work$ printf "recife:java\nolinda:java\ncaruaru:java\nnatal:java\njoao-pessoa:java\n" | kafka-console-producer.sh --bootstrap-server localhost:9092 --topic shops --reader-property parse.key=true --reader-property key.separator=:
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic shops --from-beginning --max-messages 10 --formatter-property print.partition=true --formatter-property print.key=true
The consumer rebalance protocol (KIP-848) is production-ready! Set group.protocol=consumer to try it out. See https://kafka.apache.org/documentation/#consumer_rebalance_protocol
Partition:1	recife	py
Partition:1	olinda	py
Partition:1	natal	py
Partition:1	joao-pessoa	py
Partition:1	caruaru	java
Partition:1	natal	java
Partition:2	recife	java
Partition:0	caruaru	py
Partition:0	olinda	java
Partition:0	joao-pessoa	java
Processed a total of 10 messages
```

Leia a saída do consumidor pela chave. Recife, que o cliente Python pôs na partição 1, foi para a
partição **2** pelo Java; Olinda e João Pessoa foram para a partição 0 em vez da 1. Só Caruaru e Natal
coincidem, e a coincidência é sorte. **O cliente Java faz o hash das chaves com murmur2**, que é uma
função diferente do CRC32, então a mesma chave dá outro número.

Isso importa assim que dois programas em duas linguagens escrevem no mesmo tópico. Um caixa escrito
em Python e um serviço de retaguarda escrito em Java, os dois escrevendo as mudanças de estoque do
Recife, as poriam em duas partições, e a lição 2 mostrou o que ler os eventos de uma chave fora de
ordem faz. O librdkafka já traz a correção: `murmur2_random`, uma cópia do particionador do Java, que
é o que a opção `--partitioner` do `keys.py` configura:

```
ubuntu@stream:~/work$ python keys.py --partitioner murmur2_random shops recife=m2 olinda=m2 caruaru=m2 natal=m2 joao-pessoa=m2
caruaru      partition 1  offset 6
natal        partition 1  offset 7
recife       partition 2  offset 1
olinda       partition 0  offset 3
joao-pessoa  partition 0  offset 4
```

Recife na 2, Olinda e João Pessoa na 0, Caruaru e Natal na 1: exatamente onde o Java as pôs.
**Quando clientes de mais de uma linguagem escrevem no mesmo tópico, configure `partitioner` como
`murmur2_random` em todo cliente baseado no librdkafka**, entre eles o de Python, o de Go e o de .NET.
A parte `_random` é sobre mensagens sem chave, que ele espalha ao acaso. O resto deste curso mantém o
padrão onde só Python escreve, e o produtor da lição 4 usa `murmur2_random`, para que as vendas dele
cheguem às três partições.
