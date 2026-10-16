---
title: Redis, e as linhas do INFO que importam
version: 1
---

O Redis costuma ser observado só pelo gráfico de memória, e **memória perto do limite muitas vezes é
um cache funcionando como projetado**. O que separa um Redis saudável de um doente é o que acontece
no limite: se chaves são expulsas ou escritas recusadas, se as leituras ainda encontram o que pedem,
e se a réplica está acompanhando. O `INFO` responde tudo isso, em umas duzentas linhas `nome:valor`,
e esta seção lê oito delas.

## Um Redis pequeno sob pressão

O conjunto do MongoDB sai, e o Redis volta com teto de 20 MB, a política `allkeys-lru` da aula 14,
o monitor de latência ligado e uma réplica ao lado:

```sh
docker rm -f mongo1 mongo2 mongo3 redis
docker run -d --name redis --network nosql redis:7.4 redis-server --maxmemory 20mb --maxmemory-policy allkeys-lru --latency-monitor-threshold 5
docker run -d --name redis-replica --network nosql redis:7.4 redis-server --replicaof redis 6379
```

A carga é o `redis-benchmark`, que vem na imagem. `-t set,get` roda uma rodada de `SET`s e depois
uma de `GET`s, `-r 100000` os espalha por 100.000 chaves aleatórias, e `-d 200` faz cada valor ter
200 bytes. Cem mil valores desse tamanho não cabem em 20 MB, e é essa a ideia. Rodando em segundo
plano, ele deixa o terminal livre para o `redis-cli --stat`, uma linha por segundo até ser parado:

```
ana@vm:~$ docker exec -d redis redis-benchmark -t set,get -n 600000 -r 100000 -d 200 -q
ana@vm:~$ docker exec redis timeout 5 stdbuf -oL redis-cli --stat
------- data ------ --------------------- load -------------------- - child -
keys       mem      clients blocked requests            connections          
59404      20.03M   51      0       243703 (+0)         54          
59423      20.03M   51      0       350063 (+106360)    54          
59352      20.01M   51      0       461169 (+111106)    54          
59387      20.01M   51      0       576441 (+115272)    54          
56635      20.03M   51      0       695798 (+119357)    104         
```

O `timeout 5` o para depois de cinco segundos, e o `stdbuf -oL` o faz imprimir cada linha na hora em
vez de tudo no fim; num terminal, `docker exec -it redis redis-cli --stat` e Ctrl+C fazem o mesmo. A
contagem de chaves fica perto de 59.400 enquanto 100.000 chaves estão sendo gravadas: **a memória
está colada no teto, e as chaves que não cabem são expulsas tão rápido quanto chegam as novas.**

## Oito linhas do `INFO`

```
ana@vm:~$ docker exec redis redis-cli INFO | grep -E "^(used_memory|maxmemory|evicted_keys|keyspace_hits|keyspace_misses|connected_clients|rejected_connections|instantaneous_ops_per_sec):"
connected_clients:51
used_memory:20387416
maxmemory:20971520
instantaneous_ops_per_sec:116649
rejected_connections:0
evicted_keys:212690
keyspace_hits:122951
keyspace_misses:93717
```

| campo | aqui | o que diz |
|---|---|---|
| `used_memory` / `maxmemory` | 20.387.416 de 20.971.520 bytes, 97% | cheio, como um cache com limite deve estar |
| `evicted_keys` | 212.690 | chaves jogadas fora para abrir espaço desde o início |
| `keyspace_hits` / `keyspace_misses` | 122.951 e 93.717 | leituras que encontraram a chave, e leituras que não |
| `connected_clients` | 51, os 50 do benchmark e este | o pool que as aplicações mantêm aberto |
| `rejected_connections` | 0 | clientes recusados em `maxclients` |
| `instantaneous_ops_per_sec` | 116.649 | comandos por segundo, amostrados nos últimos instantes |

**A taxa de acerto é o número para o qual um cache existe**: 122.951 acertos em 216.668 leituras dão
56,7%. Fica perto dos 59% das 100.000 chaves que cabem, que é o que leituras aleatórias sobre um
espaço de chaves que não cabe devem dar. Leia os dois campos junto com a política. Sob
`allkeys-lru`, um `evicted_keys` subindo com taxa de acerto estável é um cache trabalhando; uma taxa
de acerto que cai enquanto as expulsões sobem quer dizer que o conjunto de trabalho cresceu além da
memória, e cada erro agora é uma ida ao banco que está atrás. **Sob `noeviction` a mesma pressão não
vira expulsões, vira erros**: escritas recusadas com `OOM`, que a aula 14 mostra, e o campo a
observar passa a ser o próprio `used_memory`.

## A réplica, atrasada de propósito

O `docker pause` congela todos os processos de um contêiner sem pará-lo, o que é um bom substituto
para uma réplica que parou de ler da rede. Grave 200.000 chaves enquanto ela está congelada:

```
ana@vm:~$ docker pause redis-replica
redis-replica
ana@vm:~$ docker exec redis redis-benchmark -t set -n 200000 -r 100000 -d 200 --csv
"test","rps","avg_latency_ms","min_latency_ms","p50_latency_ms","p95_latency_ms","p99_latency_ms","max_latency_ms"
"SET","127388.53","0.260","0.104","0.231","0.471","0.655","4.751"
ana@vm:~$ docker exec redis redis-cli INFO replication | grep -E "^(slave0|master_repl_offset)"
slave0:ip=172.18.0.3,port=6379,state=online,offset=154056900,lag=2
master_repl_offset:205882318
ana@vm:~$ docker unpause redis-replica
redis-replica
ana@vm:~$ docker exec redis redis-cli INFO replication | grep -E "^(slave0|master_repl_offset)"
slave0:ip=172.18.0.3,port=6379,state=online,offset=205882318,lag=1
master_repl_offset:205882318
```

As escritas não ficaram mais lentas: 127.388 por segundo, com p99 de 0,655 ms. O primário não espera
a réplica (aula 15), e por isso **nada no caminho de escrita avisa que a réplica está com problema.**

A linha da réplica traz duas medidas diferentes, e elas discordam sobre o tamanho do problema:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 210\" role=\"img\" aria-label=\"O fluxo de replicação como uma linha de bytes. O primário produziu 205.882.318 bytes; a réplica pausada confirmou 154.056.900. O trecho entre os dois, 51.825.418 bytes, está gravado no primário e em réplica nenhuma. À parte, lag=2 conta os segundos desde a última confirmação da réplica.\"><defs><marker id=\"l20off-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"40\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fluxo de replicação, em bytes</text><rect x=\"40\" y=\"50\" width=\"463.9314290215054\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"503.9314290215054\" y=\"50\" width=\"156.06857097849462\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"271.9657145107527\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">confirmado pela réplica</text><text x=\"581.9657145107527\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">só no primário</text><line x1=\"40\" y1=\"84\" x2=\"40\" y2=\"96\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"40\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><line x1=\"503.9314290215054\" y1=\"84\" x2=\"503.9314290215054\" y2=\"96\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"503.9314290215054\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">offset=154056900</text><line x1=\"660\" y1=\"84\" x2=\"660\" y2=\"96\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"656\" y=\"120\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">master_repl_offset:205882318</text><line x1=\"507.9314290215054\" y1=\"140\" x2=\"656\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l20off-ah-amber)\" marker-start=\"url(#l20off-ah-amber)\"></line><text x=\"581.9657145107527\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">51.825.418 bytes, cerca de 49 MiB</text><text x=\"40\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lag=2: dois segundos desde a última resposta da réplica</text><text x=\"40\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não diz nada sobre quanto falta</text></svg>", "caption": "Duas leituras de uma mesma réplica pausada. A diferença em bytes é quanto se perderia; o lag é só há quanto tempo a réplica está calada."}
```

`master_repl_offset` é quantos bytes do fluxo de replicação o primário produziu, e o `offset` da
réplica é quantos ela confirmou. A diferença é de **51.825.418 bytes, cerca de 49 MiB de escritas**
que se perderiam se o primário morresse naquele momento. O `lag` é outra coisa: os segundos desde
que a réplica confirmou alguma coisa pela última vez, 2 aqui. Uma réplica viva e confirmando, mas
devagar, mostra um `lag` pequeno e uma diferença em bytes crescendo, então a diferença é a que merece
alerta. Depois do unpause os dois offsets voltam a ser iguais, e `state=online` esteve lá o tempo
todo, e é por isso que o `state` também não serve de alarme.

## Um cliente recusado

`rejected_connections` conta os clientes que o Redis recusou porque `maxclients` foi atingido. Para
ver um, ponha o limite em 2, segure uma conexão aberta com um `BLPOP` que espera dez segundos por uma
lista em que ninguém escreve, e tente uma terceira:

```
ana@vm:~$ docker exec redis redis-cli CONFIG SET maxclients 2
OK
ana@vm:~$ docker exec -d redis redis-cli BLPOP nothing 10
ana@vm:~$ docker exec redis redis-cli PING
ERR max number of clients reached

ana@vm:~$ docker exec redis redis-cli INFO stats | grep rejected_connections
rejected_connections:1
ana@vm:~$ docker exec redis redis-cli CONFIG SET maxclients 10000
OK
```

A conexão da própria réplica era a primeira das duas. A aplicação vê o erro uma vez por tentativa; o
contador o guarda depois que a aplicação tentou de novo e seguiu em frente, e é **por isso que um
contador que só sobe é alertado pela taxa**, não pelo valor.

## O slow log, e o latency doctor

O Redis atende os comandos um de cada vez, então um comando lento atrasa todos os clientes atrás
dele. O slow log guarda os comandos que levaram mais que `slowlog-log-slower-than` microssegundos,
10.000 por padrão. Com umas sessenta mil chaves nada aqui é tão lento, então o limite desce para um
milissegundo por um instante, e o `KEYS`, que percorre todas as chaves, roda uma vez:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> CONFIG GET slowlog-log-slower-than
1) "slowlog-log-slower-than"
2) "10000"
127.0.0.1:6379> CONFIG SET slowlog-log-slower-than 1000
OK
127.0.0.1:6379> SLOWLOG RESET
OK
127.0.0.1:6379> KEYS order:*
(empty array)
127.0.0.1:6379> SLOWLOG GET 1
1) 1) (integer) 0
   2) (integer) 1791618161
   3) (integer) 4517
   4) 1) "KEYS"
      2) "order:*"
   5) "127.0.0.1:51936"
   6) ""
127.0.0.1:6379> CONFIG SET slowlog-log-slower-than 10000
OK
127.0.0.1:6379> LATENCY DOCTOR
Dave, no latency spike was observed during the lifetime of this Redis instance, not in the slightest bit. I honestly think you ought to sit down calmly, take a stress pill, and think things over.
127.0.0.1:6379> exit
```

Cada entrada é um id, a hora Unix, **a duração em microssegundos**, o comando com seus argumentos, o
endereço do cliente e o nome do cliente. `KEYS order:*` não encontrou nada e ainda assim levou
4.517 µs, porque precisou olhar cada chave para não encontrar nada. Num espaço de chaves de produção
com milhões, ele leva segundos, durante os quais o Redis não responde a ninguém; o `SCAN` é a versão
que percorre em passos pequenos.

O `LATENCY DOCTOR` lê o que o monitor de latência registrou, eventos acima dos 5 ms com que o
contêiner foi iniciado, e escreve um relatório em prosa. Nesta execução ele não viu nada digno de
nota e disse isso do jeito dele. Quando vê alguma coisa, nomeia o tipo de evento, como `command` ou
`eviction-cycle`, com a média e o pior tempo e um parágrafo de conselhos. Ele precisa de
`latency-monitor-threshold` acima de zero, e o padrão é zero, então na maioria dos servidores ele não
tem nada a dizer até alguém ligá-lo.
