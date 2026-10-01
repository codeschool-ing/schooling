---
title: Standard ACLs: the source address and nothing else
version: 1
---

A **standard ACL** tests one thing: the packet's **source address**. In IOS, numbered 1 to 99, it reads:

```
access-list 10 permit host 192.168.30.20
access-list 10 deny   any
!
interface GigabitEthernet0/1
 ip access-group 10 in
```

Only `192.168.30.20` may send anything into the router through that interface. The `deny any` line
makes the implicit deny visible, which is a habit worth having, because an ACL whose last line is
invisible is an ACL somebody will misread.

The branch has two computers: `branchpc` and `guest`, plugged in on the same segment. Before any ACL,
both reach the internet:

```
ana@branchpc:~$ probe remote:80 remote:443 remote:22
remote:80              open
remote:443             open
remote:22              refused
ana@guest:~$ probe remote:80 remote:443
remote:80              open
remote:443             open
```

The same ACL on `branch`, bound to the LAN interface on ingress:

```
root@branch:~# cat acl-standard.nft
table netdev acl {
  chain lan_in {
    type filter hook ingress device "eth1" priority filter; policy drop;
    ip saddr 192.168.30.20 accept comment "10: permit host 192.168.30.20"
    meta protocol arp accept comment "(not IP: the segment has to keep working)"
  }
}
root@branch:~# nft -f acl-standard.nft
```

Two details a router ACL hides and Linux makes visible. **`policy drop` is the implicit deny.** And the
`arp` line exists because a filter this early sees every frame, and denying ARP would stop the machines
on the segment from finding the router at all; a router's IP ACL never sees ARP, so it never needs the
line. Then the two computers again:

```
ana@branchpc:~$ probe remote:80 remote:443
remote:80              open
remote:443             open
ana@guest:~$ probe remote:80 remote:443
remote:80              blocked
remote:443             blocked
```

`branchpc` goes out; `guest` is blocked at the router's door, for every destination and every port.
That is the whole power of a standard ACL, and its whole limit: **it can say who, and never where or
what**.

```
root@branch:~# nft list chain netdev acl lan_in | grep -E "counter|saddr" ; nft delete table netdev acl
		ip saddr 192.168.30.20 accept comment "10: permit host 192.168.30.20"
```
