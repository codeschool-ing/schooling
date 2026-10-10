---
title: Embutir ou referenciar, no MongoDB
version: 1
---

Esta aula usa os três contêineres que a aula 1 montou, na rede `nosql`, e nada do que foi gravado na
aula 2. Se os seus ainda guardam os dados da aula 2, remova-os com `docker rm -f mongo redis cassandra`.
Estas quatro linhas os criam de novo, e a primeira falha sem dano se a rede já existir:

```sh
docker network create nosql
docker run -d --name mongo --network nosql mongo:8.0
docker run -d --name redis --network nosql redis:7.4
docker run -d --name cassandra --network nosql -e MAX_HEAP_SIZE=256M -e HEAP_NEWSIZE=64M cassandra:5.0
```

Num armazenamento de documentos, todo dado relacionado a outro tem duas casas possíveis.
**Embutido**, ele fica dentro do documento pai e volta junto com ele. **Referenciado**, ele é um
documento próprio, e o pai guarda a sua chave. A linha 3 da lista, "mostrar um pedido", decide pelas
linhas do pedido, e o cliente decide para o outro lado.

## As linhas dentro, a cliente por referência

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.customers.insertOne({ _id: "ana@example.com", name: "Ana Ribeiro", city: "Recife" })
{ acknowledged: true, insertedId: 'ana@example.com' }
shop> const lines = [{ sku: "CB-012", qty: 2, unit_price: Decimal128("39.90") }, { sku: "MS-204", qty: 1, unit_price: Decimal128("189.00") }]

shop> db.orders.insertOne({ _id: 1001, customer: "ana@example.com", ordered_at: ISODate("2026-09-14T13:22:00Z"), lines: lines, total: Decimal128("268.80") })
{ acknowledged: true, insertedId: 1001 }
shop> const order = db.orders.findOne({ _id: 1001 })

shop> db.customers.findOne({ _id: order.customer })
{ _id: 'ana@example.com', name: 'Ana Ribeiro', city: 'Recife' }
shop> exit
```

O pedido carrega as suas linhas, e elas voltaram com ele na leitura única da aula 2. A cliente é só
`"ana@example.com"`, o `_id` de um documento em `customers`, então mostrar o pedido com o nome e a
cidade dela exigiu **uma segunda leitura, pela chave que a primeira devolveu**. As linhas `const`
guardam o primeiro resultado numa variável, que é o que uma aplicação faz entre as duas chamadas.

Duas leituras por chave são baratas, e aqui são o preço certo. A página do pedido precisa do nome da
cliente; o endereço dela muda no seu próprio ritmo; e a Ana tem muitos pedidos. Embuti-la em cada um
faria do nome uma cópia em todo pedido que ela já fez, e a aula 4 trata do que custa manter cópias.

## Três perguntas que decidem

**É lido junto com o pai?** As linhas nunca aparecem sem o seu pedido. As avaliações de um produto
aparecem numa página própria, dez por vez.

**É limitado?** Um pedido tem um punhado de linhas, e o número para de crescer quando o pedido é
feito. Avaliações, visualizações e o histórico de pedidos de uma cliente crescem enquanto o pai
existir.

**Pertence só ao pai?** Uma linha não tem vida fora do seu pedido. Uma cliente é compartilhada por
todo pedido que fez, e muda sem que nenhum deles mude.

Três sins embutem. **Um único não na segunda pergunta basta para referenciar**, porque é a que tem
um muro de verdade atrás.

## O muro: 16 MB por documento

Um documento tem um tamanho máximo, e uma lista embutida que não para de crescer chega a ele. Suponha
que a loja embutisse o histórico de cada cliente no documento dela. Dois pushes de 9 MB fazem as vezes
de anos de pedidos:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> const nine = "x".repeat(9 * 1024 * 1024)

shop> db.customers.updateOne({ _id: "ana@example.com" }, { $push: { history: nine } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
shop> bsonsize(db.customers.findOne({ _id: "ana@example.com" }))
9437275
shop> db.customers.updateOne({ _id: "ana@example.com" }, { $push: { history: nine } })
Uncaught 
MongoServerError: BSONObj size: 18874467 (0x1200063) is invalid. Size must be between 0 and 16793600(16MB) First element: _id: "ana@example.com"
shop> db.customers.findOne({ _id: "ana@example.com" }, { history: 0 })
{ _id: 'ana@example.com', name: 'Ana Ribeiro', city: 'Recife' }
shop> exit
```

O primeiro push deu certo e deixou um documento de 9.437.275 bytes, como o `bsonsize` mediu. O
segundo teria feito 18.874.467 bytes, e **o servidor o recusou**: o limite é 16 MB, 16.777.216 bytes,
e os 16.793.600 da mensagem somam a pequena folga que o servidor guarda para a sua própria
contabilidade. O último `findOne` mostra que a recusa foi limpa. O documento está como estava antes
do segundo push, e todo push seguinte nele será recusado do mesmo jeito.

É essa a falha que um embutido sem limite espera, e ela chega em produção para os clientes que mais
compram, nunca num teste com três pedidos. Bem antes do muro, um documento desse tamanho já é lento:
toda leitura do nome da Ana moveria 9 MB, e é por isso que o último `findOne` deixou o histórico de
fora com `{ history: 0 }`.
