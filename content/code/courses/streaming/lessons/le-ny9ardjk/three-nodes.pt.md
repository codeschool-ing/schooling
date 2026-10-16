---
title: Três nós, e um tópico com três cópias
version: 1
---

**Replicação quer dizer que cada partição fica guardada em vários nós ao mesmo tempo, de modo que
perder um nó não perde dado nenhum e não para nada.** O número de cópias é o **fator de
replicação** do tópico, escolhido quando o tópico é criado. Todas as lições até aqui rodaram um nó
e fator de replicação 1, que é uma cópia só num disco só: um nó fora do ar e o tópico some até ele
voltar.

Esta lição roda três. O `cluster.sh` da lição 1 já sabe como: pare o cluster de um nó, crie um novo
com três nós e suba. O `new` apaga os dados do cluster antigo, que neste curso são sempre criados
de novo pela lição que precisa deles:

```
ubuntu@stream:~/work$ ./cluster.sh stop
node 1: stopped
ubuntu@stream:~/work$ ./cluster.sh new 3
new: 3 node(s), cluster id YCLAkZhFSxymvym7xHcgzQ
ubuntu@stream:~/work$ ./cluster.sh start
node 1: up on localhost:9092
node 2: up on localhost:9093
node 3: up on localhost:9094
```

Os três nós escutam em 9092, 9093 e 9094, cada um com o próprio diretório em `~/kafka-data`. São
três processos Java numa máquina só, com pouco menos de 400 MB de memória cada, que é o 1,2 GB que
a lição 1 mediu.

## Um tópico com três cópias

`--replication-factor 3` pede uma cópia de cada partição em três nós; com três nós, isso é todos
eles. `min.insync.replicas` é assunto da seção sobre acks, e fica definido aqui para que o tópico
seja criado como um tópico de produção seria:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3 --replication-factor 3 --config min.insync.replicas=2
Created topic sales.
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092,localhost:9093 --describe --topic sales
Topic: sales	TopicId: hBMADyrPSHqe-J4ZJkPq1A	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: sales	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 1	Leader: 2	Replicas: 2,3,1	Isr: 2,3,1	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 2	Leader: 3	Replicas: 3,1,2	Isr: 3,1,2	Elr: 	LastKnownElr: 
```

O `describe` recebe uma lista de endereços em vez de um só. Qualquer nó responde pelo cluster
inteiro, e com dois endereços uma ferramenta ainda acha o cluster quando o nó que ela consultaria
primeiro é justamente o que caiu, o que acontece de propósito na seção 06.

A linha de cada partição tem três colunas de que esta lição trata:

| coluna | o que ela diz |
|---|---|
| `Leader` | o nó que recebe as escritas da partição e atende as leituras |
| `Replicas` | os nós que guardam uma cópia, **sendo o primeiro o líder preferido** |
| `Isr` | as réplicas que estão em sincronia com o líder neste momento |

`Elr` e `LastKnownElr` são mais novas, e ficam vazias enquanto tudo está saudável; a seção sobre
eleições não limpas as preenche. O Kafka espalha os líderes pelos nós, uma partição cada aqui, de
modo que as escritas de partições diferentes vão para máquinas diferentes. **A liderança é por
partição, não por nó**: nenhum nó é "o líder do cluster" nesse sentido, e todo nó é líder de alguma
coisa.

No disco, cada nó agora tem um diretório para cada partição:

```
ubuntu@stream:~/work$ ls -d ~/kafka-data/node*/log/sales-*
/home/ubuntu/kafka-data/node1/log/sales-0
/home/ubuntu/kafka-data/node1/log/sales-1
/home/ubuntu/kafka-data/node1/log/sales-2
/home/ubuntu/kafka-data/node2/log/sales-0
/home/ubuntu/kafka-data/node2/log/sales-1
/home/ubuntu/kafka-data/node2/log/sales-2
/home/ubuntu/kafka-data/node3/log/sales-0
/home/ubuntu/kafka-data/node3/log/sales-1
/home/ubuntu/kafka-data/node3/log/sales-2
```

Nove diretórios, três partições vezes três cópias. Qual deles é o do líder não aparece no disco;
uma cópia é uma cópia, e qualquer uma pode virar a líder.
