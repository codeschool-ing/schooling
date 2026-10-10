---
title: O primário que perde a maioria
version: 1
---

A aula 1 prometeu mostrar o teorema acontecendo, e esta é a metade do MongoDB nessa promessa. Uma
queda é fácil de entender: o membro morto fica em silêncio. **Uma partição é mais difícil, porque o
membro isolado está vivo, acredita ser o primário e ainda tem clientes falando com ele.** A regra que
resolve isso é a mesma com que esta aula começou: só um membro que alcança a maioria pode agir como
primário.

## Isolando o primário

O `docker network disconnect` tira um contêiner de uma rede sem pará-lo. O `docker exec` não passa
por essa rede, então você ainda consegue digitar no membro isolado. Nesta execução o primário era o
`mongo3`; use o nome do seu:

```
ana@vm:~$ docker network disconnect nosql mongo3
ana@vm:~$ docker exec -it mongo3 mongosh --quiet shop
rs0 [direct: primary] shop> db.orders.insertOne({ _id: 1001, customer: "ana@example.com", sku: "MN-330", qty: 1 }, { writeConcern: { w: 1 } })
{ acknowledged: true, insertedId: 1001 }
rs0 [direct: primary] shop> rs.status().members.map(m => ({ name: m.name, state: m.stateStr, health: m.health }))
[
  { name: 'mongo1:27017', state: '(not reachable/healthy)', health: 0 },
  { name: 'mongo2:27017', state: '(not reachable/healthy)', health: 0 },
  { name: 'mongo3:27017', state: 'SECONDARY', health: 1 }
]
rs0 [direct: secondary] shop> db.orders.insertOne({ _id: 1003, customer: "carla@example.com", sku: "CB-012", qty: 2 }, { writeConcern: { w: 1 } })
Uncaught 
MongoServerError[NotWritablePrimary]: not primary
rs0 [direct: secondary] shop> exit
```

O primeiro insert, mandado com `w: 1` no segundo seguinte ao corte, foi **confirmado**: o `mongo3`
ainda não tinha percebido nada. A captura então esperou quinze segundos antes de perguntar de novo.
Nesse ponto o `mongo3` já tinha perdido seus heartbeats, visto que o único membro que alcançava era
ele mesmo, e **descido sozinho para `SECONDARY`**. A escrita seguinte foi recusada com
`not primary`.

Essa recusa é o lado da consistência na escolha da aula 1. Um membro que não alcança a maioria não
tem como saber se os outros elegeram outro, então para de aceitar escritas em vez de arriscar uma
segunda história. Os clientes do lado dele recebem erros enquanto a partição durar.

## O outro lado

```
ana@vm:~$ docker exec mongo1 mongosh --quiet --eval 'rs.status().members.map(m => ({ name: m.name, state: m.stateStr, health: m.health }))'
[
  { name: 'mongo1:27017', state: 'SECONDARY', health: 1 },
  { name: 'mongo2:27017', state: 'PRIMARY', health: 1 },
  { name: 'mongo3:27017', state: '(not reachable/healthy)', health: 0 }
]
ana@vm:~$ docker exec -it mongo2 mongosh --quiet shop
rs0 [direct: primary] shop> db.orders.insertOne({ _id: 1002, customer: "bruno@example.com", sku: "MN-330", qty: 1 })
{ acknowledged: true, insertedId: 1002 }
rs0 [direct: primary] shop> exit
```

Os dois membros ainda conectados viram o `mongo3` como inalcançável, fizeram uma eleição entre si,
e o `mongo2` venceu. O pedido do Bruno para o mesmo monitor foi gravado com o write concern padrão,
`majority`, que dois membros conectados conseguem satisfazer.

## A cura, e a escrita que desaparece

Reconecte o `mongo3` e dê a ele uns quinze segundos:

```
ana@vm:~$ docker network connect nosql mongo3
ana@vm:~$ docker exec mongo3 mongosh --quiet --eval 'rs.status().members.map(m => ({ name: m.name, state: m.stateStr, health: m.health }))'
[
  { name: 'mongo1:27017', state: 'SECONDARY', health: 1 },
  { name: 'mongo2:27017', state: 'PRIMARY', health: 1 },
  { name: 'mongo3:27017', state: 'SECONDARY', health: 1 }
]
ana@vm:~$ docker exec mongo3 mongosh --quiet shop --eval 'db.orders.find()'
[ { _id: 1002, customer: 'bruno@example.com', sku: 'MN-330', qty: 1 } ]
ana@vm:~$ docker exec mongo3 find /data/db/rollback -name '*.bson'
/data/db/rollback/401e7bfa-7b2f-4bd4-a894-5a232c5c6843/removed.2026-10-10T07-56-28.0.bson
ana@vm:~$ docker exec mongo3 sh -c 'bsondump /data/db/rollback/*/removed.*.bson'
{"_id":{"$numberInt":"1001"},"customer":"ana@example.com","sku":"MN-330","qty":{"$numberInt":"1"}}
2026-10-10T07:56:44.989+0000	1 objects found
```

O `mongo3` voltou como secundário, e **o pedido da Ana sumiu**. Só o do Bruno está na coleção.
Quando o `mongo3` voltou, comparou o oplog dele com o do novo primário, achou o ponto em que os dois
divergiram e desfez tudo o que tinha gravado depois dele. Isso é um **rollback**. Os documentos
desfeitos não são simplesmente apagados: vão para um arquivo BSON em `/data/db/rollback`, que o
`bsondump` transforma de volta em JSON, e nada os aplica de novo a não ser uma pessoa.

O cliente da Ana tinha recebido `acknowledged: true`. Não era mentira, porque `w: 1` promete só que
o primário tem a escrita, e o primário que ela alcançou acabou do lado perdedor. Com o padrão
`w: "majority"` o mesmo insert teria esperado, falhado quando o `mongo3` renunciou, e a Ana teria
visto um erro em vez de um pedido que depois desapareceu.

**Escritas com majority são o que torna segura a renúncia.** A minoria recusa, a maioria elege, e
toda escrita que uma maioria confirmou está do lado que segue em frente. Baixar o write concern para
`w: 1` mantém a velocidade e abre mão dessa última garantia, e um arquivo de rollback que ninguém lê
é onde o custo aparece.
