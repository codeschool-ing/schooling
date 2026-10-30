---
title: Nodes, storage and the bill
version: 1
---

**Bigtable is billed for capacity, not for requests.** Firestore of lesson 10 charges per document
read and written; Bigtable charges for the nodes that exist each hour, whether anything reads them
or not. On top come the storage the tables take and the network they use. A table that nobody queries all
weekend costs exactly what it cost on Friday evening. That changes the question the bill asks: not
"how many reads", but "how many nodes does the busiest hour need, and how many do the other hours
pay for".

## Instance, cluster, node

**An instance is a container for clusters, a cluster lives in one zone, and a cluster is a number of
nodes.** The tables belong to the instance, and every cluster of the instance holds a full copy of
them. A node is the unit of serving capacity. It holds no data and serves tablets out of Colossus, so
adding one changes how fast the cluster is, not how much it can store; the documentation sets a
limit of storage per node for each storage type. A second cluster in another zone of
`southamerica-east1` is how an instance survives a zone failing, and Bigtable replicates the tables
between the clusters on its own. Replication between clusters is eventually consistent; an **app
profile** says whether an application's requests go to one cluster, for reads that see their own
writes, or to the nearest one available.

None of that exists in the emulator, which has one instance it does not know the name of:

```
ana@laptop:~/gcp$ cbt listinstances
2026/10/30 15:12:02 Getting list of instances: rpc error: code = Unimplemented desc = unimplemented feature
ana@laptop:~/gcp$ cbt createinstance quitanda-prod 'Quitanda prod' quitanda-c1 southamerica-east1-a 3 SSD
2026/10/30 15:12:02 Creating instance: rpc error: code = Unimplemented desc = unimplemented feature
```

**`Unimplemented` is the emulator saying it has no control plane.** It serves the data API and the
table half of the admin API, which is everything the previous sections used, and nothing about
instances, clusters, nodes, app profiles, backups or autoscaling. Creating the instance on Google
Cloud is one command, shown here and not run, since nothing in this course reaches Google:

```sh
gcloud bigtable instances create quitanda --display-name="Quitanda" \
  --cluster-config=id=quitanda-c1,zone=southamerica-east1-a,nodes=3 \
  --cluster-storage-type=SSD
```

**The storage type is chosen with the cluster and cannot be changed.** SSD is the default and the
one Google recommends for almost everything. HDD is cheaper per gibibyte and far slower to read a
row at random, and the documentation reserves it for tables of at least ten terabytes read mostly in
long scans. Moving from one to the other means a new cluster and a copy.

## The price, read on 2026-10-30

From cloud.google.com/bigtable/pricing, São Paulo, `southamerica-east1`, in USD:

| item | price |
|---|---|
| node, Enterprise edition | $0.98 per node-hour |
| node, Enterprise Plus edition | $1.3497 per node-hour |
| node, Enterprise, 1-year commitment | $0.784 per node-hour |
| node, Enterprise, 3-year commitment | $0.588 per node-hour |
| SSD storage | $0.26 per GiB-month |
| HDD storage | $0.039 per GiB-month |
| Infrequent Access storage | $0.039 per GiB-month |
| Data Boost | $1.274 per 1,000 SPU-hours |

**The page now names two editions, Enterprise and Enterprise Plus**, and says the edition decides
which node price applies; it attaches an in-memory capacity multiplier to Enterprise Plus nodes, and
it sends the reader to a page on editions for the rest, which this lesson could not read. So this
lesson prices Enterprise nodes and says no more about the difference than the pricing page does.
**A node is billed for the largest number that existed during each hour, with a minimum of one hour
per node provisioned**, and, in the page's words, regardless of node usage. The arithmetic for
Quitanda's click stream:

```
ana@laptop:~/gcp$ python3 -c 'node = 0.98 * 730; print(round(node, 2), round(3 * node, 2), round(6 * node, 2))'
715.4 2146.2 4292.4
ana@laptop:~/gcp$ python3 -c 'print(round(3 * 0.784 * 730, 2), round(3 * 0.588 * 730, 2))'
1716.96 1287.72
ana@laptop:~/gcp$ python3 -c 'print(2048 * 0.26, round(2048 * 0.039, 2), 8 * 90, round(8 * 90 * 0.26, 2))'
532.48 79.87 720 187.2
```

**One node for a month is 715.40 dollars**, at 730 hours, which is the monthly figure the page itself
shows. Three nodes are 2,146.20 dollars, and a second cluster of three in another zone doubles it to
4,292.40, with no charge for the replication itself, because the page charges nothing for
replication between clusters in one region. A one-year commitment brings three nodes to 1,716.96, and
three years to 1,287.72. **Storage is the small line, unless the type is wrong**: two tebibytes on
SSD are 532.48 dollars a month and on HDD 79.87, and the node lines dwarf both.

**The garbage collection policy is a price.** At an estimated 8 GiB of clicks a day, keeping ninety
days is 720 GiB, 187.20 dollars a month on SSD. That is an upper estimate, since Bigtable compresses
what it stores and the page bills the compressed size. The point stands whatever the ratio:
`maxage=90d` on the `ev` family is the retention decision and the storage bill at once, and a family
with no policy grows for ever.

## Autoscaling, and the nodes the busy hour needs

**Bigtable autoscaling is a setting of the cluster**: a minimum and a maximum number of nodes and a
CPU utilisation target, and optionally a storage utilisation target. Bigtable adds nodes when the
cluster runs above the target and removes them when it runs well below, on its own. Not run here:

```sh
gcloud bigtable clusters update quitanda-c1 --instance=quitanda \
  --autoscaling-min-nodes=1 --autoscaling-max-nodes=6 --autoscaling-cpu-target=60
```

**A new node is not instant capacity.** Bigtable has to move tablets onto it before it helps, and the
documentation warns that under load this takes minutes, up to about twenty, before the cluster shows
the benefit. So autoscaling follows a load that changes over hours, the evening peak that grows from
17:00, and arrives late for a promotion that starts at 18:00 sharp. For that, the cluster's minimum
is raised before the event and lowered after it, by a scheduled job. And because nodes are billed by
the hour, a cluster that scales up at 18:05 and down at 18:50 pays both nodes' whole hour.

**No setting rescues a hot key.** More nodes serve more tablets, and a time-first key sends every
write to one tablet, so the cluster scales up to the maximum and the write rate stays where it was.
Autoscaling multiplies a well-spread key and does nothing for a badly spread one.

**Data Boost is the other way to pay**, for reads that are not the application's. An export, a
Dataflow job or a BigQuery query over the table can run on serverless compute billed per
SPU-second, with a minimum of 60 SPU-seconds per request, instead of on the nodes the app depends on.
One SPU is about a thousandth of a node, so Data Boost suits a nightly job and is no cheaper for
serving traffic all day. The page also lists **Infrequent Access storage** at the HDD price, a tier
an SSD table can move old data into, and charges $0.0318 per GiB moved into it. Both are named here
so the line on an invoice is not new; this course does not use either.
