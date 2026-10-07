---
title: Private inside, one public address outside
version: 2
---

IPv4 has 2 to the power of 32 addresses, about 4.3 billion, and there are more devices than that.
**NAT, network address translation, lets a whole network use private addresses inside and share one
public address outside.** The private ranges are set aside by RFC 1918 — `10.0.0.0/8`,
`172.16.0.0/12` and `192.168.0.0/16` — and lesson 8 covers them: anybody may use them, so the same
address exists in thousands of offices at once, and no router on the internet carries a route to any
of them.

Lesson 1's office is built that way, and this lesson runs on it: `sudo bash ~/netlab/netlab.sh up office`.
pc1 has a private address:

```
ana@pc1:~$ ip -br addr show eth0
eth0@if155       UP             10.20.10.21/24 fe80::25:70ff:febc:29c6/64 
```

and r1, the router, has one leg in each world:

```
root@r1:~# ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0@if163       UP             10.20.10.1/24 fe80::1f:23ff:fee7:e9d5/64 
eth1@if165       UP             203.0.113.2/30 fe80::a6:80ff:fe20:1354/64 
```

`eth0`, facing the office, is `10.20.10.1/24`, pc1's gateway. `eth1`, facing the provider, is
`203.0.113.2/30`, the office's one public address. (In the lab it comes from 203.0.113.0/24, a block
reserved for documentation that stands in for a real public address.) What makes the sharing work is
a rule of nftables, r1's firewall, in a table of its own:

```
root@r1:~# nft list table ip nat
table ip nat {
	chain postrouting {
		type nat hook postrouting priority srcnat; policy accept;
		oifname "eth1" masquerade
	}
}
```

Read the chain from the outside in. `type nat hook postrouting` puts it at the last moment before a
packet leaves, after r1 has already decided where it goes. `oifname "eth1"` matches the packets
leaving by the interface that faces the internet. `masquerade` replaces their source address with the
address that interface has at that moment, which is why it is the usual choice when the provider may
change the address; with a fixed one, `snat to 203.0.113.2` says the same thing with the address
written in.

The common wrong idea is that NAT is a security feature. **NAT translates addresses; deciding what
may pass is the firewall's job.** r1 happens to do both, and its `inet filter` table, the one lesson 1
showed dropping a connection from outside, is what refuses traffic nobody asked for. The two are easy
to confuse, because a NAT router with no rule for an arriving connection has nowhere to send it
anyway — the section on port forwarding shows that happening. But a NAT router with a forwarding rule
and no firewall would deliver whatever arrived.
