---
title: Montando um cluster numa máquina só
version: 1
---

Um cluster de produção espalha esses servidores por muitas máquinas, e cada shard e o config server
são replica sets de três. **O cluster do laboratório tem as mesmas partes no menor tamanho que ainda
se comporta como um cluster**: um config server, dois shards e um `mongos`, cada um no próprio
contêiner na rede `nosql`, e cada replica set com um membro só.

## O que esta aula precisa

A rede `nosql` da aula 1, e a memória que o replica set da aula 9 estava usando. Pare os três
membros dele primeiro, com os trinta segundos que a aula 9 lhes deu:

```sh
docker stop -t 30 mongo1 mongo2 mongo3
```

## O script

Cinco servidores iniciados à mão são vinte linhas digitadas na ordem certa, então esta aula os
guarda num script. Salve-o como `cluster.sh` no seu diretório pessoal na VM:

```schooling-example
{"language": "sh", "file": "cluster.sh", "parts": [{"code": "#!/bin/sh\n# cluster.sh: a sharded MongoDB cluster on one machine, for practice only.\nset -e\n", "note": "A linha `set -e` interrompe o script no primeiro comando que falhar, para que um cluster montado pela metade avise em vez de seguir em frente."}, {"code": "start() {  # start NAME COMMAND...: one container on the nosql network\n  name=$1; shift\n  docker run -d --name \"$name\" --hostname \"$name\" --network nosql mongo:8.0 \"$@\" >/dev/null\n}\n", "note": "Todo servidor é a mesma imagem com outro comando, do jeito que a aula 9 iniciou os membros. O id de contêiner que o `docker run` imprime é descartado para a saída ficar curta."}, {"code": "wait_for() {  # wait until the server in container $1 answers\n  until docker exec \"$1\" mongosh --quiet --eval 'db.runCommand({ ping: 1 })' >/dev/null 2>&1; do sleep 1; done\n}\n", "note": "Um servidor leva um ou dois segundos para escutar. O script pergunta a cada segundo em vez de adivinhar quanto dormir."}, {"code": "initiate() {  # initiate NAME SET [EXTRA]: a replica set of one member\n  docker exec \"$1\" mongosh --quiet --eval \"rs.initiate({ _id: '$2', $3 members: [{ _id: 0, host: '$1:27017' }] }).ok\"\n  until docker exec \"$1\" mongosh --quiet --eval 'db.hello().isWritablePrimary' | grep -q true; do sleep 1; done\n}\n", "note": "Num cluster shardeado todo shard e o config server são replica sets, mesmo com um membro só. Um membro mantém o laboratório pequeno; um cluster de verdade dá três a cada conjunto, pelos motivos da aula 9. O laço espera o membro vencer a própria eleição."}, {"code": "start cfg1 mongod --configsvr --replSet cfg --port 27017 --bind_ip_all --wiredTigerCacheSizeGB 0.25\nstart shard1 mongod --shardsvr --replSet shard1 --port 27017 --bind_ip_all --wiredTigerCacheSizeGB 0.25\nstart shard2 mongod --shardsvr --replSet shard2 --port 27017 --bind_ip_all --wiredTigerCacheSizeGB 0.25\nfor c in cfg1 shard1 shard2; do wait_for $c; done\ninitiate cfg1 cfg 'configsvr: true,'\ninitiate shard1 shard1\ninitiate shard2 shard2\n", "note": "`--configsvr` e `--shardsvr` dizem qual trabalho o servidor faz; os dois escolheriam uma porta própria, e `--port 27017` mantém a que todas as outras aulas usam. `--wiredTigerCacheSizeGB 0.25` limita o cache de cada servidor a um quarto de gigabyte, porque por padrão cada um o dimensionaria pela memória da máquina inteira."}, {"code": "start mongos mongos --configdb cfg/cfg1:27017 --bind_ip_all\nwait_for mongos\ndocker exec mongos mongosh --quiet --eval 'sh.addShard(\"shard1/shard1:27017\").shardAdded'\ndocker exec mongos mongosh --quiet --eval 'sh.addShard(\"shard2/shard2:27017\").shardAdded'\n", "note": "O `mongos` não guarda nada. Ele lê o mapa do cluster no config server citado em `--configdb`, e o `sh.addShard` grava cada shard nesse mapa, como o nome de um replica set seguido de um membro."}]}
```

Rode-o com `sh`. O `time` na frente mede quanto o cluster inteiro leva para subir:

```
ana@vm:~$ time sh cluster.sh
1
1
1
shard1
shard2

real	0m16.371s
user	0m0.416s
sys	0m0.251s
```

As três linhas `1` são as três chamadas de `rs.initiate` dando certo, e os dois nomes são o
`sh.addShard` informando os shards que acrescentou. Menos de vinte segundos do nada a um cluster.

## Perguntando ao cluster o que ele é

Todo comando daqui em diante vai ao `mongos`, como iria o de uma aplicação. O `sh.status()` lê o
mapa no config server e o imprime:

```
ana@vm:~$ docker exec -it mongos mongosh --quiet
[direct: mongos] test> sh.status()
shardingVersion
{ _id: 1, clusterId: ObjectId('6acaea8cf7ad0a561ad12413') }
---
shards
[
  {
    _id: 'shard1',
    host: 'shard1/shard1:27017',
    state: 1,
    topologyTime: Timestamp({ t: 1791683224, i: 10 }),
    replSetConfigVersion: Long('-1')
  },
  {
    _id: 'shard2',
    host: 'shard2/shard2:27017',
    state: 1,
    topologyTime: Timestamp({ t: 1791683224, i: 28 }),
    replSetConfigVersion: Long('-1')
  }
]
---
active mongoses
[ { '8.0.32': 1 } ]
---
autosplit
{ 'Currently enabled': 'yes' }
---
balancer
{
  'Currently enabled': 'yes',
  'Failed balancer rounds in last 5 attempts': 0,
  'Currently running': 'no',
  'Migration Results for the last 24 hours': 'No recent migrations'
}
---
shardedDataDistribution
[]
---
databases
[
  {
    database: { _id: 'config', primary: 'config', partitioned: true },
    collections: {}
  }
]
[direct: mongos] test> exit
```

Dois shards, cada um identificado pelo replica set e pelo seu único membro. Um `mongos`, rodando
8.0.32. Um **balancer** habilitado e parado, sem migrações, porque nada foi shardeado ainda:
`databases` lista só o `config`, os metadados do próprio cluster. A próxima seção lhe dá uma
coleção.

Os quatro contêineres usaram uns 580 MB juntos depois de guardar os dados desta aula, como mede o
último comando da aula. Pare-os entre uma sessão e outra com `docker stop cfg1 shard1 shard2
mongos`, e inicie-os de novo na mesma ordem.
