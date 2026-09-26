---
title: Reaching each other
version: 1
---

The one way host and guest reach each other that you choose to use is the network. From inside:

```
ana@vm1:~$ ip route
default via 192.168.122.1 dev enp1s0 proto dhcp src 192.168.122.117 metric 100 
192.168.122.0/24 dev enp1s0 proto kernel scope link src 192.168.122.117 metric 100 
192.168.122.1 dev enp1s0 proto dhcp scope link src 192.168.122.117 metric 100 
ana@host:~$ ip -br addr show virbr0
virbr0           UP             192.168.122.1/24 
ana@vm1:~$ nc -zv -w 3 192.168.122.1 53
Connection to 192.168.122.1 53 port [tcp/domain] succeeded!
```

The guest's default route is `192.168.122.1`, and that address is the host's own, on `virbr0`, the
virtual switch of the `default` network. So **the host is the guest's router**, and every packet vm1
sends anywhere passes through host first. Port 53 answered: libvirt runs a small DNS and DHCP server
for the network on that address, and it is what gave vm1 `192.168.122.117`. The other direction needs no
demonstration, because every `ssh vm1` in this course is the host reaching the guest.

Keep that in mind for lesson 15: **a guest can always reach the host's own address on its network**,
and any service the host runs there answers the guest too. On a laptop, that is how a guest meant for
experiments ends up talking to something on the host it was never meant to see.
