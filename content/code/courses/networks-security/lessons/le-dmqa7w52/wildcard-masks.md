---
title: Wildcard masks, read bit by bit
version: 1
---

IOS ACLs write networks with a **wildcard mask** instead of a subnet mask: `192.168.30.0 0.0.0.255`
rather than `192.168.30.0/24`. The wildcard is the subnet mask inverted: **a 0 bit means "must match",
a 1 bit means "any value"**. So `0.0.0.255` says the first three bytes must match and the last may be
anything.

Python's `ipaddress` calls the wildcard the **host mask**, and computes both from a prefix:

```
ana@branch:~$ python3 -c "import ipaddress as i; n=i.ip_network(\"192.168.30.0/24\"); print(n.netmask, n.hostmask); n=i.ip_network(\"10.20.16.0/20\"); print(n.netmask, n.hostmask, n.num_addresses)"
255.255.255.0 0.0.0.255
255.255.240.0 0.0.15.255 4096
```

`/24` is netmask `255.255.255.0` and wildcard `0.0.0.255`. `/20` is `255.255.240.0` and wildcard
`0.0.15.255`, and it covers 4,096 addresses. The quick way to compute a wildcard by hand is to subtract
each byte of the netmask from 255: `255 - 240 = 15`.

Three wildcards with names of their own:

| wildcard | IOS shorthand | matches |
|---|---|---|
| `0.0.0.0` | `host 192.168.30.20` | exactly one address |
| `255.255.255.255` | `any` | every address |
| `0.0.0.255` | none | a /24 |

**A wildcard does not have to be a run of ones at the end**, which is the one thing it can do that a
prefix cannot. `192.168.0.1 0.0.254.0` matches `192.168.0.1`, `192.168.2.1`, `192.168.4.1` and so on:
host `.1` in every even-numbered third byte. It is rarely a good idea, because the next person has to
work it out bit by bit to know what it permits, and the ACLs that cause outages are the ones nobody can
read at a glance.
