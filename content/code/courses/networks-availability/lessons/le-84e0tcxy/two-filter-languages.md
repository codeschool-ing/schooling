---
title: Two filters, two languages
version: 1
---

**Wireshark has two filters, they speak different languages, and they act at different moments.**
Most of the confusion about capturing comes from treating them as one.

The capture filter acts on the wire, before anything is saved. It is written in BPF, the language of
the libpcap library, which is also what `tcpdump` speaks: `host 192.0.2.21`, `tcp port 80`,
`not arp`. It knows addresses, ports, protocols and byte offsets, and nothing about what HTTP or DNS
mean. **A packet it rejects is never recorded**, and nothing can bring it back afterwards.

The display filter acts on packets already captured, in memory or in a file. It is Wireshark's own
language, made of the names of the fields its dissectors decode: `ip.addr == 192.0.2.21`,
`tcp.port == 80`, `http.response.code >= 400`. **It hides packets and deletes none**; clear it and
they are all back.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 790 186\" role=\"img\" aria-label=\"A pipeline from left to right: the wire, then the capture filter, written in BPF as in tcpdump and given with -f, then the file files.pcap, then the display filter, written with Wireshark field names and given with -Y, then the screen. What the capture filter rejects is never recorded; what the display filter rejects is hidden and still in the file.\"><defs><marker id=\"fl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"60\" width=\"100\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"70.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the wire</text><rect x=\"160\" y=\"60\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"235.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">capture filter</text><text x=\"235.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">-f \"tcp port 80\"</text><rect x=\"350\" y=\"60\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"405.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">files.pcap</text><rect x=\"500\" y=\"60\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">display filter</text><text x=\"575.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">-Y \"http.request\"</text><rect x=\"690\" y=\"60\" width=\"80\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"730.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">screen</text><path d=\"M120 85 L160 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah)\"></path><path d=\"M310 85 L350 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah)\"></path><path d=\"M460 85 L500 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah)\"></path><path d=\"M650 85 L690 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah)\"></path><text x=\"235\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">BPF, as in tcpdump</text><text x=\"575\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Wireshark field names</text><path d=\"M235 110 L235 136\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah)\"></path><text x=\"235\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">what it rejects</text><text x=\"235\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">is never recorded</text><path d=\"M575 110 L575 136\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah)\"></path><text x=\"575\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">what it rejects is hidden</text><text x=\"575\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">and still in the file</text></svg>", "caption": "The same two filters exist in the window and in tshark, at the same two places. Only the first one can lose a packet for good."}
```

| | capture filter | display filter |
|---|---|---|
| language | BPF, as in `tcpdump` | Wireshark's field names |
| acts | before saving | after, on what was saved |
| what it drops | is gone | is hidden, still in the file |
| in `tshark` | `-f` | `-Y` |
| in the window | capture options, before Start | the bar above the packet list |
| one host | `host 192.0.2.21` | `ip.addr == 192.0.2.21` |
| one port | `tcp port 80` | `tcp.port == 80` |
| understands HTTP | no | yes |

The file from the last section, asked six questions:

```
ana@mon:~$ tshark -r files.pcap -Y dns
   11 0.008987287 192.168.10.10 → 192.0.2.53   DNS 98 Standard query 0x9ce1 A www.example.com OPT
   12 0.009225585   192.0.2.53 → 192.168.10.10 DNS 130 Standard query response 0x9ce1 A www.example.com A 192.0.2.80 OPT
   13 0.028355971 192.168.10.10 → 192.0.2.53   DNS 101 Standard query 0x7429 A nosuch.example.com OPT
   14 0.028578484   192.0.2.53 → 192.168.10.10 DNS 167 Standard query response 0x7429 No such name A nosuch.example.com SOA ns.example.com OPT
ana@mon:~$ tshark -r files.pcap -Y "http.request"
    4 0.000137514 192.168.10.10 → 192.0.2.21   HTTP 139 GET / HTTP/1.1 
   39 1.105093152 192.168.10.10 → 192.0.2.23   HTTP 151 GET /nothing-here HTTP/1.1 
ana@mon:~$ tshark -r files.pcap -Y "http.response.code >= 400"
   41 1.105425089   192.0.2.23 → 192.168.10.10 HTTP 360 HTTP/1.1 404 Not Found  (text/html)
ana@mon:~$ tshark -r files.pcap -Y "tcp.flags.syn == 1 && tcp.flags.ack == 0"
    1 0.000000000 192.168.10.10 → 192.0.2.21   TCP 74 59928 → 80 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=3641093702 TSecr=0 WS=1024
   19 1.068646331 192.168.10.10 → 192.0.2.21   TCP 74 51132 → 443 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=1132118576 TSecr=0 WS=1024
   36 1.104894905 192.168.10.10 → 192.0.2.23   TCP 74 47586 → 80 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=327870121 TSecr=0 WS=1024
ana@mon:~$ tshark -r files.pcap -Y "icmp && ip.dst == 192.0.2.22"
   15 0.041952556 192.168.10.10 → 192.0.2.22   ICMP 98 Echo (ping) request  id=0x0ccf, seq=1/256, ttl=64
   17 1.062237869 192.168.10.10 → 192.0.2.22   ICMP 98 Echo (ping) request  id=0x0ccf, seq=2/512, ttl=64
ana@mon:~$ tshark -r files.pcap -Y "tls.handshake.type == 1" -T fields -e ip.dst -e tls.handshake.extensions_server_name
192.0.2.21	www.example.com
```

Each of those is something a capture filter could not have asked. `dns` found all four lookup
packets, and frame 14 already says `No such name` for `nosuch.example.com`. `http.request` found the
two requests by what they are, and `http.response.code >= 400` found the one that failed, a 404 from
`web3`; to BPF each of them was only a TCP segment with bytes in it. A SYN without an ACK is a
connection being opened, and there were three: `web1` on 80 and 443, and `web3` on 80.

The last one prints two fields instead of a summary line, and what it found deserves a second look.
**The name of the HTTPS site, `www.example.com`, crossed the wire in clear text**, in the Client
Hello, although everything after it is encrypted. Lesson 13 opens that handshake.

**The working rule is to capture wide and display narrow.** Give the capture a simple filter that
only removes what you are sure you will not need, like `not arp` above, or `not port 22` so as not to
record your own SSH session. Then filter the display as many times as the question changes. A
capture filter that was too narrow costs a second capture, and the fault may not happen again while
you wait for it.
