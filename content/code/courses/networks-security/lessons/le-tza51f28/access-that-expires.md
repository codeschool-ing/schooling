---
title: Access that expires on its own
version: 1
---

The most common excess privilege is not a rule written too wide. It is **a rule written for a reason
that ended**: the supplier who needed SSH for a migration last March, the test that needed a port
opened for a week. Nobody removes them, because nothing breaks when they stay.

nftables sets can carry a **timeout**: an element added with one disappears when it runs out. A set
for temporary support access, and a rule that allows SSH to `app` from whatever the set holds:

```
root@fw:~# nft add set ip filter vendor "{ type ipv4_addr; flags timeout; comment \"temporary support access\"; }"
root@fw:~# nft insert rule ip filter forward index 1 iifname eth0 ip saddr @vendor ip daddr 192.168.20.10 tcp dport 22 ct state new accept comment '"vendor support, while in the set"'
```

The rule never changes. Access is granted by adding an address to the set, here the supplier's,
`203.0.113.70`, for 15 seconds, which is a demonstration; a real window is hours:

```
root@fw:~# nft add element ip filter vendor "{ 203.0.113.70 timeout 15s }"; nft list set ip filter vendor | grep elements
		elements = { 203.0.113.70 timeout 15s expires 15s }
```

The listing shows the element and how long it has left. From the supplier's machine:

```
ana@branch:~$ probe app:22
app:22                 open
```

Open. Sixteen seconds later, nobody having done anything:

```
root@fw:~# nft list set ip filter vendor | grep -c elements
0
ana@branch:~$ probe app:22
app:22                 blocked
```

**The set is empty and the port is blocked.** The access ended on schedule because the clock ended it,
not because somebody remembered.

The same idea at larger scale is **just-in-time access**: administrative privilege requested for a task,
approved, granted for a window and withdrawn automatically, with each grant recorded. The firewall rule
above is its simplest possible form, and it already removes the failure that matters: **a temporary
rule that became permanent by being forgotten.**
