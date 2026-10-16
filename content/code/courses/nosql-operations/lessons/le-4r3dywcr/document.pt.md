---
title: Um armazenamento de documentos, o MongoDB
version: 1
---

Esta aula usa os três contêineres que a aula 1 montou, na rede `nosql`. Se estiverem parados,
`docker start mongo redis cassandra` os traz de volta. Se você os removeu, estas quatro linhas os
criam de novo. Quando só os contêineres sumiram, a primeira linha falha porque a rede já existe, e as
outras três seguem:

```sh
docker network create nosql
docker run -d --name mongo --network nosql mongo:8.0
docker run -d --name redis --network nosql redis:7.4
docker run -d --name cassandra --network nosql -e MAX_HEAP_SIZE=256M -e HEAP_NEWSIZE=64M cassandra:5.0
```

O Cassandra precisa de cerca de um minuto antes de o `cqlsh` conectar; o laço `until` da aula 1 espera
por ele.

## O pedido como um documento

Um armazenamento de documentos guarda **um registro autocontido por escrita**, num formato que o
servidor sabe ler: um documento é um conjunto de campos com nome, e um campo pode conter uma lista ou
outro documento. O MongoDB os guarda em coleções, dentro de um banco. Nenhum dos dois precisa existir
antes.

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> const cable = { sku: "CB-012", name: "USB-C cable", qty: 2, unit_price: Decimal128("39.90") }

shop> const mouse = { sku: "MS-204", name: "Wireless mouse", qty: 1, unit_price: Decimal128("189.00") }

shop> db.orders.insertOne({ _id: 1001, customer: "ana@example.com", ordered_at: ISODate("2026-09-14T13:22:00Z"), lines: [cable, mouse], total: Decimal128("268.80") })
{ acknowledged: true, insertedId: 1001 }
shop> db.orders.findOne({ _id: 1001 })
{
  _id: 1001,
  customer: 'ana@example.com',
  ordered_at: ISODate('2026-09-14T13:22:00.000Z'),
  lines: [
    {
      sku: 'CB-012',
      name: 'USB-C cable',
      qty: 2,
      unit_price: Decimal128('39.90')
    },
    {
      sku: 'MS-204',
      name: 'Wireless mouse',
      qty: 1,
      unit_price: Decimal128('189.00')
    }
  ],
  total: Decimal128('268.80')
}
shop> exit
```

O banco `shop` foi nomeado na linha de comando e criado pela primeira escrita, e a coleção `orders`
também. As duas linhas `const` são JavaScript puro no `mongosh`, montando as duas linhas do pedido
antes de o insert usá-las. Três detalhes são de propósito:

- **Dinheiro é `Decimal128`.** Um número em JavaScript é um valor de ponto flutuante binário, e 39.90
  não tem forma binária exata. O `Decimal128` guarda dígitos decimais, então `268.80` fica guardado
  como foi digitado.
- **A data é guardada em UTC.** 10:22 em São Paulo, três horas atrás, é `13:22:00Z`, e um cliente a
  converte de volta para exibir.
- **O `_id` é escolhido pela aplicação** aqui, como o número do pedido. Deixe-o de fora e o MongoDB
  gera um `ObjectId`, como mostrou o primeiro insert da aula 1.

O `findOne` devolveu **o pedido inteiro numa leitura só**: o cliente, a data, as duas linhas e o
total, sem join. É esse o acordo que esta família faz. A unidade que a aplicação usa, um pedido numa
tela ou num e-mail, é a unidade que o servidor guarda, então a leitura comum é uma busca só.

## O servidor enxerga dentro

O pedido não é um pacote lacrado. O MongoDB lê os campos de todo documento, os aninhados também,
então uma pergunta sobre qualquer um deles é uma consulta. Acrescente o pedido do monitor do Bruno e
faça duas:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.orders.insertOne({ _id: 1002, customer: "bruno@example.com", ordered_at: ISODate("2026-09-15T17:05:00Z"), lines: [{ sku: "MN-330", name: "27-inch monitor", qty: 1, unit_price: Decimal128("1499.00") }], total: Decimal128("1499.00") })
{ acknowledged: true, insertedId: 1002 }
shop> db.orders.find({ "lines.sku": "MS-204" }, { customer: 1, total: 1 })
[
  { _id: 1001, customer: 'ana@example.com', total: Decimal128('268.80') }
]
shop> db.orders.find({ total: { $gt: Decimal128("500") } }, { customer: 1, total: 1 })
[
  {
    _id: 1002,
    customer: 'bruno@example.com',
    total: Decimal128('1499.00')
  }
]
shop> exit
```

`"lines.sku"` entra na lista e encontra o pedido 1001, porque uma das suas linhas é o mouse. `$gt`
compara valores `Decimal128` e acha o único pedido acima de 500. O segundo argumento do `find` é uma
projeção: ele nomeia os campos a devolver, e o `_id` vem junto a menos que você o exclua.

**Ver dentro não é o mesmo que ser rápido dentro.** Com dois pedidos, as duas consultas leem todos
os documentos. Com dois milhões continuariam lendo, até existir um índice no campo, que é a aula 7.
E algumas perguntas atravessam documentos em vez de olhar dentro de um: quantos mouses foram vendidos
em setembro exige abrir todo pedido que tenha um e somar as quantidades, que é o pipeline de
agregação da aula 8.

## O que a forma decidiu

Embutir as linhas deixou uma leitura barata e fixou uma direção. "Me mostre o pedido 1001" é um
documento; "me mostre toda linha de pedido do mouse, de todos os clientes" é uma busca por todos os
pedidos. A cidade do cliente nem está no documento, então mostrá-la ao lado do pedido é uma segunda
leitura, de outro lugar. Se essa segunda leitura deve existir é a primeira decisão da aula 3.

O MongoDB é o armazenamento de documentos que este curso opera. CouchDB e Couchbase são outros, e
vários serviços de nuvem falam o protocolo do MongoDB sem rodar o MongoDB, assunto ao qual a aula 21
volta.
