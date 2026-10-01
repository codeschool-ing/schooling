---
title: "The load balancer: one address, several servers"
version: 1
---

A busy website is not one machine, but its address is one address. **A load balancer owns the
public address and hands each new connection to one of several servers behind it**, so the
servers can be added, removed or restarted without anybody outside noticing. The common mistake is
to think of it as a router with a list of servers. A router forwards a packet to where its
destination already is; a load balancer **changes** the destination, choosing it per connection.

The lab's load balancer is lb, at 192.0.2.80, with two web servers behind it. Its whole
configuration is one rule in each direction:

```
root@lb:~# nft list table ip lb
table ip lb {
	chain prerouting {
		type nat hook prerouting priority dstnat; policy accept;
		ip daddr 192.0.2.80 tcp dport 80 dnat to numgen inc mod 2 map { 0 : 10.99.0.11, 1 : 10.99.0.18 }
	}

	chain postrouting {
		type nat hook postrouting priority srcnat; policy accept;
		oifname { "eth1", "eth2" } masquerade
	}
}
```

The `prerouting` rule reads like a sentence: a packet for `192.0.2.80`, TCP port `80`, gets its
destination rewritten (`dnat`) to one of two addresses, chosen by `numgen inc mod 2`, a counter that
goes up by one for each new connection and is taken modulo 2. Counter 0 means web1, at 10.99.0.11;
counter 1 means web2, at 10.99.0.18. **Taking the servers in turn like this is called round
robin.** The `postrouting` rule rewrites the source as well, so the web servers answer the
balancer and the balancer answers the client.

Four requests from pc1, one from pc2, and a look at web1's own address:

```
ana@pc1:~$ for i in 1 2 3 4; do curl -s http://192.0.2.80/; done
served by web2
served by web1
served by web2
served by web1
ana@pc2:~$ curl -s http://192.0.2.80/
served by web2
root@web1:~# ip -br addr show eth0
eth0@if38        UP             10.99.0.11/28 fe80::a2:feff:fe90:d6b3/64 
```

pc1's four requests went **web2, web1, web2, web1**. pc2's single request went to web2, which
is the next turn of the same counter, not a fresh start for a new client: **this balancer counts
connections, not clients**. One connection earlier, in the firewall section, pc1's `curl` was
served by web1, and the sequence continues from it.

web1's own address is `10.99.0.11/28`, a private one. Nobody outside can reach it directly, and
nobody outside needs to: the address in every request is 192.0.2.80, and only lb knows which
server is behind it this time.

## Layer 4 and layer 7

This balancer reads the destination address and port and nothing else. That makes it a **layer 4**
balancer, and it is fast and simple: it never looks inside the connection. A **layer 7** balancer
reads the HTTP request itself, so it can send `/api` to one group of servers and pictures to
another, or keep one user on the same server by reading a cookie. It pays for that by taking part
in every connection, and by needing the keys to decrypt HTTPS.

## What this one does not do

**A real load balancer checks its servers and stops sending connections to one that does not
answer.** This rule has no such check. If web2 were switched off, every second connection would go
to a machine that is not there, and half the visitors would wait for a page that never comes. Without a
health check, two servers are not more reliable than one; they are two chances to fail, and the
check is what the lab's one-line rule leaves out.

There is one more trade in the `masquerade` rule. Because lb rewrites the source, web1's log shows
lb's address on every request rather than the visitor's. A layer 7 balancer works around that by
adding a header that names the original client; this one cannot, because it only rewrites
addresses and never writes into the connection itself.
