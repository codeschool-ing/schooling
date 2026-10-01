---
title: What the provider sees of the tunnel
version: 1
---

A VPN is trusted with traffic that crosses somebody else's network, so it deserves to be checked
rather than believed. The check is simple: **listen on the provider's cable while the tunnel is in
use**, and then listen inside the tunnel, and compare.

## On the provider's cable

On `isp`, `tcpdump` was left listening on `eth0`, the cable to the head office, for four packets.
Meanwhile pc1 pinged pc2 twice; the ping finished first, so its output is printed first, and
tcpdump's after it:

```
ana@pc1:~$ ping -c 2 10.30.10.22
PING 10.30.10.22 (10.30.10.22) 56(84) bytes of data.
64 bytes from 10.30.10.22: icmp_seq=1 ttl=62 time=31.6 ms
64 bytes from 10.30.10.22: icmp_seq=2 ttl=62 time=5.89 ms

--- 10.30.10.22 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1004ms
rtt min/avg/max/mdev = 5.885/18.728/31.571/12.843 ms
root@isp:~# timeout 6 tcpdump -n -c 4 -i eth0
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
15:21:22.930237 IP 203.0.113.2.51820 > 198.51.100.2.51820: UDP, length 128
15:21:22.941353 IP 198.51.100.2.51820 > 203.0.113.2.51820: UDP, length 128
15:21:23.916676 IP 203.0.113.2.51820 > 198.51.100.2.51820: UDP, length 128
15:21:23.918704 IP 198.51.100.2.51820 > 203.0.113.2.51820: UDP, length 128
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

Four packets for two pings: two echo requests and two replies. This is everything the provider
learned about them:

- **two public addresses**, `203.0.113.2` and `198.51.100.2` — the two offices' routers;
- **one port**, 51820 at both ends, and the protocol, UDP;
- **a size**, `length 128`, the same for every packet;
- **the times**, `15:21:22.930237` for the first and `15:21:22.941353` for its answer.

Not in the list: pc1, pc2, their private addresses, the word ICMP, or any byte of what the ping
carried. The provider cannot tell a ping from a file transfer except by the sizes and the rhythm.

## Inside the tunnel

The same listening, this time on `rhq`'s `wg0` — the tunnel's end inside the head office — while pc1
pings again:

```
ana@pc1:~$ ping -c 2 10.30.10.22
PING 10.30.10.22 (10.30.10.22) 56(84) bytes of data.
64 bytes from 10.30.10.22: icmp_seq=1 ttl=62 time=5.08 ms
64 bytes from 10.30.10.22: icmp_seq=2 ttl=62 time=4.62 ms

--- 10.30.10.22 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 4.622/4.850/5.079/0.228 ms
root@rhq:~# timeout 6 tcpdump -n -c 4 -i wg0
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on wg0, link-type RAW (Raw IP), snapshot length 262144 bytes
15:21:27.606623 IP 10.20.10.21 > 10.30.10.22: ICMP echo request, id 56, seq 1, length 64
15:21:27.610556 IP 10.30.10.22 > 10.20.10.21: ICMP echo reply, id 56, seq 1, length 64
15:21:28.608540 IP 10.20.10.21 > 10.30.10.22: ICMP echo request, id 56, seq 2, length 64
15:21:28.612236 IP 10.30.10.22 > 10.20.10.21: ICMP echo reply, id 56, seq 2, length 64
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

**Here everything is in clear**: `10.20.10.21 > 10.30.10.22: ICMP echo request`, sequence numbers,
lengths. `link-type RAW (Raw IP)` says there is not even an Ethernet header: `wg0` carries bare IP
packets, because a tunnel has no MAC addresses to put in one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Two rows of boxes, drawn to scale in bytes. The top row is one packet as isp sees it: an IP header of 20 bytes from 203.0.113.2 to 198.51.100.2, a UDP header of 8 bytes from port 51820 to port 51820, then the 128 bytes UDP carries: a WireGuard header of 16 bytes, 96 encrypted bytes and a 16-byte authentication tag. The bottom row is the same packet as rhq's wg0 sees it, under the encrypted part: an IP header of 20 bytes from 10.20.10.21 to 10.30.10.22, an ICMP header of 8 bytes and 56 bytes of data, 84 in all, plus 12 bytes of padding that make it 96.\"><text x=\"24\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">What tcpdump on isp printed for one packet:</text><text x=\"24\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">IP 203.0.113.2.51820 &gt; 198.51.100.2.51820: UDP, length 128</text><rect x=\"24.0\" y=\"74\" width=\"86.0\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"67.0\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">IP</text><text x=\"67.0\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><rect x=\"110.0\" y=\"74\" width=\"34.4\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"127.2\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UDP</text><text x=\"127.2\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><rect x=\"144.4\" y=\"74\" width=\"68.8\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"178.8\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">header</text><text x=\"178.8\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16</text><rect x=\"213.2\" y=\"74\" width=\"412.8\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"419.6\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">encrypted: the packet below, padded</text><text x=\"419.6\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">96</text><rect x=\"626.0\" y=\"74\" width=\"68.8\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"660.4\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tag</text><text x=\"660.4\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16</text><path d=\"M144.4 62 L144.4 56 L694.8 56 L694.8 62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"419.6\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">length 128: what UDP carries</text><path d=\"M213.2 118 L213.2 164\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M626.0 118 L626.0 164\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"213.2\" y=\"164\" width=\"86.0\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"256.2\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">IP</text><text x=\"256.2\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><rect x=\"299.2\" y=\"164\" width=\"34.4\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"316.4\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ICMP</text><text x=\"316.4\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><rect x=\"333.6\" y=\"164\" width=\"240.8\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"454.0\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">data</text><text x=\"454.0\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">56</text><rect x=\"574.4\" y=\"164\" width=\"51.6\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"600.2\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+12</text><text x=\"213.2\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">What tcpdump on rhq's wg0 printed for the same packet:</text><text x=\"213.2\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">IP 10.20.10.21 &gt; 10.30.10.22: ICMP echo request</text></svg>", "caption": "One ping, twice. The 84-byte packet pc1 sent is padded to 96 bytes and encrypted; WireGuard adds 16 bytes in front and a 16-byte tag behind, which is the 128 that tcpdump printed on isp. Only the two outer headers can be read on the way."}
```

The 128 bytes are not a mystery. The packet pc1 sent is 84 bytes: a 20-byte IP header, an 8-byte ICMP
header and the 56 bytes of data that `56(84)` announced on the ping's first line. WireGuard pads it to
96 and encrypts it, puts a 16-byte header of its own in front and a 16-byte authentication tag behind:
16 + 96 + 16 = 128. A larger packet produces a larger datagram, so **the size is one of the things a
VPN does not hide**.

## What encryption protects, and from whom

**The tunnel protects the traffic from the path, not from the ends.** The provider, and anybody
listening on any cable between the two routers, sees the first capture. Anybody who controls `rhq`,
`rbr`, pc1 or pc2 sees the second. So a VPN is the right answer to "the provider's network is not
ours", and no answer at all to "somebody has a shell on our router".

What the path still learns is worth saying plainly, because it is the part people forget: **which
two sites talk, when, and how much**. That is called metadata, and on a link between a head office
and a branch it is mostly harmless. On a remote-access VPN it tells the network carrying it where
a person was and when they worked.

Two habits follow for a support person:

- **Test a tunnel from the outside as well as the inside.** A ping that works shows the tunnel
  carries traffic. A capture on the outside interface shows it carries *only* encrypted traffic — and
  a capture that showed ICMP between private addresses on the provider's side would mean the traffic
  was going round the tunnel, not through it.
- **Protect the ends.** The keys live on the routers, and lesson 6 adds the rest: a router whose
  configuration nobody wrote down is a router nobody can rebuild.
