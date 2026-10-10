---
title: Three nodes, one ring
version: 1
---

Lesson 2 put Cassandra on one node, where every partition lives in the same place and the partition
key looks like an index. **With more than one node it stops looking like an index and becomes an
address.** The partition key is hashed to a number, the number falls somewhere on a ring the nodes
share out between them, and that place decides which machine holds the rows. Every rule in the rest
of this lesson follows from that one fact.

## Three nodes on your machine

Lessons 16 to 19 use a cluster of three Cassandra nodes called `c1`, `c2` and `c3`, on the network
`nosql` that lesson 1 created. Three nodes take about 1.5 GB of memory between them, so stop what
you are not using first: `docker stop mongo redis cassandra` stops the containers of lesson 1, and
the single `cassandra` node is not part of the cluster.

```sh
for n in 1 2 3; do
  docker run -d --name c$n --network nosql \
    -e CASSANDRA_CLUSTER_NAME=lab -e CASSANDRA_SEEDS=c1 \
    -e CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch -e CASSANDRA_DC=dc1 -e CASSANDRA_RACK=rack1 \
    -e MAX_HEAP_SIZE=256M -e HEAP_NEWSIZE=64M cassandra:5.0
  until [ "$(docker exec c$n nodetool status 2>/dev/null | grep -c '^UN')" = $n ]; do sleep 5; done
done
```

The `-e` settings are read by the image's start script and written into Cassandra's configuration:

| setting | what it does here |
| --- | --- |
| `CASSANDRA_CLUSTER_NAME=lab` | the name every node checks before it agrees to join; a node with another name is refused |
| `CASSANDRA_SEEDS=c1` | the node a new one asks first to learn who else is in the cluster |
| `CASSANDRA_ENDPOINT_SNITCH`, `_DC`, `_RACK` | where each node says it is: data centre `dc1`, rack `rack1`. Lesson 17 needs the data centre's name |
| `MAX_HEAP_SIZE`, `HEAP_NEWSIZE` | the small heap of lesson 1, without which three nodes do not fit in a 4 GB VM |

**The loop starts one node and waits for it before the next.** A node that joins takes its share of
the ring from the nodes already there, and Cassandra expects those joins one at a time. The `until`
line asks `nodetool status` how many nodes are `UN`, up and normal, and goes on when the count
reaches the node just started. Each node took a little over a minute in the lab, so the loop takes
three or four.

If the loop never finishes, `docker logs c2` shows what the node is doing, and lesson 1's section on
failures covers a node killed for memory. If you stop the cluster between lessons, `docker start c1
c2 c3` brings it back with its data; the loop is only for a cluster that does not exist yet.

## A keyspace with one copy, and eight orders

The keyspace decides how many copies of each partition exist. This lesson asks for **one**, so that
each partition lives on exactly one node and you can see which; lesson 17 raises it to three. Save
this as `orders.cql`:

```sql
CREATE KEYSPACE shop
  WITH replication = {'class': 'NetworkTopologyStrategy', 'dc1': 1};

CREATE TABLE shop.orders_by_customer (
  customer   text,
  ordered_at timestamp,
  order_id   text,
  total      decimal,
  status     text,
  PRIMARY KEY (customer, ordered_at, order_id)
) WITH CLUSTERING ORDER BY (ordered_at DESC, order_id ASC);

INSERT INTO shop.orders_by_customer (customer, ordered_at, order_id, total, status) VALUES ('ana@example.com',   '2026-03-02 13:15:00+0000', 'A-1001',  349.90, 'delivered');
INSERT INTO shop.orders_by_customer (customer, ordered_at, order_id, total, status) VALUES ('bruno@example.com', '2026-03-02 15:40:00+0000', 'A-1002', 1499.00, 'delivered');
INSERT INTO shop.orders_by_customer (customer, ordered_at, order_id, total, status) VALUES ('carla@example.com', '2026-03-02 19:05:00+0000', 'A-1003',   39.90, 'delivered');
INSERT INTO shop.orders_by_customer (customer, ordered_at, order_id, total, status) VALUES ('ana@example.com',   '2026-03-20 00:02:00+0000', 'A-1004',  189.00, 'delivered');
INSERT INTO shop.orders_by_customer (customer, ordered_at, order_id, total, status) VALUES ('diego@example.com', '2026-03-20 11:20:00+0000', 'A-1005',  349.90, 'shipped');
INSERT INTO shop.orders_by_customer (customer, ordered_at, order_id, total, status) VALUES ('ana@example.com',   '2026-04-08 12:30:00+0000', 'A-1006', 1499.00, 'shipped');
INSERT INTO shop.orders_by_customer (customer, ordered_at, order_id, total, status) VALUES ('bruno@example.com', '2026-04-08 14:10:00+0000', 'A-1007',   39.90, 'shipped');
INSERT INTO shop.orders_by_customer (customer, ordered_at, order_id, total, status) VALUES ('elisa@example.com', '2026-04-09 09:45:00+0000', 'A-1008',  189.00, 'pending');
```

and hand it to `cqlsh`, which reads statements from its standard input. Silence means every
statement worked:

```
ana@vm:~$ docker exec -i c1 cqlsh < orders.cql
```

The times are written in UTC, with `+0000`, because that is how `cqlsh` prints them back.

## Where the partitions went

```
ana@vm:~$ docker exec c1 nodetool status shop
Datacenter: dc1
===============
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load        Tokens  Owns (effective)  Host ID                               Rack 
UN  172.18.0.3  80.02 KiB   16      31.6%             c7136733-e3d8-40a4-b1b9-6068904ef7a9  rack1
UN  172.18.0.4  119.66 KiB  16      35.7%             f2c1f805-fbdd-42e2-9442-44d0414adabf  rack1
UN  172.18.0.2  95.9 KiB    16      32.7%             2b88e753-4987-4fbf-a0a4-6a1919f4a912  rack1

ana@vm:~$ docker inspect -f '{{.Name}} {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' c1 c2 c3
/c1 172.18.0.2
/c2 172.18.0.3
/c3 172.18.0.4
ana@vm:~$ docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}" c1 c2 c3
NAME      MEM USAGE / LIMIT
c1        557.1MiB / 15.72GiB
c2        467.8MiB / 15.72GiB
c3        503.1MiB / 15.72GiB
```

`Tokens 16` is the number of places on the ring each node owns, and `Owns (effective)` is the share
of the ring that adds up to, for the keyspace `shop`. Three nodes with 16 tokens each split the ring
roughly in thirds, not exactly. Cassandra names nodes by address, so the `docker inspect` line is the
key to read everything after it: `c1` is `172.18.0.2`, `c2` is `.3`, `c3` is `.4`. Your addresses
can differ; read your own. Memory came to about 1.5 GB for the three, as promised.

The partition key is hashed by the **Murmur3** partitioner into a token, a 64-bit signed number, and
`token()` shows it:

```
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> SELECT DISTINCT customer, token(customer) FROM shop.orders_by_customer;

 customer          | system.token(customer)
-------------------+------------------------
 carla@example.com |   -5911513789470835951
 bruno@example.com |   -3891430603489557805
 elisa@example.com |    6901144969670893120
   ana@example.com |    8413089589345688709
 diego@example.com |    8993384036030544940

(5 rows)
cqlsh> exit
ana@vm:~$ for c in ana bruno carla diego elisa; do echo "$c $(docker exec c1 nodetool getendpoints shop orders_by_customer $c@example.com)"; done
ana 172.18.0.3
bruno 172.18.0.4
carla 172.18.0.3
diego 172.18.0.2
elisa 172.18.0.3
```

**The rows came back in token order, not in alphabetical order** and not in the order they were
written: Carla, the most negative token, first. A query with no partition key reads the ring from
one end to the other, which is what that order shows. `nodetool getendpoints` answers the question
the token raises, which node holds this key: Ana, Carla and Elisa are on `c2`, Bruno on `c3` and
Diego on `c1`. Nothing about the names decides that. Two neighbouring email addresses hash to tokens
nowhere near each other, which is the point: **the hash spreads keys evenly, whatever they look
like.**

## The ring itself

`nodetool ring` lists every token and its owner:

```
ana@vm:~$ docker exec c1 nodetool ring shop | head -12

Datacenter: dc1
==========
Address          Rack        Status State   Load            Owns                Token                                       
                                                                                9198835449366431173                         
172.18.0.4       rack1       Up     Normal  119.66 KiB      35.71%              -8883060869248345148                        
172.18.0.3       rack1       Up     Normal  80.02 KiB       31.64%              -8649444933386381616                        
172.18.0.2       rack1       Up     Normal  95.9 KiB        32.65%              -8269763171827006366                        
172.18.0.4       rack1       Up     Normal  119.66 KiB      35.71%              -7905170012854856482                        
172.18.0.3       rack1       Up     Normal  80.02 KiB       31.64%              -7615144286710977248                        
172.18.0.3       rack1       Up     Normal  80.02 KiB       31.64%              -7188857785429847858                        
172.18.0.4       rack1       Up     Normal  119.66 KiB      35.71%              -6757846304499179774                        
ana@vm:~$ docker exec c1 nodetool ring shop | grep -c Normal
48
```

Each line is one token, sorted. **A node owns the range that ends at its token**, starting just
after the token on the line above. The lone number above the first line is the highest token,
repeated from the bottom of the list: the first range starts just after it, wrapping round from the
top of the ring to the bottom. Forty-eight lines, sixteen per node, interleaved. Drawn as a circle, with this run's own tokens:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 380\" role=\"img\" aria-label=\"A ring of tokens from the lowest possible value at the top, going clockwise to the highest. Three nodes, c1, c2 and c3, each own sixteen arcs of it, interleaved around the ring. Five customers' partition keys are marked where their tokens fall: carla, bruno, elisa, ana and diego. Each is stored by the node that owns the arc it lands in: ana, carla and elisa on c2, bruno on c3, diego on c1.\"><path d=\"M209.0 70.0 A120 120 0 0 1 223.9 70.8\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M223.9 70.8 A120 120 0 0 1 233.3 72.3\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M233.3 72.3 A120 120 0 0 1 248.3 76.3\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M248.3 76.3 A120 120 0 0 1 262.1 81.9\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M262.1 81.9 A120 120 0 0 1 272.5 87.6\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M272.5 87.6 A120 120 0 0 1 286.7 97.7\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M286.7 97.7 A120 120 0 0 1 299.3 109.9\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M299.3 109.9 A120 120 0 0 1 306.2 118.3\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M306.2 118.3 A120 120 0 0 1 315.1 132.1\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M315.1 132.1 A120 120 0 0 1 319.7 141.3\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M319.7 141.3 A120 120 0 0 1 325.8 158.4\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M325.8 158.4 A120 120 0 0 1 328.8 172.8\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M328.8 172.8 A120 120 0 0 1 329.8 183.1\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M329.8 183.1 A120 120 0 0 1 329.3 202.6\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M329.3 202.6 A120 120 0 0 1 325.3 223.1\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M325.3 223.1 A120 120 0 0 1 320.9 235.9\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M320.9 235.9 A120 120 0 0 1 311.6 253.9\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M311.6 253.9 A120 120 0 0 1 304.4 264.0\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M304.4 264.0 A120 120 0 0 1 294.7 275.0\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M294.7 275.0 A120 120 0 0 1 286.2 282.7\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M286.2 282.7 A120 120 0 0 1 273.5 291.8\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M273.5 291.8 A120 120 0 0 1 265.1 296.6\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M265.1 296.6 A120 120 0 0 1 248.1 303.8\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M248.1 303.8 A120 120 0 0 1 233.4 307.7\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M233.4 307.7 A120 120 0 0 1 223.7 309.2\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M223.7 309.2 A120 120 0 0 1 207.1 310.0\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M207.1 310.0 A120 120 0 0 1 187.1 307.8\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M187.1 307.8 A120 120 0 0 1 174.3 304.6\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M174.3 304.6 A120 120 0 0 1 151.9 295.0\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M151.9 295.0 A120 120 0 0 1 135.6 284.1\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M135.6 284.1 A120 120 0 0 1 122.6 272.2\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M122.6 272.2 A120 120 0 0 1 114.6 262.7\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M114.6 262.7 A120 120 0 0 1 105.4 248.8\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M105.4 248.8 A120 120 0 0 1 100.7 239.6\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M100.7 239.6 A120 120 0 0 1 94.8 223.6\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M94.8 223.6 A120 120 0 0 1 91.0 205.7\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M91.0 205.7 A120 120 0 0 1 90.0 193.4\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M90.0 193.4 A120 120 0 0 1 91.2 173.3\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M91.2 173.3 A120 120 0 0 1 96.4 151.2\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M96.4 151.2 A120 120 0 0 1 103.0 135.7\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M103.0 135.7 A120 120 0 0 1 114.3 117.6\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M114.3 117.6 A120 120 0 0 1 125.5 104.8\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M125.5 104.8 A120 120 0 0 1 136.8 94.9\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M136.8 94.9 A120 120 0 0 1 146.3 88.3\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M146.3 88.3 A120 120 0 0 1 166.8 78.1\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M166.8 78.1 A120 120 0 0 1 182.3 73.2\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M182.3 73.2 A120 120 0 0 1 198.1 70.6\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M198.1 70.6 A120 120 0 0 1 209.0 70.0\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><line x1=\"223.0\" y1=\"78.8\" x2=\"224.8\" y2=\"62.9\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"231.8\" y1=\"80.1\" x2=\"234.9\" y2=\"64.4\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"245.7\" y1=\"83.9\" x2=\"250.8\" y2=\"68.7\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"258.6\" y1=\"89.1\" x2=\"265.6\" y2=\"74.7\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"268.3\" y1=\"94.4\" x2=\"276.7\" y2=\"80.7\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"281.5\" y1=\"103.8\" x2=\"291.8\" y2=\"91.5\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"293.4\" y1=\"115.2\" x2=\"305.3\" y2=\"104.5\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"299.8\" y1=\"123.1\" x2=\"312.7\" y2=\"113.5\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"308.1\" y1=\"135.9\" x2=\"322.1\" y2=\"128.2\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"312.4\" y1=\"144.5\" x2=\"327.0\" y2=\"138.0\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"318.0\" y1=\"160.5\" x2=\"333.5\" y2=\"156.2\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"320.8\" y1=\"174.0\" x2=\"336.7\" y2=\"171.7\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"321.8\" y1=\"183.5\" x2=\"337.8\" y2=\"182.6\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"321.4\" y1=\"201.7\" x2=\"337.3\" y2=\"203.4\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"317.7\" y1=\"220.9\" x2=\"333.0\" y2=\"225.3\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"313.5\" y1=\"232.8\" x2=\"328.3\" y2=\"239.0\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"304.8\" y1=\"249.6\" x2=\"318.4\" y2=\"258.1\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"298.1\" y1=\"259.1\" x2=\"310.7\" y2=\"269.0\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"289.0\" y1=\"269.4\" x2=\"300.3\" y2=\"280.7\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"281.1\" y1=\"276.5\" x2=\"291.3\" y2=\"288.9\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"269.3\" y1=\"285.0\" x2=\"277.7\" y2=\"298.6\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"261.4\" y1=\"289.5\" x2=\"268.8\" y2=\"303.7\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"245.5\" y1=\"296.2\" x2=\"250.6\" y2=\"311.4\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"231.8\" y1=\"299.9\" x2=\"234.9\" y2=\"315.6\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"222.8\" y1=\"301.3\" x2=\"224.7\" y2=\"317.2\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"207.3\" y1=\"302.0\" x2=\"206.9\" y2=\"318.0\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"188.7\" y1=\"299.9\" x2=\"185.6\" y2=\"315.7\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"176.6\" y1=\"296.9\" x2=\"171.9\" y2=\"312.2\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"155.8\" y1=\"288.0\" x2=\"148.1\" y2=\"302.0\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"140.6\" y1=\"277.9\" x2=\"130.6\" y2=\"290.4\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"128.4\" y1=\"266.8\" x2=\"116.8\" y2=\"277.7\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"120.9\" y1=\"257.9\" x2=\"108.2\" y2=\"267.6\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"112.3\" y1=\"244.8\" x2=\"98.4\" y2=\"252.7\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"108.0\" y1=\"236.3\" x2=\"93.5\" y2=\"242.9\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"102.5\" y1=\"221.3\" x2=\"87.1\" y2=\"225.8\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"99.0\" y1=\"204.7\" x2=\"83.1\" y2=\"206.7\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"98.0\" y1=\"193.1\" x2=\"82.1\" y2=\"193.6\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"99.1\" y1=\"174.4\" x2=\"83.3\" y2=\"172.2\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"104.0\" y1=\"153.8\" x2=\"88.9\" y2=\"148.6\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"110.1\" y1=\"139.3\" x2=\"95.8\" y2=\"132.1\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"120.7\" y1=\"122.4\" x2=\"107.9\" y2=\"112.7\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"131.1\" y1=\"110.5\" x2=\"119.9\" y2=\"99.1\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"141.7\" y1=\"101.2\" x2=\"132.0\" y2=\"88.5\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"150.5\" y1=\"95.1\" x2=\"142.0\" y2=\"81.5\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"169.7\" y1=\"85.5\" x2=\"163.9\" y2=\"70.6\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"184.1\" y1=\"81.0\" x2=\"180.4\" y2=\"65.5\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"198.9\" y1=\"78.6\" x2=\"197.3\" y2=\"62.6\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"209.1\" y1=\"78.0\" x2=\"208.9\" y2=\"62.0\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><circle cx=\"300.4\" cy=\"147.2\" r=\"4\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1\"></circle><text x=\"276.9\" y=\"158.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">carla</text><circle cx=\"307.0\" cy=\"214.3\" r=\"4\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1\"></circle><text x=\"281.8\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">bruno</text><circle cx=\"138.9\" cy=\"119.7\" r=\"4\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1\"></circle><text x=\"157.4\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">elisa</text><circle cx=\"182.7\" cy=\"93.8\" r=\"4\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1\"></circle><text x=\"195.3\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ana</text><circle cx=\"202.2\" cy=\"90.3\" r=\"4\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1\"></circle><text x=\"203.7\" y=\"110.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">diego</text><text x=\"210\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">token ring</text><text x=\"210\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">-2^63 … 2^63</text><text x=\"210.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lowest token, then clockwise</text><text x=\"420\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">node, address, share of the ring</text><rect x=\"420\" y=\"85\" width=\"22\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"454\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c1</text><text x=\"482\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">172.18.0.2</text><text x=\"580\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">32.7%</text><rect x=\"420\" y=\"115\" width=\"22\" height=\"14\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"454\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c2</text><text x=\"482\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">172.18.0.3</text><text x=\"580\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">31.6%</text><rect x=\"420\" y=\"145\" width=\"22\" height=\"14\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"454\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c3</text><text x=\"482\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">172.18.0.4</text><text x=\"580\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">35.7%</text><text x=\"420\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">partition key → token → owner</text><text x=\"420\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">carla</text><text x=\"468\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">-5911513789470835951</text><text x=\"652\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">c2</text><text x=\"420\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">bruno</text><text x=\"468\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">-3891430603489557805</text><text x=\"652\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">c3</text><text x=\"420\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">elisa</text><text x=\"468\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6901144969670893120</text><text x=\"652\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">c2</text><text x=\"420\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ana</text><text x=\"468\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8413089589345688709</text><text x=\"652\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">c2</text><text x=\"420\" y=\"326\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">diego</text><text x=\"468\" y=\"326\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8993384036030544940</text><text x=\"652\" y=\"326\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">c1</text></svg>", "caption": "The ring of this lab's cluster, drawn from its own nodetool ring: 48 tokens, 16 per node. A partition key is hashed to a token, and the node owning the arc the token falls in stores the partition."}
```

Ana's token, `8413089589345688709`, falls after `8141555572029014120` and up to `8538878424377726911`,
a range whose token belongs to `172.18.0.3`. That is `c2`, which is what `getendpoints` said.

**Many small ranges instead of one big one per node** is what the 16 buys. When a fourth node joins
it takes small pieces from all three, instead of half of one neighbour's range, and when a node dies
its load spreads over every survivor instead of landing on one. Older clusters used 256 tokens per
node; 16 is the default of Cassandra 4.0 and later.

What this gives you is a fact to design around: **all the rows of one partition live together, on
the nodes that own its token, and a query that names the partition key goes straight there.** The
next section is about what happens inside a partition, and the one after about the queries that do
not name one.
