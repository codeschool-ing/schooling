---
title: Uma leitura desatualizada, de propósito
version: 1
---

Esta aula precisa de quatro contêineres: os três da aula 1, começando vazios, e um segundo Redis que
copia o primeiro. Se os contêineres de aulas anteriores ainda estiverem lá, remova-os com
`docker rm -f mongo redis cassandra`. Depois, estas cinco linhas criam tudo, e a primeira falha sem
dano se a rede já existir:

```sh
docker network create nosql
docker run -d --name redis --network nosql redis:7.4
docker run -d --name redis-replica --network nosql redis:7.4 redis-server --replicaof redis 6379
docker run -d --name mongo --network nosql mongo:8.0
docker run -d --name cassandra --network nosql -e MAX_HEAP_SIZE=256M -e HEAP_NEWSIZE=64M cassandra:5.0
```

A terceira linha é a novidade. `redis-server --replicaof redis 6379` sobe um Redis que se conecta ao
contêiner chamado `redis` e **copia toda escrita que o primário recebe**, um instante depois. A aula
15 trata da replicação do Redis de verdade: como a cópia começa, quanto custa e o que acontece quando
o primário morre. Esta seção só precisa do fato de que a réplica responde a leituras.

## Duas cópias que concordam

```
ana@vm:~$ docker exec redis-replica redis-cli INFO replication | grep -E "^(role|master_host|master_link_status)"
role:slave
master_host:redis
master_link_status:up
ana@vm:~$ docker exec redis redis-cli SET stock:MN-330 1
OK
ana@vm:~$ docker exec redis-replica redis-cli GET stock:MN-330
1
```

`role:slave` é a palavra do próprio Redis para réplica, mantida no `INFO` por compatibilidade. O link
com o primário está `up`, e um valor gravado no primário já está na réplica quando o comando seguinte
é digitado.

## Puxe o cabo

`docker network disconnect` tira a réplica da rede `nosql`: o contêiner continua rodando, e não
alcança mais o primário. Isso é uma partição, feita com um comando:

```
ana@vm:~$ docker network disconnect nosql redis-replica
ana@vm:~$ docker exec redis redis-cli SET stock:MN-330 0
OK
ana@vm:~$ docker exec redis-replica redis-cli GET stock:MN-330
1
ana@vm:~$ docker exec redis-replica redis-cli INFO replication | grep -E "^(role|master_link_status)"
role:slave
master_link_status:up
ana@vm:~$ docker exec redis-replica redis-cli CONFIG GET replica-serve-stale-data
replica-serve-stale-data
yes
ana@vm:~$ docker exec redis-replica redis-cli CONFIG GET repl-timeout
repl-timeout
60
ana@vm:~$ docker exec redis-replica redis-cli INFO replication | grep -E "^(role|master_link_status|master_link_down_since_seconds)"
role:slave
master_link_status:down
master_link_down_since_seconds:0
ana@vm:~$ docker exec redis-replica redis-cli GET stock:MN-330
1
```

O primário aceitou o estoque novo, 0. A réplica, perguntada um instante depois, respondeu **1**, o
valor de antes, sem nada na resposta dizendo que podia estar desatualizado. Veja o primeiro `INFO`: a
réplica ainda informava o link como `up`. Ela ainda não sabe. Uma réplica só percebe um primário
calado quando nada chegou por `repl-timeout` segundos, 60 por padrão, e o segundo `INFO`, tirado
depois que a réplica desistiu, mostra `master_link_status:down`.

**Mesmo assim ela continua respondendo.** `replica-serve-stale-data` é `yes` por padrão, então uma
réplica que sabe que está isolada ainda serve o que tem, e o último `GET` continua dizendo 1. Com
`no`, a réplica recusaria a maioria dos comandos com um erro. Essa configuração é a escolha do CAP
da aula 1 numa linha de configuração: responder e talvez errar, ou recusar.

## Devolva o cabo

```
ana@vm:~$ docker network connect nosql redis-replica
ana@vm:~$ docker exec redis-replica redis-cli GET stock:MN-330
0
ana@vm:~$ docker exec redis-replica redis-cli INFO replication | grep -E "^(role|master_link_status)"
role:slave
master_link_status:up
```

Alguns segundos depois do `docker network connect`, a réplica tinha se reconectado, alcançado o
primário e respondido 0. **Esse é o "eventual" da consistência eventual**: quando as cópias voltam a
se falar, elas concordam. O que o termo não diz é quanto tempo isso leva, e no meio, durante um
minuto aqui, a réplica deu uma resposta que uma aplicação teria mostrado a um cliente como verdade:
um monitor em estoque.
