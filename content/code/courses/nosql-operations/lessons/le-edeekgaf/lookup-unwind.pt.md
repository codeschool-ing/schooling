---
title: Unwind, lookup e os mais vendidos
version: 1
---

A receita por produto precisa das linhas dos pedidos, e elas estão dentro de um array em cada
pedido. `$group` não consegue entrar num array elemento por elemento. **`$unwind` transforma um
documento com um array em um documento por elemento**, e daí as linhas podem ser agrupadas como
qualquer outra coisa.

## Um pedido, desenrolado

O pedido 2 por acaso lista o mouse sem fio duas vezes, que o índice multikey da aula 7 contou uma
vez só. `$unwind` mantém as duas:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.orders.find({ _id: 2 }, { items: 1 })
[
  {
    _id: 2,
    items: [
      { sku: 'MS-204', qty: 2, price: Decimal128('189.00') },
      { sku: 'MS-204', qty: 2, price: Decimal128('189.00') }
    ]
  }
]
shop> db.orders.aggregate([{ $match: { _id: 2 } }, { $unwind: "$items" }, { $project: { items: 1 } }])
[
  {
    _id: 2,
    items: { sku: 'MS-204', qty: 2, price: Decimal128('189.00') }
  },
  {
    _id: 2,
    items: { sku: 'MS-204', qty: 2, price: Decimal128('189.00') }
  }
]
shop> db.orders.aggregate([{ $unwind: "$items" }, { $count: "lines" }])
[ { lines: 200652 } ]
shop> exit
```

Os dois documentos depois do `$unwind` são cópias do pedido 2 com `items` trocado por uma linha
cada. Na coleção inteira, 100.000 pedidos viram **200.652 linhas**. Essa multiplicação é o custo a
ter em mente: todo estágio depois de um `$unwind` trabalha sobre o fluxo maior, então um `$match`
capaz de descartar documentos pertence a antes dele.

## Os mais vendidos

Unidades e receita por SKU, com o nome do produto buscado em `products`:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.orders.aggregate([
|   { $match: { status: { $ne: "cancelled" } } },
|   { $unwind: "$items" },
|   { $group: {
|       _id: "$items.sku",
|       units: { $sum: "$items.qty" },
|       revenue: { $sum: { $multiply: ["$items.price", "$items.qty"] } }
|   } },
|   { $sort: { units: -1 } },
|   { $lookup: { from: "products", localField: "_id", foreignField: "_id", as: "product" } },
|   { $project: { _id: 0, sku: "$_id", name: { $first: "$product.name" }, units: 1, revenue: 1 } }
| ])
[
  {
    units: 99678,
    revenue: Decimal128('3977152.20'),
    sku: 'CB-012',
    name: 'USB-C cable'
  },
  {
    units: 99516,
    revenue: Decimal128('34820648.40'),
    sku: 'KB-101',
    name: 'Mechanical keyboard'
  },
  {
    units: 99197,
    revenue: Decimal128('18748233.00'),
    sku: 'MS-204',
    name: 'Wireless mouse'
  },
  {
    units: 99064,
    revenue: Decimal128('148496936.00'),
    sku: 'MN-330',
    name: '27-inch monitor'
  }
]
shop> exit
```

O pipeline, estágio por estágio:

- `$match` tira os pedidos cancelados, antes de o fluxo crescer.
- `$unwind` faz um documento por linha.
- `$group` por `items.sku` soma as unidades e a receita de cada linha, `price` vezes `qty`, em
  `Decimal128`. O preço é o que foi copiado para a linha quando o pedido foi feito, como a aula 6
  defendeu, então isto é o que os clientes pagaram, diga o catálogo o que disser hoje.
- `$sort` põe primeiro quem tem mais unidades.
- **`$lookup`** é o join. Para cada documento, ele acha os `products` cujo `_id` é igual ao `_id`
  deste documento, o SKU, e os põe num array chamado `product`. É um array porque um lookup pode
  achar qualquer número de correspondências; `$first` no `$project` pega a que existe.

Os quatro produtos venderam quase o mesmo número de unidades, entre 99.064 e 99.678, porque o
gerador escolhe um produto de modo uniforme. A coluna de receita é onde eles diferem: o monitor
trouxe 148.496.936,00 e o cabo 3.977.152,20, para mais ou menos as mesmas unidades.

## Onde o lookup fica

O `$lookup` rodou sobre quatro documentos, depois do grupo, e não sobre 200.652 linhas. **Um join
posto depois da redução faz o trabalho uma vez por resultado**, e um join posto antes faz o trabalho
uma vez por linha, para a mesma resposta. Um `$lookup` não é de graça: cada documento que entra
custa uma busca na outra coleção, que só é rápida aqui porque `products` é minúscula e o `_id` dela
é indexado. Numa coleção grande, o `foreignField` precisa de índice, exatamente como um `find`
precisaria.

As aulas 3 e 4 explicaram por que documentos embutem em vez de fazer join. `$lookup` é a exceção que
você aceita em relatórios, em que o join acontece poucas vezes por dia sobre dados reduzidos; uma
página que roda um a cada requisição costuma ser sinal de que o modelo deveria ter embutido o que
essa página lê.
