---
title: A referência estendida, no MongoDB
version: 1
---

Esta aula usa dois dos três contêineres, o MongoDB e o Cassandra, e os sobe sem nada dentro. Se os da
aula 3 ainda estiverem lá, remova-os com `docker rm -f mongo redis cassandra`; depois, estas três
linhas criam os dois que esta aula precisa, e a primeira falha sem dano se a rede já existir:

```sh
docker network create nosql
docker run -d --name mongo --network nosql mongo:8.0
docker run -d --name cassandra --network nosql -e MAX_HEAP_SIZE=256M -e HEAP_NEWSIZE=64M cassandra:5.0
```

A aula 3 deixou o pedido guardando só o e-mail da cliente, então mostrar o nome dela exigiu uma
segunda leitura. A **referência estendida** é o meio-termo de costume: o pedido guarda a referência
*e* uma cópia dos poucos campos que a sua página mostra, então a leitura comum é um documento só e a
cliente completa continua a uma busca de distância. As linhas fazem o mesmo com os produtos: o
código, mais o nome e o preço.

## Um retrato que não deve se mexer

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.products.insertOne({ _id: "MS-204", name: "Wireless mouse", price: Decimal128("189.00") })
{ acknowledged: true, insertedId: 'MS-204' }
shop> db.customers.insertOne({ _id: "ana@example.com", name: "Ana Ribeiro", city: "Recife" })
{ acknowledged: true, insertedId: 'ana@example.com' }
shop> const line = { sku: "MS-204", name: "Wireless mouse", qty: 1, unit_price: Decimal128("189.00") }

shop> db.orders.insertOne({ _id: 1001, customer: { id: "ana@example.com", name: "Ana Ribeiro" }, lines: [line] })
{ acknowledged: true, insertedId: 1001 }
shop> db.orders.insertOne({ _id: 1013, customer: { id: "ana@example.com", name: "Ana Ribeiro" }, lines: [line] })
{ acknowledged: true, insertedId: 1013 }
shop> db.products.updateOne({ _id: "MS-204" }, { $set: { price: Decimal128("199.00") } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
shop> db.orders.findOne({ _id: 1001 }, { "lines.unit_price": 1 })
{ _id: 1001, lines: [ { unit_price: Decimal128('189.00') } ] }
shop> exit
```

Os dois pedidos carregam `unit_price: 189.00`, copiado do produto quando a linha foi gravada. Então a
tabela de preços muda, e o mouse sobe para 199.00 em `products`. O pedido 1001 continua dizendo
189.00, e **isso está certo**: é o que a Ana pagou. Uma nota fiscal, um reembolso e uma disputa
precisam do preço do dia, e um projeto que buscasse o preço em `products` na hora da leitura
mostraria a ela uma conta com a qual ela nunca concordou.

Nada precisou ser feito para acertar isso, e é por isso que é fácil errar na direção oposta. Uma
equipe que depois "corrige a duplicação" tirando `unit_price` das linhas e juntando com `products`
trocou um fato por outro fato, e o total de todo pedido antigo deixa de fechar.

## Uma cópia que precisa acompanhar

O nome no pedido é do outro tipo. A Ana pede à loja que a chame de Ana Ribeiro Lima, e a página "meus
pedidos" deve dizer isso em todo pedido, os antigos também:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.customers.updateOne({ _id: "ana@example.com" }, { $set: { name: "Ana Ribeiro Lima" } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
shop> db.orders.updateMany({ "customer.id": "ana@example.com" }, { $set: { "customer.name": "Ana Ribeiro Lima" } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 2,
  modifiedCount: 2,
  upsertedCount: 0
}
shop> db.orders.find({}, { "customer.name": 1 })
[
  { _id: 1001, customer: { name: 'Ana Ribeiro Lima' } },
  { _id: 1013, customer: { name: 'Ana Ribeiro Lima' } }
]
shop> exit
```

O documento da cliente mudou com `updateOne`, e depois **a aplicação mudou cada cópia** com
`updateMany`, encontradas pela referência guardada ao lado da cópia, `customer.id`. `matchedCount: 2`
são os dois pedidos que ela tem. Nada no MongoDB sabia que essas cópias existiam; o segundo comando
existe porque alguém anotou que `orders.customer.name` copia `customers.name`.

**Guarde a referência ao lado de toda cópia.** Uma cópia do nome sem um `id` ao lado só pode ser
achada de novo procurando o nome antigo, e dois clientes podem ter o mesmo.

## Qual é qual, decidido uma vez

O mesmo campo pode ser de um tipo ou de outro, conforme a finalidade da cópia. O nome numa nota
fiscal emitida é um retrato, por lei; o nome na lista "meus pedidos" acompanha. Então a decisão é
anotada por cópia, não por campo, na mesma lista que diz onde estão as cópias:

| cópia | origem | tipo | atualizada por |
|---|---|---|---|
| `orders.lines.unit_price` | `products.price` | retrato | nada, nunca |
| `orders.lines.name` | `products.name` | retrato | nada: o nome como foi vendido |
| `orders.customer.name` | `customers.name` | acompanha | a mudança de nome, com `updateMany` em `customer.id` |
| `carts.items.name` | `products.name` | acompanha | a renomeação, na última seção |

Essa tabela é a parte de um projeto desnormalizado que nenhum banco guarda por você, e a última seção
desta aula a confere contra os dados.
