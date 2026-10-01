---
title: The 802.1Q tag, four bytes in the header
version: 1
---

The mark a trunk puts on a frame is defined by the IEEE standard **802.1Q**, and it is small
enough to see whole. sw1 listened on p24 while pc1 pinged pc3 and pc2 pinged pc4; the capture
ended after both pings, so its output comes last:

```
ana@pc1:~$ ping -c 1 -q 10.20.10.23
PING 10.20.10.23 (10.20.10.23) 56(84) bytes of data.

--- 10.20.10.23 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 3.085/3.085/3.085/0.000 ms
ana@pc2:~$ ping -c 1 -q 10.20.20.24
PING 10.20.20.24 (10.20.20.24) 56(84) bytes of data.

--- 10.20.20.24 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 1.306/1.306/1.306/0.000 ms
root@sw1:~# timeout 8 tcpdump -n -e -i p24 -c 4 icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on p24, link-type EN10MB (Ethernet), snapshot length 262144 bytes
09:00:36.437905 02:25:70:bc:29:c6 > 02:d9:6b:02:17:20, ethertype 802.1Q (0x8100), length 102: vlan 10, p 0, ethertype IPv4 (0x0800), 10.20.10.21 > 10.20.10.23: ICMP echo request, id 89, seq 1, length 64
09:00:36.438786 02:d9:6b:02:17:20 > 02:25:70:bc:29:c6, ethertype 802.1Q (0x8100), length 102: vlan 10, p 0, ethertype IPv4 (0x0800), 10.20.10.23 > 10.20.10.21: ICMP echo reply, id 89, seq 1, length 64
09:00:37.346964 02:fd:f2:d2:63:ba > 02:25:46:c1:26:7d, ethertype 802.1Q (0x8100), length 102: vlan 20, p 0, ethertype IPv4 (0x0800), 10.20.20.22 > 10.20.20.24: ICMP echo request, id 90, seq 1, length 64
09:00:37.347183 02:25:46:c1:26:7d > 02:fd:f2:d2:63:ba, ethertype 802.1Q (0x8100), length 102: vlan 20, p 0, ethertype IPv4 (0x0800), 10.20.20.24 > 10.20.20.22: ICMP echo reply, id 90, seq 1, length 64
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

Read the first frame from left to right. The source is `02:25:70:bc:29:c6`, pc1, and the
destination `02:d9:6b:02:17:20`, pc3. Where an untagged frame would say what it carries, this one
says `ethertype 802.1Q (0x8100)`, then `vlan 10, p 0`, and only then `ethertype IPv4 (0x0800)` and
the IP packet. The frame is 102 bytes long. The two frames from pc2 carry `vlan 20` and are 102
bytes as well.

Now the same conversation where it arrives, on pc3's access port:

```
ana@pc1:~$ ping -c 1 -q 10.20.10.23
PING 10.20.10.23 (10.20.10.23) 56(84) bytes of data.

--- 10.20.10.23 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.696/1.696/1.696/0.000 ms
root@pc3:~# timeout 6 tcpdump -n -e -i eth0 -c 2 icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
09:00:41.501029 02:25:70:bc:29:c6 > 02:d9:6b:02:17:20, ethertype IPv4 (0x0800), length 98: 10.20.10.21 > 10.20.10.23: ICMP echo request, id 91, seq 1, length 64
09:00:41.501768 02:d9:6b:02:17:20 > 02:25:70:bc:29:c6, ethertype IPv4 (0x0800), length 98: 10.20.10.23 > 10.20.10.21: ICMP echo reply, id 91, seq 1, length 64
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

The same two MAC addresses, no `802.1Q`, no `vlan`, and a length of 98. **102 − 98 = 4: the tag
is four bytes, added by sw1 as the frame goes onto the trunk and removed by sw2 before the frame
goes out of an access port.** pc1 and pc3 never see it, which is why nothing on either PC had to
change.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"The same frame in two forms, then the tag bit by bit. Untagged, on pc3&#x27;s access port, 98 bytes: destination MAC, 6 bytes; source MAC, 6 bytes; EtherType 0x0800 for IPv4, 2 bytes; the IP packet, 84 bytes. Tagged, on the trunk p24, 102 bytes: destination MAC; source MAC; then the 4-byte tag, made of TPID 0x8100 and TCI, 2 bytes each; then EtherType 0x0800 and the IP packet. The tag, bit by bit: TPID, 16 bits, in the place where the EtherType would be; PCP, 3 bits, priority 0 to 7; DEI, 1 bit, drop first under congestion; VID, 12 bits, the VLAN number from 1 to 4094.\"><defs><marker id=\"v19g-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">untagged, on pc3's access port: 98 bytes</text><rect x=\"20\" y=\"24\" width=\"120\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80.0\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">dst MAC</text><text x=\"80.0\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">6 bytes</text><rect x=\"140\" y=\"24\" width=\"120\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"200.0\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">src MAC</text><text x=\"200.0\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">6 bytes</text><rect x=\"260\" y=\"24\" width=\"100\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310.0\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0x0800</text><text x=\"310.0\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">type: IPv4</text><rect x=\"360\" y=\"24\" width=\"340\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"530.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">IP packet, 84 bytes</text><text x=\"20\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tagged, on the trunk p24: 102 bytes</text><text x=\"350\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the tag: 4 bytes</text><rect x=\"20\" y=\"100\" width=\"120\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80.0\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">dst MAC</text><text x=\"80.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">6 bytes</text><rect x=\"140\" y=\"100\" width=\"120\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"200.0\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">src MAC</text><text x=\"200.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">6 bytes</text><rect x=\"260\" y=\"100\" width=\"90\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"305.0\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">TPID</text><text x=\"305.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0x8100</text><rect x=\"350\" y=\"100\" width=\"90\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"395.0\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">TCI</text><text x=\"395.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2 bytes</text><rect x=\"440\" y=\"100\" width=\"100\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"490.0\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0x0800</text><text x=\"490.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">type: IPv4</text><rect x=\"540\" y=\"100\" width=\"160\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"620.0\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">IP packet, 84 bytes</text><line x1=\"260\" y1=\"138\" x2=\"60\" y2=\"188\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"440\" y1=\"138\" x2=\"660\" y2=\"188\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the tag, bit by bit</text><rect x=\"60\" y=\"188\" width=\"220\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">TPID</text><text x=\"170.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">16 bits</text><rect x=\"280\" y=\"188\" width=\"120\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"340.0\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PCP</text><text x=\"340.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 bits</text><rect x=\"400\" y=\"188\" width=\"100\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">DEI</text><text x=\"450.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 bit</text><rect x=\"500\" y=\"188\" width=\"160\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"580.0\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">VID</text><text x=\"580.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">12 bits</text><text x=\"170\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">where the EtherType was</text><text x=\"340\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">priority 0 to 7</text><text x=\"450\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">drop first</text><text x=\"580\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">VLAN 1 to 4094</text></svg>", "caption": "The same ping frame on an access port and on the trunk. The switch inserts four bytes after the source address and removes them again before the frame reaches a PC."}
```

The four bytes are two fields of two bytes each. The first is the **TPID** (*tag protocol
identifier*), always `0x8100`, and it sits exactly where an untagged frame keeps its EtherType.
That placement is deliberate: a device that knows nothing about VLANs reads `0x8100` as a protocol
it does not carry and drops the frame, instead of misreading the tag as the start of an IP packet.

The second is the **TCI** (*tag control information*), sixteen bits divided three ways:

- PCP (*priority code point*), three bits of priority, 0 to 7. It is the `p 0` in tcpdump's line, and it is how a
  voice VLAN's frames can ask to be served before a file transfer's. Every frame in this lab
  carries 0, because nothing asked for anything else.
- DEI (*drop eligible indicator*), one bit saying the frame may be dropped first when a link is congested.
- VID (*VLAN identifier*), twelve bits holding the VLAN number: the `vlan 10` and `vlan 20` above.

**Twelve bits give 4096 values, and two are reserved**: 0 means the frame carries a priority and
no VLAN, and 4095 is kept by the standard. That leaves 4094 usable VLANs, numbered 1 to 4094, and
it is a hard ceiling for any network built on this tag. Networks that need more — a provider
keeping its customers' VLANs apart, a data centre with thousands of tenants — stack a second tag
(IEEE 802.1ad, often called QinQ) or carry a longer number in another header such as VXLAN's 24
bits. Neither runs in this lab.

Two consequences of adding bytes to a frame are worth knowing. Ethernet's largest frame grew from
1518 to 1522 bytes to make room for the tag, so a device on a trunk has to accept frames four bytes
longer than an access port ever delivers. And the frame's checksum at the end covers every byte,
so the switch recomputes it each time it adds or removes a tag; tcpdump on Linux does not show the
checksum, which is why the lengths above are 98 and 102 and not four bytes more.
