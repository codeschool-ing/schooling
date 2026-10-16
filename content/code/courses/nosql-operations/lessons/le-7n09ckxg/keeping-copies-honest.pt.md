---
title: Mantendo as cópias honestas
version: 1
---

Toda cópia da tabela da seção de referência estendida vai, um dia, deixar de acompanhar a sua origem:
um deploy que pulou o `updateMany`, um script que morreu no meio, uma cópia nova que alguém
acrescentou e não anotou. **Nada vai levantar erro.** Cada documento é válido sozinho, e só comparar
uma cópia com a sua origem mostra o desvio. Então a comparação é algo a escrever e rodar numa agenda,
do jeito que um backup é restaurado para provar que funciona.

## Uma renomeação, e as cópias que não acompanharam

A loja renomeia o teclado para dizer qual layout ele tem. Duas cestas abertas guardam uma cópia do
nome antigo:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.products.insertOne({ _id: "KB-101", name: "Mechanical keyboard", price: Decimal128("349.90") })
{ acknowledged: true, insertedId: 'KB-101' }
shop> db.products.insertOne({ _id: "CB-012", name: "USB-C cable", price: Decimal128("39.90") })
{ acknowledged: true, insertedId: 'CB-012' }
shop> db.carts.insertOne({ _id: "ana@example.com", items: [{ sku: "KB-101", name: "Mechanical keyboard", qty: 1 }] })
{ acknowledged: true, insertedId: 'ana@example.com' }
shop> db.carts.insertOne({ _id: "carla@example.com", items: [{ sku: "CB-012", name: "USB-C cable", qty: 3 }, { sku: "KB-101", name: "Mechanical keyboard", qty: 1 }] })
{ acknowledged: true, insertedId: 'carla@example.com' }
shop> db.products.updateOne({ _id: "KB-101" }, { $set: { name: "Mechanical keyboard, ABNT2 layout" } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
shop> const unwind = { $unwind: "$items" }

shop> const join = { $lookup: { from: "products", localField: "items.sku", foreignField: "_id", as: "product" } }

shop> const differ = { $match: { $expr: { $ne: ["$items.name", { $first: "$product.name" }] } } }

shop> db.carts.aggregate([unwind, join, differ, { $project: { sku: "$items.sku", copy: "$items.name" } }])
[
  { _id: 'ana@example.com', sku: 'KB-101', copy: 'Mechanical keyboard' },
  {
    _id: 'carla@example.com',
    sku: 'KB-101',
    copy: 'Mechanical keyboard'
  }
]
```

A verificação são três estágios, cada um guardado numa variável para a linha que os roda continuar
legível:

- **`unwind`** transforma cada cesta num documento por item;
- **`join`** busca o produto que cada item nomeia, com `$lookup`, o único join que o MongoDB tem, que
  a aula 8 desmonta;
- **`differ`** fica com os itens cujo nome copiado não é o nome atual do produto.

Ela achou as duas cópias do teclado, na cesta da Ana e na da Carla, ainda dizendo `Mechanical
keyboard`. O cabo na cesta da Carla não apareceu: a cópia dele confere.

## Corrigindo, e conferindo a correção

`updateMany` com `arrayFilters` muda só os elementos da lista que casam com o filtro: o item cujo
`sku` é `KB-101`, dentro de toda cesta que tenha um. Depois a mesma verificação roda de novo,
terminando em `$count`:

```
shop> db.carts.updateMany({ "items.sku": "KB-101" }, { $set: { "items.$[i].name": "Mechanical keyboard, ABNT2 layout" } }, { arrayFilters: [{ "i.sku": "KB-101" }] })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 2,
  modifiedCount: 2,
  upsertedCount: 0
}
shop> db.carts.aggregate([unwind, join, differ, { $count: "drifted" }])

shop> exit
```

`matchedCount: 2` são as duas cestas. A verificação não imprimiu **nada**, e essa é a resposta zero:
o `$count` só produz um documento quando algo chega até ele, então uma execução limpa é um resultado
vazio. Um script que alerta com base na verificação precisa ler "nenhum documento" como 0, e não como
uma falha ao rodar.

## Tornando isso rotina

Uma verificação que só roda quando alguém lembra é uma verificação que não roda. Três hábitos tornam
as cópias confiáveis:

- **Uma verificação por cópia da tabela**, rodando numa agenda, informando o número de cópias
  desviadas. Um número que deveria ser zero é fácil de alertar, e a aula 20 trata de alertas.
- **Corrija a partir da origem, nunca de outra cópia.** O documento do produto é a verdade; a cesta é
  corrigida a partir dele.
- **Mantenha a verificação barata.** Sobre milhões de documentos o `$lookup` acima é uma passada
  completa; rode-o num secundário ou de madrugada, ou confira só os documentos alterados desde a
  última execução.

Os retratos ficam fora de tudo isso de propósito. Uma verificação que "corrigisse" o `unit_price` de
pedidos antigos seria o pior bug da loja.
