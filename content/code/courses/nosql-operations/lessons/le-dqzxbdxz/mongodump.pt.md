---
title: Um backup lógico com mongodump
version: 1
---

Há dois jeitos de fazer backup de um banco, e esta aula executa os dois sobre os mesmos dados. **Um
dump pede ao servidor cada documento e os grava**; um snapshot copia os arquivos que o servidor
mantém em disco. Parecem dois caminhos para a mesma cópia, e o resto da aula trata de por que não
são.

## O que esta aula precisa

Um servidor MongoDB cujos dados moram num **volume nomeado**, para que os arquivos sobrevivam ao
contêiner e um segundo contêiner consiga lê-los. Remova o `mongo` da aula 1, que guardava os dados
dentro do contêiner, e pare o cluster da aula 10 se ele ainda estiver rodando:

```sh
docker rm -f mongo
docker stop cfg1 shard1 shard2 mongos
```

O servidor é um replica set de um membro. Nada aqui precisa de uma segunda cópia, mas o
`mongodump --oplog`, mais abaixo, lê o oplog, e só um membro de replica set mantém um. O
`rs.initiate()` sem argumento cria um conjunto cujo único membro é este servidor, com o próprio nome
de host:

```
ana@vm:~$ docker volume create mongo-data
mongo-data
ana@vm:~$ docker run -d --name mongo --hostname mongo --network nosql -v mongo-data:/data/db mongo:8.0 mongod --replSet rs0 --bind_ip_all
9fc22e942492fe80153736a44440b4e2f83c262fcbf41821517b38eeb293a802
ana@vm:~$ docker exec mongo mongosh --quiet --eval 'rs.initiate().ok'
1
```

## Algo para guardar

A loja de novo, com pedidos suficientes para os números significarem alguma coisa: cinco clientes,
quatro produtos e 100.000 pedidos, os mesmos em toda execução. Salve isto como `seed.js` no seu
diretório pessoal na VM:

```javascript
// seed.js: the shop's customers, products and 100,000 orders, the same on every run.
const customers = [
  { _id: 1, name: "Ana Ribeiro", email: "ana@example.com", city: "Recife" },
  { _id: 2, name: "Bruno Costa", email: "bruno@example.com", city: "São Paulo" },
  { _id: 3, name: "Carla Mendes", email: "carla@example.com", city: "Recife" },
  { _id: 4, name: "Diego Alves", email: "diego@example.com", city: "Curitiba" },
  { _id: 5, name: "Elisa Fontes", email: "elisa@example.com" },
];
db.customers.insertMany(customers);
db.customers.createIndex({ email: 1 }, { unique: true });
db.products.insertMany([
  { _id: "KB-101", name: "Mechanical keyboard", price: Decimal128("349.90") },
  { _id: "MS-204", name: "Wireless mouse", price: Decimal128("189.00") },
  { _id: "MN-330", name: "27-inch monitor", price: Decimal128("1499.00") },
  { _id: "CB-012", name: "USB-C cable", price: Decimal128("39.90") },
]);
const skus = ["KB-101", "MS-204", "MN-330", "CB-012"];
for (let batch = 0; batch < 10; batch++) {
  const orders = [];
  for (let i = 1; i <= 10000; i++) {
    const n = batch * 10000 + i;
    orders.push({ _id: n, customer: customers[n % 5].email, sku: skus[n % 4], qty: 1 + (n % 3),
                  placedAt: new Date(Date.UTC(2026, 0, 1) + n * 60000) });
  }
  db.orders.insertMany(orders);
}
db.orders.createIndex({ customer: 1, placedAt: -1 });
db.orders.createIndex({ sku: 1 });
print("orders:", db.orders.countDocuments());
```

Copie para dentro do contêiner e rode lá, depois conte o que cada coleção guarda e quais índices
ela tem. A última linha é a verificação contra a qual os restores desta aula são medidos:

```
ana@vm:~$ docker cp seed.js mongo:/tmp/seed.js
ana@vm:~$ docker exec mongo mongosh --quiet shop /tmp/seed.js
orders: 100000
ana@vm:~$ docker exec mongo mongosh --quiet shop --eval 'for (const c of db.getCollectionNames().sort()) print(c, db[c].countDocuments(), db[c].getIndexes().map(i => i.name).join(" "))'
customers 5 _id_ email_1
orders 100000 _id_ customer_1_placedAt_-1 sku_1
products 4 _id_
```

## Um dump, como arquivos

O `mongodump` vem dentro da imagem `mongo:8.0`, então roda no mesmo contêiner que o servidor.
Quando recebe um banco e um diretório, ele grava um arquivo por coleção:

```
ana@vm:~$ docker exec mongo mongodump --db shop --out /tmp/dump
2026-10-10T20:15:09.312+0000	writing `shop.orders` to `/tmp/dump/shop/orders.bson`
2026-10-10T20:15:09.312+0000	writing `shop.customers` to `/tmp/dump/shop/customers.bson`
2026-10-10T20:15:09.312+0000	writing `shop.products` to `/tmp/dump/shop/products.bson`
2026-10-10T20:15:09.314+0000	done dumping `shop.products` (4 documents)
2026-10-10T20:15:09.315+0000	done dumping `shop.customers` (5 documents)
2026-10-10T20:15:09.440+0000	done dumping `shop.orders` (100000 documents)
ana@vm:~$ docker exec mongo ls -l /tmp/dump/shop
total 8680
-rw-rw-rw- 1 root root     399 Oct 10 20:15 customers.bson
-rw-rw-rw- 1 root root     267 Oct 10 20:15 customers.metadata.json
-rw-rw-rw- 1 root root 8860000 Oct 10 20:15 orders.bson
-rw-rw-rw- 1 root root     372 Oct 10 20:15 orders.metadata.json
-rw-rw-rw- 1 root root      51 Oct 10 20:15 prelude.json
-rw-rw-rw- 1 root root     279 Oct 10 20:15 products.bson
-rw-rw-rw- 1 root root     175 Oct 10 20:15 products.metadata.json
```

Cada coleção vira um arquivo `.bson`, os documentos exatamente como o servidor os guarda, e um
`.metadata.json` ao lado. **Os metadados guardam as definições dos índices e nada mais sobre eles.**
O `orders.bson` tem 8.860.000 bytes de documentos; os dois índices de `orders` são algumas centenas
de bytes de descrição em `orders.metadata.json`, e serão construídos de novo, a partir dos
documentos, em todo restore.

## Um dump de um banco que está recebendo escritas

Um backup de verdade roda com a loja aberta. A primeira linha abaixo inicia, dentro do contêiner,
um cliente que insere um pagamento a cada dez milissegundos, mais ou menos, 500 ao todo, e volta na
hora (`-d`); o dump roda enquanto ele escreve:

```
ana@vm:~$ docker exec -d mongo mongosh --quiet shop --eval 'for (let i = 1; i <= 500; i++) { db.payments.insertOne({ _id: i, at: new Date() }); sleep(10) }'
ana@vm:~$ time docker exec mongo mongodump --oplog --gzip --archive=/tmp/shop.archive.gz
2026-10-10T20:15:11.737+0000	writing `admin.system.version` to "archive `/tmp/shop.archive.gz`"
2026-10-10T20:15:11.741+0000	done dumping `admin.system.version` (1 document)
2026-10-10T20:15:11.741+0000	writing `shop.orders` to "archive `/tmp/shop.archive.gz`"
2026-10-10T20:15:11.741+0000	writing `shop.payments` to "archive `/tmp/shop.archive.gz`"
2026-10-10T20:15:11.742+0000	writing `shop.customers` to "archive `/tmp/shop.archive.gz`"
2026-10-10T20:15:11.746+0000	writing `shop.products` to "archive `/tmp/shop.archive.gz`"
2026-10-10T20:15:11.761+0000	done dumping `shop.products` (4 documents)
2026-10-10T20:15:11.762+0000	done dumping `shop.payments` (119 documents)
2026-10-10T20:15:11.763+0000	done dumping `shop.customers` (5 documents)
2026-10-10T20:15:12.073+0000	done dumping `shop.orders` (100000 documents)
2026-10-10T20:15:12.075+0000	writing captured oplog to ``
2026-10-10T20:15:12.077+0000		dumped 26 oplog entries

real	0m0.463s
user	0m0.011s
sys	0m0.034s
ana@vm:~$ docker cp mongo:/tmp/shop.archive.gz .
ana@vm:~$ ls -l shop.archive.gz
-rw-rw-rw- 1 ana ana 810350 Oct 10 17:15 shop.archive.gz
```

`--archive` grava um arquivo só em vez de um diretório, `--gzip` o comprime, e `--oplog` é o que
importa. Um dump copia as coleções uma depois da outra, e a cópia de cada uma leva tempo, então sem
ele o resultado mistura momentos: `payments` terminou às 20:15:11.762 com 119 documentos, enquanto
`orders` foi até 20:15:12.073. **O `--oplog` também grava cada entrada do oplog escrita do início
ao fim do dump**, 26 aqui, para que um restore possa reaplicá-las e levar todas as coleções ao mesmo
momento: o fim do dump.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Uma linha do tempo do dump desta aula, de 20:15:11.737 a 20:15:12.077. Pagamentos continuam chegando o tempo todo. A coleção payments termina de ser copiada depois de 25 milissegundos, com 119 documentos, e a coleção orders depois de 336 milissegundos. Ao lado, o dump grava toda entrada do oplog escrita do início ao fim dele, 26 ao todo. Um restore que as reaplica termina no instante em que o dump acabou.\"><text x=\"140\" y=\"45\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">payments gravados</text><line x1=\"150.0\" y1=\"45\" x2=\"654.0\" y2=\"45\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"140\" y=\"85\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">copiando payments</text><line x1=\"150.0\" y1=\"85\" x2=\"654.0\" y2=\"85\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"140\" y=\"125\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">copiando orders</text><line x1=\"150.0\" y1=\"125\" x2=\"654.0\" y2=\"125\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"140\" y=\"165\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">oplog gravado: 26 entradas</text><line x1=\"150.0\" y1=\"165\" x2=\"654.0\" y2=\"165\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><line x1=\"156.0\" y1=\"39\" x2=\"156.0\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"170.4\" y1=\"39\" x2=\"170.4\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"184.8\" y1=\"39\" x2=\"184.8\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"199.2\" y1=\"39\" x2=\"199.2\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"213.6\" y1=\"39\" x2=\"213.6\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"228.0\" y1=\"39\" x2=\"228.0\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"242.4\" y1=\"39\" x2=\"242.4\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"256.8\" y1=\"39\" x2=\"256.8\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"271.2\" y1=\"39\" x2=\"271.2\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"285.6\" y1=\"39\" x2=\"285.6\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"300.0\" y1=\"39\" x2=\"300.0\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"314.4\" y1=\"39\" x2=\"314.4\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"328.8\" y1=\"39\" x2=\"328.8\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"343.2\" y1=\"39\" x2=\"343.2\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"357.6\" y1=\"39\" x2=\"357.6\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"372.0\" y1=\"39\" x2=\"372.0\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"386.4\" y1=\"39\" x2=\"386.4\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"400.8\" y1=\"39\" x2=\"400.8\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"415.2\" y1=\"39\" x2=\"415.2\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"429.6\" y1=\"39\" x2=\"429.6\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"444.0\" y1=\"39\" x2=\"444.0\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"458.4\" y1=\"39\" x2=\"458.4\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"472.8\" y1=\"39\" x2=\"472.8\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"487.2\" y1=\"39\" x2=\"487.2\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"501.6\" y1=\"39\" x2=\"501.6\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"516.0\" y1=\"39\" x2=\"516.0\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"530.4\" y1=\"39\" x2=\"530.4\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"544.8\" y1=\"39\" x2=\"544.8\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"559.2\" y1=\"39\" x2=\"559.2\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"573.6\" y1=\"39\" x2=\"573.6\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"588.0\" y1=\"39\" x2=\"588.0\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"602.4\" y1=\"39\" x2=\"602.4\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"616.8\" y1=\"39\" x2=\"616.8\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"631.2\" y1=\"39\" x2=\"631.2\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"645.6\" y1=\"39\" x2=\"645.6\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><rect x=\"199.2\" y=\"76\" width=\"25.200000000000017\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"230.4\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">119 copiados</text><rect x=\"199.2\" y=\"116\" width=\"398.40000000000003\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"398.4\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">100,000</text><rect x=\"194.4\" y=\"156\" width=\"408.0\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><line x1=\"194.4\" y1=\"30\" x2=\"194.4\" y2=\"195\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"194.4\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">dump começa</text><line x1=\"602.4\" y1=\"30\" x2=\"602.4\" y2=\"195\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><text x=\"602.4\" y=\"208\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">um restore com --oplogReplay termina aqui</text><text x=\"210.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">20:15:11.75</text><text x=\"330.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">20:15:11.85</text><text x=\"450.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">20:15:11.95</text><text x=\"570.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">20:15:12.05</text></svg>", "caption": "Cada coleção é copiada no seu próprio momento. O oplog gravado ao lado é o que permite a um restore levar todas a um único momento, o fim do dump."}
```

O arquivo foi copiado para fora do contêiner com `docker cp`, porque um backup que mora dentro do
contêiner que ele protege se perde junto com ele. Ele tem 810.350 bytes. O dump levou 0,463 segundo.
