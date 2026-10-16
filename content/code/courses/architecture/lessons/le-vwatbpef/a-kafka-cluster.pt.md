---
title: Um cluster Kafka que perde nós
version: 1
---

**Esta é uma das três aulas pesadas de que a aula 1 avisou**: três nós Kafka rodam ao mesmo tempo, cada
um na máquina virtual Java. Pare antes o laboratório de replicação (`docker compose down -v` em
`~/lab/replication`); o `docker ps` não deve listar nada antes de você começar.

A aula 6 rodou o Kafka num nó só, com `ReplicationFactor: 1`. Aqui ele roda em três, e cada partição
ganha três cópias. Ele fica em `~/lab/kafka-cluster`:

```sh
mkdir -p ~/lab/kafka-cluster && cd ~/lab/kafka-cluster
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "x-kafka: &kafka\n  image: apache/kafka:4.0.0\n  environment: &env\n    CLUSTER_ID: q1Sh-9_ISia_zwGINzRvyQ\n    KAFKA_PROCESS_ROLES: broker,controller\n    KAFKA_LISTENERS: PLAINTEXT://:9092,CONTROLLER://:9093\n    KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT\n    KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER\n    KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT", "note": "Três nós Kafka, cada um broker e controlador ao mesmo tempo, como na aula 6 mas três vezes. Tudo o que eles compartilham é escrito uma vez, em `x-kafka`, e cada nó acrescenta o seu id e o seu próprio endereço. `CLUSTER_ID` tem de ser o mesmo nos três: é como um nó sabe que está entrando neste cluster e não começando outro."}, {"code": "    KAFKA_CONTROLLER_QUORUM_VOTERS: 1@kafka-1:9093,2@kafka-2:9093,3@kafka-3:9093", "note": "Os controladores que votam nos metadados do cluster: quem lidera cada partição, que réplicas estão em dia. Três votantes, então dois deles são maioria."}, {"code": "    KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 3\n    KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 3\n    KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 2\n    KAFKA_HEAP_OPTS: \"-Xms384m -Xmx384m\"\nservices:\n  kafka-1:\n    <<: *kafka\n    hostname: kafka-1\n    environment:\n      <<: *env\n      KAFKA_NODE_ID: 1\n      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka-1:9092\n  kafka-2:\n    <<: *kafka\n    hostname: kafka-2\n    environment:\n      <<: *env\n      KAFKA_NODE_ID: 2\n      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka-2:9092\n  kafka-3:\n    <<: *kafka\n    hostname: kafka-3\n    environment:\n      <<: *env\n      KAFKA_NODE_ID: 3\n      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka-3:9092", "note": "Os tópicos internos do próprio Kafka também ganham três cópias; os padrões supõem um nó só."}]}
```

Suba, e dê meio minuto para os três nós se acharem. Depois, a mesma função de shell da aula 6, apontada
para o nó 1:

```sh
docker compose up -d
kafka() { docker compose exec -T kafka-1 /opt/kafka/bin/kafka-$1.sh --bootstrap-server kafka-1:9092 "${@:2}"; }
```

Primeiro os controladores. Eles fazem uma eleição entre si, e um deles lidera os metadados:

```
ana@vm:~/lab/kafka-cluster$ kafka metadata-quorum describe --status
ClusterId:              q1Sh-9_ISia_zwGINzRvyQ
LeaderId:               2
LeaderEpoch:            1
HighWatermark:          66
MaxFollowerLag:         0
MaxFollowerLagTimeMs:   24
CurrentVoters:          [{"id": 1, "directoryId": null, "endpoints": ["CONTROLLER://kafka-1:9093"]}, {"id": 2, "directoryId": null, "endpoints": ["CONTROLLER://kafka-2:9093"]}, {"id": 3, "directoryId": null, "endpoints": ["CONTROLLER://kafka-3:9093"]}]
CurrentObservers:       []
```

## Um tópico com três cópias de tudo

Crie `orders` com três partições e três réplicas cada, e exija **duas réplicas em dia** para uma escrita
valer:

```
ana@vm:~/lab/kafka-cluster$ kafka topics --create --topic orders --partitions 3 --replication-factor 3 --config min.insync.replicas=2
Created topic orders.
ana@vm:~/lab/kafka-cluster$ kafka topics --describe --topic orders
Topic: orders	TopicId: w_H_w3F-S5qbT7PtD_vEyw	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: orders	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 1	Leader: 2	Replicas: 2,3,1	Isr: 2,3,1	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 2	Leader: 3	Replicas: 3,1,2	Isr: 3,1,2	Elr: 	LastKnownElr: 
```

Cada partição tem um líder diferente, então as escritas se espalham pelos três nós, e cada uma tem os
três nós como réplicas. `Isr` é a lista de **réplicas em dia** (*in-sync replicas*): as cópias que estão
atualizadas em relação ao líder. Um produtor que pede `acks=all` só ouve que a mensagem foi gravada
quando toda réplica dessa lista a tem, e `min.insync.replicas=2` recusa a escrita se a lista tiver menos
de duas.

## Parando um nó

Pare o nó 2 e olhe de novo, depois grave três pedidos:

```
ana@vm:~/lab/kafka-cluster$ docker compose stop kafka-2
 Container kafka-cluster-kafka-2-1 Stopping 
 Container kafka-cluster-kafka-2-1 Stopped 
ana@vm:~/lab/kafka-cluster$ kafka topics --describe --topic orders
Topic: orders	TopicId: w_H_w3F-S5qbT7PtD_vEyw	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: orders	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,3	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 1	Leader: 3	Replicas: 2,3,1	Isr: 3,1	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 2	Leader: 3	Replicas: 3,1,2	Isr: 3,1	Elr: 	LastKnownElr: 
ana@vm:~/lab/kafka-cluster$ printf "o-1\no-2\no-3\n" | kafka console-producer --topic orders --producer-property acks=all
```

O nó 2 era o líder da partição 1, e a partição 1 agora tem um líder novo, o nó 3. O nó 2 saiu de todo `Isr`,
que caiu para dois em todo lugar. E as três escritas passaram, porque ainda existem duas cópias de cada.
**Um nó perdido, nada perdido, nada recusado.**

## Parando um segundo

```
ana@vm:~/lab/kafka-cluster$ docker compose stop kafka-3
 Container kafka-cluster-kafka-3-1 Stopping 
 Container kafka-cluster-kafka-3-1 Stopped 
ana@vm:~/lab/kafka-cluster$ kafka topics --describe --topic orders
Topic: orders	TopicId: w_H_w3F-S5qbT7PtD_vEyw	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: orders	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 1	Leader: 1	Replicas: 2,3,1	Isr: 1	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 2	Leader: 1	Replicas: 3,1,2	Isr: 1	Elr: 	LastKnownElr: 
ana@vm:~/lab/kafka-cluster$ printf "o-4\n" | kafka console-producer --topic orders --producer-property acks=all
[2026-10-10 06:16:57,313] WARN [Producer clientId=console-producer] Got error produce response with correlation id 5 on topic-partition orders-1, retrying (2 attempts left). Error: NOT_ENOUGH_REPLICAS (org.apache.kafka.clients.producer.internals.Sender)
[2026-10-10 06:16:57,410] WARN [Producer clientId=console-producer] Got error produce response with correlation id 6 on topic-partition orders-1, retrying (1 attempts left). Error: NOT_ENOUGH_REPLICAS (org.apache.kafka.clients.producer.internals.Sender)
[2026-10-10 06:16:57,618] WARN [Producer clientId=console-producer] Got error produce response with correlation id 7 on topic-partition orders-1, retrying (0 attempts left). Error: NOT_ENOUGH_REPLICAS (org.apache.kafka.clients.producer.internals.Sender)
[2026-10-10 06:16:58,097] ERROR Error when sending message to topic orders with key: null, value: 3 bytes with error: (org.apache.kafka.clients.producer.internals.ErrorLoggingCallback)
org.apache.kafka.common.errors.NotEnoughReplicasException: Messages are rejected since there are fewer in-sync replicas than required.
```

Agora cada partição tem uma réplica em dia, abaixo do mínimo de duas, e o produtor é recusado com
`NOT_ENOUGH_REPLICAS`, tenta de novo, e desiste. **O Kafka está escolhendo consistência**, no sentido da
aula 8: prefere recusar uma escrita a aceitar uma que existe num disco só. O mesmo produtor com
`acks=1`, que pergunta só ao líder, é aceito sem uma palavra:

```
ana@vm:~/lab/kafka-cluster$ printf "o-5\n" | kafka console-producer --topic orders --producer-property acks=1
```

Essa mensagem existe só no nó 1, e se o disco do nó 1 falhasse agora ela sumiria depois de o produtor
ouvir que foi gravada. `acks=all` com `min.insync.replicas=2` e três réplicas é a configuração comum em
produção exatamente por isso: sobrevive a uma falha sem recusar nada, e recusa em vez de mentir depois de
duas.

As partições do Kafka, aliás, não usam voto de maioria para os dados. Usam a lista de réplicas em dia,
então uma partição com três réplicas poderia continuar escrevendo com duas, ou com uma se você
permitisse. A maioria da seção anterior é o que os **controladores** usam, entre si, para concordar sobre
quem lidera cada partição.

## Trazendo de volta

Suba os dois nós de novo. Eles voltam, se atualizam a partir dos líderes, e retornam a todo `Isr`.
Depois leia o tópico desde o começo:

```
ana@vm:~/lab/kafka-cluster$ docker compose start kafka-2 kafka-3
 Container kafka-cluster-kafka-2-1 Starting 
 Container kafka-cluster-kafka-3-1 Starting 
 Container kafka-cluster-kafka-2-1 Started 
 Container kafka-cluster-kafka-3-1 Started 
ana@vm:~/lab/kafka-cluster$ sleep 15; kafka topics --describe --topic orders
Topic: orders	TopicId: w_H_w3F-S5qbT7PtD_vEyw	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: orders	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 1	Leader: 1	Replicas: 2,3,1	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 2	Leader: 1	Replicas: 3,1,2	Isr: 1,2,3	Elr: 	LastKnownElr: 
ana@vm:~/lab/kafka-cluster$ kafka console-consumer --topic orders --from-beginning --timeout-ms 20000 2>/dev/null | sort
o-1
o-2
o-3
o-5
```

`o-1` a `o-3` e `o-5` estão lá; `o-4`, a escrita recusada, não está, e o produtor dela ouviu isso. Nada
que foi confirmado se perdeu. Pare o cluster antes da próxima seção:

```sh
docker compose down -v
```
