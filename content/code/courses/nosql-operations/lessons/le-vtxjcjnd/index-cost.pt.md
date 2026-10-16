---
title: O que um índice custa, e três que mudam o comportamento
version: 1
---

Depois de duas seções de índices que deixaram consultas mais rápidas, a ideia errada está à mão:
**crie um índice para cada consulta e o banco fica mais rápido**. As leituras ficam. Toda escrita
fica mais lenta, porque cada insert e cada update de um campo indexado mexe em todos os índices, e
cada índice ocupa memória que os documentos usariam. Esta seção mede as duas coisas, e depois
encontra três índices cujo propósito é uma regra, não velocidade.

## Tamanho, e quais índices alguém usa

A coleção juntou nove índices até agora, dois deles redundantes. `stats` informa tamanhos na escala
que você pedir, aqui megabytes:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.orders.stats({ scale: 1024 * 1024 }).size
22.922405242919922
shop> db.orders.stats({ scale: 1024 * 1024 }).indexSizes
{
  _id_: 1.04296875,
  customer_1: 0.5625,
  status_1: 0.48828125,
  'status_1_ordered_at_-1': 1.09765625,
  'ordered_at_-1_status_1': 2.15234375,
  'status_1_total_1_ordered_at_-1': 1.703125,
  'status_1_ordered_at_-1_total_1': 2.29296875,
  'customer_1_ordered_at_-1_total_1': 2.3984375,
  'items.sku_1': 0.8125
}
shop> db.orders.find({ customer: "ana@example.com" }).toArray().length
82
shop> db.orders.find({ status: "pending" }).sort({ ordered_at: -1 }).limit(20).toArray().length
20
shop> db.orders.aggregate([{ $indexStats: {} }, { $project: { _id: 0, name: 1, ops: "$accesses.ops" } }, { $sort: { name: 1 } }])
[
  { name: '_id_', ops: Long('0') },
  { name: 'customer_1', ops: Long('1') },
  { name: 'customer_1_ordered_at_-1_total_1', ops: Long('0') },
  { name: 'items.sku_1', ops: Long('0') },
  { name: 'ordered_at_-1_status_1', ops: Long('0') },
  { name: 'status_1', ops: Long('0') },
  { name: 'status_1_ordered_at_-1', ops: Long('2') },
  { name: 'status_1_ordered_at_-1_total_1', ops: Long('0') },
  { name: 'status_1_total_1_ordered_at_-1', ops: Long('0') }
]
shop> exit
```

Os documentos ocupam 22,9 MB. **Os nove índices ocupam cerca de 12,6 MB juntos**, mais da metade
disso de novo, e cada um quer estar na memória quando é usado. Os dois maiores são os índices
compostos de três campos, com 2,3 e 2,4 MB.

`$indexStats` conta, por índice, as operações que o usaram desde que o servidor subiu. As duas
consultas rodadas logo acima passaram por `customer_1` e `status_1_ordered_at_-1`, e os contadores
mostram isso; as chamadas a `explain` das seções anteriores não contam. Num servidor de verdade,
depois de uma semana de tráfego real, **um índice cuja contagem continua em zero é candidato a ser
removido**, e `status_1` é o caso mais claro aqui: `status_1_ordered_at_-1` começa pelo mesmo campo
e responde a toda consulta que `status_1` responderia.

## O custo de escrita, medido

Insira os mesmos 100.000 documentos numa coleção vazia duas vezes: uma só com `_id`, outra com os
mesmos oito índices a mais que `orders` tem:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> const docs = db.orders.find().toArray()

shop> function timedInsert() {
|   db.copy.deleteMany({});
|   const t = Date.now();
|   db.copy.insertMany(docs);
|   return Date.now() - t;
| }
[Function: timedInsert]
shop> db.copy.drop()
true
shop> timedInsert()
1294
shop> db.orders.getIndexes().filter((i) => i.name !== "_id_").forEach((i) => db.copy.createIndex(i.key))

shop> db.copy.getIndexes().length
9
shop> timedInsert()
3080
shop> db.copy.drop()
true
shop> exit
```

**1.294 milissegundos com um índice, 3.080 com nove.** Isso é o insert, de ponta a ponta, a partir
do mongosh, e os números são desta execução; os seus vão ser outros, assim como os do laboratório
na próxima execução. O que se mantém de uma execução para outra é a direção e a ordem de grandeza:
mais que o dobro do tempo, para os mesmos documentos, porque cada documento virou nove entradas de
índice em vez de uma. Uma loja que insere alguns pedidos por segundo não vai notar. Uma coleção que
recebe milhares de escritas por segundo, como eventos ou sessões, sente cada índice que carrega.

## Unique: um índice que recusa

Um índice declarado `unique` faz de um segundo documento com a mesma chave um erro, o mesmo `E11000`
que a aula 6 encontrou no `_id`:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.customers.insertMany([{ _id: 1, email: "ana@example.com" }, { _id: 2, email: "bruno@example.com" }])
{ acknowledged: true, insertedIds: { '0': 1, '1': 2 } }
shop> db.customers.createIndex({ email: 1 }, { unique: true })
email_1
shop> db.customers.insertOne({ _id: 3, email: "ana@example.com" })
Uncaught 
MongoServerError: E11000 duplicate key error collection: shop.customers index: email_1 dup key: { email: "ana@example.com" }
shop> db.orders.createIndex({ customer: 1, status: 1 }, { unique: true })
Uncaught 
MongoServerError[DuplicateKey]: Index build failed: 247e692a-0353-43f0-b4a6-0d6b34b167ff: Collection shop.orders ( 1eb122b4-9908-49ba-9950-3c5769671f09 ) :: caused by :: E11000 duplicate key error collection: shop.orders index: customer_1_status_1 dup key: { customer: "ana@example.com", status: "cancelled" }
shop> exit
```

O e-mail duplicado foi recusado. **O último comando é o caso que as pessoas encontram primeiro**:
pedir um índice único numa coleção que já o viola. A construção do índice falhou e citou a primeira
duplicata que achou: a Ana tem mais de um pedido cancelado. Nada foi criado; as duplicatas
existentes precisam ser resolvidas antes de a regra poder existir. Um índice único também é o único
jeito que o MongoDB tem de tornar "um por cliente" verdade sob concorrência, porque dois inserts
verificados pela aplicação no mesmo instante não veem duplicata nenhuma.

## Partial: um índice sobre parte dos documentos

O depósito só pergunta sobre pedidos pendentes. Um índice restrito a eles por
`partialFilterExpression` guarda 4.044 entradas em vez de 100.000:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> load("/summary.js")
true
shop> db.orders.createIndex({ ordered_at: -1 }, { name: "pending_by_date", partialFilterExpression: { status: "pending" } })
pending_by_date
shop> db.orders.stats({ scale: 1024 }).indexSizes["pending_by_date"]
64
shop> db.orders.stats({ scale: 1024 }).indexSizes["status_1_ordered_at_-1"]
1124
shop> summary(db.orders.find({ status: "pending" }).sort({ ordered_at: -1 }).limit(20).hint("pending_by_date"))
{
  stages: 'LIMIT <- FETCH <- IXSCAN',
  returned: 20,
  keys: 20,
  docs: 20,
  ms: 2
}
shop> summary(db.orders.find({ status: "paid" }).sort({ ordered_at: -1 }).limit(20).hint("pending_by_date"))
{
  stages: 'LIMIT <- FETCH <- IXSCAN',
  returned: 0,
  keys: 4044,
  docs: 4044,
  ms: 24
}
shop> db.orders.find({ status: "paid" }).sort({ ordered_at: -1 }).limit(20).hint("pending_by_date").toArray().length
0
shop> db.orders.find({ status: "paid" }).sort({ ordered_at: -1 }).limit(20).toArray().length
20
shop> exit
```

**64 KB contra 1.124 KB** do `{ status: 1, ordered_at: -1 }` completo, e a consulta do depósito lê
20 chaves, como antes. O preço é uma regra: o planejador só usa um índice parcial para uma consulta
cujo filtro garante que ela está dentro do filtro parcial. Uma consulta por `status: "pending"` se
qualifica; uma consulta por `status: "paid"` não, e o planejador deixa o índice de lado.

O segundo `summary` o forçou com `hint`, e o resultado é o motivo para levar essa regra a sério.
**A consulta forçada por pedidos pagos devolveu 0**, lendo 4.044 entradas pendentes e não ficando
com nenhuma, enquanto a mesma consulta sem o hint devolveu 20. Um hint que nomeia um índice parcial
pode devolver uma resposta incompleta sem erro nenhum, então um hint no código da aplicação é uma
promessa de que o índice serve para a consulta, feita por uma pessoa, e nunca mais conferida.

## TTL: um índice que apaga

Uma sessão deveria sumir algum tempo depois do último uso. Um **índice TTL** num campo de data, com
`expireAfterSeconds`, faz o servidor apagar cada documento quando esse campo fica mais velho que o
número dado:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.sessions.insertMany([
|   { _id: "s-old", customer: "ana@example.com", last_seen: new Date(Date.now() - 10 * 60 * 1000) },
|   { _id: "s-new", customer: "bruno@example.com", last_seen: new Date() }
| ])
{ acknowledged: true, insertedIds: { '0': 's-old', '1': 's-new' } }
shop> db.sessions.createIndex({ last_seen: 1 }, { expireAfterSeconds: 300 })
last_seen_1
shop> db.sessions.find({}, { _id: 1 })
[ { _id: 's-old' }, { _id: 's-new' } ]
shop> db.sessions.find({}, { _id: 1 })
[ { _id: 's-new' } ]
shop> exit
```

`s-old` foi visto pela última vez há dez minutos contra um limite de cinco, e setenta segundos depois
tinha sumido; `s-new` fica até cinco minutos depois da própria data. **A remoção não é imediata.**
Uma tarefa em segundo plano roda uma vez por minuto e remove o que expirou, então um documento pode
passar do limite em até um minuto, mais num servidor ocupado. Um código que nunca pode ver uma
sessão expirada ainda confere a data ele mesmo; o índice TTL é o que impede a coleção de crescer
para sempre.
