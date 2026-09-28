---
title: Extended ACLs: source, destination, protocol and port
version: 1
---

An **extended ACL** tests the same fields as lesson 1's rules: source and destination address,
protocol, and for TCP and UDP the ports. In IOS, numbered 100 to 199 or given a name:

```
ip access-list extended BRANCH-OUT
 10 permit tcp 192.168.30.0 0.0.0.255 any eq www
 11 permit tcp 192.168.30.0 0.0.0.255 any eq 443
 20 permit udp 192.168.30.0 0.0.0.255 any eq domain
 30 deny   ip any any log
!
interface GigabitEthernet0/1
 ip access-group BRANCH-OUT in
```

Anything on the branch LAN may browse and resolve names, and nothing else leaves. The numbers on the
left are **sequence numbers**: a line can later be inserted between 10 and 20 without rewriting the
list. The same policy on `branch`, with each line's IOS form in its comment:

```
root@branch:~# cat acl-extended.nft
table netdev acl {
  chain lan_in {
    type filter hook ingress device "eth1" priority filter; policy drop;
    meta protocol arp accept
    ip saddr 192.168.30.0/24 ip daddr 192.168.30.1 accept comment "the router itself"
    ip saddr 192.168.30.0/24 tcp dport { 80, 443 } counter accept comment "10: permit tcp 192.168.30.0 0.0.0.255 any eq www 443"
    ip saddr 192.168.30.0/24 udp dport 53 counter accept comment "20: permit udp 192.168.30.0 0.0.0.255 any eq domain"
    counter comment "the implicit deny, counted"
  }
  chain wan_in {
    type filter hook ingress device "eth0" priority filter; policy accept;
    ip daddr 192.168.30.0/24 tcp flags & (ack | rst) == 0 counter drop comment "no new TCP towards the branch: the IOS established keyword"
  }
}
root@branch:~# nft -f acl-extended.nft
```

The rule for the router's own address keeps the branch able to reach its gateway, which an IOS ACL
applied inbound also has to allow if the router is to be managed from that side. The last line counts
what the implicit deny catches. Then the test:

```
ana@branchpc:~$ probe remote:80 remote:443 remote:22
remote:80              open
remote:443             open
remote:22              blocked
ana@guest:~$ probe remote:80
remote:80              open
```

The web passes for both computers now, because the ACL speaks about the subnet rather than one
host; `remote:22` is **blocked**, where before any ACL it was `refused`, which means the packet no
longer reaches `remote` at all. The counters say where each packet went:

```
root@branch:~# nft list table netdev acl | grep counter
		ip saddr 192.168.30.0/24 tcp dport { 80, 443 } counter packets 12 bytes 612 accept comment "10: permit tcp 192.168.30.0 0.0.0.255 any eq www 443"
		ip saddr 192.168.30.0/24 udp dport 53 counter packets 0 bytes 0 accept comment "20: permit udp 192.168.30.0 0.0.0.255 any eq domain"
		counter packets 1 bytes 60 comment "the implicit deny, counted"
		ip daddr 192.168.30.0/24 tcp flags ! rst,ack counter packets 0 bytes 0 drop comment "no new TCP towards the branch: the IOS established keyword"
```

Twelve packets through the web line, none through DNS in this test, and **one packet caught by the
implicit deny**: the `SYN` to port 22. A `log` on the IOS `deny` line would have recorded it; on
`branch`, the counter does.
