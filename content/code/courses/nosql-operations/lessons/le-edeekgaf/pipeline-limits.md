---
title: What the pipeline needs from you
version: 1
---

The pipeline is a list, and the server runs it in order, with two exceptions that matter for
performance: it may move a stage earlier when that cannot change the answer, and it hands the
first stages to the same query engine `find` uses, which is where indexes live. **Only the stages
at the front of the pipeline can use an index**, because every later stage reads documents the
pipeline made, which no index describes.

## Which stages reach the index

`stagesOf` collects every `stage` named in an explain, outermost first, so the plan fits on one
line. Three pipelines, with an index on `{ status: 1, ordered_at: -1 }`:

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

- **`$match` first**: `GROUP <- FETCH <- IXSCAN`, as lesson 7 would expect. The match became an
  index scan on `status`.
- **`$match` after a `$group` on the same field**: `IXSCAN` again, and even `PROJECTION_COVERED`.
  The server saw that matching `_id: "pending"` after grouping by `status` keeps exactly the
  documents with status pending, so it moved the match in front of the group, and the group only
  needed `status`, which the index holds.
- **`$match` on something the group computed**: `COLLSCAN`. Whether a customer's list of statuses
  contains `pending` is not known until every order of that customer has been grouped, so the
  match cannot move and the group reads everything.

The rule to write by is the first case: **filter first, in a `$match` on stored fields**, and do
not rely on the optimiser to rescue the second. It rescued that one because the match was on the
group key, and it cannot rescue the third.

## Memory, and the 100 MB per stage

A stage that has to see all its input before it can emit anything, such as `$sort` without an index
or `$group`, holds that input in memory, and **each such stage may use 100 MB**. Past that it either
writes temporary files to disk or fails. Since MongoDB 6.0, `allowDiskUse` is on by default, so it
writes; a client that passes `allowDiskUse: false` asks for the failure instead.

The 100,000 orders do not reach that limit. Sorting all of them by total, with a `$skip` so the
sort cannot be cut short, needed 30,435,884 bytes, about 29 MB. **To see the limit act on a
collection this small, the session below lowers it to 10 MB**, with a server parameter that exists
for exactly this kind of test and has no business being changed on a server you care about, and puts
it back at the end:

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

Three answers to the same pipeline:

- At the default, `memLimit: 104857600`: **`usedDisk: false`**, `spills: 0`. 29 MB fit in 100.
- At 10 MB, with `allowDiskUse: false`: refused, with the message `Sort exceeded memory limit of
  10485760 bytes, but did not opt in to external sorting`.
- At 10 MB with the default: the same sort succeeded, with **`usedDisk: true` and `spills: 4`**. It
  wrote sorted runs to disk four times and merged them.

`usedDisk: true` in an explain is the line to look for when a pipeline is slower than it should
be: reading and writing temporary files is far slower than memory, and it usually means a sort an
index could have done, or a `$group` with more distinct keys than anyone expected. The fix is
seldom to raise the limit. It is a `$match` that sends fewer documents in, an index that makes the
sort unnecessary, or a `$project` early in the pipeline that drops the fields no later stage reads,
since the memory counted is the size of what each document still carries.
