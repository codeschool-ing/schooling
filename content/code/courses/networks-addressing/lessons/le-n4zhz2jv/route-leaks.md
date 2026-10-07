---
title: Route leaks, and the two filters that stop them
version: 2
---

A **route leak** is an announcement that goes somewhere its policy says it should not. The commonest shape
is the one this lab can make: **a customer announcing to one provider the routes it learned from the
other**, which offers to carry traffic between two large networks through a company's small link. The
company never meant to be a transit network; one wrong line makes it one.

edge's announcements to ispb, as they stand:

```
root@edge:~# vtysh -c "show ip bgp neighbors 192.0.2.6 advertised-routes"
BGP table version is 3, local router ID is 192.0.2.1, vrf id 0
Default local pref 100, local AS 64500
Status codes:  s suppressed, d damped, h history, * valid, > best, = multipath,
               i internal, r RIB-failure, S Stale, R Removed
Nexthop codes: @NNN nexthop's vrf id, < announce-nh-self
Origin codes:  i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

   Network          Next Hop            Metric LocPrf Weight Path
*> 203.0.113.0/24   0.0.0.0                  0         32768 i

Total number of prefixes 1
```

One prefix, the company's own. Now the mistake, staged on purpose: an outbound route map called
`EVERYTHING`, a single `permit` entry with no `match`, which permits every route, applied towards ispb in
place of `TO-PROVIDER`:

```
root@edge:~# vtysh -c "configure terminal" -c "route-map EVERYTHING permit 10" -c "exit" -c "router bgp 64500" -c "address-family ipv4 unicast" -c "neighbor 192.0.2.6 route-map EVERYTHING out"
root@edge:~# vtysh -c "show ip bgp neighbors 192.0.2.6 advertised-routes"
BGP table version is 3, local router ID is 192.0.2.1, vrf id 0
Default local pref 100, local AS 64500
Status codes:  s suppressed, d damped, h history, * valid, > best, = multipath,
               i internal, r RIB-failure, S Stale, R Removed
Nexthop codes: @NNN nexthop's vrf id, < announce-nh-self
Origin codes:  i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

   Network          Next Hop            Metric LocPrf Weight Path
*> 198.51.100.0/25  0.0.0.0                                0 64501 i
*> 198.51.100.128/25
                    0.0.0.0                                0 64502 i
*> 203.0.113.0/24   0.0.0.0                  0         32768 i

Total number of prefixes 3
```

**Three prefixes**, where there was one: the company's block, and both providers' customer networks.
edge is now telling ispb *send me your traffic for ispa's customers and I will pass it on*. The listing
shows the paths as edge holds them; ispb would receive each with 64500 added at the front.

## The filter on the other side

Did ispb take the offer? Its view of ispa's customers:

```
root@ispb:~# vtysh -c "show ip bgp 198.51.100.0/25"
BGP routing table entry for 198.51.100.0/25, version 2
Paths: (1 available, best #1, table default)
  Advertised to non peer-group peers:
  192.0.2.5 192.0.2.9
  64501
    192.0.2.9 from 192.0.2.9 (192.0.2.2)
      Origin IGP, metric 0, valid, external, best (First path received)
      Last update: Tue Sep 29 08:49:48 2026
```

**One path available, from `192.0.2.9`, ispa, over the cable between the providers.** Nothing from edge.
ispb's configuration in `bgp.sh` applies a route map to everything from its customer that permits
`203.0.113.0/24` and nothing else, the provider-side twin of edge's `TO-PROVIDER`. So the leak was caught
by the second filter.

Two details make the case sharper. ispb's own block, `198.51.100.128/25`, would have been dropped anyway,
because the path edge offered contains 64502, and a BGP router refuses a path that contains its own AS.
And in this lab the leaked route for ispa's customers, `64500 64501`, would have lost to the direct
`64501` on length. **On the real internet it would not have to**: a provider giving its customers' routes a
higher local preference, as the previous section described, prefers a leaked route from a customer over
the correct one from a peer, whatever the lengths. That is how a leak through a small network draws the
traffic of large ones through a link that cannot carry it, and it has happened, more than once, with
services that millions of people use becoming slow or unreachable for hours.

**So there are two filters, one on each side of every customer link**, and neither is enough alone:

- *the customer's outbound filter*: announce your own prefixes, and your customers' if you have any, and
  nothing learned from a provider or a peer;
- *the provider's inbound filter*: accept from a customer only the prefixes that customer is entitled to
  announce.

## Putting it back, with a safety net

```
root@edge:~# vtysh -c "configure terminal" -c "router bgp 64500" -c "address-family ipv4 unicast" -c "neighbor 192.0.2.6 route-map TO-PROVIDER out" -c "neighbor 192.0.2.2 maximum-prefix 1000" -c "neighbor 192.0.2.6 maximum-prefix 1000"
root@edge:~# vtysh -c "show ip bgp neighbors 192.0.2.6 advertised-routes"
BGP table version is 3, local router ID is 192.0.2.1, vrf id 0
Default local pref 100, local AS 64500
Status codes:  s suppressed, d damped, h history, * valid, > best, = multipath,
               i internal, r RIB-failure, S Stale, R Removed
Nexthop codes: @NNN nexthop's vrf id, < announce-nh-self
Origin codes:  i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

   Network          Next Hop            Metric LocPrf Weight Path
*> 203.0.113.0/24   0.0.0.0                  0         32768 i

Total number of prefixes 1
```

`TO-PROVIDER` is back towards ispb, and one prefix is announced again. The same change added
`maximum-prefix 1000` to both neighbours: **if a provider ever sends edge more than 1000 prefixes, edge
closes the session** instead of filling its table with whatever arrived. It is the receiving side's guard
against the mirror image of this section, a provider leaking something huge towards you, and it is cheap:
the number only has to be comfortably above what you expect to receive.

The final configuration, as FRR keeps it:

```
root@edge:~# vtysh -c "show running-config" | sed -n "/^router bgp/,\$p"
router bgp 64500
 bgp router-id 192.0.2.1
 neighbor 192.0.2.2 remote-as 64501
 neighbor 192.0.2.6 remote-as 64502
 !
 address-family ipv4 unicast
  network 203.0.113.0/24
  neighbor 192.0.2.2 maximum-prefix 1000
  neighbor 192.0.2.2 route-map FROM-PROVIDER in
  neighbor 192.0.2.2 route-map TO-ISPA out
  neighbor 192.0.2.6 maximum-prefix 1000
  neighbor 192.0.2.6 route-map FROM-PROVIDER in
  neighbor 192.0.2.6 route-map TO-PROVIDER out
 exit-address-family
exit
!
ip prefix-list OURS seq 5 permit 203.0.113.0/24
!
route-map TO-PROVIDER permit 10
 match ip address prefix-list OURS
exit
!
route-map FROM-PROVIDER deny 5
 match ip address prefix-list OURS
exit
!
route-map FROM-PROVIDER permit 10
exit
!
route-map TO-ISPA permit 10
 match ip address prefix-list OURS
 set as-path prepend 64500 64500
exit
!
route-map EVERYTHING permit 10
exit
!
end
```

Read it top to bottom: the AS, the two neighbours, the one network, the limits, and a route map in and out
on each session, `TO-ISPA` towards ispa with the prepend from the previous section. One thing should not be
there. **`route-map EVERYTHING` is still defined**, unused, waiting for somebody to apply it again by
mistake; `no route-map EVERYTHING` would remove it. It was not removed in this lab, and it is the kind of
leftover a configuration review exists to find.
