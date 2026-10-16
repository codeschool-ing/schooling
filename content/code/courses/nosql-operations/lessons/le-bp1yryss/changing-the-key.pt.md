---
title: A chave que não dá para mudar depois, e quanto custa mudá-la hoje
version: 1
---

Durante a maior parte da história do MongoDB o título desta aula era literalmente verdade. A chave
de shard ficava fixa quando a coleção era shardeada, e mudá-la queria dizer criar uma coleção nova
com a chave nova, copiar todo documento e trocar a aplicação de coleção. **Isso mudou em dois
passos, e nenhum deles deixou a mudança barata.**

| versão | comando | o que faz |
|---|---|---|
| 4.4 | `refineCollectionShardKey` | acrescenta campos ao **fim** da chave existente; nada se move |
| 5.0 | `reshardCollection` | qualquer chave nova; a coleção inteira é copiada para os novos lugares |
| 8.0 | `unshardCollection`, `moveCollection` | transformam uma coleção shardeada de volta em não shardeada, ou movem uma não shardeada para outro shard; não executados aqui |

## Refinar: barato, e numa direção só

A chave de valor único da seção anterior pode ser refinada para `{ country: 1, visitId: 1 }`,
porque a chave nova começa pela antiga. Ela precisa antes de um índice na chave nova:

```
ana@vm:~$ docker exec -it mongos mongosh --quiet shop
[direct: mongos] shop> function spread(coll) { return db.getSiblingDB("admin").aggregate([{ $shardedDataDistribution: {} }, { $match: { ns: "shop." + coll } }, { $unwind: "$shards" }, { $project: { _id: 0, shard: "$shards.shardName", owned: "$shards.numOwnedDocuments", orphaned: "$shards.numOrphanedDocs" } }]).toArray() }
[Function: spread]
[direct: mongos] shop> function ranges(coll) { const uuid = db.getSiblingDB("config").collections.findOne({ _id: "shop." + coll }).uuid; db.getSiblingDB("config").chunks.find({ uuid }).sort({ min: 1 }).forEach(c => print(c.shard, EJSON.stringify(c.min), EJSON.stringify(c.max), c.jumbo ? "jumbo" : "")) }
[Function: ranges]
[direct: mongos] shop> db.visits_by_country.createIndex({ country: 1, visitId: 1 })
country_1_visitId_1
[direct: mongos] shop> db.adminCommand({ refineCollectionShardKey: "shop.visits_by_country", key: { country: 1, visitId: 1 } }).ok
1
[direct: mongos] shop> ranges("visits_by_country")
shard2 {"country":{"$minKey":1},"visitId":{"$minKey":1}} {"country":"BR","visitId":11154} 
shard2 {"country":"BR","visitId":11154} {"country":"BR","visitId":22308} 
shard2 {"country":"BR","visitId":22308} {"country":"BR","visitId":33462} 
shard1 {"country":"BR","visitId":33462} {"country":{"$maxKey":1},"visitId":{"$maxKey":1}} 

[direct: mongos] shop> spread("visits_by_country")
[
  { shard: 'shard2', owned: 33462, orphaned: 0 },
  { shard: 'shard1', owned: 66538, orphaned: 33462 }
]
[direct: mongos] shop> exit
```

O refine em si mudou só o mapa: toda faixa existente agora também tem limites de `visitId`. **O que
ele comprou foi a capacidade de dividir.** Noventa segundos depois o balancer tinha dividido a faixa
antes indivisível e movido três pedaços para o `shard2`, exatamente como fez com `visits`, que foi
shardeada por essa chave desde o início. Refinar não remove um campo, não reordena campos e não muda
o primeiro campo. Conserta uma chave grossa demais, e nada mais.

## Resharding: qualquer coisa, ao preço de uma cópia inteira

`orders` foi shardeada pelo `orderId` que cresce na seção sobre a chave de shard, e todo pedido novo
cai num shard só. Refinar não ajuda: acrescentar um campo depois de `orderId` ainda ordena primeiro
por `orderId`. **O `reshardCollection` aceita uma chave inteiramente nova** e reconstrói a coleção
com ela:

```
ana@vm:~$ docker exec -it mongos mongosh --quiet shop
[direct: mongos] shop> function spread(coll) { return db.getSiblingDB("admin").aggregate([{ $shardedDataDistribution: {} }, { $match: { ns: "shop." + coll } }, { $unwind: "$shards" }, { $project: { _id: 0, shard: "$shards.shardName", owned: "$shards.numOwnedDocuments", orphaned: "$shards.numOrphanedDocs" } }]).toArray() }
[Function: spread]
[direct: mongos] shop> const started = Date.now()

[direct: mongos] shop> db.adminCommand({ reshardCollection: "shop.orders", key: { orderId: "hashed" } }).ok
1
[direct: mongos] shop> (Date.now() - started) / 1000
332.94
[direct: mongos] shop> spread("orders")
[
  { shard: 'shard1', owned: 9859, orphaned: 0 },
  { shard: 'shard2', owned: 10141, orphaned: 0 }
]
[direct: mongos] shop> db.orders.find({ orderId: { $gte: 100, $lt: 200 } }).explain().queryPlanner.winningPlan.stage
SHARD_MERGE
[direct: mongos] shop> exit
ana@vm:~$ docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}" cfg1 shard1 shard2 mongos
NAME      MEM USAGE / LIMIT
cfg1      127.8MiB / 15.72GiB
shard1    221.4MiB / 15.72GiB
shard2    188.2MiB / 15.72GiB
mongos    46.66MiB / 15.72GiB
```

Levou **332,94 segundos** para 20.000 pedidos pequenos, cinco minutos e meio. Esse número quase não
é trabalho: por padrão o resharding passa pelo menos cinco minutos copiando, para que os shards
tenham tempo de acompanhar as escritas que chegam durante a cópia, e numa coleção real a cópia em si
passa a dominar. Depois disso os pedidos ficaram espalhados em 9.859 e 10.141, a mesma divisão da
coleção hashed, e uma faixa de números de pedido virou uma consulta `SHARD_MERGE`, o preço que a
seção sobre a chave de shard mostrou para uma chave hashed.

O que o resharding faz por baixo é o antigo procedimento manual, automatizado. Cada shard constrói a
coleção de novo com a chave nova, copiando cada documento para o shard que a chave nova indica e
aplicando as escritas que chegam enquanto isso. No fim o cluster bloqueia as escritas na coleção
por um instante curto enquanto faz a troca. **Ele precisa de disco livre para uma segunda cópia da
coleção nos shards, e põe a carga de mover tudo num cluster que provavelmente está fazendo
resharding porque já estava em apuros.**

Então "a chave que não dá para mudar depois" agora é "a chave que custa uma cópia inteira para mudar
depois". A escolha feita no primeiro dia continua sendo aquela com que o cluster vive, a menos que
você pague por outra; o padrão de acesso da aula 3 é de onde você a escolhe.
