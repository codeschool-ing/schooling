---
title: What the firewall never sees
version: 1
---

The firewall filters traffic **between** zones. Two machines in the same segment talk through the
switch, and their packets never cross `fw`:

```
ana@app:~$ probe db:5432 db:22
db:5432                open
db:22                  open
```

`app` reaches the database and SSH on `db` freely. Nothing in `baseline.nft` allowed it and nothing
could have stopped it: the rules are on a machine these packets never pass through. The same is true
on the staff LAN. `desk` shares a folder on port 445, the port Windows file sharing uses:

```
ana@laptop:~$ probe desk:22
desk:22                refused
ana@laptop:~$ probe desk:445
desk:445               open
```

**Every computer on the LAN can reach every other one.** For most offices that is how it has always
been, and it is exactly the path lesson 9 shows ransomware taking: from the first machine somebody
infected, sideways, to every share it can open. A segment is only as trustworthy as its least careful
member.

There are three answers, and later lessons take each one:

| answer | what it does | lesson |
|---|---|---|
| smaller segments | more zones, so fewer machines share each one | this lesson's matrix, applied again |
| a firewall on each machine | every host filters what reaches it, even from its neighbours | 21 |
| identity instead of location | a machine is trusted for what it proves, not for where it sits | 20 |

In real networks, segments are usually **VLANs**: one switch divided into several logical networks,
each with its own address range, and routed between through the firewall. The lab builds each
segment as its own bridge, which behaves the same way. What matters is the property both share: a
VLAN only protects anything if the traffic between VLANs is forced through a firewall, and a switch
that routes between them by itself has undone the segmentation.

For reference, the matrix as `fw` holds it, one comment per cell:

```
root@fw:~# nft list chain ip filter forward | grep -E "comment|policy"
		type filter hook forward priority filter; policy drop;
		iifname "eth2" oifname { "eth0", "eth1" } tcp dport { 80, 443 } ct state new accept comment "staff browse"
		iifname "eth2" oifname "eth1" ip daddr 192.0.2.53 meta l4proto { tcp, udp } th dport 53 ct state new accept comment "staff resolve names"
		iifname "eth2" oifname "eth3" ip daddr 192.168.20.10 tcp dport 8080 ct state new accept comment "staff use the application"
		iifname "eth0" oifname "eth1" ip daddr 192.0.2.80 tcp dport { 80, 443 } ct state new accept comment "the world reaches the shop"
		iifname "eth0" oifname "eth1" ip daddr 192.0.2.53 udp dport 53 ct state new accept comment "the world asks our names"
		iifname "eth1" oifname "eth3" ip saddr 192.0.2.80 ip daddr 192.168.20.10 tcp dport 8080 ct state new accept comment "the proxy reaches the application"
		iifname "eth4" oifname { "eth1", "eth3" } tcp dport 22 ct state new accept comment "administration over SSH"
```
