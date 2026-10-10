---
title: MongoDB, índices e o preço de embutir
version: 1
---

A consulta por todo show no Teatro Ipê devolveu os documentos certos. Como ela os achou é outra
pergunta, e o `explain` responde. Isto imprime três campos do plano: a etapa que leu os dados,
quantos documentos ela olhou e quantos devolveu. Depois um índice no campo embutido, e a mesma
pergunta de novo:

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

**O `COLLSCAN` examinou os 100 documentos para devolver 34**: uma varredura da coleção, o equivalente
no MongoDB à leitura sequencial do PostgreSQL. Depois do `createIndex`, o plano é um **`IXSCAN`** que
examinou exatamente os 34 que devolveu. Em cem documentos a diferença é nada; em dez milhões é a
diferença entre uma consulta e uma queda, e é a mesma lição de um índice em qualquer banco. O
MongoDB indexa campos aninhados e elementos de listas tão facilmente quanto os de primeiro nível.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Duas barras para a mesma consulta em 100 documentos de show. Sem índice, uma varredura da coleção examinou os 100 para devolver 34. Com um índice em venue.name, uma varredura do índice examinou exatamente os 34 que devolveu.\"><text x=\"110\" y=\"56\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">COLLSCAN</text><rect x=\"125\" y=\"40\" width=\"440.00000000000006\" height=\"32\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"125\" y=\"40\" width=\"149.60000000000002\" height=\"32\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"575.0\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">100 examinados</text><text x=\"110\" y=\"126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">IXSCAN</text><rect x=\"125\" y=\"110\" width=\"149.60000000000002\" height=\"32\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"125\" y=\"110\" width=\"149.60000000000002\" height=\"32\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"284.6\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">34 examinados</text><text x=\"200\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">34 devolvidos</text></svg>", "caption": "Documentos examinados para devolver os 34 shows no Teatro Ipê, antes e depois do índice."}
```

## Renomeando a casa

A aula 4 disse que o custo de embutir é a atualização. A Arena Sul vira Arena Sul Hall:

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

**33 documentos bateram e 33 foram modificados** por um fato que mudou. No PostgreSQL da bilheteria
seria uma linha de uma tabela de casas. O `updateMany` muda cada documento atomicamente, e **as 33
mudanças não são uma transação**: um leitor no meio poderia ver alguns shows com o nome velho e
outros com o novo. Para o nome de uma casa isso é inofensivo. Para um fato que precisa concordar
entre documentos, é o motivo para guardar uma referência em vez de uma cópia, ou para pagar por uma
transação entre documentos.

Remova o contêiner no fim, como acima; os dados vão junto.
