---
title: The LAN, the network you own
version: 2
---

The five names in this lesson's title are not five sizes on one ruler. The usual picture is a set of
circles — small for a LAN, bigger for a MAN, biggest for a WAN — and it gets the most useful part
wrong. **What separates a LAN from a WAN is who owns the links**, and the size follows from that.

A **LAN** (*local area network*) is the network inside one site, built from cables, switches and
access points that the company bought, installed and can walk up to. Because it is yours, it is
fast and cheap: a switch port costs the same whether it is busy or idle, and nobody sends a bill
for the traffic. A LAN is also, in the ordinary case, **one broadcast domain** — the machines on it
reach each other directly, finding each other's MAC addresses with ARP, without a router in between.

This lesson's lab is a company with two sites:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"The sites scenario of the lab, left to right. The head office LAN, 10.20.10.0/24, holds pc1 at 10.20.10.21 and the router rhq at 10.20.10.1, whose other side is 203.0.113.2. The provider, the WAN, holds isp at 203.0.113.1 and 198.51.100.1, on the links 203.0.113.0/30 and 198.51.100.0/30. The branch LAN, 10.30.10.0/24, holds the router rbr at 198.51.100.2 and 10.30.10.1, and pc2 at 10.30.10.22. Above them, a WireGuard tunnel joins rhq, wg0 at 10.255.255.1, to rbr, wg0 at 10.255.255.2, over the provider.\"><rect x=\"8\" y=\"62\" width=\"228\" height=\"208\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"18\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">head office LAN</text><text x=\"18\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.10.0/24</text><rect x=\"252\" y=\"62\" width=\"216\" height=\"208\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"262\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">provider: the WAN</text><rect x=\"484\" y=\"62\" width=\"228\" height=\"208\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"702\" y=\"78\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">branch LAN</text><text x=\"702\" y=\"94\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.30.10.0/24</text><rect x=\"20\" y=\"140\" width=\"92\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"30\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.10.21</text><rect x=\"132\" y=\"140\" width=\"92\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"142\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rhq</text><text x=\"142\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.10.1</text><text x=\"142\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">203.0.113.2</text><rect x=\"310\" y=\"140\" width=\"100\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"320\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">isp</text><text x=\"320\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">203.0.113.1</text><text x=\"320\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">198.51.100.1</text><rect x=\"496\" y=\"140\" width=\"92\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"506\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rbr</text><text x=\"506\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">198.51.100.2</text><text x=\"506\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.30.10.1</text><rect x=\"608\" y=\"140\" width=\"92\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"618\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"618\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.30.10.22</text><path d=\"M112 170.0 L132 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M224 170.0 L310 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M410 170.0 L496 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M588 170.0 L608 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"360\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">203.0.113.0/30</text><text x=\"360\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">198.51.100.0/30</text><path d=\"M178.0 56 L178.0 30 L542.0 30 L542.0 56\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M178.0 62 L178.0 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><path d=\"M542.0 62 L542.0 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"360\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">WireGuard tunnel, built in the VPN section</text><text x=\"186.0\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">wg0 10.255.255.1</text><text x=\"534.0\" y=\"44\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.255.255.2 wg0</text></svg>", "caption": "The lab of lesson 4: two LANs that belong to the company and a WAN that belongs to the provider. The tunnel at the top does not exist until the VPN section types it."}
```

Save it as `~/netlab/sites.sh` and build it with `sudo bash ~/netlab/netlab.sh up sites`:

```bash
# ~/netlab/sites.sh: a head office and a branch in another city, each with a
# router that does NAT, joined only by the provider.
#
#   pc1 --- rhq ==== isp ==== rbr --- pc2
#   10.20.10.0/24  203.0.113.0/30  198.51.100.0/30  10.30.10.0/24
#
# THE TUNNEL KEYS ARE WRITTEN HERE so that `wg show` prints the same thing
# every time. They protect nothing, because anybody can read them in this
# file. A real tunnel uses keys made with `wg genkey`.
local n
node pc1; node pc2; node rhq router; node rbr router; node isp router
link pc1 eth0 rhq eth0; addr pc1 eth0 10.20.10.21/24; addr rhq eth0 10.20.10.1/24; gw pc1 10.20.10.1
link pc2 eth0 rbr eth0; addr pc2 eth0 10.30.10.22/24; addr rbr eth0 10.30.10.1/24; gw pc2 10.30.10.1
link rhq eth1 isp eth0; addr rhq eth1 203.0.113.2/30;  addr isp eth0 203.0.113.1/30;  gw rhq 203.0.113.1
link rbr eth1 isp eth1; addr rbr eth1 198.51.100.2/30; addr isp eth1 198.51.100.1/30; gw rbr 198.51.100.1
for n in rhq rbr; do
  ip netns exec $n nft -f - <<'NFT'
table ip nat {
  chain postrouting {
    type nat hook postrouting priority srcnat;
    oifname "eth1" masquerade
  }
}
NFT
done
install -m 600 /dev/null "$LAB/rhq/wg.key"; echo 'GDNn9hZF8EMa3dOdNriCkv7wUSNKPmiNFnLAFss/320=' > "$LAB/rhq/wg.key"
install -m 600 /dev/null "$LAB/rbr/wg.key"; echo '+NDqNEgyW6ovPD5VS4cet2/zHvQ8YDbzo42zM27XtHc=' > "$LAB/rbr/wg.key"
```

The two routers do NAT, like the office's r1, and the last two lines write the private keys of a
tunnel that the section on VPNs builds between them.

pc1 is at the head office. Its own view of the network says exactly where its LAN ends:

```
ana@pc1:~$ ip -br addr show eth0
eth0@if199       UP             10.20.10.21/24 fe80::25:70ff:febc:29c6/64 
ana@pc1:~$ ip route
default via 10.20.10.1 dev eth0 
10.20.10.0/24 dev eth0 proto kernel scope link src 10.20.10.21 
```

Two routes, and they are the whole of the LAN idea. `10.20.10.0/24 dev eth0 ... scope link` means
**every address from 10.20.10.0 to 10.20.10.255 is reached directly on the cable**, by asking for
its MAC address: that range is pc1's LAN. Everything else falls to `default via 10.20.10.1`, the
router `rhq`, and leaves the LAN through it. The edge of a LAN is where a packet has to be handed to
a router; lesson 14 reads routing tables like this one in full.

pc2 is at the branch, in another city:

```
ana@pc2:~$ ip -br addr show eth0
eth0@if201       UP             10.30.10.22/24 fe80::fd:f2ff:fed2:63ba/64 
```

`10.30.10.22/24` is in a different range, so pc2 is on a different LAN, and nothing in pc1's table
reaches it directly. Two LANs of the same company, each with its own router, each one fast and
free inside. The question for the rest of the lesson is what joins them.

## What a LAN is not

- **It is not "everything behind my router".** A company floor with a hundred PCs can be several
  LANs, deliberately kept apart; this lesson's VLAN section shows the usual way.
- **It is not defined by a distance.** A LAN across a campus of several buildings, on fibre the
  company owns, is still a LAN. A link to the building across the street rented from a provider is
  not.
- **It is not only cables.** Wi-Fi from the company's own access points is part of the LAN; the
  access point bridges the radio to the same Ethernet (lesson 1).

The addresses inside both LANs, `10.20.10.0/24` and `10.30.10.0/24`, come from the private ranges
that lesson 8 lists. That detail decides the VPN section of this lesson: a private address means
something only inside the network that chose it.
