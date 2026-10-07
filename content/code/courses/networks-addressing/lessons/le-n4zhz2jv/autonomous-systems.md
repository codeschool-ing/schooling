---
title: Autonomous systems and their numbers
version: 2
---

Lesson 16's protocols assume every router is run by the same people. The internet is the opposite case:
**tens of thousands of networks, each run by its own organisation**, each deciding for itself what to
carry and for whom. Each one is an **autonomous system** (AS): a set of routers under one administration
with one routing policy towards the rest of the world.

Inside an AS you run an IGP, OSPF or IS-IS, and get the fast, trusting convergence of lesson 16.
**Between ASes you run BGP** (*Border Gateway Protocol*, version 4, RFC 4271), which carries reachability
and, above all, policy: not only *I can reach this* but *and this is who I will carry it for*.

## AS numbers

Each AS is identified by an **AS number** (ASN). They were 16 bits wide, 1 to 65535, and ran short, so
they were extended to 32 bits; both kinds are in use today. Some ranges are set aside:

| range | what it is for |
|---|---|
| 64496 to 64511 | documentation, for examples and labs like this one |
| 64512 to 65534 | private use, inside one organisation, never announced to the internet |
| 4200000000 to 4294967294 | private use, the 32-bit equivalent |

A public ASN is assigned by a regional internet registry, LACNIC for Latin America, which in Brazil
assigns through NIC.br. An organisation needs one when it wants its own address block reachable through
more than one provider, which is this lab's company.

## The lab

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 420\" role=\"img\" aria-label=\"The lab for this lesson, in three autonomous systems. The company, AS 64500, holds 203.0.113.0/24: www at 203.0.113.10 behind the router edge, whose other two interfaces are 192.0.2.1 and 192.0.2.5. Provider A, AS 64501, runs ispa, cabled to edge over 192.0.2.0/30 (ispa is 192.0.2.2) and serving a1, 198.51.100.10, on 198.51.100.0/25. Provider B, AS 64502, runs ispb, cabled to edge over 192.0.2.4/30 (ispb is 192.0.2.6) and serving b1, 198.51.100.130, on 198.51.100.128/25. ispa and ispb are also cabled to each other over 192.0.2.8/30, at 192.0.2.9 and 192.0.2.10.\"><defs><marker id=\"bt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M220 10 L500 10 L500 182 L220 182 L220 10\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"232\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">AS 64500</text><text x=\"310\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the company</text><path d=\"M10 230 L310 230 L310 410 L10 410 L10 230\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"22\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">AS 64501</text><text x=\"100\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">provider A</text><path d=\"M410 230 L710 230 L710 410 L410 410 L410 230\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"422\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">AS 64502</text><text x=\"500\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">provider B</text><rect x=\"300\" y=\"40\" width=\"120\" height=\"41\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www</text><text x=\"310\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">203.0.113.10</text><rect x=\"290\" y=\"104\" width=\"140\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">edge</text><text x=\"300\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 192.0.2.1</text><text x=\"300\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth2 192.0.2.5</text><path d=\"M360 81 L360 104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"40\" y=\"262\" width=\"160\" height=\"71\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"276\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ispa</text><text x=\"50\" y=\"294\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth0 192.0.2.2</text><text x=\"50\" y=\"309\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 192.0.2.9</text><text x=\"50\" y=\"324\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth2 198.51.100.1</text><rect x=\"40\" y=\"358\" width=\"160\" height=\"41\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"372\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a1</text><text x=\"50\" y=\"390\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">198.51.100.10</text><path d=\"M120 333 L120 358\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"212\" y=\"380\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">198.51.100.0/25</text><rect x=\"520\" y=\"262\" width=\"160\" height=\"71\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"276\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ispb</text><text x=\"530\" y=\"294\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth0 192.0.2.6</text><text x=\"530\" y=\"309\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 192.0.2.10</text><text x=\"530\" y=\"324\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth2 198.51.100.129</text><rect x=\"520\" y=\"358\" width=\"160\" height=\"41\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"372\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">b1</text><text x=\"530\" y=\"390\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">198.51.100.130</text><path d=\"M600 333 L600 358\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"508\" y=\"380\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">198.51.100.128/25</text><path d=\"M310 167 L160 262\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"214\" y=\"205\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.0.2.0/30</text><path d=\"M410 167 L560 262\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"506\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.0.2.4/30</text><path d=\"M200 297 L520 297\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"360\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.0.2.8/30</text></svg>", "caption": "The lab for this lesson. Each dashed line is an autonomous system; every cable crossing one carries an eBGP session."}
```

Save it as `~/netlab/bgp.sh` and build it with `sudo bash ~/netlab/netlab.sh up bgp`:

```bash
# ~/netlab/bgp.sh: a company with its own block, 203.0.113.0/24, and its own
# autonomous system, 64500, connected to two providers that also peer with
# each other. The providers are configured here; the company's router, edge,
# starts with nothing.
#
#            www 203.0.113.10
#                 |
#               edge (AS 64500)
#              /              \
#   192.0.2.0/30              192.0.2.4/30
#            /                  \
#   ispa (AS 64501) --------- ispb (AS 64502)
#        |         192.0.2.8/30      |
#   a1 198.51.100.10          b1 198.51.100.130
#   (198.51.100.0/25)         (198.51.100.128/25)
isp_bgp() {  # isp_bgp NODE ASN OWN-PREFIX ROUTER-ID CUSTOMER PEER PEER-ASN
  frr "$1" <<CONF
hostname $1
ip prefix-list CUSTOMER seq 5 permit 203.0.113.0/24
route-map FROM-CUSTOMER permit 10
 match ip address prefix-list CUSTOMER
route-map ANY permit 10
router bgp $2
 bgp router-id $4
 neighbor $5 remote-as 64500
 neighbor $6 remote-as $7
 address-family ipv4 unicast
  network $3
  neighbor $5 route-map FROM-CUSTOMER in
  neighbor $5 route-map ANY out
  neighbor $6 route-map ANY in
  neighbor $6 route-map ANY out
 exit-address-family
CONF
}
node www; node a1; node b1
node edge router; node ispa router; node ispb router
link www eth0 edge eth0;  addr www eth0 203.0.113.10/24; addr edge eth0 203.0.113.1/24; gw www 203.0.113.1
link edge eth1 ispa eth0; addr edge eth1 192.0.2.1/30; addr ispa eth0 192.0.2.2/30
link edge eth2 ispb eth0; addr edge eth2 192.0.2.5/30; addr ispb eth0 192.0.2.6/30
link ispa eth1 ispb eth1; addr ispa eth1 192.0.2.9/30; addr ispb eth1 192.0.2.10/30
link a1 eth0 ispa eth2;   addr a1 eth0 198.51.100.10/25;  addr ispa eth2 198.51.100.1/25;   gw a1 198.51.100.1
link b1 eth0 ispb eth2;   addr b1 eth0 198.51.100.130/25; addr ispb eth2 198.51.100.129/25; gw b1 198.51.100.129
isp_bgp ispa 64501 198.51.100.0/25   192.0.2.2 192.0.2.1 192.0.2.10 64502
isp_bgp ispb 64502 198.51.100.128/25 192.0.2.6 192.0.2.5 192.0.2.9  64501
echo "hostname edge" | FRR_EXTRA=bgpd frr edge
```

`isp_bgp` writes one provider's FRR configuration: its own block, a session with the customer whose
incoming routes pass through the route map `FROM-CUSTOMER`, and a session with the other provider. The
section on route leaks comes back to that route map. edge, the company's router, is started with BGP
running and nothing configured, because this lesson types its configuration.

The company, AS 64500, holds the block `203.0.113.0/24` with a web server on it. Its router, `edge`, is
cabled to two providers, ispa in AS 64501 and ispb in AS 64502, which are also cabled to each other and
each serve a customer network of their own, with one host, a1 and b1. Every ASN and address is from the
ranges reserved for documentation.

**The providers are already configured, and edge has nothing.** ispa's BGP table shows what it knows:

```
root@ispa:~# vtysh -c "show ip bgp"
BGP table version is 2, local router ID is 192.0.2.2, vrf id 0
Default local pref 100, local AS 64501
Status codes:  s suppressed, d damped, h history, * valid, > best, = multipath,
               i internal, r RIB-failure, S Stale, R Removed
Nexthop codes: @NNN nexthop's vrf id, < announce-nh-self
Origin codes:  i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

   Network          Next Hop            Metric LocPrf Weight Path
*> 198.51.100.0/25  0.0.0.0                  0         32768 i
*> 198.51.100.128/25
                    192.0.2.10               0             0 64502 i

Displayed  2 routes and 2 total paths
```

Two networks. `198.51.100.0/25` is ispa's own customers: next hop `0.0.0.0`, meaning *this router*, and
weight 32768, the value FRR gives a route the router itself originates. `198.51.100.128/25` is ispb's,
learned across the cable between them, from `192.0.2.10`, with the **AS path** `64502`: the route came
from AS 64502. The `i` at the end is the origin code, IGP, meaning the route was put into BGP by a
`network` statement. **Nothing about 203.0.113.0/24**, because nobody has announced it, and so:

```
ana@a1:~$ ping -c 1 -W 1 203.0.113.10
PING 203.0.113.10 (203.0.113.10) 56(84) bytes of data.
From 198.51.100.1 icmp_seq=1 Destination Net Unreachable

--- 203.0.113.10 ping statistics ---
1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 0ms

```

ispa, `198.51.100.1`, has no route to the company. The rest of this lesson builds edge's side, one piece at
a time.
