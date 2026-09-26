---
title: The bridge
version: 1
---

A server's guests usually need to be reachable from the office, so their network cards are plugged
into a **bridge**, a switch made of software inside the host:

```
ana@host:~$ ip -br link show type bridge
virbr0           UP             52:54:00:0b:54:ea <BROADCAST,MULTICAST,UP,LOWER_UP> 
ana@host:~$ bridge link
18: vnet2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master virbr0 state forwarding priority 32 cost 2 
```

The lab has one, `virbr0`, and `bridge link` shows what is plugged into it: `vnet2`, vm1's cable from
lesson 3. libvirt's `virbr0` is joined to nothing physical, and the host routes the guests out, which
is lesson 11's NAT.

Proxmox's installer makes a bridge called **`vmbr0`**, and plugs the server's real network card into
it. So a new Proxmox guest on `vmbr0` sits directly on the office network, gets its address from the
office's DHCP, and is reachable by anyone there, like the bridged mode of lesson 5. That is what a
server needs, and it is also why **a test machine on a Proxmox server is on the real network unless
somebody decides otherwise**. Lesson 15 is about deciding otherwise.
