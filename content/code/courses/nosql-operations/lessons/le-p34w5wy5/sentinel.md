---
title: Sentinel, and a failover nobody typed
version: 1
---

A replica can take over, but something has to notice that the primary is gone, choose a replica,
promote it, point the other replicas at it and tell the clients. **Sentinel is that something**: a
separate process, run in an odd number of copies, that watches the primary and acts only when a
majority of its copies agree. One Sentinel would be a single point of failure of its own, and could
not tell "the primary is down" from "I am cut off".

## The configuration, whole

Every Sentinel gets the same six lines:

```ini
port 26379
sentinel resolve-hostnames yes
sentinel announce-hostnames yes
sentinel monitor shop redis-1 6379 2
sentinel down-after-milliseconds shop 5000
sentinel failover-timeout shop 30000
```

| line | what it says |
| --- | --- |
| `port 26379` | Sentinel's own port, separate from Redis's 6379 |
| `resolve-hostnames`, `announce-hostnames` | use and announce names such as `redis-1` rather than addresses |
| `monitor shop redis-1 6379 2` | watch the primary at `redis-1:6379` under the name `shop`, and treat it as down when **2** Sentinels agree: the quorum |
| `down-after-milliseconds shop 5000` | a primary silent for 5 seconds is down, in this Sentinel's opinion |
| `failover-timeout shop 30000` | how long a failover may take before another may be tried |

Sentinel rewrites its own file as it learns: the replicas it found, the other Sentinels, the current
primary. So each copy needs its own writable file, and the first command below gives each a directory
of its own.

## Three Sentinels

```
ana@vm:~$ for i in 1 2 3; do mkdir sentinel-$i && cp sentinel.conf sentinel-$i/; done
ana@vm:~$ for i in 1 2 3; do docker run -d --name sentinel-$i --network nosql -v "$PWD/sentinel-$i:/conf" redis:7.4 redis-sentinel /conf/sentinel.conf; done
e7b6cf8bc30679058892da52b7816070e677f6026bb7db72a01529ca1e0a5207
93be74a7cf8a2912d33c20c0e4712766d3c332e63c4fa83b7787693a1a6ad02b
124166a00dee91fe3731b8f0d98e7da446ca27d71c05b00a184aa29d6e9f892a
```

`redis-sentinel` is the same program as `redis-server` started in another mode, and it ships in the
same image. Asked who the primary is, and what it knows:

```
ana@vm:~$ docker exec sentinel-1 redis-cli -p 26379 SENTINEL get-master-addr-by-name shop
redis-1
6379
ana@vm:~$ docker exec sentinel-1 redis-cli -p 26379 SENTINEL master shop | paste - - | grep -E "^(flags|num-slaves|num-other-sentinels|quorum)\s"
flags	master
num-slaves	2
num-other-sentinels	2
quorum	2
```

A client never asks for `redis-1`; it asks a Sentinel for the primary of `shop`, which is why a
failover can move the primary without anybody changing an address. Every common client library has a
Sentinel mode that does exactly this.

## Stopping the primary

```
ana@vm:~$ docker stop redis-1
redis-1
ana@vm:~$ docker exec sentinel-1 redis-cli -p 26379 SENTINEL get-master-addr-by-name shop
redis-2
6379
ana@vm:~$ for s in sentinel-1 sentinel-2 sentinel-3; do echo "== $s"; docker logs $s 2>&1 | grep -E "[+](sdown|odown|vote-for-leader|selected-slave|promoted-slave|switch-master) "; done
== sentinel-1
1:X 10 Oct 2026 20:13:16.130 # +sdown master shop redis-1 6379
1:X 10 Oct 2026 20:13:16.186 # +odown master shop redis-1 6379 #quorum 3/2
1:X 10 Oct 2026 20:13:16.189 # +vote-for-leader 00d0b02cc79045c8796a9a0d3834320e2a5863b2 1
1:X 10 Oct 2026 20:13:16.319 # +selected-slave slave redis-2:6379 redis-2 6379 @ shop redis-1 6379
1:X 10 Oct 2026 20:13:17.209 # +promoted-slave slave redis-2:6379 redis-2 6379 @ shop redis-1 6379
1:X 10 Oct 2026 20:13:18.296 # +switch-master shop redis-1 6379 redis-2 6379
1:X 10 Oct 2026 20:13:23.324 # +sdown slave redis-1:6379 redis-1 6379 @ shop redis-2 6379
== sentinel-2
1:X 10 Oct 2026 20:13:16.083 # +sdown master shop redis-1 6379
1:X 10 Oct 2026 20:13:16.194 # +vote-for-leader 00d0b02cc79045c8796a9a0d3834320e2a5863b2 1
1:X 10 Oct 2026 20:13:17.244 # +odown master shop redis-1 6379 #quorum 3/2
1:X 10 Oct 2026 20:13:17.307 # +switch-master shop redis-1 6379 redis-2 6379
1:X 10 Oct 2026 20:13:22.363 # +sdown slave redis-1:6379 redis-1 6379 @ shop redis-2 6379
== sentinel-3
1:X 10 Oct 2026 20:13:16.121 # +sdown master shop redis-1 6379
1:X 10 Oct 2026 20:13:16.194 # +vote-for-leader 00d0b02cc79045c8796a9a0d3834320e2a5863b2 1
1:X 10 Oct 2026 20:13:16.199 # +odown master shop redis-1 6379 #quorum 2/2
1:X 10 Oct 2026 20:13:17.307 # +switch-master shop redis-1 6379 redis-2 6379
1:X 10 Oct 2026 20:13:22.369 # +sdown slave redis-1:6379 redis-1 6379 @ shop redis-2 6379
```

Read the three logs together. About five seconds after the stop, each Sentinel marked the primary
**subjectively down**, `+sdown`, its own opinion. Once two of them agreed it was **objectively down**,
`+odown`, with the quorum it reached. They then voted for a leader, and all three logs name the same id
in `+vote-for-leader`. The leader, here `sentinel-1`, chose `redis-2` (`+selected-slave`), promoted it
(`+promoted-slave`) and announced the change (`+switch-master`), which the other two repeat. From
`+sdown` to `+switch-master` took about two seconds in `sentinel-1`'s log, 20:13:16.130 to
20:13:18.296. The last line of each, `+sdown slave redis-1`, is Sentinel already counting the stopped
server as a replica of the new primary.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 220\" role=\"img\" aria-label=\"A timeline of the failover. The primary redis-1 stops. For five seconds nothing happens: that is down-after-milliseconds. Then each Sentinel marks it subjectively down, and once two agree, objectively down. The Sentinels elect a leader, the leader selects redis-2 and promotes it, and announces the switch. redis-3 is pointed at the new primary. When redis-1 returns, it is made a replica.\"><line x1=\"30\" y1=\"110\" x2=\"670\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><line x1=\"40\" y1=\"100\" x2=\"40\" y2=\"120\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"40\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">redis-1 stops</text><line x1=\"210\" y1=\"100\" x2=\"210\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"2\"></line><text x=\"210\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">+sdown</text><line x1=\"290\" y1=\"100\" x2=\"290\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"2\"></line><text x=\"290\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">+odown</text><line x1=\"370\" y1=\"100\" x2=\"370\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"2\"></line><text x=\"370\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">+vote-for-leader</text><line x1=\"460\" y1=\"100\" x2=\"460\" y2=\"120\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"460\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">+promoted-slave</text><line x1=\"560\" y1=\"100\" x2=\"560\" y2=\"120\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"560\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">+switch-master</text><rect x=\"40\" y=\"40\" width=\"170\" height=\"26\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"125\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">5 s of silence</text><text x=\"260\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2 Sentinels agree: the quorum</text><text x=\"460\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">redis-2 becomes the primary</text><text x=\"620\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">clients ask again</text><text x=\"620\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">redis-1, on return: a replica</text></svg>", "caption": "Sentinel's failover in the order its logs print it. The first five seconds are waiting; the rest took about two seconds in the lab."}
```

## After the failover

```
ana@vm:~$ primary=$(docker exec sentinel-1 redis-cli -p 26379 SENTINEL get-master-addr-by-name shop | head -1); echo $primary
redis-2
ana@vm:~$ docker exec $primary redis-cli GET order:1001
paid
ana@vm:~$ docker start redis-1
redis-1
ana@vm:~$ docker exec redis-1 redis-cli INFO replication | grep -E "^(role|master_host|master_link_status):"
role:slave
master_host:redis-2
master_link_status:down
```

The new primary has order 1001: it was replicated long before the stop. And when `redis-1` came back,
**it did not come back as primary.** Sentinel had already moved on, so it told the returning server to
become a replica of the new one, and `INFO replication` says so: a replica of `redis-2`, its link still coming up when asked. Two primaries accepting writes for the
same data is the outcome all of this exists to prevent.
