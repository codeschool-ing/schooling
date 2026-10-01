---
title: "The network card: where the cable meets the computer"
version: 1
---

Every device in lesson 1 has network cards, and so does every computer that talks to them. **A
network card turns frames into a signal on the medium and the signal back into frames, and it
carries the MAC address that names the device on its link.** It is the one piece of equipment that
belongs to layers 1 and 2 at once: it makes the signal, and it decides which frames are for its
own machine.

The common picture is a board plugged into a slot. That still exists, but most cards today are a
chip on the main board, a radio inside a laptop, or, as in this lab, no hardware at all. To the
operating system they look the same: an interface with a name, an address and counters. Here is
pc1's:

```
ana@pc1:~$ ip link show eth0
78: eth0@if77: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 02:25:70:bc:29:c6 brd ff:ff:ff:ff:ff:ff link-netns sw1
ana@pc1:~$ ethtool -i eth0
driver: veth
version: 1.0
firmware-version: 
expansion-rom-version: 
bus-info: 
supports-statistics: yes
supports-test: no
supports-eeprom-access: no
supports-register-dump: no
supports-priv-flags: no
```

`ip link show` prints the interface `eth0`, its state flags, and on the second line its MAC
address, **`02:25:70:bc:29:c6`**. `LOWER_UP` is the card reporting a live link at the other end.
`link-netns sw1` is the lab showing through: the other end of this cable is inside the namespace
called sw1, the switch.

`ethtool -i` asks the card about itself, and the answer is the honest one: **`driver: veth`, a
virtual Ethernet pair**, which is the lab's card and cable in one piece of software. On a physical
machine that line names the driver of the real chip, and the empty `firmware-version` and
`bus-info` would hold the card's firmware and its slot on the board. A virtual card has neither.

## The counters

A card counts what it does, and those counters are the first place to look when a link misbehaves.
Here they are before and after five pings to the server:

```
ana@pc1:~$ ip -s link show eth0
78: eth0@if77: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 02:25:70:bc:29:c6 brd ff:ff:ff:ff:ff:ff link-netns sw1
    RX:  bytes packets errors dropped  missed   mcast           
          1788      22      0       0       0       0 
    TX:  bytes packets errors dropped carrier collsns           
           570       7      0       0       0       0 
ana@pc1:~$ ping -c 5 -q 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4011ms
rtt min/avg/max/mdev = 0.592/2.146/6.059/1.984 ms
ana@pc1:~$ ip -s link show eth0
78: eth0@if77: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 02:25:70:bc:29:c6 brd ff:ff:ff:ff:ff:ff link-netns sw1
    RX:  bytes packets errors dropped  missed   mcast           
          2390      29      0       0       0       0 
    TX:  bytes packets errors dropped carrier collsns           
          1102      13      0       0       0       0 
```

Read the `packets` column of each pair of lines:

| | before | after | difference |
|---|---|---|---|
| received (RX) | 22 | 29 | 7 |
| sent (TX) | 7 | 13 | 6 |

Five echo requests went out and five replies came back, so five of each difference is the ping.
The rest are frames that are not pings: the lab had emptied every neighbour table before this
block, so pc1 had to ask for the server's MAC address with ARP before its first ping could leave.
**A counter counts frames, whatever is in them**, which is why it never matches the number of
pings exactly.

The columns that matter on a real link are the ones that stayed at zero here. `errors` counts
frames that arrived damaged, `dropped` counts frames the system had no room for, and `collsns`
counts collisions, which lesson 18 explains and which a modern full-duplex link never has.
**`errors` that keep rising point at layer 1**: a damaged cable, a dirty fibre connector, a port
going bad. Read them twice, a minute apart. A number that has not moved is history; a number that
is moving is the fault.
