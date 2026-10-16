---
title: Um primário e duas réplicas
version: 1
---

A aula 13 fez o Redis sobreviver a um reinício. **Uma réplica o faz sobreviver à perda da máquina**:
um segundo Redis que recebe toda escrita que o primeiro faz e pode tomar o lugar dele. A replicação do
Redis é simples de ligar, uma opção na réplica, e tem uma propriedade em torno da qual gira o resto
desta aula: **o primário responde ao cliente primeiro e manda a escrita às réplicas depois.**

## Três contêineres

O contêiner `redis` único das aulas anteriores sai; três entram no lugar dele, na mesma rede, para que
cada um ache os outros pelo nome:

```
ana@vm:~$ docker rm -f redis
redis
ana@vm:~$ docker run -d --name redis-1 --network nosql redis:7.4 redis-server --replica-announce-ip redis-1
68e9c00965b15a1da48039c7cd353f2f6241cca9b3a4854b55f6c0ff5b7d4ea2
ana@vm:~$ docker run -d --name redis-2 --network nosql redis:7.4 redis-server --replica-announce-ip redis-2 --replicaof redis-1 6379
03ff9650a9d3a678b668c41ebe9326b9212287d9ad14880045939c0be93bd4d3
ana@vm:~$ docker run -d --name redis-3 --network nosql redis:7.4 redis-server --replica-announce-ip redis-3 --replicaof redis-1 6379
c44e395338bfb8433b30acddeff346f1c4e52588a6b21bfc0e7e29ae5eba3cb6
```

`--replicaof redis-1 6379` faz de um servidor a réplica do que está nesse endereço: ele se conecta,
recebe uma cópia completa do conjunto de dados e depois cada escrita conforme acontece.
`--replica-announce-ip` dá a cada servidor o nome que os outros devem usar para ele. Sem isso uma
réplica é conhecida pelo endereço dentro da rede do Docker, o que funciona e é mais difícil de ler nas
seções seguintes.

## O que cada um diz de si

```
ana@vm:~$ docker exec redis-1 redis-cli INFO replication | grep -E "^(role|connected_slaves|slave[0-9]|master_repl_offset):"
role:master
connected_slaves:2
slave0:ip=redis-2,port=6379,state=online,offset=0,lag=0
slave1:ip=redis-3,port=6379,state=online,offset=0,lag=0
master_repl_offset:0
ana@vm:~$ docker exec redis-2 redis-cli INFO replication | grep -E "^(role|master_host|master_link_status|slave_repl_offset|slave_read_only):"
role:slave
master_host:redis-1
master_link_status:up
slave_repl_offset:0
slave_read_only:1
```

O primário conta duas réplicas, `online`, e o **offset de replicação**: o número de bytes de escritas
que ele produziu desde o começo do fluxo de replicação. Cada réplica informa o offset que recebeu.
Quando os dois números são iguais, a réplica tem tudo; a diferença, quando há, é o quanto ela está
atrás. E uma réplica é **somente leitura** por padrão:

```
ana@vm:~$ docker exec redis-1 redis-cli SET order:1001 paid
OK
ana@vm:~$ docker exec redis-2 redis-cli GET order:1001
paid
ana@vm:~$ docker exec redis-2 redis-cli SET order:1002 paid
READONLY You can't write against a read only replica.
```

A escrita no primário chegou à réplica, que a respondeu numa leitura; a escrita na réplica foi
recusada com `READONLY`. Uma réplica que aceitasse escritas guardaria dados que o primário nunca viu, e
a próxima cópia completa vinda do primário os apagaria.

## Assíncrona de propósito

O primário não espera as réplicas antes de responder. Duzentas mil escritas, num único `EVAL`, e os dois
servidores contados em seguida:

```
ana@vm:~$ docker exec redis-1 redis-cli EVAL "for i = 1, 200000 do redis.call('SET', 'page:' .. i, 'x') end" 0 > /dev/null; docker exec redis-1 redis-cli DBSIZE; docker exec redis-2 redis-cli DBSIZE
200001
200001
ana@vm:~$ docker exec redis-2 redis-cli DBSIZE
200001
```

Os dois contaram 200.001 na hora, e a réplica de novo um instante depois. Numa máquina só, pela própria
rede do Docker, a réplica já tinha alcançado o primário antes de o comando seguinte começar. **A janela existe, e aqui
foi curta demais para ser vista.** Entre duas máquinas ela é de pelo menos uma ida e volta
pela rede, e as duas seções seguintes a tornam longa de propósito.

**Essa janela é o custo da velocidade**, e é o PA/EL da aula 1. O primário responde na hora e replica em segundo plano, então uma leitura numa réplica pode estar atrasada, e uma escrita que o primário confirmou
pode não existir em mais lugar nenhum por um instante. Em geral o instante é de milissegundos. Duas
seções adiante, ele é longo o bastante para perder um pedido.

A replicação também não é backup. Um `FLUSHALL` no primário chega a todas as réplicas nos mesmos
milissegundos, e uma chave apagada por engano é apagada em todo lugar. Os arquivos da aula 13, guardados
em outro lugar, são o backup.
