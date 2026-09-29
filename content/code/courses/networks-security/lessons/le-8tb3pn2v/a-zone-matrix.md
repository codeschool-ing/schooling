---
title: Writing the policy as a matrix, then as rules
version: 1
---

Before writing a rule, write down **which zone may start a conversation with which, on what**. A
table of zones against zones, each cell naming what is allowed and every empty cell meaning denied,
is short enough to review and complete enough to check against:

| from ↓ to → | internet | DMZ | staff LAN | servers | management |
|---|---|---|---|---|---|
| **internet** | · | `www` on 80 and 443; `dns` on UDP 53 | — | — | — |
| **DMZ** | — | · | — | `www` to `app` on 8080 | — |
| **staff LAN** | web, 80 and 443 | web, 80 and 443; DNS | · | `app` on 8080 | — |
| **servers** | — | — | — | · | — |
| **management** | — | SSH | — | SSH | · |

Read a row to see what a zone can do and a column to see what can reach it. The **servers row is
empty**: nothing on the servers segment starts a conversation with any other zone. The application
answers; it never calls out. The DMZ's row has one entry, and it is one host to one host on one port.

`fw` already holds this matrix as rules, in `baseline.nft`, written for the lab and loaded now:

```
root@fw:~# cat baseline.nft
flush ruleset
table ip filter {
  chain forward {
    type filter hook forward priority filter; policy drop;
    ct state established,related accept
    ct state invalid drop
    iifname "eth2" oifname { "eth0", "eth1" } tcp dport { 80, 443 } ct state new accept comment "staff browse"
    iifname "eth2" oifname "eth1" ip daddr 192.0.2.53 meta l4proto { tcp, udp } th dport 53 ct state new accept comment "staff resolve names"
    iifname "eth2" oifname "eth3" ip daddr 192.168.20.10 tcp dport 8080 ct state new accept comment "staff use the application"
    iifname "eth0" oifname "eth1" ip daddr 192.0.2.80 tcp dport { 80, 443 } ct state new accept comment "the world reaches the shop"
    iifname "eth0" oifname "eth1" ip daddr 192.0.2.53 udp dport 53 ct state new accept comment "the world asks our names"
    iifname "eth1" oifname "eth3" ip saddr 192.0.2.80 ip daddr 192.168.20.10 tcp dport 8080 ct state new accept comment "the proxy reaches the application"
    iifname "eth4" oifname { "eth1", "eth3" } tcp dport 22 ct state new accept comment "administration over SSH"
  }
  chain input {
    type filter hook input priority filter; policy drop;
    ct state established,related accept
    iifname "lo" accept
    iifname "eth4" ip saddr 192.168.99.0/24 tcp dport 22 ct state new accept comment "fw is administered from mgmt only"
  }
}
root@fw:~# nft -f baseline.nft
```

Each `accept` line carries out part of the matrix, and **each carries a comment saying what it allows**. The input
chain protects `fw` itself: it may be administered only from the management segment. Policy `drop`
on both chains is every empty cell at once.

Two details in the rules deserve a second look. The DNS cell for the staff reads `meta l4proto { tcp,
udp } th dport 53`, both transports on one line, because DNS falls back to TCP for large answers.
The internet's DNS cell is **UDP only**, which the next section's test makes visible. And every
rule that leaves the DMZ names **a source address as well as a destination**: `ip saddr 192.0.2.80`
means that of all the machines in the DMZ, only the proxy may reach the application.
