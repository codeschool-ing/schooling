---
title: A mask that is wider than it looks
version: 1
---

Administrators on the management segment should reach the servers over SSH. The rule is typed quickly:

```
root@fw:~# nft add rule ip filter forward ip saddr 192.168.99.0/16 oifname eth3 tcp dport 22 ct state new accept comment '"admins reach the servers over SSH"'
```

`192.168.99.0/16`. The intent was `/24`: the management segment. Listing the rule back shows what nftables
actually stored:

```
root@fw:~# nft list chain ip filter forward | grep "admins reach" | sed "s/^\t*//"
ip saddr 192.168.0.0/16 oifname "eth3" tcp dport 22 ct state new accept comment "admins reach the servers over SSH"
```

**`192.168.0.0/16`.** A `/16` keeps only the first two bytes, so nftables normalised the address to
the network it really describes, which contains every range in the lab that starts with `192.168`: the
management segment, and also the staff LAN, the servers and the branch. From the staff LAN:

```
ana@laptop:~$ probe app:22 db:22
app:22                 open
db:22                  open
```

SSH on both servers is open to `laptop`. Nothing failed to load and no rule looks wrong at a glance; the
cell of the matrix that says *staff LAN to servers: application only* is simply no longer true.

**Read every rule back after loading it.** The rule set in the kernel is the truth, and it is not
always the text that was typed: nftables rewrote this address to the network it describes. A quick
look at the listing catches exactly this class of mistake, where the typed text and the stored meaning
differ. Router ACLs set the same trap with lesson 17's wildcard masks, where one wrong byte widens a
line by a factor of 256.
