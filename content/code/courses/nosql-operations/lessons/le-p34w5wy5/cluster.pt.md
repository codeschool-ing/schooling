---
title: Redis Cluster, slots e o failover dentro dele
version: 1
---

O Sentinel mantém disponível um conjunto de dados. Não faz nada por um conjunto maior que uma máquina,
nem por uma taxa de escrita que uma máquina não aguenta: toda escrita continua indo para um primário.
**O Redis Cluster divide os dados entre vários primários**, cada um com as suas réplicas, e leva o
failover para dentro dos próprios servidores, sem Sentinel nenhum.

## 16.384 slots

Um cluster divide o espaço de chaves em **16.384 hash slots**. O slot de uma chave é um hash do nome
dela, CRC16 módulo 16.384, e cada primário é dono de uma faixa de slots. Qualquer servidor diz em que
slot uma chave está, e qual servidor é o dono; um cliente que manda uma chave ao servidor errado é
informado de para onde ir, em vez de ser atendido.

## Seis nós

Três primários e uma réplica para cada um. O laboratório do Sentinel sai primeiro; depois, seis
servidores com o modo cluster ligado e um timeout de nó de cinco segundos, o `down-after-milliseconds`
do próprio cluster:

```
ana@vm:~$ docker rm -f redis-1 redis-2 redis-3 sentinel-1 sentinel-2 sentinel-3
redis-1
redis-2
redis-3
sentinel-1
sentinel-2
sentinel-3
ana@vm:~$ for i in 1 2 3 4 5 6; do docker run -d --name node-$i --network nosql redis:7.4 redis-server --cluster-enabled yes --cluster-node-timeout 5000; done
c3b0315bf8df7bc8e5fb411e292ab8abddad28f9ccf3a67f65289e96e6e57c4a
4ddbfe602ac08f206d01b55054c0d73205386d4d733afa6b7630a6bb53e5ac22
39b3e975268188ab1acef7f4c02f00267603e091ee6819f51bbd49972c8568b9
fdaa7143c9bf53a3d23fbb7df3ed6d4d628b296b1a89e8ebf80faf085694a9b5
ff9c7371ac71c04f0d8df4f64958a6d523026813d5137e43d19d068934a1e34a
f59e85439d03e0c496d3c795d0dc6ca712756f8b1cae21aa240f385400fb165c
ana@vm:~$ ips=$(for i in 1 2 3 4 5 6; do docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}:6379' node-$i; done); echo $ips
172.18.0.2:6379 172.18.0.3:6379 172.18.0.4:6379 172.18.0.5:6379 172.18.0.6:6379 172.18.0.7:6379
```

O `redis-cli --cluster create` quer endereços, não nomes, então o terceiro comando pede ao Docker o
endereço de cada nó na rede. Depois um comando forma o cluster: `--cluster-replicas 1` pede uma réplica
por primário, então dos seis nós três viram primários, e `--cluster-yes` aceita o arranjo que ele propõe
em vez de perguntar:

```
ana@vm:~$ docker exec node-1 redis-cli --cluster create $ips --cluster-replicas 1 --cluster-yes
>>> Performing hash slots allocation on 6 nodes...
Master[0] -> Slots 0 - 5460
Master[1] -> Slots 5461 - 10922
Master[2] -> Slots 10923 - 16383
Adding replica 172.18.0.6:6379 to 172.18.0.2:6379
Adding replica 172.18.0.7:6379 to 172.18.0.3:6379
Adding replica 172.18.0.5:6379 to 172.18.0.4:6379
M: a43e40b3d1c18772cf5ef54a2537a18f687e4ce8 172.18.0.2:6379
   slots:[0-5460] (5461 slots) master
M: e0c513ff83ee74d532e5bacd29589e43acae8675 172.18.0.3:6379
   slots:[5461-10922] (5462 slots) master
M: 72c910109e09b056709c8121bf4c136465ee73e9 172.18.0.4:6379
   slots:[10923-16383] (5461 slots) master
S: 1315e9ee2bf8b0cbc4cc313582591af3108ca4b3 172.18.0.5:6379
   replicates 72c910109e09b056709c8121bf4c136465ee73e9
S: 45581110339d850d8d5390cead354011d83d9978 172.18.0.6:6379
   replicates a43e40b3d1c18772cf5ef54a2537a18f687e4ce8
S: d89c3791b873c3dfe32f267febb08e5e14e24977 172.18.0.7:6379
   replicates e0c513ff83ee74d532e5bacd29589e43acae8675
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join
..
>>> Performing Cluster Check (using node 172.18.0.2:6379)
M: a43e40b3d1c18772cf5ef54a2537a18f687e4ce8 172.18.0.2:6379
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
M: e0c513ff83ee74d532e5bacd29589e43acae8675 172.18.0.3:6379
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
M: 72c910109e09b056709c8121bf4c136465ee73e9 172.18.0.4:6379
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
S: 1315e9ee2bf8b0cbc4cc313582591af3108ca4b3 172.18.0.5:6379
   slots: (0 slots) slave
   replicates 72c910109e09b056709c8121bf4c136465ee73e9
S: 45581110339d850d8d5390cead354011d83d9978 172.18.0.6:6379
   slots: (0 slots) slave
   replicates a43e40b3d1c18772cf5ef54a2537a18f687e4ce8
S: d89c3791b873c3dfe32f267febb08e5e14e24977 172.18.0.7:6379
   slots: (0 slots) slave
   replicates e0c513ff83ee74d532e5bacd29589e43acae8675
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```

Os três primeiros endereços viraram primários, com os slots divididos em três faixas, e cada um dos
outros três replica um deles. O resumo do próprio cluster:

```
ana@vm:~$ docker exec node-1 redis-cli CLUSTER INFO | grep -E "^cluster_(state|slots_assigned|known_nodes|size):"
cluster_state:ok
cluster_slots_assigned:16384
cluster_known_nodes:6
cluster_size:3
ana@vm:~$ docker exec node-1 redis-cli CLUSTER NODES | cut -d' ' -f2,3,9 | sort
172.18.0.2:6379@16379 myself,master 0-5460
172.18.0.3:6379@16379 master 5461-10922
172.18.0.4:6379@16379 master 10923-16383
172.18.0.5:6379@16379 slave
172.18.0.6:6379@16379 slave
172.18.0.7:6379@16379 slave
```

`cluster_state:ok`, os 16.384 slots atribuídos, seis nós e um **size** de 3: o número de primários
servindo slots. A lista de nós mostra o endereço, o papel e a faixa de slots de cada primário.

## Redirecionamentos

O `redis-cli` sem `-c` trata um nó do cluster como um servidor só, e é avisado quando uma chave mora em
outro lugar:

```
ana@vm:~$ docker exec -it node-1 redis-cli
127.0.0.1:6379> CLUSTER KEYSLOT product:KB-101
(integer) 14967
127.0.0.1:6379> SET product:KB-101 34990
(error) MOVED 14967 172.18.0.4:6379
```

**`MOVED 14967` e um endereço** é a resposta do cluster: o slot 14967 mora naquele nó, pergunte lá.
Nada foi gravado. Com `-c`, o `redis-cli` segue o redirecionamento sozinho, como faz uma biblioteca de
cliente que conhece o cluster, e o prompt dele passa para o nó para onde foi mandado:

```
ana@vm:~$ docker exec -it node-1 redis-cli -c
127.0.0.1:6379> SET product:KB-101 34990
-> Redirected to slot [14967] located at 172.18.0.4:6379
OK
172.18.0.4:6379> GET product:KB-101
"34990"
```

## Chaves que precisam ficar juntas

Um comando que mexe em várias chaves só funciona se elas estiverem no mesmo slot, porque senão nenhum
nó conseguiria aplicá-lo de forma atômica:

```
ana@vm:~$ docker exec -it node-1 redis-cli -c
127.0.0.1:6379> MSET cart:ana:items KB-101 cart:ana:total 34990
(error) CROSSSLOT Keys in request don't hash to the same slot
127.0.0.1:6379> CLUSTER KEYSLOT cart:ana:items
(integer) 186
127.0.0.1:6379> CLUSTER KEYSLOT cart:ana:total
(integer) 12994
127.0.0.1:6379> CLUSTER KEYSLOT {cart:ana}:items
(integer) 10321
127.0.0.1:6379> CLUSTER KEYSLOT {cart:ana}:total
(integer) 10321
127.0.0.1:6379> MSET {cart:ana}:items KB-101 {cart:ana}:total 34990
-> Redirected to slot [10321] located at 172.18.0.3:6379
OK
```

`CROSSSLOT`: as duas chaves do carrinho da Ana caem em slots diferentes, então o `MSET` não consegue
gravá-las juntas, e uma transação ou um script Lua também não. **Uma hash tag** resolve: quando uma
chave contém `{…}`, só a parte dentro das chaves entra no hash, então `{cart:ana}:items` e
`{cart:ana}:total` dividem um slot e o `MSET` deu certo. O preço é que uma hash tag pode concentrar
dados: ponha o carrinho de todo cliente sob uma tag e um slot guarda todos eles, num nó só, que é a
partição quente da aula 3.

## Um primário some

O nó dono do slot de `product:KB-101` é parado:

```
ana@vm:~$ docker stop node-3
node-3
ana@vm:~$ docker exec node-1 redis-cli CLUSTER NODES | cut -d' ' -f2,3,9 | sort
172.18.0.2:6379@16379 myself,master 0-5460
172.18.0.3:6379@16379 master 5461-10922
172.18.0.4:6379@16379 master,fail
172.18.0.5:6379@16379 master 10923-16383
172.18.0.6:6379@16379 slave
172.18.0.7:6379@16379 slave
ana@vm:~$ docker exec node-1 redis-cli CLUSTER INFO | grep -E "^cluster_state:"
cluster_state:ok
```

Cinco segundos de silêncio é o timeout do nó. Os outros primários marcaram `172.18.0.4` como `fail`, e
a réplica dele, `172.18.0.5`, virou primário com os slots `10923-16383`. O `cluster_state` continuou
`ok`, porque todo slot ainda tem dono. Perguntado de novo pelo teclado, o nó 1 manda o cliente ao novo
dono:

```
ana@vm:~$ docker exec -it node-1 redis-cli -c
127.0.0.1:6379> GET product:KB-101
-> Redirected to slot [14967] located at 172.18.0.5:6379
"34990"
```

O preço do teclado ainda estava lá, servido pela réplica promovida: ele foi replicado antes da parada.
Uma escrita confirmada pelo primário antigo no instante antes de ele morrer, e ainda não replicada,
teria se perdido exatamente como na seção anterior. **A replicação do Cluster também é assíncrona**, e o
`WAIT` existe lá pelo mesmo motivo e com o mesmo limite.
