---
title: localhost, host and none
version: 1
---

**Inside a container, `localhost` is the container.** That one sentence explains the most common
networking question about Docker, and two network modes are the exceptions that prove it.

## `localhost` is not the machine

`shelf` runs on the host's `127.0.0.1:8080`, published the way lesson 17 recommends. Ana's own `curl`
reaches it. From inside a container:

```
ana@vm:~$ docker run -d --name host-shelf -p 127.0.0.1:8080:8080 shelf:1.0.0
2f7c8145907e9578672b080aaafea667ce463db0022be1acb480128f29cca77c
ana@vm:~$ curl -s localhost:8080/version
1.0.0
ana@vm:~$ docker exec box-c wget -qO- -T 2 localhost:8080/version
wget: can't connect to remote host (127.0.0.1): Connection refused
ana@vm:~$ docker run --rm --add-host host.docker.internal:host-gateway alpine:3.22 wget -qO- -T 2 host.docker.internal:8080/version
wget: can't connect to remote host (172.17.0.1): Connection refused
ana@vm:~$ docker run --rm -p 8081:8080 -d --name pub shelf:1.0.0 >/dev/null; sleep 1; docker run --rm --add-host host.docker.internal:host-gateway alpine:3.22 wget -qO- -T 2 host.docker.internal:8081/version
1.0.0
```

Three attempts, read in order:

1. **`localhost` from `box-c` is refused**: it asks `box-c`'s own loopback, where nothing listens.
2. **`host.docker.internal`**, mapped to `host-gateway` by `--add-host`, is the host's address as
   seen from the bridge, `172.17.0.1`. Still refused, because the service listens only on
   `127.0.0.1`, which is exactly what lesson 17 did on purpose.
3. **A service published on every address answers** through the same name.

So a container that must reach a service on its host needs two things: a name for the host,
`host.docker.internal` with `host-gateway`, and a service listening somewhere the bridge reaches.
Publishing on every address does that and also opens it to the network, which is lesson 17's warning;
`-p 172.17.0.1:8081:8080` would listen on the bridge's address alone. That last form was not run in
the lab. Docker Desktop provides `host.docker.internal` without the flag.

## `--network host`: no namespace at all

```
ana@vm:~$ docker run -d --name hostnet --network host -e PORT=9090 shelf:1.0.0
61b23df2c4ef629f6bfa3368d52401df30a3ccdb0eec0ac8e90aaebb4b321553
ana@vm:~$ ss -ltn | grep -E "State|:9090"
State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
LISTEN 0      4096         0.0.0.0:9090       0.0.0.0:*          
ana@vm:~$ curl -s localhost:9090/version
1.0.0
ana@vm:~$ docker inspect hostnet --format "{{json .NetworkSettings.Networks}}" | jq -c "keys"
["host"]
```

**`shelf` listened on the host's `0.0.0.0:9090` directly, with no `-p`**, because with `host` the
container keeps the host's network namespace: its interfaces, its ports and its `localhost`. It is
the fastest path, since there is no bridge and no address translation, and it gives up every wall
this lesson described: two containers that want the same port collide, and anything the program
listens on is listening on the machine. It suits a few system tools; it is not a way to avoid
learning `-p`.

## `--network none`: no network at all

```
ana@vm:~$ docker run --rm --network none alpine:3.22 ip -o link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000\    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
```

**One interface, the loopback, and nothing else.** A batch job that reads files and writes files, a
build step that must not download anything, a program being examined: none of them needs a network,
and `none` makes sure they do not have one.
