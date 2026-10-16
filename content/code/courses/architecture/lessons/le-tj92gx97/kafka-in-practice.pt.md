---
title: O Kafka na prática
version: 1
---

O Kafka vem com ferramentas de linha de comando para cada uma das suas operações, dentro do contêiner em
`/opt/kafka/bin`. Os nomes são longos e todas precisam do endereço do broker, então defina uma função de
shell curta para o resto da aula, em `~/lab/brokers`:

```sh
kafka() { docker compose exec -T kafka /opt/kafka/bin/kafka-$1.sh --bootstrap-server localhost:9092 "${@:2}"; }
```

`kafka topics …` agora roda `kafka-topics.sh` no contêiner, contra o broker que roda ao lado dela. A função
dura até o shell ser fechado; digite de novo num shell novo.

## Um tópico com três partições

```
ana@vm:~/lab/brokers$ kafka topics --create --topic orders --partitions 3
Created topic orders.
ana@vm:~/lab/brokers$ kafka topics --describe --topic orders
Topic: orders	TopicId: r7mFHLM1RNGzSBSTEfBxgA	PartitionCount: 3	ReplicationFactor: 1	Configs: segment.bytes=1073741824
	Topic: orders	Partition: 0	Leader: 1	Replicas: 1	Isr: 1	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 1	Leader: 1	Replicas: 1	Isr: 1	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 2	Leader: 1	Replicas: 1	Isr: 1	Elr: 	LastKnownElr: 
```

Cada partição tem um **líder**, o broker que recebe as escritas dela, e uma lista de **réplicas**. Com um
broker há um de cada, o broker 1, e `ReplicationFactor: 1` quer dizer que um disco perdido nesse broker é
o tópico perdido; a aula 10 trata de fazer melhor.

## Escrevendo com chaves

O produtor de console lê linhas da entrada. Com `parse.key=true` e `:` como separador, cada linha é uma
chave e um valor; a chave aqui é o cliente que fez o pedido:

```
ana@vm:~/lab/brokers$ printf "ana:order 1\nbruno:order 2\nana:order 3\ncarla:order 4\nbruno:order 5\n" | kafka console-producer --topic orders --property parse.key=true --property key.separator=:
```

## Lendo como grupo

O consumidor de console entra num grupo com `--group`, começa na mensagem mais antiga na primeira vez em
que o grupo lê, e com três propriedades `print` mostra a partição, o offset e a chave de cada mensagem:

```
ana@vm:~/lab/brokers$ kafka console-consumer --topic orders --group email --from-beginning --max-messages 5 --property print.partition=true --property print.offset=true --property print.key=true
Partition:1	Offset:0	ana	order 1
Partition:1	Offset:1	ana	order 3
Partition:2	Offset:0	bruno	order 2
Partition:2	Offset:1	carla	order 4
Partition:2	Offset:2	bruno	order 5
Processed a total of 5 messages
```

Leia a saída à luz do modelo. **Toda mensagem com chave `ana` está na partição 1, e na ordem em que foi
escrita**: o pedido 1 no offset 0, o pedido 3 no offset 1. Bruno e carla caíram na partição 2, onde os três
pedidos deles estão na ordem em que foram mandados. A partição 0 não recebeu nada; com três chaves e três
partições, nada promete uma distribuição igual. E **o consumidor não imprimiu os pedidos na ordem em que
foram produzidos**: imprimiu a partição 1 e depois a 2, porque entre partições não há ordem a manter.

O Kafka guardou a posição do grupo:

```
ana@vm:~/lab/brokers$ kafka consumer-groups --describe --group email

Consumer group 'email' has no active members.

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
email           orders          0          0               0               0               -               -               -
email           orders          1          2               2               0               -               -               -
email           orders          2          3               3               0               -               -               -
```

`CURRENT-OFFSET` é onde o grupo vai ler em seguida em cada partição, `LOG-END-OFFSET` é onde a próxima
mensagem vai ser escrita, e **`LAG` é a diferença**: quantas mensagens o grupo ainda não leu. Tudo zero,
porque o grupo leu tudo. O lag é o número a vigiar em qualquer consumidor: estável ou caindo, os
consumidores acompanham; crescendo, não acompanham, e a mensagem não lida mais antiga envelhece a cada
minuto.
