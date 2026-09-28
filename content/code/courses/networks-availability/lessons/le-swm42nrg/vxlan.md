---
title: A layer 2 VPN with VXLAN
version: 1
---

Every tunnel so far joined two networks: a subnet at each end and a router between them, so a packet
from the laptop to the till lost a hop of TTL at each router. **A layer 2 VPN joins two ends into one
Ethernet segment instead**: one subnet, one broadcast domain, machines at both ends that reach each
other by MAC address as if they shared a switch.

VXLAN, Virtual eXtensible LAN, does it by carrying whole Ethernet frames inside UDP, port 4789, with an
8-byte header whose main field is a 24-bit network identifier, the **VNI**. Where a VLAN tag,
lesson 19 of `networks-addressing`, has 12 bits and about four thousand values, a VNI has about sixteen
million. Unlike GRE, this lab's kernel has it, so the tunnel is the kernel's own. On `hq`:

```
ana@hq:~$ sudo ip link add vx0 type vxlan id 100 local 203.0.113.2 remote 198.51.100.2 dstport 4789 dev eth1
ana@hq:~$ sudo ip addr add 172.16.0.1/24 dev vx0 && sudo ip link set vx0 up
ana@hq:~$ ip link show vx0
4: vx0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/ether ca:2e:ce:6e:53:49 brd ff:ff:ff:ff:ff:ff
```

`vx0` is an Ethernet interface, with a MAC address of its own and `BROADCAST` among its flags, which
no tunnel in the earlier lessons had. `branch` got the mirror image, with `172.16.0.2`, as root and not
shown. **Its MTU is 1450, and the figure below says where the other 50 bytes go.** Then `hq` pinged
the far end, and the ISP's router captured the tunnel with `-e`, which prints the Ethernet addresses:

```
ana@hq:~$ ping -c 1 172.16.0.2
PING 172.16.0.2 (172.16.0.2) 56(84) bytes of data.
64 bytes from 172.16.0.2: icmp_seq=1 ttl=64 time=1.27 ms

--- 172.16.0.2 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.266/1.266/1.266/0.000 ms
ana@isp:~$ sudo tcpdump -n -t -e -i eth0 -c 4 udp port 4789
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
52:54:00:00:71:02 > 52:54:00:00:71:01, ethertype IPv4 (0x0800), length 92: 203.0.113.2.57530 > 198.51.100.2.4789: VXLAN, flags [I] (0x08), vni 100
ca:2e:ce:6e:53:49 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 172.16.0.2 tell 172.16.0.1, length 28
52:54:00:00:71:01 > 52:54:00:00:71:02, ethertype IPv4 (0x0800), length 92: 198.51.100.2.57530 > 203.0.113.2.4789: VXLAN, flags [I] (0x08), vni 100
96:6b:a3:79:75:aa > ca:2e:ce:6e:53:49, ethertype ARP (0x0806), length 42: Reply 172.16.0.2 is-at 96:6b:a3:79:75:aa, length 28
52:54:00:00:71:02 > 52:54:00:00:71:01, ethertype IPv4 (0x0800), length 148: 203.0.113.2.47755 > 198.51.100.2.4789: VXLAN, flags [I] (0x08), vni 100
ca:2e:ce:6e:53:49 > 96:6b:a3:79:75:aa, ethertype IPv4 (0x0800), length 98: 172.16.0.1 > 172.16.0.2: ICMP echo request, id 26447, seq 1, length 64
52:54:00:00:71:01 > 52:54:00:00:71:02, ethertype IPv4 (0x0800), length 148: 198.51.100.2.47755 > 203.0.113.2.4789: VXLAN, flags [I] (0x08), vni 100
96:6b:a3:79:75:aa > ca:2e:ce:6e:53:49, ethertype IPv4 (0x0800), length 98: 172.16.0.2 > 172.16.0.1: ICMP echo reply, id 26447, seq 1, length 64
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

Four packets, each printed as two lines: the outer frame, from `hq`'s real interface to the ISP's
router, and the frame inside it. **The first one carried an ARP broadcast**, `ff:ff:ff:ff:ff:ff`, asking
who has `172.16.0.2`; `branch` answered it, and the ping and its reply followed. A broadcast crossing
an ISP is exactly what no earlier tunnel could do, and it is what makes the two ends one segment. The
reply's `ttl=64` says the same: no router stood between the two ends, as far as the inner packet could
tell.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 198\" role=\"img\" aria-label=\"One frame drawn as a row of headers, the captured ping of 148 bytes: an outer Ethernet header of 14 bytes, an outer IP header of 20, UDP to port 4789 of 8, a VXLAN header of 8, then hq&#x27;s own frame of 98 bytes unchanged, an inner Ethernet header of 14 and the IP packet with its ICMP message of 84. The outer IP packet, from the outer IP header to the end, is 134 bytes, and it is what the link&#x27;s MTU of 1500 counts. The outer IP, UDP, VXLAN and inner Ethernet headers are 50 bytes in front of the inner IP packet, so the inner packet may be at most 1500 minus 50, 1450 bytes.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">The captured ping through vx0: a 148-byte frame on the wire</text><rect x=\"20\" y=\"64\" width=\"104\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"72.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">outer Ethernet</text><text x=\"72.0\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">14 bytes</text><rect x=\"128\" y=\"64\" width=\"84\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">outer IP</text><text x=\"170.0\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20 bytes</text><rect x=\"216\" y=\"64\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"256.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UDP 4789</text><text x=\"256.0\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8 bytes</text><rect x=\"300\" y=\"64\" width=\"70\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"335.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">VXLAN</text><text x=\"335.0\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8 bytes</text><rect x=\"374\" y=\"64\" width=\"104\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"426.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">inner Ethernet</text><text x=\"426.0\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">14 bytes</text><rect x=\"482\" y=\"64\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"572.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">IP + ICMP</text><text x=\"572.0\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">84 bytes</text><path d=\"M374 61 L374 56 L662 56 L662 61\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"518.0\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hq's own frame, 98 bytes, unchanged</text><path d=\"M128 111 L128 116 L662 116 L662 111\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"395.0\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the outer IP packet, 134 bytes: what the link's MTU of 1500 counts</text><path d=\"M128 143 L128 148 L478 148 L478 143\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"303.0\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50 bytes in front of the inner IP packet: 1500 − 50 = 1450</text><rect x=\"20\" y=\"177\" width=\"14\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"40\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">added by VXLAN</text><rect x=\"190\" y=\"177\" width=\"14\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"210\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the frame vx0 sent</text></svg>", "caption": "The overhead is 50 bytes whichever way it is counted: 148 − 98 on the wire, 134 − 84 as IP. The inner Ethernet header is why the MTU of vx0 is 1450 and not 1464."}
```

The last command shows how `vx0` knows where to send a frame:

```
ana@hq:~$ ip neigh show dev vx0; bridge fdb show dev vx0
172.16.0.2 lladdr 96:6b:a3:79:75:aa REACHABLE 
96:6b:a3:79:75:aa dst 198.51.100.2 self 
00:00:00:00:00:00 dst 198.51.100.2 via eth1 self permanent
```

The forwarding table is a switch's MAC table, lesson 18 of `networks-addressing`, with one difference:
**each entry points not at a port but at the public address of the other end.** `96:6b:a3:79:75:aa` was
learnt from the reply and lives behind `198.51.100.2`. The all-zeros entry is where a broadcast or an
unknown destination goes, the flood list; with more sites there would be one such line per site, and a
broadcast would be copied to each of them.

**Nothing in any of this is encrypted.** The ISP read the ARP request and the ping as easily as it read
lesson 1's GRE. VXLAN was built for data centres, over links the operator owns; across a network you do
not control it goes inside IPsec or another encrypted tunnel, and pays both overheads.
