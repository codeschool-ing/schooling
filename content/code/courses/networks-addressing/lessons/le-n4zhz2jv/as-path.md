---
title: Policy, and the AS path that decides
version: 1
---

A BGP policy is written with two tools. A **prefix list** names prefixes. A **route map** is an ordered list
of entries, each one *permit* or *deny*, each matching something, a prefix list for instance, and
optionally changing the route; **a route that matches no entry is denied**. edge gets three of them:

```
root@edge:~# vtysh -c "configure terminal" -c "ip prefix-list OURS seq 5 permit 203.0.113.0/24" -c "route-map TO-PROVIDER permit 10" -c "match ip address prefix-list OURS" -c "exit" -c "route-map FROM-PROVIDER deny 5" -c "match ip address prefix-list OURS" -c "exit" -c "route-map FROM-PROVIDER permit 10" -c "exit" -c "router bgp 64500" -c "address-family ipv4 unicast" -c "neighbor 192.0.2.2 route-map FROM-PROVIDER in" -c "neighbor 192.0.2.2 route-map TO-PROVIDER out" -c "neighbor 192.0.2.6 route-map FROM-PROVIDER in" -c "neighbor 192.0.2.6 route-map TO-PROVIDER out"
```

Read it as policy rather than syntax:

- `OURS` is the company's block, `203.0.113.0/24`, and nothing else.
- **`TO-PROVIDER`**, applied *out* to both providers, permits what matches `OURS`. Everything else falls
  off the end and is denied: **edge announces its own block and nothing more**.
- **`FROM-PROVIDER`**, applied *in*, first denies `OURS`, so no provider can tell edge how to reach the
  company's own network, then permits everything else.

The summary changes from `(Policy)` to numbers:

```
root@edge:~# vtysh -c "show bgp summary"

IPv4 Unicast Summary (VRF default):
BGP router identifier 192.0.2.1, local AS number 64500 vrf-id 0
BGP table version 3
RIB entries 5, using 960 bytes of memory
Peers 2, using 1448 KiB of memory

Neighbor        V         AS   MsgRcvd   MsgSent   TblVer  InQ OutQ  Up/Down State/PfxRcd   PfxSnt Desc
192.0.2.2       4      64501        16        10        0    0    0 00:00:13            2        1 N/A
192.0.2.6       4      64502        16        10        0    0    0 00:00:13            2        1 N/A

Total number of neighbors 2
```

**2 received and 1 sent on each session**: each provider sent its two customer networks, and edge sent its
one block to each. ispa lists edge among the peers it passes 203.0.113.0/24 to, as the next section's
capture shows, and whatever arrives edge refuses twice over: `FROM-PROVIDER` denies it, and the path
contains 64500, edge's own AS. **A BGP router drops any route whose AS path already
contains its own number**, which is how BGP avoids loops between ASes.

## Reading edge's table

```
root@edge:~# vtysh -c "show ip bgp"
BGP table version is 3, local router ID is 192.0.2.1, vrf id 0
Default local pref 100, local AS 64500
Status codes:  s suppressed, d damped, h history, * valid, > best, = multipath,
               i internal, r RIB-failure, S Stale, R Removed
Nexthop codes: @NNN nexthop's vrf id, < announce-nh-self
Origin codes:  i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

   Network          Next Hop            Metric LocPrf Weight Path
*  198.51.100.0/25  192.0.2.6                              0 64502 64501 i
*>                  192.0.2.2                0             0 64501 i
*> 198.51.100.128/25
                    192.0.2.6                0             0 64502 i
*                   192.0.2.2                              0 64501 64502 i
*> 203.0.113.0/24   0.0.0.0                  0         32768 i

Displayed  3 routes and 5 total paths
```

Five paths for three networks. For `198.51.100.0/25`, ispa's customers, edge holds two:

- through `192.0.2.6`, ispb, with the AS path **`64502 64501`**: ispb heard it from ispa and passed it on;
- through `192.0.2.2`, ispa, with the AS path **`64501`**, marked `>`, best.

**The AS path is the list of ASes a route has crossed, newest first, with the origin last.** All else
being equal, the shorter path wins, and here all else is equal. `198.51.100.128/25` is the mirror image:
best through ispb, `64502`. The company's own block has next hop `0.0.0.0` and weight 32768, originated
here.

BGP's choice goes through a fixed list of tie-breakers, in order, and stops at the first that differs.
The first few, on FRR and Cisco: the highest **weight** (local to one router), the highest **local
preference** (shared inside one AS), a route this router originated, **the shortest AS path**, the origin
code, the lowest **MED**, and then eBGP over iBGP. Everything this lesson does with real traffic happens at
the AS path step, because nothing before it was set.

The best paths go into the kernel:

```
root@edge:~# ip route
192.0.2.0/30 dev eth1 proto kernel scope link src 192.0.2.1 
192.0.2.4/30 dev eth2 proto kernel scope link src 192.0.2.5 
198.51.100.0/25 nhid 15 via 192.0.2.2 dev eth1 proto bgp metric 20 
198.51.100.128/25 nhid 16 via 192.0.2.6 dev eth2 proto bgp metric 20 
203.0.113.0/24 dev eth0 proto kernel scope link src 203.0.113.1 
```

`proto bgp`, and the same `metric 20` lesson 16 met on RIP's routes, FRR's number rather than BGP's. Now a1
and b1 reach the web server, **each through its own provider**:

```
ana@a1:~$ traceroute -n 203.0.113.10
traceroute to 203.0.113.10 (203.0.113.10), 30 hops max, 60 byte packets
 1  198.51.100.1  2.503 ms  0.519 ms  0.155 ms
 2  192.0.2.1  0.605 ms  0.168 ms  0.128 ms
 3  203.0.113.10  1.421 ms  0.388 ms  0.131 ms
ana@b1:~$ traceroute -n 203.0.113.10
traceroute to 203.0.113.10 (203.0.113.10), 30 hops max, 60 byte packets
 1  198.51.100.129  2.477 ms  0.631 ms  0.294 ms
 2  192.0.2.5  0.834 ms  0.713 ms  0.534 ms
 3  203.0.113.10  0.680 ms  0.551 ms  0.236 ms
```

a1's traffic arrives at `192.0.2.1`, edge's interface towards ispa; b1's at `192.0.2.5`, towards ispb.
Three hops each, and both providers carry the company's traffic, which is the point of having two.
