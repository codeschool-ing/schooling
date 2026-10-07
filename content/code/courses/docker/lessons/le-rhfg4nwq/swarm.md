---
title: What Compose does not do
version: 2
---

**Compose runs an application on one machine, and when that machine goes, so does the application.**
Lesson 19 said so. Everything past that, several machines, a container replaced when it dies, a new
version rolled out without stopping the old one, is the job of an **orchestrator**: a program that is
told the state that should exist and keeps making it true.

Docker Engine has one built in, **Swarm mode**, and it is the quickest way to see what an orchestrator
does, because it takes the same images and nearly the same Compose files.

## A swarm of one

```
ana@vm:~$ docker swarm init --advertise-addr 127.0.0.1 | head -2
Swarm initialized: current node (88ypwtcrjv74msr85cm5fv3nc) is now a manager.

ana@vm:~$ docker node ls --format "table {{.Hostname}}\t{{.Status}}\t{{.ManagerStatus}}"
HOSTNAME   STATUS    MANAGER STATUS
vm         Ready     Leader
```

**Ana's machine is now a swarm with one node, which is both its manager and its only worker.** A real
swarm adds machines with `docker swarm join` and the token `init` prints; everything below works the
same with more nodes, and spreads the containers across them.

`shelf:1.0.0` and `shelf:1.0.1` here are built from lesson 18's Dockerfile, the one with the health
check: in `~/shelf`, `docker build -q --build-arg VERSION=1.0.0 -t shelf:1.0.0 .`, and the same
again with `1.0.1`.

## A service, not a container

```
ana@vm:~$ ls /proc/net/ip_vs
ls: cannot access '/proc/net/ip_vs': No such file or directory
ana@vm:~$ docker network create --driver overlay --attachable shopnet
kpi0msj33bzsrnh2hltucg2rw
ana@vm:~$ docker service create --name shelf --replicas 3 --network shopnet --endpoint-mode dnsrr --detach shelf:1.0.0
image shelf:1.0.0 could not be accessed on a registry to record
its digest. Each node will access shelf:1.0.0 independently,
possibly leading to different nodes running different
versions of the image.

6q4a1ctydh780l7f1omrygg6w
ana@vm:~$ docker service ls --format "table {{.Name}}\t{{.Replicas}}\t{{.Image}}"
NAME      REPLICAS   IMAGE
shelf     3/3        shelf:1.0.0
ana@vm:~$ docker service ps shelf --format "table {{.Name}}\t{{.Image}}\t{{.CurrentState}}"
NAME      IMAGE         CURRENT STATE
shelf.1   shelf:1.0.0   Running 9 seconds ago
shelf.2   shelf:1.0.0   Running 9 seconds ago
shelf.3   shelf:1.0.0   Running 9 seconds ago
ana@vm:~$ docker run --rm --network shopnet alpine:3.22 nslookup shelf | grep Address | sort
Address:	127.0.0.11:53
Address: 10.0.1.2
Address: 10.0.1.3
Address: 10.0.1.4
ana@vm:~$ docker run --rm --network shopnet alpine:3.22 wget -qO- shelf:8080/version
1.0.0
```

**A service is a description: this image, three copies.** Swarm turns it into three **tasks**, each a
container, and keeps the count at three. Two things to read in the output:

- **The warning about the digest.** Swarm tries to resolve the tag to a digest in a registry, so that
  every node runs the same bytes, which is lesson 16's argument made by the tool itself. `shelf:1.0.0`
  exists only on this machine, so each node would resolve the tag on its own. A real deployment names
  an image in a registry, by digest.
- **The lab's kernel has no IPVS**, the module that Swarm uses to give a service one virtual address
  and to route a published port to any node. That is what the first command checks. So this service
  uses `--endpoint-mode dnsrr`: on the overlay network `shopnet`, the name `shelf` answers with all
  three tasks' addresses, and a client picks one. On a normal Linux host, the default, a virtual IP,
  and `--publish 8080:8080` work, and the port answers on every node.

## It puts back what dies

```
ana@vm:~$ docker kill $(docker ps -q --filter name=shelf.2) > /dev/null
ana@vm:~$ docker service ps shelf --format "table {{.Name}}\t{{.CurrentState}}\t{{.Error}}"
NAME          CURRENT STATE            ERROR
shelf.1       Running 25 seconds ago   
shelf.2       Running 4 seconds ago    
 \_ shelf.2   Failed 15 seconds ago    "task: non-zero exit (137)"
shelf.3       Running 25 seconds ago   
ana@vm:~$ docker service ls --format "table {{.Name}}\t{{.Replicas}}"
NAME      REPLICAS
shelf     3/3
```

**Ana killed one task's container, and Swarm started another in its place**: `shelf.2` failed with
exit code 137, the `SIGKILL` of lesson 17, and a new `shelf.2` was running within seconds. Nobody ran a
command. The service said three, there were two, and the manager acted on the difference. That loop,
**desired state against actual state**, is the whole idea of an orchestrator, Kubernetes included.
