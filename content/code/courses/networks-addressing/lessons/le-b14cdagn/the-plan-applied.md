---
title: The plan, built
version: 2
---

A plan on paper becomes a network in a handful of lines: one address, with its mask, on each
interface of the router. This lesson's lab is the plan built, and it is lesson 12's `plan.sh`. r1 has one cable to each of the three
LANs and one to r2, and behind r2 is hq1, a PC at head office that every test in this lesson starts
from:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"The lab for this lesson. Three PCs, each on its own LAN cabled to the router r1: sales1, 10.20.32.10, on the sales /25, reached on r1's eth1 with gateway .1; eng1, 10.20.32.140, on the engineering /26, on eth2 with gateway .129; and ops1, 10.20.32.200, on the operations /27, on eth3 with gateway .193. r1 is cabled to r2 by the link 10.20.32.224/30, r1 at .225 and r2 at .226. r2 holds one route, the /24, for all of it, and behind r2, on 10.20.99.0/24, is hq1 at 10.20.99.10.\"><rect x=\"20\" y=\"20\" width=\"180\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"35\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sales1  10.20.32.10</text><text x=\"30\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sales, /25</text><line x1=\"200\" y1=\"42\" x2=\"330\" y2=\"42\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><text x=\"265\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 .1</text><rect x=\"20\" y=\"90\" width=\"180\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">eng1  10.20.32.140</text><text x=\"30\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">engineering, /26</text><line x1=\"200\" y1=\"112\" x2=\"330\" y2=\"112\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><text x=\"265\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth2 .129</text><rect x=\"20\" y=\"160\" width=\"180\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ops1  10.20.32.200</text><text x=\"30\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">operations, /27</text><line x1=\"200\" y1=\"182\" x2=\"330\" y2=\"182\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><text x=\"265\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth3 .193</text><rect x=\"330\" y=\"28\" width=\"120\" height=\"168\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"390\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"390\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">router</text><line x1=\"450\" y1=\"112\" x2=\"540\" y2=\"112\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><text x=\"456\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.225</text><text x=\"534\" y=\"102\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.226</text><text x=\"495\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.32.224/30</text><rect x=\"540\" y=\"86\" width=\"110\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r2</text><text x=\"595\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one route: /24</text><line x1=\"595\" y1=\"138\" x2=\"595\" y2=\"168\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><text x=\"603\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.99.0/24</text><rect x=\"540\" y=\"168\" width=\"110\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"550\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">hq1</text><text x=\"550\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.99.10</text></svg>", "caption": "The plan built: three LANs and a /30 on r1's four interfaces, and r2 reaching all of them through one route."}
```

Each LAN's gateway takes the first host address of its subnet, which is a habit rather than a rule
but one worth keeping: the gateway is the address people type most, and .1, .129 and .193 can be
worked out from the plan without looking anything up.

| network | subnet | r1's interface | gateway | the PC in the lab |
|---|---|---|---|---|
| sales | 10.20.32.0/25 | eth1 | 10.20.32.1 | sales1, .10 |
| engineering | 10.20.32.128/26 | eth2 | 10.20.32.129 | eng1, .140 |
| operations | 10.20.32.192/27 | eth3 | 10.20.32.193 | ops1, .200 |
| link to r2 | 10.20.32.224/30 | eth0 | — | r2, .226 |

Here is r1, as built:

```
root@r1:~# ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth1@if194       UP             10.20.32.1/25 fe80::a6:80ff:fe20:1354/64 
eth2@if196       UP             10.20.32.129/26 fe80::26:62ff:fe13:4f3c/64 
eth3@if198       UP             10.20.32.193/27 fe80::e3:72ff:fe9b:b7c2/64 
eth0@if199       UP             10.20.32.225/30 fe80::1f:23ff:fee7:e9d5/64 
root@r1:~# ip route
default via 10.20.32.226 dev eth0 
10.20.32.0/25 dev eth1 proto kernel scope link src 10.20.32.1 
10.20.32.128/26 dev eth2 proto kernel scope link src 10.20.32.129 
10.20.32.192/27 dev eth3 proto kernel scope link src 10.20.32.193 
10.20.32.224/30 dev eth0 proto kernel scope link src 10.20.32.225 
```

**Nobody typed a route to any of the four subnets.** Each `proto kernel scope link` line appeared
when its address was set, because an address with a mask says which network is on that cable. That
is also why a wrong mask is so expensive: the route comes from the mask, and lesson 12 showed a /24
typed in place of a /25 making a PC look for another subnet's machines on its own cable. The one route somebody did
type is the default, towards r2 at 10.20.32.226, for everything that is not one of r1's own
subnets.

r2 is upstream, and this is its whole table:

```
root@r2:~# ip route
10.20.32.0/24 via 10.20.32.225 dev eth0 
10.20.32.224/30 dev eth0 proto kernel scope link src 10.20.32.226 
10.20.99.0/24 dev eth1 proto kernel scope link src 10.20.99.1 
```

Three LANs behind r1, and **r2 reaches all of them with one line**, `10.20.32.0/24 via
10.20.32.225`. r2 does not know the company has a /25, a /26 and a /27; it knows that everything in
10.20.32.0/24 is r1's business, and r1 sorts it out. That single route is a summary, and the next
section is about what it buys and what it costs.

Now the test that matters, from hq1, on the far side of both routers:

```
ana@hq1:~$ ping -c 1 -q 10.20.32.10
PING 10.20.32.10 (10.20.32.10) 56(84) bytes of data.

--- 10.20.32.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 10.249/10.249/10.249/0.000 ms
ana@hq1:~$ ping -c 1 -q 10.20.32.140
PING 10.20.32.140 (10.20.32.140) 56(84) bytes of data.

--- 10.20.32.140 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 2.809/2.809/2.809/0.000 ms
ana@hq1:~$ ping -c 1 -q 10.20.32.200
PING 10.20.32.200 (10.20.32.200) 56(84) bytes of data.

--- 10.20.32.200 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 2.080/2.080/2.080/0.000 ms
ana@hq1:~$ traceroute -n 10.20.32.200
traceroute to 10.20.32.200 (10.20.32.200), 30 hops max, 60 byte packets
 1  10.20.99.1  4.096 ms  0.420 ms  0.190 ms
 2  10.20.32.225  0.557 ms  0.215 ms  0.223 ms
 3  10.20.32.200  0.889 ms  0.304 ms  0.451 ms
```

One packet to each LAN, and one back from each. The traceroute shows the path in three hops: r2,
which answers from its address on hq1's side, 10.20.99.1; then r1, from its end of the link,
10.20.32.225; then ops1 itself. The round-trip times are this lab's one computer talking to itself,
and they say nothing about a network.

**Every address in that traceroute was decided by the plan**, down to which end of the /30 is r1's.
Writing the table above before typing a single command is what made the build a few lines long, and
it is the document somebody will need on the day one of these subnets has to grow.
