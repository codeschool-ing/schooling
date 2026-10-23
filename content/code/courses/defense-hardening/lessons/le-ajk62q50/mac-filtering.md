---
title: A list of hardware addresses
version: 1
---

**Every network card has a hardware address, the MAC address, and every frame it sends carries it
as the source.** The lab gives each machine a fixed one that ends in the last number of its IP
address in hexadecimal: `desk` at `.20` is `52:54:00:a8:3c:14`. The simplest port control is a list:
frames from these addresses pass, everything else is dropped.

On `sw`, the list for `desk`'s port allows `desk` itself and the reception printer, whose address is
`52:54:00:a8:3c:63` (the lab has no printer; the address stands for one):

```
ana@sw:~$ cat nac/macfilter.nft
table netdev macfilter {
	chain desk_port {
		type filter hook ingress device "port-desk" priority filter; policy drop;
		ether saddr { 52:54:00:a8:3c:14, 52:54:00:a8:3c:63 } counter accept
		counter
	}
}
```

A **netdev** table is attached to one interface and sees frames as they arrive, before the bridge or
the IP stack. The chain hooks `ingress` on `port-desk` with `policy drop`, so a frame is dropped
unless a rule accepts it, and the one rule accepts the two addresses in the set. Each rule carries a
`counter`, which the end of this section reads. Load it, and `desk` still works:

```
ana@sw:~$ sudo nft -f nac/macfilter.nft && echo loaded
loaded
ana@desk:~$ ping -c1 -W1 web | tail -2
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.418/0.418/0.418/0.000 ms
```

Then plug in "a different device": on `desk`, change the card's address to one the list does not
have, and try again.

```
ana@desk:~$ sudo ip link set eth0 address 52:54:00:a8:3c:99; ping -c1 -W1 web | tail -2
1 packets transmitted, 0 received, 100% packet loss, time 0ms

ana@desk:~$ sudo ip link set eth0 address 52:54:00:a8:3c:63; ping -c1 -W1 web | tail -2
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.063/0.063/0.063/0.000 ms
ana@desk:~$ sudo ip link set eth0 address 52:54:00:a8:3c:14
```

The address ending in `:99` is refused, as it should be. The address ending in `:63` passes, and
that is the printer's. Back on `sw`, the counters agree:

```
ana@sw:~$ sudo nft list chain netdev macfilter desk_port
table netdev macfilter {
	chain desk_port {
		type filter hook ingress device "port-desk" priority filter; policy drop;
		ether saddr { 52:54:00:a8:3c:14, 52:54:00:a8:3c:63 } counter packets 4 bytes 224 accept
		counter packets 2 bytes 56
	}
}
ana@sw:~$ sudo nft delete table netdev macfilter && echo removed
removed
```

Four frames passed the list, 224 bytes: two pings of 84 bytes and the two ARP requests of 28 that
found `web` before each one. Two were dropped, 56 bytes, which is two ARP requests from the unknown
address asking where `web` was. They got no answer, so its ping never left the machine. The table
is removed at the end, because the next sections replace it.

## What the list is good for

A MAC filter keeps out the honest mistake: the visitor who plugs a laptop into the wrong socket, the
switch somebody connects to make two ports out of one. Each of those arrives with an address nobody
listed, and is refused. It is also cheap: every managed switch has it, under names like **port
security** or **sticky MAC**, which learns the first address it sees on a port and refuses others.
The next section is about what it cannot do.
