---
title: The default bridge
version: 1
---

**Lesson 4 said each container gets its own network namespace: its own interfaces, addresses and
routes.** This lesson looks at how those namespaces are wired together, and to the machine. A fresh
daemon has three networks:

```
ana@vm:~$ docker network ls
NETWORK ID     NAME      DRIVER    SCOPE
2d949de13bd0   bridge    bridge    local
ff3f48e4f5cb   host      host      local
25e410e18a45   none      null      local
ana@vm:~$ ip -brief addr show docker0
docker0          DOWN           172.17.0.1/16 
```

`bridge` is where containers go when nothing else is said; `host` and `none` are the two ends of the
scale, at the end of this lesson. **`docker0` is the bridge itself**: a virtual switch in the host's
kernel, with the address `172.17.0.1`, and `DOWN` because nothing is plugged into it yet.

## A cable called veth

```
ana@vm:~$ docker run -d --name box-a alpine:3.22 sleep 600
54b006057a096a03466f1b5f3692e09d14972e544d742ae9aaa8383aacd757e3
ana@vm:~$ ip -brief link | grep -E "^(docker0|veth)"
docker0          UP             46:f7:bb:9f:ee:1e <BROADCAST,MULTICAST,UP,LOWER_UP> 
veth47fa4d1@if2  UP             9a:82:17:c6:b3:8f <BROADCAST,MULTICAST,UP,LOWER_UP> 
ana@vm:~$ docker exec box-a ip addr show eth0
2: eth0@if114: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP 
    link/ether f2:cd:14:8d:8b:55 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
ana@vm:~$ docker exec box-a ip route
default via 172.17.0.1 dev eth0 
172.17.0.0/16 dev eth0 scope link  src 172.17.0.2 
```

**Starting one container plugged one cable in.** A *veth pair* is two virtual interfaces joined like
the two ends of a cable: one end, `eth0`, is moved into the container's namespace with the address
`172.17.0.2`; the other end, `veth…` on the host, is plugged into `docker0`, which is now `UP`. The
container's default route goes to `172.17.0.1`, so **the host is the container's gateway**, and its
way out to anywhere else.

## Address, but no name

```
ana@vm:~$ docker run -d --name box-b alpine:3.22 sleep 600
596fcaebb8f540709e20c5a14c9d118297b8857e17ba9a7445007459b5e18630
ana@vm:~$ docker exec box-b ping -c 1 -W 1 box-a
ping: bad address 'box-a'
ana@vm:~$ docker exec box-b ping -c 1 -W 1 $(docker inspect box-a --format "{{.NetworkSettings.Networks.bridge.IPAddress}}")
PING 172.17.0.2 (172.17.0.2): 56 data bytes
64 bytes from 172.17.0.2: seq=0 ttl=64 time=0.472 ms

--- 172.17.0.2 ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 0.472/0.472/0.472 ms
```

`box-b` cannot find `box-a` by name, `bad address`, and reaches it at once by address. **The default
bridge has no name resolution between containers**, for historical reasons Docker keeps for
compatibility. Addresses are handed out at start and can change on the next one, so an address in a
configuration file is a bug waiting for a restart. The fix is a network of your own, and it is the
next section.
