---
title: Escrever, ler e alterar documentos
version: 1
---

Para começar, a loja precisa de duas coleções: os produtos e alguns pedidos. O `_id` de um produto
é o seu SKU, porque esse é o nome que toda linha de pedido vai usar para ele. Um pedido leva as
suas linhas dentro dele, cada uma com o preço **de quando o pedido foi feito**, que é a duplicação
que a aula 4 defendeu: o preço do catálogo pode mudar amanhã e este pedido não pode.

## Insert

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.products.insertMany([
|   { _id: "KB-101", name: "Mechanical keyboard", price: NumberDecimal("349.90"), stock: 12 },
|   { _id: "MS-204", name: "Wireless mouse", price: NumberDecimal("189.00"), stock: 40 },
|   { _id: "MN-330", name: "27-inch monitor", price: NumberDecimal("1499.00"), stock: 1 },
|   { _id: "CB-012", name: "USB-C cable", price: NumberDecimal("39.90"), stock: 200 }
| ])
{
  acknowledged: true,
  insertedIds: { '0': 'KB-101', '1': 'MS-204', '2': 'MN-330', '3': 'CB-012' }
}
shop> db.orders.insertMany([
|   { _id: 1, customer: "ana@example.com", status: "paid", ordered_at: new Date("2026-03-02T10:15:00-03:00"),
|     items: [{ sku: "KB-101", qty: 1, price: NumberDecimal("349.90") }, { sku: "CB-012", qty: 2, price: NumberDecimal("39.90") }],
|     total: NumberDecimal("429.70") },
|   { _id: 2, customer: "bruno@example.com", status: "pending", ordered_at: new Date("2026-03-02T11:40:00-03:00"),
|     items: [{ sku: "MN-330", qty: 1, price: NumberDecimal("1499.00") }],
|     total: NumberDecimal("1499.00") },
|   { _id: 3, customer: "carla@example.com", status: "paid", ordered_at: new Date("2026-03-03T09:05:00-03:00"),
|     items: [{ sku: "MS-204", qty: 1, price: NumberDecimal("189.00") }],
|     total: NumberDecimal("189.00") }
| ])
{ acknowledged: true, insertedIds: { '0': 1, '1': 2, '2': 3 } }
shop> db.products.insertOne({ _id: "KB-101", name: "Mechanical keyboard" })
Uncaught 
MongoServerError: E11000 duplicate key error collection: shop.products index: _id_ dup key: { _id: "KB-101" }
shop> exit
```

`insertMany` respondeu com o `_id` de cada documento, na ordem em que foram enviados. A última
linha tentou um segundo `KB-101` e foi recusada com `E11000 duplicate key error`. Toda coleção tem
um índice único em `_id` que não pode ser removido, e é a única restrição que o MongoDB impõe sem
que ninguém peça. Vale reconhecer esse código de erro: a aula 7 cria um índice único próprio e o
encontra de novo.

Nenhuma daquelas três instruções descreveu uma coleção. Não houve `CREATE TABLE`: o primeiro insert
em `products` criou `products`, e o primeiro em `orders` criou `orders`. **A forma de um documento
é o que a instrução que o escreveu disse.**

## Find: um filtro e uma projeção

`find` recebe dois documentos. O primeiro é o **filtro**, que diz quais documentos casam; o
segundo é a **projeção**, que diz quais campos deles voltam:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.products.find({ price: { $lt: NumberDecimal("200") } }, { name: 1, price: 1 })
[
  { _id: 'MS-204', name: 'Wireless mouse', price: Decimal128('189.00') },
  { _id: 'CB-012', name: 'USB-C cable', price: Decimal128('39.90') }
]
shop> db.orders.find({ "items.sku": "CB-012" }, { customer: 1, total: 1 })
[
  { _id: 1, customer: 'ana@example.com', total: Decimal128('429.70') }
]
shop> db.orders.find({ status: "paid" }, { _id: 0, customer: 1, ordered_at: 1 }).sort({ ordered_at: -1 })
[
  {
    customer: 'carla@example.com',
    ordered_at: ISODate('2026-03-03T12:05:00.000Z')
  },
  {
    customer: 'ana@example.com',
    ordered_at: ISODate('2026-03-02T13:15:00.000Z')
  }
]
shop> exit
```

Quatro detalhes nessa saída respondem pela maior parte do trabalho do dia a dia:

- **Os operadores começam com `$`.** `{ price: { $lt: NumberDecimal("200") } }` se lê "preço menor
  que 200". Comparar um decimal com um decimal é exato; a próxima seção mostra o que acontece quando
  o campo guarda outra coisa.
- **Um caminho com ponto entra em arrays.** `"items.sku": "CB-012"` casou com o pedido 1 porque uma
  das linhas dele tem esse SKU. Não se escreveu nenhum laço sobre o array, e não existe join com uma
  tabela de linhas de pedido para escrever.
- **`_id` volta a menos que você diga `_id: 0`.** Todo outro campo de uma projeção só vem se pedido,
  a partir do momento em que você nomeia um.
- **`sort` recebe um campo e uma direção**, `-1` para decrescente. As datas voltaram em UTC, como a
  seção anterior disse que voltariam.

## Update: operadores, nunca um documento inteiro

Um update nomeia os campos que muda, com um operador para cada tipo de mudança. `$set` escreve um
valor, `$inc` soma a um número, `$push` acrescenta a um array:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.orders.updateOne(
|   { _id: 2 },
|   { $set: { status: "paid" }, $push: { history: { status: "paid", at: new Date("2026-03-02T11:52:00-03:00") } } }
| )
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
shop> db.products.updateOne({ _id: "MN-330" }, { $inc: { stock: -1 } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
shop> db.products.findOne({ _id: "MN-330" })
{
  _id: 'MN-330',
  name: '27-inch monitor',
  price: Decimal128('1499.00'),
  stock: 0
}
shop> db.orders.updateOne({ _id: 1 }, { status: "shipped" })
Uncaught 
MongoInvalidArgumentError: Update document requires atomic operators
shop> db.orders.updateOne({ _id: 22 }, { $set: { status: "paid" } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 0,
  modifiedCount: 0,
  upsertedCount: 0
}
shop> db.orders.deleteOne({ _id: 3 })
{ acknowledged: true, deletedCount: 1 }
shop> exit
```

O pedido 2 mudou de status e ganhou um array `history` numa instrução só. O estoque do monitor foi
de 1 para 0. **As duas coisas aconteceram de forma atômica dentro do seu documento**: dois clientes
rodando aquele `$inc` no mesmo instante produzem -1 e -2, nunca duas cópias de -1, porque o
servidor aplica o operador ao valor que estiver lá. Ler o estoque, subtrair na aplicação e gravar o
resultado de volta é a versão que perde uma venda, e é a versão que as pessoas escrevem primeiro.

As duas respostas seguintes são as que valem lembrar.

`updateOne({ _id: 1 }, { status: "shipped" })` foi recusado antes de sair do mongosh: **`Update
document requires atomic operators`**. Sem essa verificação, um documento sem nenhum `$` significaria
"substitua o pedido inteiro por `{ status: "shipped" }`", e as linhas, o total e o cliente
sumiriam. Substituir um documento inteiro é outra chamada, `replaceOne`, para que isso não aconteça
por esquecer um `$set`.

`updateOne({ _id: 22 }, …)` nomeia um pedido que não existe, e a resposta não é um erro. É
`acknowledged: true` com **`matchedCount: 0`**. O servidor fez exatamente o que lhe pediram, que era
alterar todo pedido com `_id` 22, e não havia nenhum. Uma aplicação que só verifica exceções vai
informar que esse pedido foi pago. A contagem é o resultado; leia-a.

`deleteOne` removeu o pedido 3 e disse isso com `deletedCount: 1`. Vale a mesma regra: um delete que
não casou com nada responde `deletedCount: 0`, sem reclamar.

## Upsert: atualize, ou insira se nada casou

Um fornecedor manda um suporte de notebook que a loja nunca vendeu. `upsert: true` transforma um
update que não casa com nada num insert montado a partir do filtro e dos operadores:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.products.updateOne(
|   { _id: "LS-050" },
|   { $set: { name: "Laptop stand", price: NumberDecimal("149.00") }, $inc: { stock: 5 } },
|   { upsert: true }
| )
{
  acknowledged: true,
  insertedId: 'LS-050',
  matchedCount: 0,
  modifiedCount: 0,
  upsertedCount: 1
}
shop> db.products.updateOne(
|   { _id: "LS-050" },
|   { $set: { name: "Laptop stand", price: NumberDecimal("149.00") }, $inc: { stock: 5 } },
|   { upsert: true }
| )
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
shop> db.products.findOne({ _id: "LS-050" })
{
  _id: 'LS-050',
  name: 'Laptop stand',
  price: Decimal128('149.00'),
  stock: 10
}
shop> exit
```

A primeira chamada não casou com nada e inseriu, `upsertedCount: 1`, com o `_id` do filtro. A
segunda encontrou o documento e aplicou os operadores de novo, então **o estoque é 10, não 5**. O
upsert costuma ser descrito como um jeito de tornar uma escrita segura para repetir, e só com
`$set` ele é. Com `$inc` não é: um cliente que tenta de novo depois de um timeout repõe a
prateleira duas vezes. O operador para "só ao inserir" é `$setOnInsert`; um contador que precisa
sobreviver a novas tentativas precisa que a tentativa leve uma identidade que o servidor reconheça,
que é de novo o problema da aula 4 de escrever o mesmo dado duas vezes.
