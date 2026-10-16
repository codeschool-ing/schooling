---
title: Uma varredura e uma busca, lidas no explain
version: 1
---

Um índice é mais fácil de entender numa coleção grande o bastante para ele importar, e a loja da
aula 6 tem três pedidos. Esta aula precisa do `mongo` da aula 1, iniciado com `docker start mongo`
ou criado de novo com estas duas linhas:

```sh
docker network create nosql
docker run -d --name mongo --network nosql mongo:8.0
```

## Cem mil pedidos, os mesmos da aula

O programa abaixo enche `shop` com os quatro produtos e 100.000 pedidos. **Ele substitui as duas
coleções**, então os produtos da aula 6 e o validador deles vão embora; nada nesta aula precisa
deles. Salve-o como `orders.js` no seu diretório pessoal na VM:

```schooling-example
{
  "language": "javascript",
  "file": "orders.js",
  "parts": [
    {
      "code": "// orders.js: the shop's products and 100,000 orders, the same ones on every run.\nlet seed = 2026;\nfunction random() {\n  seed = (seed * 48271) % 2147483647;\n  return seed / 2147483647;\n}\nfunction pick(list) {\n  return list[Math.floor(random() * list.length)];\n}\n\n",
      "note": "**Um gerador de números aleatórios que você enxerga.** `Math.random()` dá pedidos diferentes a cada execução, e os seus números nunca bateriam com os da aula. Este é o gerador de Park–Miller: multiplica por 48271, guarda o resto, e a mesma semente dá a mesma sequência em qualquer máquina. Todo produto fica abaixo de 2^53, então um double do JavaScript o guarda com exatidão."
    },
    {
      "code": "const products = [\n  { _id: \"KB-101\", name: \"Mechanical keyboard\", cents: 34990 },\n  { _id: \"MS-204\", name: \"Wireless mouse\", cents: 18900 },\n  { _id: \"MN-330\", name: \"27-inch monitor\", cents: 149900 },\n  { _id: \"CB-012\", name: \"USB-C cable\", cents: 3990 },\n];\nconst money = (cents) => Decimal128.fromString((cents / 100).toFixed(2));\n\n",
      "note": "**Os quatro produtos, com preço em centavos.** Conta com centavos inteiros é exata; `money` transforma uma soma de centavos no `Decimal128` que a aula 6 recomendou, passando por uma string, nunca por um double."
    },
    {
      "code": "const customers = [\"ana\", \"bruno\", \"carla\", \"diego\", \"elisa\"];\nfor (let n = 6; n <= 1000; n++) customers.push(\"customer\" + n);\n\n",
      "note": "**Mil clientes.** Os cinco da aula 6 e mais 995, para que um cliente seja uma fatia pequena dos pedidos, que é o que faz um índice em `customer` valer a pena."
    },
    {
      "code": "const statuses = [];\nfor (const [status, weight] of [[\"delivered\", 70], [\"shipped\", 15], [\"paid\", 10], [\"pending\", 4], [\"cancelled\", 1]]) {\n  for (let w = 0; w < weight; w++) statuses.push(status);\n}\n\n",
      "note": "**Status com pesos.** Uma lista de 100 entradas em que `delivered` aparece 70 vezes e `pending` 4: escolher nela de modo uniforme dá cerca de 70% entregues e 4% pendentes, a assimetria que uma loja de verdade tem."
    },
    {
      "code": "db.products.drop();\ndb.products.insertMany(products.map((p) => ({ _id: p._id, name: p.name, price: money(p.cents) })));\n\n",
      "note": "**A coleção products, substituída.** `drop` a remove com os índices e qualquer validador, então uma segunda execução começa do mesmo lugar que a primeira."
    },
    {
      "code": "db.orders.drop();\nconst start = Date.UTC(2026, 0, 1);\nlet batch = [];\nfor (let id = 1; id <= 100000; id++) {\n  const items = [];\n  let cents = 0;\n  const lines = 1 + Math.floor(random() * 3);\n  for (let l = 0; l < lines; l++) {\n    const p = pick(products);\n    const qty = 1 + Math.floor(random() * 3);\n    items.push({ sku: p._id, qty: qty, price: money(p.cents) });\n    cents += qty * p.cents;\n  }\n  batch.push({\n    _id: id,\n    customer: pick(customers) + \"@example.com\",\n    status: pick(statuses),\n    ordered_at: new Date(start + Math.floor(random() * 365 * 86400) * 1000),\n    items: items,\n    total: money(cents),\n  });\n  if (batch.length === 1000) {\n    db.orders.insertMany(batch);\n    batch = [];\n  }\n}\n",
      "note": "**100.000 pedidos, mil de cada vez.** Cada um tem de uma a três linhas de uma a três unidades, uma data em algum ponto de 2026 com precisão de segundo e um total somado em centavos. `insertMany` com mil documentos é uma ida e volta em vez de mil."
    },
    {
      "code": "print(db.orders.countDocuments() + \" orders, \" + db.products.countDocuments() + \" products\");\n",
      "note": "**Uma contagem para conferir.** Se a sua execução imprimir outra coisa, o arquivo difere deste."
    }
  ]
}
```

Todo número que esta aula cita depende desses pedidos, então eles precisam ser os mesmos na sua
máquina e no laboratório. É por isso que o gerador foi escrito à mão: rode-o duas vezes, em
qualquer lugar, e o mesmo cliente tem os mesmos 82 pedidos.

O segundo arquivo é um auxiliar. `explain("executionStats")` responde com quarenta linhas ou mais,
e esta aula compara os mesmos cinco números o tempo todo, então `summary` os separa. Salve-o como
`summary.js`:

```javascript
// summary.js: the few numbers of explain("executionStats") this lesson reads.
function summary(cursor) {
  const e = cursor.explain("executionStats").executionStats;
  const stages = [];
  for (let s = e.executionStages; s; s = s.inputStage) stages.push(s.stage);
  return {
    stages: stages.join(" <- "),
    returned: e.nReturned,
    keys: e.totalKeysExamined,
    docs: e.totalDocsExamined,
    ms: e.executionTimeMillis,
  };
}
```

`stages` lista o plano de fora para dentro: `LIMIT <- FETCH <- IXSCAN` quer dizer que uma
varredura de índice alimentou uma busca de documentos, que alimentou um limite. `keys` é quantas
entradas de índice foram lidas, `docs` quantos documentos, e `returned` quantos voltaram. Copie os
dois arquivos para o contêiner e rode o gerador; ele leva alguns segundos:

```
ana@vm:~$ docker cp orders.js mongo:/orders.js
ana@vm:~$ docker cp summary.js mongo:/summary.js
ana@vm:~$ docker exec mongo mongosh --quiet shop /orders.js
100000 orders, 4 products
```

## Sem índice: todos os documentos

Olhe um pedido, depois pergunte como o servidor encontra os da Ana:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.orders.findOne()
{
  _id: 1,
  customer: 'customer405@example.com',
  status: 'delivered',
  ordered_at: ISODate('2026-04-24T16:32:41.000Z'),
  items: [ { sku: 'MS-204', qty: 2, price: Decimal128('189.00') } ],
  total: Decimal128('378.00')
}
shop> db.orders.find({ customer: "ana@example.com" }).explain("executionStats").executionStats
{
  executionSuccess: true,
  nReturned: 82,
  executionTimeMillis: 34,
  totalKeysExamined: 0,
  totalDocsExamined: 100000,
  executionStages: {
    isCached: false,
    stage: 'COLLSCAN',
    filter: { customer: { '$eq': 'ana@example.com' } },
    nReturned: 82,
    executionTimeMillisEstimate: 29,
    works: 100001,
    advanced: 82,
    needTime: 99918,
    needYield: 0,
    saveState: 1,
    restoreState: 1,
    isEOF: 1,
    direction: 'forward',
    docsExamined: 100000
  }
}
shop> exit
```

**`COLLSCAN`, `totalDocsExamined: 100000`, `nReturned: 82`.** Para devolver 82 pedidos o servidor
leu todos os 100.000, porque nada lhe dizia onde estavam os da Ana. `needTime: 99918` é a mesma
história contada de outro jeito: esse tanto de passos não produziu nada. 34 milissegundos é rápido,
e é rápido porque a coleção cabe na memória e nada mais está rodando. O trabalho cresce com a
coleção, não com a resposta: um milhão de pedidos é dez vezes a leitura para os mesmos 82.

## Com índice: as entradas que casam, e só elas

`load` roda `summary.js` dentro do shell, e a partir daí `summary` é uma função que você pode
chamar:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> load("/summary.js")
true
shop> summary(db.orders.find({ customer: "ana@example.com" }))
{ stages: 'COLLSCAN', returned: 82, keys: 0, docs: 100000, ms: 21 }
shop> db.orders.createIndex({ customer: 1 })
customer_1
shop> summary(db.orders.find({ customer: "ana@example.com" }))
{ stages: 'FETCH <- IXSCAN', returned: 82, keys: 82, docs: 82, ms: 2 }
shop> exit
```

`createIndex({ customer: 1 })` constrói uma lista ordenada do `customer` de cada pedido com um
ponteiro para o documento, e responde com o nome do índice. A mesma consulta agora lê **82 entradas
de índice e 82 documentos para devolver 82**. O plano tem dois estágios: `IXSCAN` percorreu a parte
do índice em que o cliente é `ana@example.com`, e `FETCH` abriu cada documento para o qual ela
apontava.

A proporção a observar é **examinados contra devolvidos**. `docs: 100000` contra `returned: 82` é
uma varredura da coleção, digam o que disserem os milissegundos num notebook ocioso; `keys: 82,
docs: 82, returned: 82` é um índice fazendo todo o trabalho. Os milissegundos são a única coluna que
muda de uma execução para outra, na sua máquina e no laboratório, e são a menos confiável das
cinco. As contagens são as mesmas toda vez, e são elas que você compara.

O `1` no índice quer dizer crescente. Num índice de um campo só a direção não importa, porque o
servidor consegue percorrê-lo nos dois sentidos. A próxima seção trata de quando ela importa.
