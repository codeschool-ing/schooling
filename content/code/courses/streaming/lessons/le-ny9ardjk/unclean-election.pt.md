---
title: Eleição de líder não limpa: disponível ou correto
version: 1
---

**Quando toda réplica da ISR de uma partição se foi e só sobra uma réplica desatualizada, o Kafka
pode esperar uma réplica em sincronia voltar, e a partição fica indisponível até lá, ou fazer da
desatualizada a líder, e perder todo registro que ela não tinha.** Fazê-la líder é uma **eleição
de líder não limpa** (*unclean leader election*). Ela vem desligada por padrão,
`unclean.leader.election.enable=false`, e esta seção provoca a situação para mostrar o que o
padrão protege.

## Preparando a perda

A situação precisa de uma partição cuja última réplica em sincronia morre depois das outras. Um
tópico com duas réplicas postas à mão nos nós 2 e 3 deixa tudo fácil de acompanhar;
`--replica-assignment 2:3` quer dizer uma partição, com réplicas no nó 2 e no nó 3, o nó 2
primeiro. Dez vendas entram com as duas réplicas em sincronia. Depois o nó 3 morre, e mais dez
vendas entram só com o nó 2, o que `min.insync.replicas=1` neste tópico permite:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic till-log --replica-assignment 2:3 --config min.insync.replicas=1
Created topic till-log.
ubuntu@stream:~/work$ python acks.py --topic till-log
acks=all: 10 delivered
partition 0: offsets 0 to 9
ubuntu@stream:~/work$ ./cluster.sh kill 3
node 3: killed
ubuntu@stream:~/work$ sleep 15; kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic till-log
Topic: till-log	TopicId: utv0ygFwQ-OUoRoOKuvJXA	PartitionCount: 1	ReplicationFactor: 2	Configs: min.insync.replicas=1
	Topic: till-log	Partition: 0	Leader: 2	Replicas: 2,3	Isr: 2	Elr: 	LastKnownElr: 
ubuntu@stream:~/work$ python acks.py --topic till-log
acks=all: 10 delivered
partition 0: offsets 10 to 19
```

Os offsets 0 a 9 foram para as duas réplicas. Depois que o nó 3 morreu, a ISR encolheu para o nó 2
sozinho, e os offsets 10 a 19 foram confirmados por ele, então estão no nó 2 e em nenhum outro
lugar. Agora o nó 2 também morre, e o nó 3, que parou no offset 10, volta:

```
ubuntu@stream:~/work$ ./cluster.sh kill 2
node 2: killed
ubuntu@stream:~/work$ ./cluster.sh start 3
node 3: up on localhost:9094
ubuntu@stream:~/work$ sleep 15; kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic till-log
Topic: till-log	TopicId: utv0ygFwQ-OUoRoOKuvJXA	PartitionCount: 1	ReplicationFactor: 2	Configs: min.insync.replicas=1
	Topic: till-log	Partition: 0	Leader: none	Replicas: 2,3	Isr: 	Elr: 2	LastKnownElr: 2
ubuntu@stream:~/work$ python acks.py --topic till-log --count 1
acks=all: 1 _MSG_TIMED_OUT
```

**`Leader: none`**: a partição está offline. O nó 3 está vivo e tem uma cópia, e o Kafka não vai
usá-la, porque ela não está na ISR e não tem as últimas dez vendas. Produtores esperam e estouram
o tempo; consumidores não recebem nada.

## Elr: as réplicas que ainda podem liderar sem perda

As duas colunas que estavam vazias até agora se preencheram. **`Elr` é a lista de Eligible Leader
Replicas**, do KIP-966, que o Kafka 4 trouxe: réplicas que saíram da ISR quando ela já estava no
`min.insync.replicas` ou abaixo dele, e de que por isso se sabe que têm todo registro confirmado.
O nó 2 está nela, porque era a última réplica em sincronia quando a ISR o perdeu. Quando o nó 2
voltar, o Kafka pode fazê-lo líder de forma limpa e não perder nada. `LastKnownElr` guarda a
última lista dessas quando até a Elr está vazia, para que um operador veja que nó trazer de volta
primeiro.

Então a saída limpa é reiniciar o nó 2. A não limpa é mandar o Kafka usar o que tem:

```
ubuntu@stream:~/work$ kafka-leader-election.sh --bootstrap-server localhost:9092 --election-type unclean --topic till-log --partition 0
Successfully completed leader election (UNCLEAN) for partitions till-log-0
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic till-log
Topic: till-log	TopicId: utv0ygFwQ-OUoRoOKuvJXA	PartitionCount: 1	ReplicationFactor: 2	Configs: min.insync.replicas=1
	Topic: till-log	Partition: 0	Leader: 3	Replicas: 2,3	Isr: 3	Elr: 	LastKnownElr: 
ubuntu@stream:~/work$ kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic till-log
till-log:0:10
```

A partição voltou, liderada pelo nó 3, e o log dela termina no offset 10. **As dez vendas gravadas
enquanto o nó 3 estava fora sumiram**: elas foram confirmadas ao produtor, com `acks=all`, e não
existem mais. Quando o nó 2 volta, ele não as traz de volta. Ele descobre que o log do líder
diverge do seu no offset 10, e **trunca** o próprio log para casar com o do líder:

```
ubuntu@stream:~/work$ ./cluster.sh start 2
node 2: up on localhost:9093
ubuntu@stream:~/work$ sleep 10; kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic till-log
Topic: till-log	TopicId: utv0ygFwQ-OUoRoOKuvJXA	PartitionCount: 1	ReplicationFactor: 2	Configs: min.insync.replicas=1
	Topic: till-log	Partition: 0	Leader: 3	Replicas: 2,3	Isr: 2,3	Elr: 	LastKnownElr: 
ubuntu@stream:~/work$ kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic till-log
till-log:0:10
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic till-log --from-beginning --timeout-ms 5000 2>/dev/null | wc -l
10
```

As duas réplicas estão em sincronia de novo, o offset final continua 10, e um consumidor lendo
desde o começo recebe dez vendas.

## Qual escolher

| | eleição não limpa desligada (o padrão) | eleição não limpa ligada |
|---|---|---|
| a última réplica em sincronia morre | a partição para até ela voltar | uma réplica desatualizada assume na hora |
| o que se perde | tempo | todo registro que o novo líder não tinha |
| quem fica sabendo | todo mundo, na hora | ninguém, até as contas não fecharem |

Para vendas, pagamentos, estoque e tudo que alguém vai conciliar depois, o padrão é a única escolha
sensata: uma parada é visível e acaba, um buraco nos dados é silencioso e permanente. Ligá-la se
defende para dados que só valem frescos, como posições de veículos ou métricas, em que uma hora sem
nada é pior que alguns pontos perdidos. De um jeito ou de outro é uma decisão por tópico,
`unclean.leader.election.enable` definido com `kafka-configs.sh`, e a ferramenta de eleição acima é
a mesma decisão tomada uma vez, à mão, por alguém que decidiu que os registros que faltam valem
menos que a parada.
