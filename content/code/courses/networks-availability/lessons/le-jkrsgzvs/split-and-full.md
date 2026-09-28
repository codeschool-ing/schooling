---
title: Split tunnel and full tunnel
version: 1
---

One decision shapes a remote-access user's day more than any other: **does only the company's traffic
go through the tunnel, or everything?** The first is a split tunnel and the second a full tunnel. On
WireGuard it is one line, the laptop's `AllowedIPs`, which lesson 4 showed is also its routing table.

Ana's laptop first, split:

```
ana@remote:~$ sudo grep AllowedIPs /etc/wireguard/wg0.conf
AllowedIPs = 10.20.0.0/24, 192.168.10.0/24
ana@remote:~$ ip route get 192.168.10.10; ip route get 192.0.2.21
192.168.10.10 dev wg0 src 10.20.0.3 uid 1001 
    cache 
192.0.2.21 via 192.168.1.1 dev eth0 src 192.168.1.50 uid 1001 
    cache 
ana@remote:~$ traceroute -n -q 1 192.0.2.21
traceroute to 192.0.2.21 (192.0.2.21), 30 hops max, 60 byte packets
 1  192.168.1.1  0.848 ms
 2  198.51.100.1  0.623 ms
 3  192.0.2.21  0.567 ms
ana@remote:~$ curl -s http://192.0.2.21/
served by web1
```

`AllowedIPs` names the tunnel's network and the head office LAN, nothing else. `ip route get` asks the
kernel which way a packet would go without sending one. To `files` through `wg0`, from her tunnel
address `10.20.0.3`; to `web1` out of `eth0`, through the home router `192.168.1.1`. The traceroute
agrees, home router, ISP, `web1`. **The company never sees her web traffic at all.**

Then her file was changed to `AllowedIPs = 0.0.0.0/0`, with the tunnel taken down first, as root and
not shown, and she brought it up again:

```
ana@remote:~$ sudo wg-quick up wg0
[#] ip link add wg0 type wireguard
Error: Unknown device type.
[!] Missing WireGuard kernel module. Falling back to slow userspace implementation.
[#] wireguard-go wg0
┌──────────────────────────────────────────────────────┐
│                                                      │
│   Running wireguard-go is not required because this  │
│   kernel has first class support for WireGuard. For  │
│   information on installing the kernel module,       │
│   please visit:                                      │
│         https://www.wireguard.com/install/           │
│                                                      │
└──────────────────────────────────────────────────────┘
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.20.0.3/24 dev wg0
[#] ip link set mtu 1420 up dev wg0
[#] wg set wg0 fwmark 51820
[#] ip -4 rule add not fwmark 51820 table 51820
[#] ip -4 rule add table main suppress_prefixlength 0
[#] ip -4 route add 0.0.0.0/0 dev wg0 table 51820
[#] sysctl -q net.ipv4.conf.all.src_valid_mark=1
[#] nft -f /dev/fd/63
```

This `wg-quick` does more than it did in lesson 4, because a default route through the tunnel has a
trap in it. The tunnel's own packets, the encrypted UDP to `hq`, would be routed into the tunnel too, and
go round in a circle. The lines after `mtu 1420` are how it avoids that. WireGuard marks its own outgoing
packets with `fwmark 51820`. **Every packet without the mark is looked up in a separate table, 51820,
whose only route is a default through `wg0`**, while the marked ones use the ordinary table and leave by
`eth0`. `suppress_prefixlength 0` lets the ordinary table still decide anything more specific than a
default route, which keeps the home LAN reachable. The `nft` line loads firewall rules that `wg-quick`
does not print.

```
ana@remote:~$ ip route get 192.0.2.21
192.0.2.21 dev wg0 table 51820 src 10.20.0.3 uid 1001 
    cache 
ana@remote:~$ traceroute -n -q 1 192.0.2.21
traceroute to 192.0.2.21 (192.0.2.21), 30 hops max, 60 byte packets
 1  10.20.0.1  1.048 ms
 2  203.0.113.1  1.267 ms
 3  192.0.2.21  1.278 ms
ana@remote:~$ curl -s http://192.0.2.21/
served by web1
ana@web1:~$ tail -n 2 /lab/web1/www/logs/access.log | cut -d" " -f1-7
198.51.100.77 - - [28/Sep/2026:18:09:20 -0300] "GET /
203.0.113.2 - - [28/Sep/2026:18:09:20 -0300] "GET /
```

Now the route to `web1` is `dev wg0 table 51820`, and the traceroute goes to `hq` first, `10.20.0.1`,
then out to the ISP from the head office. The page is the same. The last two lines of `web1`'s access
log are the two requests, made in the same second: **the same laptop and the same page, and `web1` saw
two different clients.** Split, the request came from `198.51.100.77`, Ana's home router. Full, it came
from `203.0.113.2`, because `hq` forwarded her traffic to the internet and translated it to its own
address (NAT, lesson 11 of `networks-addressing`).

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 245\" role=\"img\" aria-label=\"Five machines: remote at 192.168.1.50, homegw at 198.51.100.77, the ISP router at 203.0.113.1, web1 at 192.0.2.21, and hq at 203.0.113.2 above the ISP. The split path runs remote, homegw, ISP, web1, and web1 logs 198.51.100.77. The full path runs from remote through a dashed tunnel to hq, then from hq back through the ISP to web1, and web1 logs 203.0.113.2.\"><defs><marker id=\"pa-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"150\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">remote</text><text x=\"85.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.1.50</text><rect x=\"180\" y=\"150\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"245.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">homegw</text><text x=\"245.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">198.51.100.77</text><rect x=\"370\" y=\"150\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"435.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">isp</text><text x=\"435.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">203.0.113.1</text><rect x=\"600\" y=\"150\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"665.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">web1</text><text x=\"665.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.21</text><rect x=\"370\" y=\"40\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"435.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hq</text><text x=\"435.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">203.0.113.2</text><path d=\"M150 170 L180 170\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M310 170 L370 170\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M500 170 L600 170\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M435 80 L435 150\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M85 196 L 85 214 L 665 214 L 665 196\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#pa-ah)\"></path><text x=\"375\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">split: web1 logs 198.51.100.77</text><path d=\"M85 150 C 85 60, 250 60, 366 60\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" stroke-dasharray=\"6 4\" marker-end=\"url(#pa-ah)\"></path><text x=\"150\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">tunnel</text><path d=\"M455 80 L 455 146\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#pa-ah)\"></path><path d=\"M500 162 L 596 162\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#pa-ah)\"></path><text x=\"470\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">full: web1 logs 203.0.113.2</text></svg>", "caption": "The same request to web1, split and full. The full tunnel's packets still cross homegw and the ISP, encrypted inside the tunnel, and then cross the ISP a second time on their way out of hq."}
```

That second address is most of the case for a full tunnel. The company's firewall, filtering and logs
apply to everything she does. A service that accepts only the office's address works from her kitchen.
On a café's Wi-Fi her traffic crosses the café's network encrypted, provided her DNS goes the same way,
and the next section shows that this is not automatic. The cost is the path in the figure: **every video call and every download crosses the head office's internet link twice**, in
and out. When that link fails, she loses the internet as well as the office.

A split tunnel is the opposite trade. The head office carries only its own traffic and her calls go
straight out, but whatever else she does is outside the company's view, and so is the rest of the
network her laptop sits on. Many companies split, and send a short list of sensitive destinations
through the tunnel by adding them to the list.
