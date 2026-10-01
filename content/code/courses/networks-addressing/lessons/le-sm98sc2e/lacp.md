---
title: LACP, the two ends agreeing
version: 1
---

A LAG can be configured with no protocol at all: tell each switch which ports belong together and
it will spread traffic over them. That is a **static** LAG, and its weakness is that each end trusts
its own configuration and nothing else. If one cable of the group is plugged into the wrong switch,
or the far end was never configured, the near end sends part of its traffic into a port that is not
expecting it, and nothing reports a fault.

**LACP**, the *Link Aggregation Control Protocol*, makes the two ends check each other. It was
published as IEEE 802.3ad and now lives in IEEE 802.1AX, which is why Linux still calls the mode
`802.3ad`. Each end sends **LACPDUs** on every member: who it is (a system priority and MAC), which
group the port belongs to (a *key*), and the port's state. **A port joins the LAG only when the
partner on the other end of that cable agrees** to the same group. A cable plugged into the wrong
switch shows the wrong partner, and it is left out.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The lab for lesson 21. pc1 is on port p1 of sw1. sw1 and sw2 are joined by two cables, e1 and e2 at each end, bundled on each switch into one logical port, bond0, which sits in the switch's bridge br0. sw1's bond uses the MAC address 02:1d:22:fd:7e:72 and sees sw2, 02:fc:ce:91:32:14, as its LACP partner on both cables. pc2, pc3 and pc4 are on sw2, at 10.20.10.22, 10.20.10.23 and 10.20.10.24; pc1 is 10.20.10.21. Each switch sends a LACPDU on each cable every second.\"><defs><marker id=\"lag-p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"16\" y=\"96\" width=\"92\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"62\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"62\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.10.21</text><path d=\"M108 116 L150 116\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"140\" y=\"106\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p1</text><rect x=\"150\" y=\"70\" width=\"140\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"220\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">sw1</text><rect x=\"206\" y=\"98\" width=\"76\" height=\"54\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"244\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bond0</text><text x=\"166\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">br0</text><rect x=\"430\" y=\"70\" width=\"140\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">sw2</text><rect x=\"438\" y=\"98\" width=\"76\" height=\"54\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"476\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bond0</text><text x=\"554\" y=\"125\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">br0</text><path d=\"M282 128 L438 128\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"272\" y=\"128\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">e1</text><text x=\"448\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">e1</text><path d=\"M282 142 L438 142\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"272\" y=\"142\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">e2</text><text x=\"448\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">e2</text><path d=\"M304 116 H416 Q424 116 424 124 V146 Q424 154 416 154 H304 Q296 154 296 146 V124 Q296 116 304 116 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"360\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">one logical link, two cables</text><path d=\"M360 64 L360 114\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#lag-p)\"></path><text x=\"360\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a LACPDU each way, every second, on each cable</text><text x=\"220\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sw1, the actor</text><text x=\"220\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">02:1d:22:fd:7e:72</text><text x=\"500\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sw2, the partner</text><text x=\"500\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">02:fc:ce:91:32:14</text><rect x=\"612\" y=\"40\" width=\"92\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"658\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"658\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.10.22</text><path d=\"M570 116 L612 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"612\" y=\"98\" width=\"92\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"658\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc3</text><text x=\"658\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.10.23</text><path d=\"M570 116 L612 118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"612\" y=\"156\" width=\"92\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"658\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc4</text><text x=\"658\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.10.24</text><path d=\"M570 116 L612 176\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path></svg>", "caption": "Spanning tree and the MAC table see one port, bond0, at each end. LACP runs on each cable underneath and keeps a member in the bundle only while the partner on that cable agrees."}
```

## Bundling the two cables on sw1

On `sw1`, four commands make a bond in LACP mode, put both cables in it and put the bond in the
switch:

```
root@sw1:~# ip link add bond0 type bond mode 802.3ad lacp_rate fast miimon 100 xmit_hash_policy layer2+3
root@sw1:~# ip link set e1 down && ip link set e2 down
root@sw1:~# ip link set e1 master bond0 && ip link set e2 master bond0
root@sw1:~# ip link set bond0 master br0 && ip link set bond0 up
```

The first line carries every decision. `mode 802.3ad` is LACP. **`lacp_rate fast` asks the partner
for a LACPDU every second** rather than every 30, so a dead member is noticed in seconds. `miimon 100`
makes the bond check each member's link every 100 milliseconds. `xmit_hash_policy layer2+3` decides
how traffic is spread, which the next section shows. The cables are taken down before they join, which is
why each member's `Link Failure Count` reads 1 further down. The same four commands ran on `sw2`, out of view, because
LACP needs both ends.

Ten seconds later, the bond is one interface with two members:

```
root@sw1:~# ip -br link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
br0              UP             02:6a:dc:93:3b:8a <BROADCAST,MULTICAST,UP,LOWER_UP> 
bond0            UP             02:1d:22:fd:7e:72 <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> 
e1@if485         UP             02:1d:22:fd:7e:72 <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> 
e2@if487         UP             02:1d:22:fd:7e:72 <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> 
p1@if490         UP             02:b7:0a:5d:30:6c <BROADCAST,MULTICAST,UP,LOWER_UP> 
```

`bond0` is the `MASTER` and both cables are its members, flagged `SLAVE`, which is the word the
kernel still prints. **The bond took `e1`'s MAC address, `02:1d:22:fd:7e:72`, and so did `e2`**: to the
switch, one logical port has one address.

## What the bond says about itself

The kernel describes the whole negotiation in one file:

```
root@sw1:~# cat /proc/net/bonding/bond0
Ethernet Channel Bonding Driver: v6.8.0-142-generic

Bonding Mode: IEEE 802.3ad Dynamic link aggregation
Transmit Hash Policy: layer2+3 (2)
MII Status: up
MII Polling Interval (ms): 100
Up Delay (ms): 0
Down Delay (ms): 0
Peer Notification Delay (ms): 0

802.3ad info
LACP active: on
LACP rate: fast
Min links: 0
Aggregator selection policy (ad_select): stable
System priority: 65535
System MAC address: 02:1d:22:fd:7e:72
Active Aggregator Info:
	Aggregator ID: 1
	Number of ports: 2
	Actor Key: 15
	Partner Key: 15
	Partner Mac Address: 02:fc:ce:91:32:14

Slave Interface: e1
MII Status: up
Speed: 10000 Mbps
Duplex: full
Link Failure Count: 1
Permanent HW addr: 02:1d:22:fd:7e:72
Slave queue ID: 0
Aggregator ID: 1
Actor Churn State: monitoring
Partner Churn State: monitoring
Actor Churned Count: 0
Partner Churned Count: 0
details actor lacp pdu:
    system priority: 65535
    system mac address: 02:1d:22:fd:7e:72
    port key: 15
    port priority: 255
    port number: 1
    port state: 63
details partner lacp pdu:
    system priority: 65535
    system mac address: 02:fc:ce:91:32:14
    oper key: 15
    port priority: 255
    port number: 1
    port state: 63

Slave Interface: e2
MII Status: up
Speed: 10000 Mbps
Duplex: full
Link Failure Count: 1
Permanent HW addr: 02:ce:7c:39:59:d3
Slave queue ID: 0
Aggregator ID: 1
Actor Churn State: monitoring
Partner Churn State: monitoring
Actor Churned Count: 0
Partner Churned Count: 0
details actor lacp pdu:
    system priority: 65535
    system mac address: 02:1d:22:fd:7e:72
    port key: 15
    port priority: 255
    port number: 2
    port state: 63
details partner lacp pdu:
    system priority: 65535
    system mac address: 02:fc:ce:91:32:14
    oper key: 15
    port priority: 255
    port number: 2
    port state: 63
ana@pc1:~$ ping -c 2 -q 10.20.10.22
PING 10.20.10.22 (10.20.10.22) 56(84) bytes of data.

--- 10.20.10.22 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 0.928/2.420/3.912/1.492 ms
```

Read it from the top. **`Aggregator ID: 1` with `Number of ports: 2`** is the first thing to check:
both cables made it into the same aggregator. `Partner Mac Address:
02:fc:ce:91:32:14` is `sw2`, and the same address appears as the partner on both members, which is
the check a static LAG never makes. `Actor Key: 15` and `Partner Key: 15` are the two ends naming
the same group. In this file the *actor* is the end you are reading on, and the *partner* is the far
end.

Each member then shows the LACPDU it sends and the one it received. **`port state: 63` on both
sides** is a byte of six flags, all set: the port is actively sending LACPDUs, using the fast
timeout, willing to aggregate, in sync with its partner, collecting frames and distributing them.
A member that is cabled and up but not yet in sync would show a lower number.

And the ping that failed in the previous section now crosses the bond: 2 sent, 2 received.
