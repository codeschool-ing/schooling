---
title: The established keyword, and what it cannot do
version: 1
---

Lesson 1 met the problem every stateless filter has: replies. An ACL that lets the branch browse must
also let the answers back in, and without state it cannot know which packets are answers. IOS offers
the `established` keyword on TCP lines:

```
ip access-list extended BRANCH-IN
 10 permit tcp any 192.168.30.0 0.0.0.255 established
 20 deny   ip any any
```

`established` matches any TCP packet with the **ACK or RST flag set**. The first packet of a new
connection, a `SYN`, carries neither, so it fails the test; every later packet of a connection carries
ACK. The `wan_in` chain in `acl-extended.nft`, back in section 04, does the same on `branch`'s internet side: it
drops TCP towards the branch whose ACK and RST flags are both clear.

A server on `branchpc` is listening on 8080, started there as root with
`setsid socat TCP-LISTEN:8080,bind=192.168.30.20,fork,reuseaddr SYSTEM:"echo branchpc" </dev/null >/dev/null 2>&1 &`. `remote` tries to open a connection to it, and the branch's
own computer opens one outwards:

```
ana@remote:~$ probe 192.168.30.20:8080
192.168.30.20:8080     blocked
root@branch:~# nft list chain netdev acl wan_in | grep counter
		ip daddr 192.168.30.0/24 tcp flags ! rst,ack counter packets 1 bytes 60 drop comment "no new TCP towards the branch: the IOS established keyword"
ana@branchpc:~$ nc -w1 203.0.113.50 80 </dev/null
remote web
```

The inbound `SYN` is **blocked**, and the counter shows the one packet dropped. The outbound connection
works, because every packet coming back to `branchpc` carries ACK.

**What it cannot do is lesson 1's point, restated for routers.** `established` checks a flag the sender
sets. A packet crafted with ACK already set passes the line whether or not any connection exists. The
receiving host answers it with a reset, so no connection opens, but the ACL did let it through, and
scans that map a network with such packets rely on exactly that. And
the keyword exists only for TCP: UDP replies, DNS answers included, need a line of their own that
permits a source port, which is the hole lesson 1 walked through.

**Where state matters, the answer is a stateful firewall, or IOS's reflexive ACLs and zone-based
firewall features**, which add connection tracking to the router. Where it does not, at a core switch
dropping what can never be legitimate, a plain ACL remains the cheapest filter there is.
