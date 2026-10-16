---
title: Faixas, o balancer, e uma chave com um valor só
version: 1
---

O mapa que um config server guarda é uma lista de **faixas**, que a documentação antiga chama de
chunks, cada uma um trecho de valores da chave de shard que pertence a um shard. Nada garante que as
faixas continuem justas: os dados chegam para onde a chave os manda, e um shard enche mais rápido que
outro. **O balancer é um processo no config server que mede quantos dados cada shard possui, por
coleção, e move faixas do mais cheio para o mais vazio** até a diferença ficar pequena.

## Vendo-o mover dados

Desde o MongoDB 7.0 o balancer compara tamanho de dados em vez de contar faixas, e só age quando a
diferença entre dois shards passa de umas três vezes o tamanho de faixa da coleção. O tamanho de
faixa padrão é 128 MB, muito mais do que uma coleção de laboratório guarda, então o
`configureCollectionBalancing` o define como 1 MB para esta coleção. Mais dois auxiliares se juntam
ao `spread`: `ranges` imprime o mapa de uma coleção, uma linha por faixa, com a palavra `jumbo` onde
o cluster desistiu de uma faixa; `visits` grava 100.000 visualizações de página, todas do Brasil,
numeradas por `visitId`. A chave é `{ country: 1, visitId: 1 }`:

```
ana@vm:~$ docker exec -it mongos mongosh --quiet shop
[direct: mongos] shop> function spread(coll) { return db.getSiblingDB("admin").aggregate([{ $shardedDataDistribution: {} }, { $match: { ns: "shop." + coll } }, { $unwind: "$shards" }, { $project: { _id: 0, shard: "$shards.shardName", owned: "$shards.numOwnedDocuments", orphaned: "$shards.numOrphanedDocs" } }]).toArray() }
[Function: spread]
[direct: mongos] shop> function ranges(coll) { const uuid = db.getSiblingDB("config").collections.findOne({ _id: "shop." + coll }).uuid; db.getSiblingDB("config").chunks.find({ uuid }).sort({ min: 1 }).forEach(c => print(c.shard, EJSON.stringify(c.min), EJSON.stringify(c.max), c.jumbo ? "jumbo" : "")) }
[Function: ranges]
[direct: mongos] shop> function visits(coll) { for (let b = 0; b < 10; b++) { const docs = []; for (let i = 0; i < 10000; i++) docs.push({ country: "BR", visitId: b * 10000 + i, sku: "MS-204", page: "/products/MS-204" }); db.getCollection(coll).insertMany(docs) } return db.getCollection(coll).countDocuments() }
[Function: visits]
[direct: mongos] shop> sh.shardCollection("shop.visits", { country: 1, visitId: 1 })
{
  collectionsharded: 'shop.visits',
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1791683288, i: 39 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: Long('0')
    }
  },
  operationTime: Timestamp({ t: 1791683288, i: 39 })
}
[direct: mongos] shop> db.adminCommand({ configureCollectionBalancing: "shop.visits", chunkSize: 1 }).ok
1
[direct: mongos] shop> visits("visits")
100000
[direct: mongos] shop> spread("visits")
[ { shard: 'shard1', owned: 100000, orphaned: 0 } ]
[direct: mongos] shop> spread("visits")
[
  { shard: 'shard2', owned: 33462, orphaned: 0 },
  { shard: 'shard1', owned: 66538, orphaned: 33462 }
]
[direct: mongos] shop> ranges("visits")
shard2 {"country":{"$minKey":1},"visitId":{"$minKey":1}} {"country":"BR","visitId":11154} 
shard2 {"country":"BR","visitId":11154} {"country":"BR","visitId":22308} 
shard2 {"country":"BR","visitId":22308} {"country":"BR","visitId":33462} 
shard1 {"country":"BR","visitId":33462} {"country":{"$maxKey":1},"visitId":{"$maxKey":1}} 

[direct: mongos] shop> exit
```

Logo depois dos inserts, o `shard1` possuía as 100.000: a coleção começou como uma faixa só no shard
primário do banco. A captura então esperou noventa segundos. **Nesse ponto o balancer tinha separado
três faixas de 11.154 visitas cada e as tinha movido para o `shard2`**, que possuía 33.462.

A coluna `orphaned` é a outra metade de uma movimentação. Uma migração copia uma faixa para o novo
shard, troca a posse no mapa, e só então apaga a cópia antiga, depois de um atraso de quinze minutos
por padrão, para que consultas já rodando no shard antigo possam terminar. Até lá o `shard1` ainda
guarda 33.462 documentos que não possui mais, e toda contagem pelo `mongos` os deixa de fora.

## Uma chave com um valor só

Agora as mesmas 100.000 visitas, shardeadas só por `{ country: 1 }`. Toda visita diz `"BR"`, então a
chave tem **um valor só**:

```
ana@vm:~$ docker exec -it mongos mongosh --quiet shop
[direct: mongos] shop> function ranges(coll) { const uuid = db.getSiblingDB("config").collections.findOne({ _id: "shop." + coll }).uuid; db.getSiblingDB("config").chunks.find({ uuid }).sort({ min: 1 }).forEach(c => print(c.shard, EJSON.stringify(c.min), EJSON.stringify(c.max), c.jumbo ? "jumbo" : "")) }
[Function: ranges]
[direct: mongos] shop> function visits(coll) { for (let b = 0; b < 10; b++) { const docs = []; for (let i = 0; i < 10000; i++) docs.push({ country: "BR", visitId: b * 10000 + i, sku: "MS-204", page: "/products/MS-204" }); db.getCollection(coll).insertMany(docs) } return db.getCollection(coll).countDocuments() }
[Function: visits]
[direct: mongos] shop> sh.shardCollection("shop.visits_by_country", { country: 1 })
{
  collectionsharded: 'shop.visits_by_country',
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1791683389, i: 40 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: Long('0')
    }
  },
  operationTime: Timestamp({ t: 1791683389, i: 40 })
}
[direct: mongos] shop> db.adminCommand({ configureCollectionBalancing: "shop.visits_by_country", chunkSize: 1 }).ok
1
[direct: mongos] shop> visits("visits_by_country")
100000
[direct: mongos] shop> ranges("visits_by_country")
shard1 {"country":{"$minKey":1}} {"country":{"$maxKey":1}} jumbo

[direct: mongos] shop> sh.splitFind("shop.visits_by_country", { country: "BR" })
Uncaught 
MongoServerError[CannotSplit]: Unable to find median in chunk because chunk is indivisible.
[direct: mongos] shop> exit
```

Uma faixa, do menor valor possível ao maior, marcada `jumbo`, e ainda no `shard1` depois de um
minuto. Quando se pediu para dividi-la na mediana, o cluster respondeu que a faixa é `indivisible`.
**Uma faixa só pode ser cortada entre dois valores diferentes da chave**, e aqui não há segundo
valor. O balancer não consegue mover parte da coleção, e não vai mover a coleção inteira, então ele
para de tentar e marca a faixa.

Isso é **cardinalidade**, o número de valores distintos que uma chave pode assumir, e ela é um teto
para o quanto a coleção pode ser espalhada: uma chave com quatro valores nunca usa mais de quatro
shards, por mais shards que você acrescente. Um campo de status, um país, uma flag booleana são todas
chaves que parecem inofensivas no começo e enchem um shard. A próxima seção muda esta.
