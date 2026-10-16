---
title: Os controllers, e para que serve uma maioria
version: 1
---

**Alguém precisa decidir quem lidera cada partição e quem está na ISR dela, e no Kafka 4 esse
alguém é um pequeno grupo de controllers que decide por votação.** Os controllers guardam os
metadados do cluster — tópicos, partições, líderes, ISRs, configurações — num log próprio,
`__cluster_metadata`, o diretório que a lição 1 achou no disco. Um controller por vez é o **ativo**
e escreve nesse log; os outros o copiam, e uma mudança conta quando a maioria deles a tem. O
protocolo se chama KRaft, a versão do Kafka do Raft.

O Kafka antigo guardava os mesmos metadados num sistema à parte, o ZooKeeper. O Kafka 4.0 o
removeu, então um cluster Kafka 4 é feito só de processos Kafka.

Neste laboratório cada nó é broker e controller ao mesmo tempo, que é o que diz
`process.roles=broker,controller` na configuração dele. Um cluster de produção costuma separar os
dois papéis: três ou cinco máquinas pequenas rodam só os controllers, com
`process.roles=controller`, e os brokers que guardam dados rodam com `process.roles=broker`. Assim
uma falha de broker nunca mexe na votação, e um broker ocupado nunca a atrasa.

## Quem está votando

```
ubuntu@stream:~/work$ kafka-metadata-quorum.sh --bootstrap-server localhost:9092 describe --status
ClusterId:              YCLAkZhFSxymvym7xHcgzQ
LeaderId:               1
LeaderEpoch:            1
HighWatermark:          426
MaxFollowerLag:         0
MaxFollowerLagTimeMs:   0
CurrentVoters:          [{"id": 1, "endpoints": ["CONTROLLER://localhost:9192"]}, {"id": 2, "endpoints": ["CONTROLLER://localhost:9193"]}, {"id": 3, "endpoints": ["CONTROLLER://localhost:9194"]}]
CurrentObservers:       []
```

`LeaderId` é o controller ativo, o que é diferente do líder de uma partição: um nó lidera a
votação, e todo nó lidera algumas partições. `CurrentVoters` lista os três votantes com as portas
de controller, 9192 a 9194. `HighWatermark` é a mesma ideia da de uma partição: o fim do que a
maioria dos votantes já gravou. `MaxFollowerLag` é quanto o votante mais lento está atrás, em
registros.

## Perdendo a maioria

Três votantes precisam de dois de acordo. **Perca um e os outros dois seguem; perca dois e o que
sobra não consegue decidir nada**, porque não sabe dizer se é o sobrevivente ou o que ficou isolado
dos outros. Ele não chuta. Mate os nós 2 e 3, peça ao nó 1 algo que exige uma decisão, e depois
pergunte a ele quem está no comando:

```
ubuntu@stream:~/work$ ./cluster.sh kill 2
node 2: killed
ubuntu@stream:~/work$ ./cluster.sh kill 3
node 3: killed
ubuntu@stream:~/work$ timeout 60 kafka-topics.sh --bootstrap-server localhost:9092 --create --topic returns --partitions 3 2>/dev/null; echo "exit $?"
exit 124
ubuntu@stream:~/work$ timeout 30 kafka-metadata-quorum.sh --bootstrap-server localhost:9092 describe --status 2>/dev/null; echo "exit $?"
exit 124
```

Os dois comandos não imprimiram nada e esperaram até o `timeout` encerrá-los, e o `timeout` informa
isso com o código de saída 124.

O nó 1 está rodando e a porta dele responde; o que ele não consegue é mudar o cluster. O `create`
nunca recebeu resposta, e nenhuma liderança nem ISR pode mudar enquanto falta a maioria.

**A cura é trazer de volta votantes suficientes para formar uma maioria**, não fazer o sobrevivente
decidir sozinho:

```
ubuntu@stream:~/work$ ./cluster.sh start
node 1: already running
node 1: up on localhost:9092
node 2: up on localhost:9093
node 3: up on localhost:9094
ubuntu@stream:~/work$ kafka-metadata-quorum.sh --bootstrap-server localhost:9092 describe --status | grep -E "LeaderId|HighWatermark"
LeaderId:               1
HighWatermark:          499
```

O `LeaderId` é o nó 1 de novo e o `HighWatermark` andou, de 426 antes da falha para 499: os
controllers voltam a votar, e o log de metadados está sendo escrito. A aritmética explica por que
controllers vêm em número ímpar: três sobrevivem a uma falha, cinco a duas, e quatro só a uma, como
três, custando uma máquina a mais.

## Neste laboratório, e num de verdade

Como todo nó aqui também é controller, perder dois nós de três perde ao mesmo tempo as cópias dos
dados e os votos. É por isso que a seção sobre acks subiu o `min.insync.replicas` para ver uma
recusa em vez de matar um segundo nó. Com controllers separados, matar dois brokers de três
deixaria a votação intacta, as ISRs encolheriam para um, e produtores com `acks=all` receberiam
`NotEnoughReplicas`, exatamente como receberam lá.
