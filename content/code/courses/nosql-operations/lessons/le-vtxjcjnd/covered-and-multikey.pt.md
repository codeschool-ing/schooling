---
title: Consultas cobertas e índices em arrays
version: 1
---

Todo plano até aqui terminou em `FETCH`: o índice dizia onde estavam os documentos, e o servidor
abria cada um. Dois tipos de índice mudam esse quadro. Um responde sem abrir documento nenhum. O
outro indexa os elementos de um array, algo que o índice de uma tabela não tem como fazer.

## Uma consulta que o índice responde sozinho

O histórico de pedidos da Ana precisa de uma data e de um total por pedido e de mais nada. Se todo
campo que a consulta filtra, ordena e devolve está num mesmo índice, os documentos nunca são lidos:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> load("/summary.js")
true
shop> db.orders.createIndex({ customer: 1, ordered_at: -1, total: 1 })
customer_1_ordered_at_-1_total_1
shop> summary(db.orders.find({ customer: "ana@example.com" }, { _id: 0, ordered_at: 1, total: 1 }).sort({ ordered_at: -1 }))
{
  stages: 'PROJECTION_COVERED <- IXSCAN',
  returned: 82,
  keys: 82,
  docs: 0,
  ms: 4
}
shop> summary(db.orders.find({ customer: "ana@example.com" }, { ordered_at: 1, total: 1 }).sort({ ordered_at: -1 }))
{
  stages: 'PROJECTION_SIMPLE <- FETCH <- IXSCAN',
  returned: 82,
  keys: 82,
  docs: 82,
  ms: 1
}
shop> exit
```

**`docs: 0`, e o plano é `PROJECTION_COVERED <- IXSCAN`.** As 82 datas e os 82 totais saíram das
próprias entradas do índice. Isso importa mais do que os milissegundos sugerem: um índice é pequeno
e fica quase todo na memória, e documentos são grandes e podem estar no disco, então uma consulta
coberta num servidor ocupado evita as leituras que são a parte lenta.

A segunda consulta difere numa coisa só: ela não disse `_id: 0`. `_id` volta a menos que seja
excluído, como a aula 6 mostrou, e ele não está neste índice, então o servidor teve de abrir cada
documento para buscá-lo, e o plano ganhou um `FETCH` com `docs: 82`. **Uma consulta coberta é frágil
exatamente desse jeito**: um campo a mais numa projeção, acrescentado por alguém que não sabia, a
transforma de volta numa busca de documentos, e nada falha.

## Um índice por dentro de um array

Cada pedido guarda as suas linhas no array `items`. Indexe `items.sku`, e o servidor escreve uma
entrada para cada SKU distinto de cada pedido:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> load("/summary.js")
true
shop> db.orders.createIndex({ "items.sku": 1 })
items.sku_1
shop> summary(db.orders.find({ "items.sku": "MN-330" }))
{
  stages: 'FETCH <- IXSCAN',
  returned: 42139,
  keys: 42139,
  docs: 42139,
  ms: 70
}
shop> db.orders.find({ "items.sku": "MN-330" }).explain().queryPlanner.winningPlan.inputStage.isMultiKey
true
shop> db.orders.validate().keysPerIndex
{
  _id_: 100000,
  customer_1: 100000,
  'customer_1_ordered_at_-1_total_1': 100000,
  'items.sku_1': 169164,
  'ordered_at_-1_status_1': 100000,
  status_1: 100000,
  'status_1_ordered_at_-1': 100000,
  'status_1_ordered_at_-1_total_1': 100000,
  'status_1_total_1_ordered_at_-1': 100000
}
shop> db.labels.insertOne({ tags: ["gift", "fragile"], sizes: [1, 2] })
{
  acknowledged: true,
  insertedId: ObjectId('6acae9916e351c81c753ea4d')
}
shop> db.labels.createIndex({ tags: 1, sizes: 1 })
Uncaught 
MongoServerError[CannotIndexParallelArrays]: Index build failed: 777236ab-40fa-45f3-ad3b-8ae57cc2d841: Collection shop.labels ( 7aeb54c4-4d87-4648-a143-29002d58f2d6 ) :: caused by :: collection scan stopped. totalRecords: 0; durationMillis: 2ms; phase: collection scan; collectionScanPosition: (None); readSource: kNoTimestamp :: caused by :: cannot index parallel arrays [sizes] [tags]
shop> exit
```

O índice atende a consulta do jeito de sempre, e o explain informa **`isMultiKey: true`**, que o
servidor marcou sozinho na primeira vez em que indexou um documento cujo `items` tinha mais de um
elemento. `keysPerIndex` mostra o que isso significa em tamanho: todos os outros índices têm
exatamente 100.000 entradas, uma por pedido, e **`items.sku_1` tem 169.164**, porque um pedido com
três SKUs diferentes põe três entradas nele. Um pedido que lista o mesmo SKU duas vezes põe uma.

Um índice multikey tem dois limites que vale conhecer antes que surpreendam.

- **Ele não cobre uma consulta sobre o campo do array.** Uma entrada diz que uma das linhas do
  pedido tem aquele SKU; ela não diz qual linha, nem quantas, então o documento precisa ser lido.
- **Um índice composto pode ter no máximo um campo de array por documento.** O último comando
  tentou indexar dois arrays juntos, e o servidor recusou com `cannot index parallel arrays [sizes]
  [tags]`: uma entrada para cada par de elementos cresceria como o produto dos tamanhos dos dois
  arrays. A recusa também acontece depois, num insert, quando existe um índice em dois campos e
  chega um documento com arrays nos dois.

A própria consulta é um aviso de outro tipo. O monitor está em 42.139 pedidos de 100.000, então o
índice achou 42.139 entradas e o servidor abriu 42.139 documentos. **Um índice num valor que casa
com quase metade da coleção economiza pouco**, e o planejador faria quase o mesmo lendo tudo.
Índices compensam em campos seletivos, aqueles em que um valor separa uma fatia pequena, como
`customer` fez com 82 pedidos de 100.000.
