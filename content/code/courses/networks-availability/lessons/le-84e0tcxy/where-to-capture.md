---
title: Where to put the capture
version: 1
---

The usual picture is that any machine on an office network can watch the office's traffic, if it
only runs the right program. **On a switched network it cannot.** A switch learns which MAC address
sits behind which port, as lesson 18 of `networks-addressing` showed, and sends a unicast frame out of
that one port and no other. A laptop on the next port sees its own traffic, the broadcasts, and very
little else.

The lab shows it. `files` fetched a page from `web1` while `laptop`, on the same switch, captured
everything to or from `files` for five seconds:

```
ana@laptop:~$ sudo timeout 5 tcpdump -n -i eth0 host 192.168.10.10 and not host 192.168.10.20
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
18:09:32.323256 ARP, Request who-has 192.168.10.1 tell 192.168.10.10, length 28

1 packet captured
1 packet received by filter
0 packets dropped by kernel
```

**One packet in five seconds, and it was a broadcast.** `files` asked who has `192.168.10.1`, its
gateway, and an ARP request goes out of every port. The HTTP request and the page that came back
travelled between the port of `files` and the port of `hq`, and the switch never copied them to the
laptop's.

## Three places that do see the traffic

**A mirror port**, which Cisco calls SPAN, is a switch setting that copies every frame of one port,
or of a whole VLAN, out of another port where an analyser listens. The lab's switch was set to mirror
the port of `files` to `mon`, a machine with one interface and no IP address, and the same request
was made again:

```
ana@mon:~$ tshark -n -i eth0 -c 6 -f "tcp port 80"
Capturing on 'eth0'
6 packets captured
    1 0.000000000 192.168.10.10 → 192.0.2.21   TCP 74 59920 → 80 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=1038947159 TSecr=0 WS=1024
    2 0.000077141   192.0.2.21 → 192.168.10.10 TCP 74 80 → 59920 [SYN, ACK] Seq=0 Ack=1 Win=65160 Len=0 MSS=1460 SACK_PERM TSval=3565941641 TSecr=1038947159 WS=1024
    3 0.000092290 192.168.10.10 → 192.0.2.21   TCP 66 59920 → 80 [ACK] Seq=1 Ack=1 Win=64512 Len=0 TSval=1038947159 TSecr=3565941641
    4 0.000160803 192.168.10.10 → 192.0.2.21   HTTP 139 GET / HTTP/1.1 
    5 0.000172681   192.0.2.21 → 192.168.10.10 TCP 66 80 → 59920 [ACK] Seq=1 Ack=74 Win=65536 Len=0 TSval=3565941641 TSecr=1038947159
    6 0.000388243   192.0.2.21 → 192.168.10.10 HTTP 309 HTTP/1.1 200 OK  (text/html)
```

This time `mon` saw the whole conversation: the three packets that open the connection, the `GET`,
the acknowledgement and the `200 OK`. **`mon` needs no address to do it**, because it never takes
part in anything; it reads copies. That is also why an analyser on a mirror port is invisible to the
machines it watches.

**A tap** is a small device put in the cable itself. It passes the traffic through and copies both
directions to a monitoring port, whatever the switch is configured to do. It costs money and a moment
of downtime to insert, and it is the answer when a mirror port cannot be trusted to be complete. The
lab has no tap, so this one is described and not shown.

**On the host itself** is the third place, and often the simplest: capture on the server that is
misbehaving, where every packet it sends or receives crosses its own interface. That is lesson 12,
with `tcpdump` on `web1`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"A switch with four machines. Above it, files at 192.168.10.10 and hq at 192.168.10.1, joined through the switch by the HTTP conversation, which uses only those two ports. Below it, laptop at 192.168.10.20, which saw one ARP broadcast in five seconds, and mon, with no address, on a mirror port that receives a copy of every frame of the port of files.\"><defs><marker id=\"wh-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"wh-ph\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"60\" y=\"20\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"135.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">files</text><text x=\"135.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.10.10</text><rect x=\"460\" y=\"20\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"535.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hq</text><text x=\"535.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.10.1</text><rect x=\"60\" y=\"124\" width=\"550\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"335\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">switch</text><rect x=\"60\" y=\"230\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"135\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">mon</text><text x=\"135\" y=\"261\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no address</text><rect x=\"460\" y=\"230\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"535.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">laptop</text><text x=\"535.0\" y=\"261.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.10.20</text><path d=\"M135 66 L135 124\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M535 66 L535 124\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M135 174 L135 230\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M535 174 L535 230\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M165 70 L165 122\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#wh-am)\"></path><path d=\"M505 122 L505 70\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#wh-am)\"></path><path d=\"M105 176 L105 228\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#wh-ph)\"></path><text x=\"335\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">HTTP: only the port of files and the port of hq</text><text x=\"335\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">forwards by MAC address, from the port of files to the port of hq</text><text x=\"222\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">mirror port: a copy of</text><text x=\"222\" y=\"261\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">every frame of files</text><text x=\"622\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">saw one ARP</text><text x=\"622\" y=\"261\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">broadcast in 5 s</text></svg>", "caption": "The two captures of the first section. A switch delivers a unicast frame to one port, so the laptop saw only the broadcast; the mirror port hands mon a copy of everything files sends and receives."}
```

A mirror port has one limit to know before trusting it. **It copies into one port of fixed speed.**
Mirror a busy 10 Gbit/s uplink to a 1 Gbit/s port and the switch drops the copies it has no room
for. The capture then looks as if packets went missing on the network when they went missing on
the way to the analyser.
