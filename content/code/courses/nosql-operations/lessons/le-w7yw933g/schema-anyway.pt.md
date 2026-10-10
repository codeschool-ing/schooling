---
title: O esquema que existe mesmo assim
version: 1
---

O MongoDB costuma ser vendido como **sem esquema**, e a expressão descreve o servidor corretamente e
o sistema de forma errada. O servidor aceita qualquer documento em qualquer coleção. Os programas
que leem esses documentos não: uma página de produto espera que `price` seja um número, um
relatório espera que `ordered_at` seja uma data, e um processo de envio espera que toda linha de
pedido tenha um `sku`. **O esquema não sumiu. Ele saiu do banco e foi para cada trecho de código
que lê os dados**, onde ninguém o escreveu e nada o verifica.

## Três escritas que o servidor aceita

Um produto novo chega de uma importação de planilha com o preço como texto. Um segundo é digitado à
mão com um nome de campo errado. Um terceiro vai para uma coleção com nome errado:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.products.insertOne({ _id: "SD-128", name: "128 GB memory card", price: "79.90", stock: 30 })
{ acknowledged: true, insertedId: 'SD-128' }
shop> db.products.insertOne({ _id: "WC-720", name: "Webcam", prcie: NumberDecimal("259.00"), stock: 8 })
{ acknowledged: true, insertedId: 'WC-720' }
shop> db.prodcuts.insertOne({ _id: "HS-300", name: "Headset", price: NumberDecimal("299.90"), stock: 5 })
{ acknowledged: true, insertedId: 'HS-300' }
shop> db.getCollectionNames()
[ 'products', 'prodcuts', 'orders' ]
shop> exit
```

As três responderam `acknowledged: true`. O preço do cartão de memória é a string `"79.90"`. A
webcam tem um campo chamado `prcie` e nenhum `price`. O headset está numa coleção chamada
`prodcuts`, que não existia até aquele insert criá-la; é o hábito que a aula 1 notou, a primeira
escrita criando o que quer que ela nomeie, e aqui ele é o defeito inteiro. Num banco relacional,
cada um dos três é um erro no momento do engano, com o número da linha da instrução que o causou.
Aqui cada um é um documento, e o erro chega depois, em outro lugar.

## Onde eles aparecem

Rode as consultas que o próprio código da loja rodaria:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.products.find({ price: { $lt: NumberDecimal("100") } }, { name: 1, price: 1 })
[ { _id: 'CB-012', name: 'USB-C cable', price: Decimal128('39.90') } ]
shop> db.products.find({}, { name: 1, price: 1 }).sort({ price: 1 })
[
  { _id: 'WC-720', name: 'Webcam' },
  { _id: 'CB-012', name: 'USB-C cable', price: Decimal128('39.90') },
  { _id: 'LS-050', name: 'Laptop stand', price: Decimal128('149.00') },
  { _id: 'MS-204', name: 'Wireless mouse', price: Decimal128('189.00') },
  {
    _id: 'KB-101',
    name: 'Mechanical keyboard',
    price: Decimal128('349.90')
  },
  {
    _id: 'MN-330',
    name: '27-inch monitor',
    price: Decimal128('1499.00')
  },
  { _id: 'SD-128', name: '128 GB memory card', price: '79.90' }
]
shop> db.products.aggregate([{ $project: { name: 1, with_tax: { $multiply: ["$price", NumberDecimal("1.1")] } } }])
Uncaught 
MongoServerError[TypeMismatch]: PlanExecutor error during aggregation :: caused by :: $multiply only supports numeric types, not string
shop> db.products.aggregate([{ $group: { _id: { $type: "$price" }, products: { $sum: 1 } } }])
[
  { _id: 'missing', products: 1 },
  { _id: 'string', products: 1 },
  { _id: 'decimal', products: 5 }
]
shop> db.products.find({ price: { $type: "string" } }, { name: 1, price: 1 })
[ { _id: 'SD-128', name: '128 GB memory card', price: '79.90' } ]
shop> db.products.find({ price: { $exists: false } })
[
  {
    _id: 'WC-720',
    name: 'Webcam',
    prcie: Decimal128('259.00'),
    stock: 8
  }
]
shop> exit
```

**"Produtos abaixo de 100" deixou de fora o cartão de memória a 79,90.** O MongoDB compara valores
de tipos diferentes primeiro pelo tipo, numa ordem fixa, e um intervalo de números nunca contém
uma string. A consulta não falhou. Ela devolveu uma lista curta, e nada na página pareceria errado.

**Ordenar por preço pôs a webcam em primeiro e o cartão de memória por último.** Um campo ausente
ordena como `null`, antes de qualquer número; uma string ordena depois de qualquer número. O item
mais barato do catálogo está no fim da lista, e o que não tem preço nenhum está no topo.

**O cálculo do imposto falhou de vez**, `$multiply only supports numeric types, not string`, e esse
é o melhor desfecho dos três, porque é o único que diz alguma coisa. Ele disse isso num relatório,
sobre um documento escrito por uma importação, talvez meses depois de a importação rodar.

`prodcuts` não aparece em nenhuma dessas respostas, porque nada a lê. O headset está no banco e
ausente da loja, e só `getCollectionNames()` o mostra.

## Achando o que já está lá

O esquema que uma coleção tem de fato é algo que se mede, e dois operadores fazem a maior parte
disso. **`$type` num `$group`** conta os tipos que um campo assume na coleção inteira: cinco
decimais, uma string e um ausente, que é o censo a rodar antes de confiar em qualquer campo de uma
coleção herdada. **`$type` num filtro** busca os infratores de um tipo, e **`$exists: false`** busca
os documentos em que o campo está ausente, que é como o campo com nome errado da webcam aparece. A
coleção com nome errado não tem consulta; a lista de nomes de coleções, lida por uma pessoa, é a
verificação.

Isso acha o estrago depois de feito. A próxima seção faz o servidor recusá-lo na porta.
