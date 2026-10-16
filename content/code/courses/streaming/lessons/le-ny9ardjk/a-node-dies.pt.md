---
title: Um nó morre enquanto os caixas vendem
version: 1
---

**Quando um líder morre, os controllers percebem que ele parou de mandar heartbeats, escolhem um
novo líder entre a ISR da partição e avisam todos os nós; produtores e consumidores acham o novo
líder pedindo metadados novos e seguem em frente.** A troca inteira leva segundos. O trabalho do
produtor durante esses segundos é guardar as vendas que não conseguiu entregar e mandá-las de
novo, o que ele faz sozinho, dentro do `message.timeout.ms`.

Ache o líder da partição para onde vai a chave `recife`. Toda execução do `acks.py` até aqui a
imprimiu: partição 1. O `describe` diz quem a lidera:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092,localhost:9093 --describe --topic sales
Topic: sales	TopicId: hBMADyrPSHqe-J4ZJkPq1A	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: sales	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 1	Leader: 2	Replicas: 2,3,1	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 2	Leader: 1	Replicas: 3,1,2	Isr: 1,2,3	Elr: 	LastKnownElr: 
```

Nesta execução, a partição 1 é liderada pelo nó 2. O Kafka escolheu os líderes quando o tópico foi
criado, então o seu pode ser outro nó: use o que o seu `describe` nomear.

## Mate o líder, no meio do fluxo

No segundo shell, inicie um produtor que manda cem vendas a cinco por segundo, vinte segundos ao
todo:

```
ubuntu@stream:~/work$ python acks.py --acks all --count 100 --rate 5
```

Alguns segundos depois, no primeiro shell, mate o líder da partição 1 com `-9`, que encerra o
processo sem chance de se despedir, como faria uma queda de energia. Use o número que o seu
`describe` imprimiu:

```
ubuntu@stream:~/work$ ./cluster.sh kill 2    # the leader of partition 1
node 2: killed
```

Quando o produtor termina, o segundo shell mostra:

```
ubuntu@stream:~/work$ python acks.py --acks all --count 100 --rate 5
%6|1791683985.882|FAIL|rdkafka#producer-1| [thrd:localhost:9093/2]: localhost:9093/2: Disconnected: connection closed by peer: receive 0 after POLLIN (after 5938ms in state UP)
%3|1791683985.948|FAIL|rdkafka#producer-1| [thrd:localhost:9093/2]: localhost:9093/2: Connect to ipv4#127.0.0.1:9093 failed: Connection refused (after 0ms in state CONNECT)
%3|1791683986.294|FAIL|rdkafka#producer-1| [thrd:localhost:9093/2]: localhost:9093/2: Connect to ipv4#127.0.0.1:9093 failed: Connection refused (after 0ms in state CONNECT, 1 identical error(s) suppressed)
acks=all: 100 delivered
partition 1: offsets 290 to 389
```

**Cem entregues, nenhuma falha**, nos offsets 290 a 389: cem offsets seguidos para cem vendas. As
três linhas `FAIL` são o cliente percebendo que a conexão com o nó 2 foi fechada e que nada mais
responde em 9093; enquanto procurava o novo líder, ele guardou as vendas na memória e as mandou
quando o achou.

O `describe`, com dois endereços:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092,localhost:9093 --describe --topic sales
[2026-10-10 23:00:01,556] WARN [AdminClient clientId=adminclient-1] Connection to node -2 (localhost/127.0.0.1:9093) could not be established. Node may not be available. (org.apache.kafka.clients.NetworkClient)
Topic: sales	TopicId: hBMADyrPSHqe-J4ZJkPq1A	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: sales	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,3	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 1	Leader: 3	Replicas: 2,3,1	Isr: 1,3	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 2	Leader: 1	Replicas: 3,1,2	Isr: 1,3	Elr: 	LastKnownElr: 
```

A linha `WARN` é a ferramenta tentando primeiro o 9093 e encontrando-o morto; o segundo endereço
respondeu. O nó 2 saiu de todas as ISRs, e a partição 1 agora é liderada pelo nó 3, que estava na
ISR dela.

## O nó volta

Suba-o de novo. Ele tem um log que para onde ele morreu, então começa como seguidor, busca o que
perdeu e volta para a ISR:

```
ubuntu@stream:~/work$ ./cluster.sh start 2
node 2: up on localhost:9093
ubuntu@stream:~/work$ sleep 10; kafka-topics.sh --bootstrap-server localhost:9092,localhost:9093 --describe --topic sales
Topic: sales	TopicId: hBMADyrPSHqe-J4ZJkPq1A	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: sales	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 1	Leader: 3	Replicas: 2,3,1	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 2	Leader: 1	Replicas: 3,1,2	Isr: 1,2,3	Elr: 	LastKnownElr: 
```

Toda ISR está completa de novo, e os líderes não estão onde começaram. **Um nó que volta não pega a
liderança de volta.** Isso deixa a carga desigual: um nó lidera duas partições, e recebe o dobro
das escritas e o dobro das leituras de outro.

O primeiro nó de cada lista `Replicas` é o **líder preferido** da partição, e o Kafka devolve a
liderança a ele de dois jeitos. O broker faz sozinho: com `auto.leader.rebalance.enable=true`, o
padrão, ele confere a cada `leader.imbalance.check.interval.seconds`, 300 por padrão, e devolve os
líderes quando a parte de um nó está desequilibrada em mais de dez por cento. Ou você pede na hora:

```
ubuntu@stream:~/work$ kafka-leader-election.sh --bootstrap-server localhost:9092 --election-type preferred --all-topic-partitions
Successfully completed leader election (PREFERRED) for partitions sales-2, sales-1
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092,localhost:9093 --describe --topic sales
Topic: sales	TopicId: hBMADyrPSHqe-J4ZJkPq1A	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: sales	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 1	Leader: 2	Replicas: 2,3,1	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 2	Leader: 3	Replicas: 3,1,2	Isr: 1,2,3	Elr: 	LastKnownElr: 
```

As partições 1 e 2 tinham líderes diferentes dos preferidos: a partição 2 desde que o nó 3 foi
congelado duas seções atrás, a partição 1 desde que o nó 2 foi morto. As duas voltaram, e cada nó
lidera uma partição de novo.

## O que custou

Nada que tenha sido confirmado. Cem vendas enviadas, cem entregues, em cem offsets seguidos, então
nenhuma foi gravada duas vezes também. O que a falha custou foi **tempo**: por alguns segundos a
partição ficou sem líder, e as vendas enviadas nesses segundos esperaram na memória do produtor. Um
consumidor da partição teria visto a mesma pausa. Esse é o preço da replicação bem feita, e ele se
mede em segundos porque os controllers esperam alguns segundos de silêncio antes de declarar um nó
morto: o bastante para não trocar de líder a cada heartbeat lento, pouco o bastante para que um
caixa nunca perceba.
