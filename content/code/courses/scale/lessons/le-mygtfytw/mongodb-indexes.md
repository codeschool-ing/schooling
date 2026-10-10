---
title: MongoDB, indexes and the price of embedding
version: 1
---

The query for every show at Teatro Ipê returned the right documents. How it found them is a
separate question, and `explain` answers it. This prints three fields of the query plan: the stage
that read the data, how many documents it looked at, and how many it returned. Then an index on the
embedded field, and the same question again:

```
ana@lab:~/tickets$ docker exec mongo mongosh --quiet tickets --eval 'const p = db.shows.find({"venue.name": "Teatro Ipê"}).explain("executionStats"); printjson({stage: p.queryPlanner.winningPlan.inputStage?.stage ?? p.queryPlanner.winningPlan.stage, examined: p.executionStats.totalDocsExamined, returned: p.executionStats.nReturned})'
{
  stage: 'COLLSCAN',
  examined: 100,
  returned: 34
}
ana@lab:~/tickets$ docker exec mongo mongosh --quiet tickets --eval 'db.shows.createIndex({"venue.name": 1})'
venue.name_1
ana@lab:~/tickets$ docker exec mongo mongosh --quiet tickets --eval 'const p = db.shows.find({"venue.name": "Teatro Ipê"}).explain("executionStats"); printjson({stage: p.queryPlanner.winningPlan.inputStage?.stage ?? p.queryPlanner.winningPlan.stage, examined: p.executionStats.totalDocsExamined, returned: p.executionStats.nReturned})'
{
  stage: 'IXSCAN',
  examined: 34,
  returned: 34
}
```

**`COLLSCAN` examined all 100 documents to return 34**: a collection scan, MongoDB's equivalent of
PostgreSQL's sequential scan. After `createIndex`, the plan is an **`IXSCAN`** that examined exactly
the 34 it returned. On a hundred documents the difference is nothing; on ten million it is the
difference between a query and an outage, and it is the same lesson as an index in any database.
MongoDB indexes nested fields and array elements as easily as top-level ones.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Two bars for the same query on 100 show documents. Without an index, a collection scan examined all 100 to return 34. With an index on venue.name, an index scan examined exactly the 34 it returned.\"><text x=\"110\" y=\"56\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">COLLSCAN</text><rect x=\"125\" y=\"40\" width=\"440.00000000000006\" height=\"32\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"125\" y=\"40\" width=\"149.60000000000002\" height=\"32\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"575.0\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">100 examined</text><text x=\"110\" y=\"126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">IXSCAN</text><rect x=\"125\" y=\"110\" width=\"149.60000000000002\" height=\"32\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"125\" y=\"110\" width=\"149.60000000000002\" height=\"32\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"284.6\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">34 examined</text><text x=\"200\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">34 returned</text></svg>", "caption": "Documents examined to return the 34 shows at Teatro Ipê, before and after the index."}
```

## Renaming the venue

Lesson 4 said the cost of embedding is the update. Arena Sul becomes Arena Sul Hall:

```
ana@lab:~/tickets$ docker exec mongo mongosh --quiet tickets --eval 'db.shows.updateMany({"venue.name": "Arena Sul"}, {$set: {"venue.name": "Arena Sul Hall"}})'
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 33,
  modifiedCount: 33,
  upsertedCount: 0
}
ana@lab:~/tickets$ docker rm -f mongo
mongo
```

**33 documents matched and 33 were modified** for one fact that changed. In the box office's
PostgreSQL it would have been one row of a venues table. `updateMany` changes each document
atomically, and **the 33 changes are not one transaction**: a reader in the middle could see some
shows at the old name and some at the new. For a venue's name that is harmless. For a fact that has
to agree across documents, it is the reason to keep a reference instead of a copy, or to pay for a
multi-document transaction.

Remove the container at the end, as above; the data goes with it.
