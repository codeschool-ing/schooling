---
title: Registering, and what the registry is
version: 1
---

Each instance, as it starts, sent Consul its name, `stock`, its own address and a health check to run.
Ask the registry, as a client library would, for the instances that are passing:

```
ana@vm:~/lab/gateway$ $D stock
3 healthy instance(s) of stock
  stock-1 at 172.18.0.6:8000
  stock-2 at 172.18.0.5:8000
  stock-3 at 172.18.0.3:8000
```

Three instances, each at the address Docker gave its container, and nobody wrote any of them down.
This is **self-registration**: each instance announces itself. The alternative, **third-party
registration**, has the platform do it on the instance's behalf; Kubernetes, which starts every
container, registers it as part of starting it, and the application never knows.

The registry is the one component every other component depends on to find anything, so it cannot be a
single machine that fails. Consul keeps its catalogue in a **Raft** cluster of servers:

```
ana@vm:~/lab/gateway$ docker compose exec consul consul operator raft list-peers
Node          ID                                    Address         State   Voter  RaftProtocol  Commit Index  Trails Leader By
dc9cab511ced  c072e083-9c16-1313-1091-d748802d3c50  127.0.0.1:8300  leader  true   3             23            -
```

One peer, the leader, with nobody to follow it, because the lab runs Consul in development mode. A real
Consul cluster runs three or five servers, and lesson 10 explained why: a majority of three survives one
failure, and two servers would survive none. **etcd**, which holds Kubernetes's state, and **ZooKeeper**
are the same kind of store for the same reason. Lesson 8 put this family on the consistent side, and
here is why it belongs there: two halves of a split cluster each handing out a different list of
instances is a worse failure than a registry that refuses to change until the cable is fixed.
