---
title: O que o pipeline precisa de você
version: 1
---

O pipeline é uma lista, e o servidor a roda em ordem, com duas exceções que importam para o
desempenho: ele pode mover um estágio para antes quando isso não muda a resposta, e entrega os
primeiros estágios ao mesmo motor de consulta que o `find` usa, que é onde os índices vivem. **Só os
estágios do começo do pipeline podem usar um índice**, porque todo estágio seguinte lê documentos
que o pipeline produziu, e nenhum índice os descreve.

## Quais estágios chegam ao índice

`stagesOf` junta todo `stage` citado num explain, de fora para dentro, para o plano caber numa
linha. Três pipelines, com um índice em `{ status: 1, ordered_at: -1 }`:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> function stagesOf(explained) {
|   const stages = [];
|   JSON.stringify(explained, (key, value) => { if (key === "stage") stages.push(value); return value; });
|   return stages;
| }
[Function: stagesOf]
shop> db.orders.createIndex({ status: 1, ordered_at: -1 })
status_1_ordered_at_-1
shop> stagesOf(db.orders.explain().aggregate([{ $match: { status: "pending" } }, { $group: { _id: "$customer", orders: { $sum: 1 } } }]))
[ 'GROUP', 'FETCH', 'IXSCAN' ]
shop> stagesOf(db.orders.explain().aggregate([{ $group: { _id: "$status", orders: { $sum: 1 } } }, { $match: { _id: "pending" } }]))
[ 'GROUP', 'PROJECTION_COVERED', 'IXSCAN' ]
shop> stagesOf(db.orders.explain().aggregate([{ $group: { _id: "$customer", statuses: { $push: "$status" } } }, { $match: { statuses: "pending" } }]))
[ 'GROUP', 'COLLSCAN' ]
shop> exit
```

- **`$match` primeiro**: `GROUP <- FETCH <- IXSCAN`, como a aula 7 faria esperar. O match virou uma
  varredura de índice em `status`.
- **`$match` depois de um `$group` no mesmo campo**: `IXSCAN` de novo, e até `PROJECTION_COVERED`. O
  servidor viu que casar `_id: "pending"` depois de agrupar por `status` mantém exatamente os
  documentos com status pending, então moveu o match para antes do grupo, e o grupo só precisava de
  `status`, que o índice guarda.
- **`$match` sobre algo que o grupo calculou**: `COLLSCAN`. Se a lista de status de um cliente contém
  `pending` só se sabe depois que todos os pedidos daquele cliente foram agrupados, então o match não
  pode se mover e o grupo lê tudo.

A regra para escrever é o primeiro caso: **filtre primeiro, num `$match` sobre campos guardados**, e
não conte com o otimizador para salvar o segundo. Ele salvou aquele porque o match era sobre a chave
do grupo, e não tem como salvar o terceiro.

## Memória, e os 100 MB por estágio

Um estágio que precisa ver toda a sua entrada antes de emitir qualquer coisa, como um `$sort` sem
índice ou um `$group`, guarda essa entrada na memória, e **cada estágio desses pode usar 100 MB**.
Passado isso, ele escreve arquivos temporários em disco ou falha. Desde o MongoDB 6.0, o
`allowDiskUse` vem ligado por padrão, então ele escreve; um cliente que passa `allowDiskUse: false`
pede a falha em vez disso.

Os 100.000 pedidos não chegam a esse limite. Ordenar todos pelo total, com um `$skip` para a
ordenação não poder ser encurtada, precisou de 30.435.884 bytes, cerca de 29 MB. **Para ver o limite
agir numa coleção tão pequena, a sessão abaixo o baixa para 10 MB**, com um parâmetro do servidor
que existe exatamente para esse tipo de teste e não tem por que ser mudado num servidor com o qual
você se importa, e o devolve no fim:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> function sortStage(explained) {
|   let sort = null;
|   JSON.stringify(explained, (key, value) => { if (value && value.stage === "SORT" && "usedDisk" in value) sort = value; return value; });
|   return { memLimit: sort.memLimit, totalDataSizeSorted: sort.totalDataSizeSorted, usedDisk: sort.usedDisk, spills: sort.spills };
| }
[Function: sortStage]
shop> const byTotal = [{ $sort: { total: -1 } }, { $skip: 99999 }]

shop> sortStage(db.orders.explain("executionStats").aggregate(byTotal))
{
  memLimit: 104857600,
  totalDataSizeSorted: 30435884,
  usedDisk: false,
  spills: 0
}
shop> db.adminCommand({ setParameter: 1, internalQueryMaxBlockingSortMemoryUsageBytes: 10485760 })
{ was: 104857600, ok: 1 }
shop> db.orders.aggregate(byTotal, { allowDiskUse: false })
Uncaught 
MongoServerError[QueryExceededMemoryLimitNoDiskUseAllowed]: PlanExecutor error during aggregation :: caused by :: Sort exceeded memory limit of 10485760 bytes, but did not opt in to external sorting.
shop> sortStage(db.orders.explain("executionStats").aggregate(byTotal))
{
  memLimit: 10485760,
  totalDataSizeSorted: 30435884,
  usedDisk: true,
  spills: 4
}
shop> db.adminCommand({ setParameter: 1, internalQueryMaxBlockingSortMemoryUsageBytes: 104857600 })
{ was: 10485760, ok: 1 }
shop> exit
```

Três respostas para o mesmo pipeline:

- No padrão, `memLimit: 104857600`: **`usedDisk: false`**, `spills: 0`. 29 MB couberam em 100.
- Com 10 MB e `allowDiskUse: false`: recusado, com a mensagem `Sort exceeded memory limit of
  10485760 bytes, but did not opt in to external sorting`.
- Com 10 MB e o padrão: a mesma ordenação deu certo, com **`usedDisk: true` e `spills: 4`**. Ela
  gravou trechos ordenados em disco quatro vezes e os intercalou.

`usedDisk: true` num explain é a linha a procurar quando um pipeline está mais lento do que deveria:
ler e escrever arquivos temporários é muito mais lento que a memória, e quase sempre significa uma
ordenação que um índice poderia ter feito, ou um `$group` com mais chaves distintas do que alguém
esperava. A correção raramente é subir o limite. É um `$match` que mande menos documentos para
dentro, um índice que torne a ordenação desnecessária, ou um `$project` cedo no pipeline que jogue
fora os campos que nenhum estágio seguinte lê, já que a memória contada é o tamanho do que cada
documento ainda carrega.
