---
title: Site to site, a tunnel the till knows nothing about
version: 1
---

"VPN" usually brings to mind an app on a laptop and a button somebody presses. **A site-to-site VPN has
no button and no user.** It joins two networks, router to router, and the people and machines on them
never learn it is there.

The lab's two offices are joined that way, by the WireGuard tunnel of lesson 4 between `hq` and
`branch`. This is the till tracing its way to the file server at the head office:

```
ana@till:~$ traceroute -n -q 1 192.168.10.10
traceroute to 192.168.10.10 (192.168.10.10), 30 hops max, 60 byte packets
 1  192.168.20.1  0.069 ms
 2  10.20.0.1  2.324 ms
 3  192.168.10.10  2.618 ms
ana@till:~$ ip route
default via 192.168.20.1 dev eth0 
192.168.20.0/24 dev eth0 proto kernel scope link src 192.168.20.30 
```

Three hops. The first is `branch`, the till's gateway. **The second is `10.20.0.1`, `hq`'s address
inside the tunnel, and the whole crossing of the internet is that one hop.** The ISP's router forwarded
encrypted UDP and never saw the traceroute's packets inside it, so it had no reason to answer as a hop.
The third is `files`. The 2.324 ms at hop 2 is not distance: no link in the lab has any delay, so every
time here is one computer's own work.

The till's routing table is the other half of the evidence. It has a default route to its gateway and
its own LAN, and nothing else: no tunnel address, no VPN software, no key. It would look the same if the
two offices were joined by a leased line, and that is the point. **Which traffic goes to the other
office is decided once, on the router, for every device behind it**, printers, cameras and tills
included, none of which could run a VPN client if asked.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 270\" role=\"img\" aria-label=\"Two panels. Site to site: routers hq and branch joined by one dashed tunnel, always up; files and laptop hang off hq and the till off branch, and the devices run nothing. Remote access: three devices, Ana at home, a hotel laptop and a phone, each with its own dashed tunnel to hq, the concentrator; one tunnel per person, each with its own key.\"><defs><marker id=\"sh-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"360\" height=\"250\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 4\"></rect><text x=\"24\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">site to site</text><rect x=\"40\" y=\"110\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hq</text><text x=\"90.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">203.0.113.2</text><rect x=\"240\" y=\"110\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"290.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">branch</text><text x=\"290.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">198.51.100.2</text><path d=\"M140 122 C 175 90, 205 90, 240 122\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#sh-ah)\"></path><text x=\"190\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">one tunnel, always up</text><rect x=\"30\" y=\"190\" width=\"56\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"58.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">files</text><path d=\"M58 190 L90 150\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"92\" y=\"190\" width=\"56\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">laptop</text><path d=\"M120 190 L90 150\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"262\" y=\"190\" width=\"56\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"290.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">till</text><path d=\"M290 190 L290 150\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"190\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the devices run nothing</text><rect x=\"390\" y=\"10\" width=\"360\" height=\"250\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 4\"></rect><text x=\"404\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">remote access</text><rect x=\"640\" y=\"115\" width=\"90\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"685\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hq</text><text x=\"685\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">concentrator</text><rect x=\"410\" y=\"60\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Ana at home</text><path d=\"M530 76 L 636 135\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#sh-ah)\"></path><rect x=\"410\" y=\"122\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a hotel laptop</text><path d=\"M530 138 L 636 135\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#sh-ah)\"></path><rect x=\"410\" y=\"184\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a phone</text><path d=\"M530 200 L 636 135\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#sh-ah)\"></path><text x=\"570\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one tunnel per person, each with its own key</text></svg>", "caption": "Where the tunnel ends decides who it knows. Site to site ends at routers and knows two offices; remote access ends on each device and knows each person."}
```

That arrangement has a character of its own:

- it is always up. Nobody logs in, and the tunnel is there at three in the morning for the backup
  job as much as at nine for the people;
- it authenticates a site, not a person. **Anything plugged into the branch LAN reaches the
  head office as the branch**, a visitor's laptop included. So each end still needs firewall rules saying which
  of the other office's addresses may reach which servers, and a guest network kept off the tunnel, on
  its own VLAN (lesson 19 of `networks-addressing`);
- it has few peers, with fixed addresses. Its configuration changes when an office opens or moves,
  and the network team owns it;
- its routes are written by hand here. With two offices that is two lines. With thirty, the offices
  run a routing protocol across the tunnels, OSPF or BGP from lessons 16 and 17 of `networks-addressing`,
  which is where GRE inside IPsec from lessons 1 and 2 still earns its place.
