---
title: Redis Cluster, slots and the failover inside it
version: 1
---

Sentinel keeps one dataset available. It does nothing for a dataset larger than one machine, or a
write rate one machine cannot take: every write still goes to one primary. **Redis Cluster splits the
data across several primaries**, each with its own replicas, and moves the failover inside the
servers themselves, with no Sentinel at all.

## 16,384 slots

A cluster divides the key space into **16,384 hash slots**. The slot of a key is a hash of the key
name, CRC16 modulo 16,384, and each primary owns a range of slots. Any server can tell you which slot
a key is in, and which server owns it; a client that sends a key to the wrong server is told where to
go instead of being served.

## Six nodes

Three primaries and a replica for each. The Sentinel lab goes first; then six servers with cluster
mode on, and a node timeout of five seconds, the cluster's own `down-after-milliseconds`:

```
ana@vm:~$ docker rm -f redis-1 redis-2 redis-3 sentinel-1 sentinel-2 sentinel-3
redis-1
redis-2
redis-3
sentinel-1
sentinel-2
sentinel-3
ana@vm:~$ for i in 1 2 3 4 5 6; do docker run -d --name node-$i --network nosql redis:7.4 redis-server --cluster-enabled yes --cluster-node-timeout 5000; done
c3b0315bf8df7bc8e5fb411e292ab8abddad28f9ccf3a67f65289e96e6e57c4a
4ddbfe602ac08f206d01b55054c0d73205386d4d733afa6b7630a6bb53e5ac22
39b3e975268188ab1acef7f4c02f00267603e091ee6819f51bbd49972c8568b9
fdaa7143c9bf53a3d23fbb7df3ed6d4d628b296b1a89e8ebf80faf085694a9b5
ff9c7371ac71c04f0d8df4f64958a6d523026813d5137e43d19d068934a1e34a
f59e85439d03e0c496d3c795d0dc6ca712756f8b1cae21aa240f385400fb165c
ana@vm:~$ ips=$(for i in 1 2 3 4 5 6; do docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}:6379' node-$i; done); echo $ips
172.18.0.2:6379 172.18.0.3:6379 172.18.0.4:6379 172.18.0.5:6379 172.18.0.6:6379 172.18.0.7:6379
```

`redis-cli --cluster create` wants addresses, not names, so the third command asks Docker for each
node's address on the network. Then one command forms the cluster: `--cluster-replicas 1` asks for one
replica per primary, so of six nodes three become primaries, and `--cluster-yes` accepts the layout
it proposes instead of asking:

```
ana@vm:~$ docker exec node-1 redis-cli --cluster create $ips --cluster-replicas 1 --cluster-yes
>>> Performing hash slots allocation on 6 nodes...
Master[0] -> Slots 0 - 5460
Master[1] -> Slots 5461 - 10922
Master[2] -> Slots 10923 - 16383
Adding replica 172.18.0.6:6379 to 172.18.0.2:6379
Adding replica 172.18.0.7:6379 to 172.18.0.3:6379
Adding replica 172.18.0.5:6379 to 172.18.0.4:6379
M: a43e40b3d1c18772cf5ef54a2537a18f687e4ce8 172.18.0.2:6379
   slots:[0-5460] (5461 slots) master
M: e0c513ff83ee74d532e5bacd29589e43acae8675 172.18.0.3:6379
   slots:[5461-10922] (5462 slots) master
M: 72c910109e09b056709c8121bf4c136465ee73e9 172.18.0.4:6379
   slots:[10923-16383] (5461 slots) master
S: 1315e9ee2bf8b0cbc4cc313582591af3108ca4b3 172.18.0.5:6379
   replicates 72c910109e09b056709c8121bf4c136465ee73e9
S: 45581110339d850d8d5390cead354011d83d9978 172.18.0.6:6379
   replicates a43e40b3d1c18772cf5ef54a2537a18f687e4ce8
S: d89c3791b873c3dfe32f267febb08e5e14e24977 172.18.0.7:6379
   replicates e0c513ff83ee74d532e5bacd29589e43acae8675
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join
..
>>> Performing Cluster Check (using node 172.18.0.2:6379)
M: a43e40b3d1c18772cf5ef54a2537a18f687e4ce8 172.18.0.2:6379
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
M: e0c513ff83ee74d532e5bacd29589e43acae8675 172.18.0.3:6379
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
M: 72c910109e09b056709c8121bf4c136465ee73e9 172.18.0.4:6379
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
S: 1315e9ee2bf8b0cbc4cc313582591af3108ca4b3 172.18.0.5:6379
   slots: (0 slots) slave
   replicates 72c910109e09b056709c8121bf4c136465ee73e9
S: 45581110339d850d8d5390cead354011d83d9978 172.18.0.6:6379
   slots: (0 slots) slave
   replicates a43e40b3d1c18772cf5ef54a2537a18f687e4ce8
S: d89c3791b873c3dfe32f267febb08e5e14e24977 172.18.0.7:6379
   slots: (0 slots) slave
   replicates e0c513ff83ee74d532e5bacd29589e43acae8675
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```

The first three addresses became primaries, with the slots split into three ranges, and each of the
other three replicates one of them. The cluster's own summary:

```
ana@vm:~$ docker exec node-1 redis-cli CLUSTER INFO | grep -E "^cluster_(state|slots_assigned|known_nodes|size):"
cluster_state:ok
cluster_slots_assigned:16384
cluster_known_nodes:6
cluster_size:3
ana@vm:~$ docker exec node-1 redis-cli CLUSTER NODES | cut -d' ' -f2,3,9 | sort
172.18.0.2:6379@16379 myself,master 0-5460
172.18.0.3:6379@16379 master 5461-10922
172.18.0.4:6379@16379 master 10923-16383
172.18.0.5:6379@16379 slave
172.18.0.6:6379@16379 slave
172.18.0.7:6379@16379 slave
```

`cluster_state:ok`, all 16,384 slots assigned, six nodes, and a **size** of 3: the number of primaries
serving slots. The list of nodes shows the address, the role and the slot range of each primary.

## Redirections

`redis-cli` without `-c` treats a cluster node as a single server, and is told when a key lives
elsewhere:

```
ana@vm:~$ docker exec -it node-1 redis-cli
127.0.0.1:6379> CLUSTER KEYSLOT product:KB-101
(integer) 14967
127.0.0.1:6379> SET product:KB-101 34990
(error) MOVED 14967 172.18.0.4:6379
```

**`MOVED 14967` and an address** is the cluster's answer: slot 14967 lives on that node, ask there.
Nothing was written. With `-c`, `redis-cli` follows the redirection itself, as a cluster-aware client
library does, and its prompt moves to the node it was sent to:

```
ana@vm:~$ docker exec -it node-1 redis-cli -c
127.0.0.1:6379> SET product:KB-101 34990
-> Redirected to slot [14967] located at 172.18.0.4:6379
OK
172.18.0.4:6379> GET product:KB-101
"34990"
```

## Keys that must be together

A command touching several keys works only if they are in the same slot, because no single node could
otherwise apply it atomically:

```
ana@vm:~$ docker exec -it node-1 redis-cli -c
127.0.0.1:6379> MSET cart:ana:items KB-101 cart:ana:total 34990
(error) CROSSSLOT Keys in request don't hash to the same slot
127.0.0.1:6379> CLUSTER KEYSLOT cart:ana:items
(integer) 186
127.0.0.1:6379> CLUSTER KEYSLOT cart:ana:total
(integer) 12994
127.0.0.1:6379> CLUSTER KEYSLOT {cart:ana}:items
(integer) 10321
127.0.0.1:6379> CLUSTER KEYSLOT {cart:ana}:total
(integer) 10321
127.0.0.1:6379> MSET {cart:ana}:items KB-101 {cart:ana}:total 34990
-> Redirected to slot [10321] located at 172.18.0.3:6379
OK
```

`CROSSSLOT`: the two keys of Ana's cart hash to different slots, so `MSET` cannot set them together,
and neither could a transaction or a Lua script. **A hash tag** fixes it: when a key contains `{…}`,
only the part inside the braces is hashed, so `{cart:ana}:items` and `{cart:ana}:total` share a slot
and the `MSET` succeeded. The price is that a hash tag can concentrate data: put every customer's cart
under one tag and one slot holds them all, on one node, which is the hot partition of lesson 3.

## A primary goes away

The node that owns the slot of `product:KB-101` is stopped:

```
ana@vm:~$ docker stop node-3
node-3
ana@vm:~$ docker exec node-1 redis-cli CLUSTER NODES | cut -d' ' -f2,3,9 | sort
172.18.0.2:6379@16379 myself,master 0-5460
172.18.0.3:6379@16379 master 5461-10922
172.18.0.4:6379@16379 master,fail
172.18.0.5:6379@16379 master 10923-16383
172.18.0.6:6379@16379 slave
172.18.0.7:6379@16379 slave
ana@vm:~$ docker exec node-1 redis-cli CLUSTER INFO | grep -E "^cluster_state:"
cluster_state:ok
```

Five seconds of silence is the node timeout. The other primaries marked `172.18.0.4` as `fail`, and its
replica, `172.18.0.5`, became a primary with the slots `10923-16383`. `cluster_state` stayed `ok`,
because every slot still has an owner. Asked for the keyboard again, node 1 sends the client to the
new owner:

```
ana@vm:~$ docker exec -it node-1 redis-cli -c
127.0.0.1:6379> GET product:KB-101
-> Redirected to slot [14967] located at 172.18.0.5:6379
"34990"
```

The keyboard's price was still there, served by the promoted replica: it was replicated before the
stop. A write acknowledged by the old primary in the instant before it died, and not yet replicated,
would have been lost exactly as in the previous section. **Cluster replication is asynchronous too**,
and `WAIT` exists there for the same reason and with the same limit.
