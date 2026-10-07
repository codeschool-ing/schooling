---
title: One gateway, and a way to make it two
version: 1
---

The obvious way to make an office's way out redundant is to plug in a second router. **On its own, a
second router changes nothing for the hosts.** A host does not know about routers in general; it knows
one address, its default gateway, and sends everything that is not on its own network there. The
laptop's routing table says so in two lines:

```
ana@laptop:~$ ip route
default via 192.168.10.1 dev eth0 
192.168.10.0/24 dev eth0 proto kernel scope link src 192.168.10.20 
```

When the router at `192.168.10.1` dies, the laptop keeps sending to `192.168.10.1`, and nothing answers.
A second router on the same cable, working perfectly, is not asked. Lesson 14 called this redundancy the
hosts cannot use, and the gateway is where offices meet it first.

Changing every host is not the answer. There may be hundreds, some of them printers and phones that take
their gateway from DHCP once and never think about it again. **The fix is to leave the hosts alone and
make the address move instead.** Two routers agree that one of them will answer for `192.168.10.1` and the
other will take over the moment the first stops. The address belongs to neither machine. It belongs to a
**virtual router**, a group of real ones, and the hosts cannot tell which real router is behind it on any
given day.

That is VRRP, the Virtual Router Redundancy Protocol, an IETF standard: version 2 is RFC 3768 and
version 3, which adds IPv6, is RFC 5798. The group has a number, the **VRID**, so that several groups can
share a LAN. Each router in it has a **priority**, and the one with the highest priority that is alive is
the **master**, which holds the address. The others are **backups**, which listen.

## The two routers

Head office has two routers, `hq` and `hq2`, both on the LAN and both with a link to the ISP. For this
lesson `hq` moves from `192.168.10.1` to `192.168.10.2`, and `hq2` sits at `192.168.10.3`, which frees
`.1` to become the virtual address. A real network does the same thing when it adds VRRP: **the hosts
keep the gateway they always had**, and the routers move out of its way. On `hq`, with the hardware
address that goes with `.2`, so that a MAC in a capture still says whose it is:

```sh
sudo ip addr del 192.168.10.1/24 dev eth0
sudo ip link set eth0 address 52:54:00:a8:0a:02
sudo ip addr add 192.168.10.2/24 dev eth0
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 750 270\" role=\"img\" aria-label=\"The laptop at 192.168.10.20 has one gateway, 192.168.10.1. That address belongs to a virtual router, VRID 10, drawn as a dashed box around two real routers: hq at 192.168.10.2 with MAC 52:54:00:a8:0a:02, master with priority 150, and hq2 at 192.168.10.3 with MAC 52:54:00:a8:0a:03, backup with priority 100. hq sends an advertisement to 224.0.0.18 every second, which hq2 hears. Both routers reach the ISP router at 203.0.113.1 through their eth1.\"><defs><marker id=\"vr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"106\" width=\"130\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">laptop</text><text x=\"85.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.10.20</text><text x=\"85\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">gateway:</text><text x=\"85\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.10.1</text><rect x=\"220\" y=\"22\" width=\"300\" height=\"236\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"232\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">virtual router, vrid 10</text><rect x=\"300\" y=\"52\" width=\"140\" height=\"26\" rx=\"13\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"370\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">192.168.10.1</text><path d=\"M150 130 L296 66\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vr-ah)\"></path><rect x=\"250\" y=\"96\" width=\"240\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"266\" y=\"113\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">hq</text><text x=\"474\" y=\"113\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">master, priority 150</text><text x=\"266\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.10.2   52:54:00:a8:0a:02</text><rect x=\"250\" y=\"176\" width=\"240\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"266\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">hq2</text><text x=\"474\" y=\"193\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">backup, priority 100</text><text x=\"266\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.10.3   52:54:00:a8:0a:03</text><path d=\"M 250 140 C 232 150, 232 176, 248 192\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#vr-ah)\"></path><text x=\"370\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">hq to 224.0.0.18, every 1 s</text><rect x=\"600\" y=\"136\" width=\"130\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"665.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">isp</text><text x=\"665.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">203.0.113.1</text><path d=\"M490 125 L600 152\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M490 205 L600 168\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"545\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">eth1</text><text x=\"545\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">eth1</text></svg>", "caption": "The laptop knows one address, and the address belongs to whichever of the two routers is master. Each router keeps its own address and its own hardware address; only 192.168.10.1 moves."}
```

The VRRP daemon on both is keepalived, which also runs the health checks of lesson 16. This is its
configuration on `hq`, `/etc/keepalived/keepalived.conf`, to write with `sudo nano`:

```schooling-example
{"language": "conf", "file": "keepalived.conf", "parts": [{"code": "vrrp_instance office {\n    state BACKUP\n    interface eth0", "note": "One VRRP instance, named `office`. Both routers start as backups and let the election decide, and `eth0` is the LAN side, where the advertisements are sent and heard."}, {"code": "    virtual_router_id 10\n    priority 150\n    advert_int 1", "note": "The group's number on this LAN, this router's priority and the advertisement interval in seconds. `hq2` has the same file with a priority of 100, so `hq` wins while it is healthy."}, {"code": "    virtual_ipaddress {\n        192.168.10.1/24\n    }", "note": "The address that moves: the hosts' default gateway. It belongs to whichever router is master, and to neither otherwise."}, {"code": "    track_interface {\n        eth1\n    }\n}", "note": "`eth1` is the link to the ISP. If it goes down, this router gives up the address even though its LAN side is fine."}]}
```

`hq2` gets the same file with one change, `priority 100` instead of `priority 150`. With both routers holding the same VRID and the same
virtual address, the only thing left to decide is who goes first, and that is an election.
