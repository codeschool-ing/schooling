---
title: "The firewall: a rule for every packet"
version: 1
---

"Firewall" sounds like a box with a wall drawn on it, or like the antivirus on a laptop. **A
firewall is a list of rules that every packet crossing a point in the network is checked against,
and each rule ends in a decision: let it through, or drop it.** The rules read addresses, ports
and, in a stateful firewall such as this lab's, the state of the connection the packet belongs to. Where
the rules run is a detail: a dedicated appliance, a laptop's own operating system, or a router.

In this lab they run on r1, written for `nftables`, Linux's packet filter. Here is the chain that
judges every packet r1 forwards:

```
root@r1:~# nft list chain inet filter forward
table inet filter {
	chain forward {
		type filter hook forward priority filter; policy drop;
		ct state established,related counter packets 10 bytes 876 accept
		iifname "eth0" oifname "eth1" counter packets 14 bytes 864 accept
		counter packets 0 bytes 0 comment "everything else: dropped"
	}
}
```

Four lines carry the policy, read top to bottom:

- `policy drop` is the default: **a packet that matches no rule is dropped**. Everything allowed
  has to be said.
- `ct state established,related ... accept` lets through any packet that belongs to a connection
  already accepted, in either direction. `ct` is connection tracking: r1 remembers every
  conversation it has let start.
- `iifname "eth0" oifname "eth1" ... accept` lets a *new* connection start if it comes in from the
  office side and goes out to the provider.
- The last line only counts what reaches it, which is everything else, before the policy drops it.

**Nothing in that list lets a connection start from outside.** Each rule also carries a `counter`,
so the list says how much traffic each rule has already decided: 10 packets matched the first,
14 the second and none the last.

Now one connection in each direction. pc1 asks the web service beyond the provider for a page; the
provider tries to open the web server inside the office. (The lab gave the provider a route to the
office's private network for this block, so that the firewall is the only thing in the way.)

```
ana@pc1:~$ curl -s http://192.0.2.80/
served by web1
root@isp:~# curl -s -m 5 http://10.20.10.10/; echo "exit status $?"
exit status 28
root@r1:~# nft list chain inet filter forward
table inet filter {
	chain forward {
		type filter hook forward priority filter; policy drop;
		ct state established,related counter packets 21 bytes 1729 accept
		iifname "eth0" oifname "eth1" counter packets 15 bytes 924 accept
		counter packets 5 bytes 300 comment "everything else: dropped"
	}
}
```

pc1 got its page, `served by web1`. The provider's `curl` was given five seconds with `-m 5`, got
nothing at all in that time and gave up with **exit status 28**, curl's code for a timeout. Then the
counters, against the first listing:

| rule | before | after |
|---|---|---|
| established or related | 10 packets | 21 packets |
| new, from office to provider | 14 packets | 15 packets |
| everything else, dropped | 0 packets | 5 packets |

pc1's request added **one packet to the second rule and eleven to the first**. Only the first
packet of a connection is new; once the firewall had let it through, every packet after it, in
both directions, belonged to an established connection. The provider's attempt matched neither
rule and was counted by the last line: 5 packets, 300 bytes, all of them dropped.

**`drop` answers nothing**, which is why the provider's curl waited out its five seconds instead of
failing at once. The alternative, `reject`, sends back a refusal so the sender learns immediately.
Dropping tells a stranger less about what is behind the router; rejecting spares a legitimate
user who was refused by mistake a long wait for an answer that is not coming.

This is a **stateful** firewall, and the word matters. A rule list without connection tracking
would need a rule for the replies as well, and could not tell a reply from a stranger knocking with
the same ports. The `ct state` line is what makes "the office may start conversations, the
internet may not" a two-line policy. Lesson 11 puts NAT on the same router, and the two are
easy to confuse: NAT rewrites addresses, and the firewall decides what passes.
