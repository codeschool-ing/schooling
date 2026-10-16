---
title: A chave de shard, por faixa ou hashed
version: 1
---

A chave de shard é um campo, ou alguns campos, que todo documento de uma coleção shardeada tem.
**O cluster corta a faixa de valores dela em pedaços e entrega cada pedaço a um shard**, então a
chave decide duas coisas ao mesmo tempo: onde cada documento novo é gravado, e quais shards uma
consulta precisa perguntar. Uma chave boa para uma e ruim para a outra é o erro comum, e a versão
mais frequente dele parece perfeitamente sensata.

## Um número de pedido que só cresce

Números de pedido sobem de um em um a cada pedido novo. Como chave **por faixa**, `{ orderId: 1 }`,
os valores ficam em ordem, então pedidos vizinhos ficam na mesma faixa. A sessão abaixo shardeia
`orders` por ela, divide a coleção vazia em 5001 e move a faixa de cima para o `shard2`, para que
cada shard tenha metade da reta numérica antes de qualquer escrita.

Dois auxiliares são digitados primeiro, porque a sessão usa cada um duas vezes. `spread` pergunta ao
cluster quantos documentos cada shard possui, pelo estágio `$shardedDataDistribution`. `load` gera
pedidos com números consecutivos entre dois valores, do jeito que chegam os números de pedido de uma
loja, e devolve a contagem da coleção:

```
ana@vm:~$ docker exec -it mongos mongosh --quiet shop
[direct: mongos] shop> sh.enableSharding("shop", "shard1")
{
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1791683230, i: 3 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: Long('0')
    }
  },
  operationTime: Timestamp({ t: 1791683229, i: 6 })
}
[direct: mongos] shop> sh.shardCollection("shop.orders", { orderId: 1 })
{
  collectionsharded: 'shop.orders',
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1791683231, i: 36 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: Long('0')
    }
  },
  operationTime: Timestamp({ t: 1791683231, i: 36 })
}
[direct: mongos] shop> sh.splitAt("shop.orders", { orderId: 5001 })
{
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1791683232, i: 7 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: Long('0')
    }
  },
  operationTime: Timestamp({ t: 1791683232, i: 7 })
}
[direct: mongos] shop> sh.moveChunk("shop.orders", { orderId: 5001 }, "shard2")
{
  millis: 192,
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1791683233, i: 42 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: Long('0')
    }
  },
  operationTime: Timestamp({ t: 1791683233, i: 42 })
}
[direct: mongos] shop> function spread(coll) { return db.getSiblingDB("admin").aggregate([{ $shardedDataDistribution: {} }, { $match: { ns: "shop." + coll } }, { $unwind: "$shards" }, { $project: { _id: 0, shard: "$shards.shardName", owned: "$shards.numOwnedDocuments", orphaned: "$shards.numOrphanedDocs" } }]).toArray() }
[Function: spread]
[direct: mongos] shop> function load(coll, first, last) { const customers = ["ana@example.com", "bruno@example.com", "carla@example.com", "diego@example.com", "elisa@example.com"]; const docs = []; for (let id = first; id <= last; id++) docs.push({ orderId: id, customer: customers[id % 5], sku: "KB-101", qty: 1 + id % 3 }); db.getCollection(coll).insertMany(docs); return db.getCollection(coll).countDocuments() }
[Function: load]
[direct: mongos] shop> load("orders", 1, 10000)
10000
[direct: mongos] shop> spread("orders")
[
  { shard: 'shard2', owned: 5000, orphaned: 0 },
  { shard: 'shard1', owned: 5000, orphaned: 0 }
]
[direct: mongos] shop> load("orders", 10001, 20000)
20000
[direct: mongos] shop> spread("orders")
[
  { shard: 'shard1', owned: 5000, orphaned: 0 },
  { shard: 'shard2', owned: 15000, orphaned: 0 }
]
[direct: mongos] shop> exit
```

Os primeiros 10.000 pedidos se dividiram por igual, 5.000 por shard, porque metade dos números caiu
abaixo de 5001. **Os 10.000 seguintes foram todos para o `shard2`**, que terminou com 15.000 contra
5.000 do `shard1`. Todo número de pedido novo é maior que qualquer anterior, então todo pedido novo
cai na faixa de cima, e a faixa de cima está num shard só. Divida-a de novo e o pedaço mais novo
continua num shard só; mova-o e o ponto quente vai junto. Com uma chave que cresce, **toda a carga de
escrita cai num shard de cada vez**, e acrescentar shards acrescenta máquinas que não recebem nada
dela. Timestamps, `ObjectId`s e qualquer contador se comportam do mesmo jeito.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Duas retas de números de pedido. Em cima, uma chave por faixa: o shard1 tem os números abaixo de 5001 e o shard2 os de 5001 para cima, e todo pedido novo, numerado de 10.001 a 20.000, cai na ponta de cima, no shard2. Embaixo, uma chave hashed: os mesmos pedidos novos passam pelo hash, e os hashes caem pela faixa inteira, nos dois shards.\"><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">chave por faixa</text><rect x=\"40\" y=\"50\" width=\"220\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"150\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shard1</text><rect x=\"260\" y=\"50\" width=\"400\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"460\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shard2</text><text x=\"40\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">MinKey</text><text x=\"260\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">5001</text><text x=\"660\" y=\"94\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">MaxKey</text><text x=\"560\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pedidos novos de 10.001 a 20.000</text><line x1=\"600\" y1=\"52\" x2=\"600\" y2=\"78\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><line x1=\"608\" y1=\"52\" x2=\"608\" y2=\"78\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><line x1=\"616\" y1=\"52\" x2=\"616\" y2=\"78\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><line x1=\"624\" y1=\"52\" x2=\"624\" y2=\"78\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><line x1=\"632\" y1=\"52\" x2=\"632\" y2=\"78\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><line x1=\"640\" y1=\"52\" x2=\"640\" y2=\"78\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><line x1=\"648\" y1=\"52\" x2=\"648\" y2=\"78\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><text x=\"560\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">os 10.000 aqui</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">chave hashed</text><rect x=\"40\" y=\"170\" width=\"310\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"195\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shard1</text><rect x=\"350\" y=\"170\" width=\"310\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"505\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shard2</text><line x1=\"242.9\" y1=\"172\" x2=\"242.9\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"137.7\" y1=\"172\" x2=\"137.7\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"441.8\" y1=\"172\" x2=\"441.8\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"90.0\" y1=\"172\" x2=\"90.0\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"371.8\" y1=\"172\" x2=\"371.8\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"268.3\" y1=\"172\" x2=\"268.3\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"81.3\" y1=\"172\" x2=\"81.3\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"354.5\" y1=\"172\" x2=\"354.5\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"68.8\" y1=\"172\" x2=\"68.8\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"309.7\" y1=\"172\" x2=\"309.7\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"88.5\" y1=\"172\" x2=\"88.5\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"101.2\" y1=\"172\" x2=\"101.2\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"304.1\" y1=\"172\" x2=\"304.1\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"548.7\" y1=\"172\" x2=\"548.7\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"121.3\" y1=\"172\" x2=\"121.3\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"181.7\" y1=\"172\" x2=\"181.7\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"427.5\" y1=\"172\" x2=\"427.5\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"622.2\" y1=\"172\" x2=\"622.2\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"396.9\" y1=\"172\" x2=\"396.9\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"287.2\" y1=\"172\" x2=\"287.2\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"639.6\" y1=\"172\" x2=\"639.6\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"74.3\" y1=\"172\" x2=\"74.3\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"567.9\" y1=\"172\" x2=\"567.9\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"222.1\" y1=\"172\" x2=\"222.1\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"133.7\" y1=\"172\" x2=\"133.7\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"117.6\" y1=\"172\" x2=\"117.6\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"233.6\" y1=\"172\" x2=\"233.6\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"542.2\" y1=\"172\" x2=\"542.2\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"155.9\" y1=\"172\" x2=\"155.9\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"399.6\" y1=\"172\" x2=\"399.6\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"434.5\" y1=\"172\" x2=\"434.5\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"272.4\" y1=\"172\" x2=\"272.4\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"379.0\" y1=\"172\" x2=\"379.0\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"84.2\" y1=\"172\" x2=\"84.2\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"82.2\" y1=\"172\" x2=\"82.2\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"171.2\" y1=\"172\" x2=\"171.2\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"459.7\" y1=\"172\" x2=\"459.7\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"306.0\" y1=\"172\" x2=\"306.0\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"237.0\" y1=\"172\" x2=\"237.0\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"402.0\" y1=\"172\" x2=\"402.0\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><text x=\"350\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">espalhados pelos dois</text></svg>", "caption": "Para onde foram os 10.000 pedidos seguintes. Um valor que cresce sempre cai na faixa de cima; o hash dele cai em qualquer lugar."}
```

## Os mesmos pedidos com uma chave hashed

`{ orderId: "hashed" }` mantém o campo mas shardeia por um hash do valor, o que espalha números
vizinhos pela faixa inteira. Shardear uma coleção vazia desse jeito também cria uma faixa por shard
de saída:

```
ana@vm:~$ docker exec -it mongos mongosh --quiet shop
[direct: mongos] shop> function load(coll, first, last) { const customers = ["ana@example.com", "bruno@example.com", "carla@example.com", "diego@example.com", "elisa@example.com"]; const docs = []; for (let id = first; id <= last; id++) docs.push({ orderId: id, customer: customers[id % 5], sku: "KB-101", qty: 1 + id % 3 }); db.getCollection(coll).insertMany(docs); return db.getCollection(coll).countDocuments() }
[Function: load]
[direct: mongos] shop> sh.shardCollection("shop.orders_hashed", { orderId: "hashed" })
{
  collectionsharded: 'shop.orders_hashed',
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1791683244, i: 44 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: Long('0')
    }
  },
  operationTime: Timestamp({ t: 1791683244, i: 43 })
}
[direct: mongos] shop> load("orders_hashed", 1, 20000)
20000
[direct: mongos] shop> db.orders_hashed.getShardDistribution()
Shard shard2 at shard2/shard2:27017
{
  data: '907KiB',
  docs: 10141,
  chunks: 1,
  'estimated data per chunk': '907KiB',
  'estimated docs per chunk': 10141
}
---
Shard shard1 at shard1/shard1:27017
{
  data: '881KiB',
  docs: 9859,
  chunks: 1,
  'estimated data per chunk': '881KiB',
  'estimated docs per chunk': 9859
}
---
Totals
{
  data: '1.74MiB',
  docs: 20000,
  chunks: 2,
  'Shard shard2': [
    '50.7 % data',
    '50.7 % docs in cluster',
    '91B avg obj size on shard'
  ],
  'Shard shard1': [
    '49.29 % data',
    '49.29 % docs in cluster',
    '91B avg obj size on shard'
  ]
}
[direct: mongos] shop> exit
```

9.859 num shard e 10.141 no outro, a partir dos mesmos 20.000 números consecutivos. As escritas
ficam espalhadas, desde o primeiro pedido.

## O que cada chave custa a uma consulta

Agora faça as mesmas perguntas às duas coleções, e olhe só o estágio de topo do plano, que diz
quantos shards o `mongos` envolveu. `SINGLE_SHARD` quer dizer um; `SHARD_MERGE` quer dizer que ele
perguntou a todos os shards e juntou o que voltou:

```
ana@vm:~$ docker exec -it mongos mongosh --quiet shop
[direct: mongos] shop> db.orders.find({ orderId: 12345 }).explain().queryPlanner.winningPlan.stage
SINGLE_SHARD
[direct: mongos] shop> db.orders.find({ customer: "ana@example.com" }).explain().queryPlanner.winningPlan.stage
SHARD_MERGE
[direct: mongos] shop> db.orders.find({ orderId: { $gte: 100, $lt: 200 } }).explain().queryPlanner.winningPlan.stage
SINGLE_SHARD
[direct: mongos] shop> db.orders_hashed.find({ orderId: 12345 }).explain().queryPlanner.winningPlan.stage
SINGLE_SHARD
[direct: mongos] shop> db.orders_hashed.find({ orderId: { $gte: 100, $lt: 200 } }).explain().queryPlanner.winningPlan.stage
SHARD_MERGE
[direct: mongos] shop> exit
```

| consulta | `orderId` por faixa | `orderId` hashed |
|---|---|---|
| um pedido, `orderId: 12345` | um shard | um shard |
| uma faixa, `orderId` de 100 a 199 | um shard | **todos os shards** |
| por cliente, um campo fora da chave | **todos os shards** | todos os shards |

Um valor exato da chave vai a um shard nos dois tipos. **Uma faixa da chave é onde eles se
separam**: numa chave por faixa os valores são vizinhos e moram juntos, e num hash eles foram
espalhados de propósito, então a faixa precisa ser recolhida de todo lugar. E uma consulta que não
cita a chave pergunta a todos os shards seja qual for a chave, que é o argumento para escolher uma
chave que as consultas frequentes citam, o padrão de acesso da aula 3 de novo.

Então a troca está escrita na chave. **Chaves por faixa servem consultas por faixa e concentram
escritas que crescem; chaves hashed espalham escritas e espalham faixas.** Uma chave composta, como
um cliente seguido de uma data, é como uma coleção real costuma ter as duas coisas: escritas
espalhadas por muitos clientes, e o histórico de um cliente lido de um shard só.
