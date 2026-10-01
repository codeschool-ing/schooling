---
title: Defences that live in the switch and on the host
version: 1
---

Detection says something happened. Several defences make ARP spoofing fail outright, and most of
them live in the switch, which is the one device that knows which port each machine is really on.

| defence | where | what it does |
|---|---|---|
| **DHCP snooping** | switch | records which address the DHCP server gave to which MAC on which port, and refuses DHCP answers from ports that are not the server's |
| **dynamic ARP inspection** | switch | checks every ARP answer against the DHCP snooping table, and drops an answer claiming an address its port was never given |
| **port security** | switch | limits the MAC addresses a port may present |
| **802.1X** | switch and host | the port stays closed until the machine authenticates (lesson 22) |
| **static neighbour entries** | host | a critical host keeps a fixed MAC for its gateway and ignores ARP about it |

Dynamic ARP inspection is the direct answer: a lie about the gateway's address arrives on a port that
was never given the gateway's address, and the switch drops it before any machine hears it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"A switch with dynamic ARP inspection. Its snooping table says the gateway&#x27;s address, 192.168.10.1, was learnt on port 1, and 192.168.10.20 was given to port 3. An ARP answer arriving on port 1 claiming 192.168.10.1 matches the table and is forwarded. An ARP answer arriving on port 5 claiming 192.168.10.1 does not match and is dropped, so no machine on the segment hears it.\"><defs><marker id=\"da-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"da-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"230\" y=\"20\" width=\"260\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"245\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">switch: snooping table</text><text x=\"245\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">port 1  192.168.10.1</text><text x=\"245\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">port 3  192.168.10.20</text><text x=\"245\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">port 4  192.168.10.21</text><rect x=\"20\" y=\"40\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fw</text><text x=\"30\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">port 1, the gateway</text><rect x=\"20\" y=\"160\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a machine</text><text x=\"30\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">port 5</text><rect x=\"550\" y=\"90\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"560\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">port 3</text><path d=\"M170 63 L230 63\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#da-ah-phosphor)\"></path><text x=\"174\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">is-at .1</text><path d=\"M490 80 L550 105\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#da-ah-phosphor)\"></path><text x=\"496\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">forwarded</text><path d=\"M170 183 L250 150\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#da-ah-amber)\" stroke-dasharray=\"4 3\"></path><text x=\"180\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">&quot;192.168.10.1 is at my MAC&quot;: dropped at the port</text></svg>", "caption": "The switch knows which port each address belongs to, so a claim from the wrong port never reaches anybody."}
```
It needs
DHCP snooping to know the truth, and it needs static entries for anything configured by hand, like
the gateway itself.

## A fixed entry on the host

When the switch cannot help, a host can refuse to learn. On `laptop`, the gateway's MAC written in by
hand as a permanent entry:

```
root@laptop:~# ip neigh replace 192.168.10.1 lladdr 52:54:00:a8:0a:01 dev eth0 nud permanent; ip neigh show 192.168.10.1
192.168.10.1 dev eth0 lladdr 52:54:00:a8:0a:01 PERMANENT 
```

`PERMANENT` entries are not replaced by ARP answers. `laptop` still works normally:

```
ana@laptop:~$ curl -s https://www.example.com/
orders service: ok
```

The cost is maintenance: replace the gateway's network card, or fail over to a second firewall with a
different MAC, and every host with the old entry loses its way out. It is reasonable for a handful of
critical servers talking to one gateway and unmanageable across an office, which is why the switch
features exist.

**The defence that works whatever else fails is still encryption.** A host that sends everything over
TLS or SSH, checking certificates and host keys, gives a machine in the middle only metadata. The
switch features make the attack hard; encryption makes it pointless.
