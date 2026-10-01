---
title: What NAT costs
version: 1
---

NAT solved the shortage of IPv4 addresses and charged for it in ways that turn up years later. The
first one shows inside the office itself.

pc2 tries the forwarded service by its public address, the way a laptop would whose bookmark holds
the public name:

```
ana@pc2:~$ curl -s -m 4 http://203.0.113.2:8080/; echo "exit status $?"
exit status 7
```

Connection refused, from inside, while the same address and port worked from isp a moment before. The
rule explains it: `iifname "eth1" tcp dport 8080 dnat to 10.20.10.10:80`. pc2's request reached r1 on
**eth0**, so the forward did not match, and the packet was simply for r1, which has nothing on port
8080. This is the **hairpin** problem: a service published through NAT cannot be reached at its public
address from the network it lives in, unless the router is set up for it. There are two usual fixes:
give the inside its own answer for the name (split DNS, so the office resolves the server's name to
`10.20.10.10`), or add hairpin NAT on the router, which also matches the inside interface and rewrites
the source so that the reply comes back through r1 rather than straight from srv.

The rest of the costs come from what NAT does to the idea that any machine can reach any other:

- **end to end is gone.** A machine inside cannot be reached unless somebody forwards a port to it, one
  service per public port. Lesson 5 showed what that does to peer-to-peer programs: relays and the
  STUN, TURN and ICE machinery exist because of it;
- **logs see one address for everybody.** Every server the office used recorded 203.0.113.2 for all
  three PCs. A complaint from outside naming that address names the whole office, and finding the
  machine means matching the port and the exact time against records r1 would have to keep — the
  lab's r1 keeps none;
- **the middle holds state.** r1 has an entry for every connection. If r1 restarts, the table is gone
  and every open connection through it breaks; if the table fills, new connections fail;
- **NAT twice.** Providers short of addresses run carrier-grade NAT (CGNAT): the customer's router gets
  an outside address from `100.64.0.0/10`, a block set aside for exactly this, and the provider
  translates again. A port forward on the customer's router then forwards from an address the
  internet cannot reach.

**IPv6 does not need any of this.** With 128-bit addresses there are enough for every device to have
a public one, and lesson 9 numbers an office that way. What remains is the firewall: an IPv6 router
still drops connections nobody asked for, by rule, which is the job NAT was being mistaken for all
along.
