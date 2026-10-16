---
title: A logical backup with mongodump
version: 1
---

There are two ways to back up a database, and this lesson runs both on the same data. **A dump
asks the server for every document and writes them out**; a snapshot copies the files the server
keeps on disk. They sound like two routes to the same copy, and the rest of the lesson is about
why they are not.

## What this lesson needs

One MongoDB server whose data lives in a **named volume**, so that the files outlive the container
and a second container can read them. Remove lesson 1's `mongo`, which kept its data inside the
container, and stop lesson 10's cluster if it is still running:

```sh
docker rm -f mongo
docker stop cfg1 shard1 shard2 mongos
```

The server is a replica set of one member. Nothing here needs a second copy, but `mongodump
--oplog`, below, reads the oplog, and only a replica-set member keeps one. `rs.initiate()` with no
argument makes a set whose only member is this server, under its own host name:

```
ana@vm:~$ docker volume create mongo-data
mongo-data
ana@vm:~$ docker run -d --name mongo --hostname mongo --network nosql -v mongo-data:/data/db mongo:8.0 mongod --replSet rs0 --bind_ip_all
9fc22e942492fe80153736a44440b4e2f83c262fcbf41821517b38eeb293a802
ana@vm:~$ docker exec mongo mongosh --quiet --eval 'rs.initiate().ok'
1
```

## Something to back up

The shop again, with enough orders that the numbers mean something: five customers, four products
and 100,000 orders, the same on every run. Save this as `seed.js` in your home directory on the VM:

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

Copy it into the container and run it there, then count what each collection holds and which
indexes it carries. The last line is the check the restores in this lesson are measured against:

```
ana@vm:~$ docker cp seed.js mongo:/tmp/seed.js
ana@vm:~$ docker exec mongo mongosh --quiet shop /tmp/seed.js
orders: 100000
ana@vm:~$ docker exec mongo mongosh --quiet shop --eval 'for (const c of db.getCollectionNames().sort()) print(c, db[c].countDocuments(), db[c].getIndexes().map(i => i.name).join(" "))'
customers 5 _id_ email_1
orders 100000 _id_ customer_1_placedAt_-1 sku_1
products 4 _id_
```

## A dump, as files

`mongodump` ships inside the `mongo:8.0` image, so it runs in the same container as the server.
Asked for one database and a directory, it writes one file per collection:

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

Each collection becomes a `.bson` file, the documents exactly as the server stores them, and a
`.metadata.json` beside it. **The metadata holds the definitions of the indexes and nothing else
about them.** `orders.bson` is 8,860,000 bytes of documents; the two indexes on `orders` are a few
hundred bytes of description in `orders.metadata.json`, and they will be built again, from the
documents, on every restore.

## A dump of a database that is being written to

A real backup runs while the shop is open. The first line below starts a client inside the
container that inserts a payment every ten milliseconds or so, 500 in all, and returns at once
(`-d`); the dump runs while it writes:

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

`--archive` writes one file instead of a directory, `--gzip` compresses it, and `--oplog` is the one
that matters. A dump copies collections one after another and the copy of each takes time, so
without it the result mixes moments: `payments` was finished at 20:15:11.762 with 119 documents,
while `orders` went on until 20:15:12.073. **`--oplog` also records every oplog entry written
from the start of the dump to its end**, 26 here, so that a restore can replay them and bring every
collection to the same moment: the end of the dump.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"A timeline of the dump in this lesson, from 20:15:11.737 to 20:15:12.077. Payments keep arriving the whole time. The payments collection is finished being copied after 25 milliseconds with 119 documents, the orders collection after 336 milliseconds. Alongside, the dump records every oplog entry written from its start to its end, 26 of them. A restore that replays them ends at the moment the dump finished.\"><text x=\"140\" y=\"45\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">payments written</text><line x1=\"150.0\" y1=\"45\" x2=\"654.0\" y2=\"45\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"140\" y=\"85\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">copying payments</text><line x1=\"150.0\" y1=\"85\" x2=\"654.0\" y2=\"85\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"140\" y=\"125\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">copying orders</text><line x1=\"150.0\" y1=\"125\" x2=\"654.0\" y2=\"125\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"140\" y=\"165\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">oplog recorded: 26 entries</text><line x1=\"150.0\" y1=\"165\" x2=\"654.0\" y2=\"165\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><line x1=\"156.0\" y1=\"39\" x2=\"156.0\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"170.4\" y1=\"39\" x2=\"170.4\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"184.8\" y1=\"39\" x2=\"184.8\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"199.2\" y1=\"39\" x2=\"199.2\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"213.6\" y1=\"39\" x2=\"213.6\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"228.0\" y1=\"39\" x2=\"228.0\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"242.4\" y1=\"39\" x2=\"242.4\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"256.8\" y1=\"39\" x2=\"256.8\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"271.2\" y1=\"39\" x2=\"271.2\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"285.6\" y1=\"39\" x2=\"285.6\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"300.0\" y1=\"39\" x2=\"300.0\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"314.4\" y1=\"39\" x2=\"314.4\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"328.8\" y1=\"39\" x2=\"328.8\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"343.2\" y1=\"39\" x2=\"343.2\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"357.6\" y1=\"39\" x2=\"357.6\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"372.0\" y1=\"39\" x2=\"372.0\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"386.4\" y1=\"39\" x2=\"386.4\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"400.8\" y1=\"39\" x2=\"400.8\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"415.2\" y1=\"39\" x2=\"415.2\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"429.6\" y1=\"39\" x2=\"429.6\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"444.0\" y1=\"39\" x2=\"444.0\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"458.4\" y1=\"39\" x2=\"458.4\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"472.8\" y1=\"39\" x2=\"472.8\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"487.2\" y1=\"39\" x2=\"487.2\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"501.6\" y1=\"39\" x2=\"501.6\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"516.0\" y1=\"39\" x2=\"516.0\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"530.4\" y1=\"39\" x2=\"530.4\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"544.8\" y1=\"39\" x2=\"544.8\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"559.2\" y1=\"39\" x2=\"559.2\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"573.6\" y1=\"39\" x2=\"573.6\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"588.0\" y1=\"39\" x2=\"588.0\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"602.4\" y1=\"39\" x2=\"602.4\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"616.8\" y1=\"39\" x2=\"616.8\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"631.2\" y1=\"39\" x2=\"631.2\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"645.6\" y1=\"39\" x2=\"645.6\" y2=\"51\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><rect x=\"199.2\" y=\"76\" width=\"25.200000000000017\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"230.4\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">119 copied</text><rect x=\"199.2\" y=\"116\" width=\"398.40000000000003\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"398.4\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">100,000</text><rect x=\"194.4\" y=\"156\" width=\"408.0\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><line x1=\"194.4\" y1=\"30\" x2=\"194.4\" y2=\"195\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"194.4\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">dump starts</text><line x1=\"602.4\" y1=\"30\" x2=\"602.4\" y2=\"195\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><text x=\"602.4\" y=\"208\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">a restore with --oplogReplay ends here</text><text x=\"210.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">20:15:11.75</text><text x=\"330.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">20:15:11.85</text><text x=\"450.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">20:15:11.95</text><text x=\"570.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">20:15:12.05</text></svg>", "caption": "Each collection is copied at its own moment. The oplog recorded alongside is what lets a restore move all of them to one moment, the end of the dump."}
```

The archive was copied out of the container with `docker cp`, because a backup that lives inside
the container it protects is lost with it. It is 810,350 bytes. The dump took 0.463 seconds.
