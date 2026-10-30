---
title: A local Redis, and what it says about itself
version: 1
---

**Both Azure services run the Redis engine, and the engine runs on a laptop.** The lab's `compose.yaml`
from lesson 1 has it under the profile `redis`: the official image, version 8.2.2, on port 6379 of
`127.0.0.1` only. Start it with the Cosmos DB emulator, because the next section puts it in front of
Cosmos DB:

```sh
docker compose --profile cosmos --profile redis up -d
```

`redis-cli` is inside the container, and `docker compose exec redis` reaches it without installing
anything:

```
ana@laptop:~/azure$ docker compose exec redis redis-server --version
Redis server v=8.2.2 sha=00000000:1 malloc=jemalloc-5.3.0 bits=64 build=fe8f07ffb18b0e6d
ana@laptop:~/azure$ docker compose exec redis redis-cli CONFIG GET maxmemory
maxmemory
0
ana@laptop:~/azure$ docker compose exec redis redis-cli CONFIG GET maxmemory-policy
maxmemory-policy
noeviction
ana@laptop:~/azure$ docker compose exec redis redis-cli CONFIG GET cluster-enabled
cluster-enabled
no
ana@laptop:~/azure$ docker compose exec redis redis-cli CLUSTER INFO
ERR This instance has cluster support disabled
```

**Version 8.2.2, no memory limit, `noeviction`, and no cluster support.** A `maxmemory` of 0 means
Redis may use whatever memory the machine has, and `noeviction` means that when it cannot, it refuses
writes rather than throwing anything away. Those are the engine's own defaults and sensible ones for a
laptop. A managed cache is configured differently: it has a fixed size, the documented default policy
of Azure Cache for Redis is `volatile-lru`, and you cannot run `CONFIG` there to find out, because the
service blocks it. The eviction section sets these by hand, to watch what each policy does.

**`CLUSTER INFO` refuses because this Redis is a single server**, which is how a Basic, Standard or
Premium cache without clustering looks to a client. The last section starts a second Redis with cluster
support, to see what changes for the keys.

**What this container cannot teach is the service around the engine**: failover to a replica, patching,
TLS on 6380, the network rules and the sign-in with Microsoft Entra ID. Those are taught from the
documentation in the section before this one, and nothing here imitates them.
