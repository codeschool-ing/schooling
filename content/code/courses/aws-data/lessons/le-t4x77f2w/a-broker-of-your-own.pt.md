---
title: Um broker Kafka só seu
version: 1
---

**O moto não tem Kafka dentro, então esta seção usa o de verdade.** O Apache Kafka é código aberto,
roda em Java, e um broker num notebook é um Kafka completo: tópicos, partições, offsets e grupos de
consumidores se comportam exatamente como no MSK, com uma máquina em vez de três. O que um broker só
não consegue mostrar é a replicação, que é o assunto da próxima seção, e ela diz onde.

O terminal é o da lição 1: o moto rodando no terminal dele e as quatro linhas de "O seu laboratório, em resumo" da lição 1 digitadas neste; o moto só é preciso da seção sobre o MSK em diante. Primeiro o Java, depois a versão, que tem cerca de 130 MB, em `~/aws`:

```sh
sudo apt-get install -y openjdk-21-jre-headless
cd ~/aws
curl -sS -O https://archive.apache.org/dist/kafka/4.4.0/kafka_2.13-4.4.0.tgz
```

```
ana@laptop:~/aws$ java -version
openjdk version "21.0.12.1" 2026-08-18
OpenJDK Runtime Environment (build 21.0.12.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 21.0.12.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
ana@laptop:~/aws$ du -h kafka_2.13-4.4.0.tgz
130M	kafka_2.13-4.4.0.tgz
ana@laptop:~/aws$ tar -xzf kafka_2.13-4.4.0.tgz && ls kafka_2.13-4.4.0
LICENSE
NOTICE
bin
config
libs
licenses
site-docs
```

**O `archive.apache.org` guarda toda versão do Kafka para sempre**, e é por isso que a lição o usa em
vez dos espelhos de download, que guardam só as últimas. `2.13` é a versão do Scala com que a versão
foi compilada e não muda nada para você; `4.4.0` é a versão do Kafka.

## Formatar uma vez, ligar num terceiro terminal

O diretório de log de um broker precisa ser formatado antes da primeira partida, com um id para o
cluster. No modo KRaft, o único que o Kafka 4 tem, o broker guarda os próprios metadados e não precisa
de mais nada rodando ao lado. Daqui em diante o seu terminal trabalha dentro da versão, então faça
`cd kafka_2.13-4.4.0` primeiro:

```
ana@laptop:~/aws/kafka_2.13-4.4.0$ KAFKA_CLUSTER_ID="$(bin/kafka-storage.sh random-uuid)" && bin/kafka-storage.sh format --standalone -t $KAFKA_CLUSTER_ID -c config/server.properties
Bootstrap metadata: BootstrapMetadata(records=[ApiMessageAndVersion(FeatureLevelRecord(name='metadata.version', featureLevel=33) at version 0), ApiMessageAndVersion(FeatureLevelRecord(name='eligible.leader.replicas.version', featureLevel=1) at version 0), ApiMessageAndVersion(FeatureLevelRecord(name='group.version', featureLevel=1) at version 0), ApiMessageAndVersion(FeatureLevelRecord(name='share.version', featureLevel=2) at version 0), ApiMessageAndVersion(FeatureLevelRecord(name='streams.version', featureLevel=1) at version 0), ApiMessageAndVersion(FeatureLevelRecord(name='transaction.version', featureLevel=2) at version 0)], metadataVersionLevel=33, source=format command)
Formatting dynamic metadata voter directory /tmp/kraft-combined-logs with metadata.version 4.4-IV2.
```

**O diretório de log é `/tmp/kraft-combined-logs`**, como diz o `config/server.properties` que vem
junto, então reiniciar a máquina o esvazia e a formatação tem de ser feita de novo. Depois abra um
terceiro terminal, ao lado do do moto e do seu, e ligue o broker em primeiro plano lá:

```sh
cd ~/aws/kafka_2.13-4.4.0
bin/kafka-server-start.sh config/server.properties
```

Ele imprime o log e fica rodando, escutando em `localhost:9092`. `Ctrl+C` o para. Todo comando abaixo
roda no seu terminal de sempre, a partir de `~/aws/kafka_2.13-4.4.0`.

## Um tópico, e registros com chave

Três partições, e uma cópia de cada, porque há um broker só:

```
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-topics.sh --bootstrap-server localhost:9092 --create --topic orders --partitions 3 --replication-factor 1
Created topic orders.
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic orders
Topic: orders	TopicId: dlW2N4ajSJu4zfoc7UnRyg	PartitionCount: 3	ReplicationFactor: 1	Configs: min.insync.replicas=1,segment.bytes=1073741824
	Topic: orders	Partition: 0	Leader: 1	Replicas: 1	Isr: 1	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 1	Leader: 1	Replicas: 1	Isr: 1	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 2	Leader: 1	Replicas: 1	Isr: 1	Elr: 	LastKnownElr: 
```

Os mesmos quatro eventos com que o produtor da lição 20 começou, mandados com o produtor de console,
que lê um registro por linha e divide cada linha no `:` em chave e valor. Depois um consumidor de
console no grupo `fraud` os lê, imprimindo a partição e o offset de cada registro:

```
ana@laptop:~/aws/kafka_2.13-4.4.0$ printf 'c-17:o-101 placed\nc-02:o-102 placed\nc-17:o-101 packed\nc-05:o-103 placed\n' | bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic orders --reader-property parse.key=true --reader-property key.separator=:
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic orders --group fraud --from-beginning --max-messages 4 --formatter-property print.partition=true --formatter-property print.offset=true --formatter-property print.key=true
The consumer rebalance protocol (KIP-848) is production-ready! Set group.protocol=consumer to try it out. See https://kafka.apache.org/documentation/#consumer_rebalance_protocol
Partition:0	Offset:0	c-02	o-102 placed
Partition:1	Offset:0	c-17	o-101 placed
Partition:1	Offset:1	c-17	o-101 packed
Partition:2	Offset:0	c-05	o-103 placed
Processed a total of 4 messages
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group fraud

Consumer group 'fraud' has no active members.

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
fraud           orders          0          1               1               0               -               -               -
fraud           orders          1          2               2               0               -               -               -
fraud           orders          2          1               1               0               -               -               -
```

**`c-17` foi para a partição 1, `c-02` para a 0 e `c-05` para a 2**, por murmur2 em vez de MD5, e os
dois eventos de `c-17` estão nos offsets 0 e 1 da mesma partição, na ordem em que foram mandados. A
primeira linha da saída do consumidor é o Kafka anunciando um protocolo mais novo para rebalancear
grupos; é um aviso, não um erro. O último comando pergunta ao broker o que ele sabe do grupo: para cada
partição, o offset que o grupo confirmou, o fim do log, e a diferença, o **lag**. Os três são 0, porque
o `fraud` leu tudo. O grupo "has no active members" porque o consumidor de console saiu; os offsets
dele ficam no broker.

## Lag, e ler de novo

Mais três eventos, e o grupo descrito de novo antes de alguém lê-los:

```
ana@laptop:~/aws/kafka_2.13-4.4.0$ printf 'c-17:o-101 delivered\nc-02:o-102 packed\nc-05:o-103 cancelled\n' | bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic orders --reader-property parse.key=true --reader-property key.separator=:
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group fraud

Consumer group 'fraud' has no active members.

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
fraud           orders          0          1               2               1               -               -               -
fraud           orders          1          2               3               1               -               -               -
fraud           orders          2          1               2               1               -               -               -
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic orders --group fraud --max-messages 3 --formatter-property print.partition=true --formatter-property print.offset=true --formatter-property print.key=true
The consumer rebalance protocol (KIP-848) is production-ready! Set group.protocol=consumer to try it out. See https://kafka.apache.org/documentation/#consumer_rebalance_protocol
Partition:0	Offset:1	c-02	o-102 packed
Partition:1	Offset:2	c-17	o-101 delivered
Partition:2	Offset:1	c-05	o-103 cancelled
Processed a total of 3 messages
```

**O lag é 1 em toda partição**, um registro não lido em cada, e o consumidor ligado em seguida, no
mesmo grupo, leu exatamente esses três e nada que já tivesse lido: continuou dos offsets confirmados.
Lag é o número que um operador vigia. Um grupo cujo lag cresce é um grupo ficando para trás, e num
tópico com retenção de um dia, um lag mais velho que um dia são registros perdidos, que é o aviso de
retenção da lição 20 nos termos do Kafka.

**Reprocessar é um comando**, rodado enquanto o grupo não tem membros ativos:

```
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group fraud --topic orders --reset-offsets --to-earliest --execute

GROUP           TOPIC           PARTITION  NEW-OFFSET
fraud           orders          0          0
fraud           orders          1          0
fraud           orders          2          0
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic orders --group fraud --max-messages 7 --formatter-property print.partition=true --formatter-property print.offset=true --formatter-property print.key=true
The consumer rebalance protocol (KIP-848) is production-ready! Set group.protocol=consumer to try it out. See https://kafka.apache.org/documentation/#consumer_rebalance_protocol
Partition:0	Offset:0	c-02	o-102 placed
Partition:0	Offset:1	c-02	o-102 packed
Partition:1	Offset:0	c-17	o-101 placed
Partition:1	Offset:1	c-17	o-101 packed
Partition:1	Offset:2	c-17	o-101 delivered
Partition:2	Offset:0	c-05	o-103 placed
Partition:2	Offset:1	c-05	o-103 cancelled
Processed a total of 7 messages
```

Os sete registros voltaram, em ordem dentro de cada partição. Esta é a forma Kafka do `TRIM_HORIZON`,
feita para um grupo inteiro de uma vez, e é como uma equipe reprocessa depois de corrigir um bug.
`--to-datetime` volta a um horário em vez disso, que é o `AT_TIMESTAMP`.

## Retenção e o log no disco

```
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name orders --alter --add-config retention.ms=604800000,retention.bytes=10737418240
Completed updating config for topic orders.
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name orders --describe
Dynamic configs for topic orders are:
  retention.bytes=10737418240 sensitive=false synonyms={DYNAMIC_TOPIC_CONFIG:retention.bytes=10737418240, DEFAULT_CONFIG:log.retention.bytes=-1}
  retention.ms=604800000 sensitive=false synonyms={DYNAMIC_TOPIC_CONFIG:retention.ms=604800000}
ana@laptop:~/aws/kafka_2.13-4.4.0$ ls /tmp/kraft-combined-logs/orders-1/
00000000000000000000.index
00000000000000000000.log
00000000000000000000.timeindex
leader-epoch-checkpoint
partition.metadata
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic orders
orders:0:2
orders:1:3
orders:2:2
```

**Sete dias ou 10 GB por partição, o que vier primeiro.** `604800000` são sete dias em milissegundos e
`10737418240` são 10 GiB. A listagem do diretório é o log da partição 1 no disco: um **segmento**,
`00000000000000000000.log`, com o nome do primeiro offset que guarda, e dois índices ao lado, um por
offset e um por tempo. A retenção apaga segmentos inteiros, nunca registros soltos, então uma partição
pode guardar um pouco mais que o limite até o segmento mais antigo passar dele por inteiro. E o
`kafka-get-offsets.sh` imprime o fim do log de cada partição, `orders:1:3` querendo dizer que a
partição 1 guarda os offsets de 0 a 2.

Quando terminar, `Ctrl+C` no terminal do broker o para.
