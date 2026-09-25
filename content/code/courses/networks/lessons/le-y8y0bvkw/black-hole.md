---
title: Small pages load, big ones hang
version: 1
---

Path MTU discovery depends on one ICMP message getting back. Plenty of firewalls drop ICMP as a matter
of habit, on the theory that `ping` is only for attackers. Here the provider's router is given that
habit, and the route caches are cleared so nobody remembers the smaller MTU:

```
ana@laptop:~$ curl -sS -m 5 -o /dev/null -w '%{http_code} %{size_download} bytes\n' https://www.example.com/
200 173 bytes
ana@laptop:~$ curl -sS -m 5 -o /dev/null -w '%{http_code} %{size_download} bytes\n' https://www.example.com/prices.txt
curl: (28) Operation timed out after 5002 milliseconds with 0 out of 186893 bytes received
200 0 bytes
```

**The home page loads and the price list does not.** The home page is 173 bytes, and every packet of
that connection was small. The price list is 186893 bytes, and the server sends it in full-sized
1500-byte packets. Each one reaches the provider's router, cannot fit the 1492-byte line, and is
dropped; the ICMP that would have said so is dropped too. curl got the headers, which were small, so
it knew the size of what was coming, and then waited five seconds for bytes that never arrived: `0
out of 186893 bytes received`.

This is a **PMTU black hole**, and it is one of the most confusing faults support meets. Nothing
is down. `ping` works. Small websites work. Email with a small attachment works and a large one hangs.
A VPN, which adds a header of its own and shrinks the MTU again, makes it worse.

The fix routers use is **MSS clamping**. In the TCP handshake, each side announces its **MSS**,
*maximum segment size*, the most data it will accept in one segment:

```
ana@laptop:~$ sudo tcpdump -n -c 2 -i eth0 "tcp[tcpflags] & tcp-syn != 0"
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
13:16:11.376614 IP 192.168.10.20.46916 > 192.0.2.80.443: Flags [S], seq 2699027394, win 64240, options [mss 1460,sackOK,TS val 3790312328 ecr 0,nop,wscale 10], length 0
13:16:11.376962 IP 192.0.2.80.443 > 192.168.10.20.46916: Flags [S.], seq 1567898401, ack 2699027395, win 65160, options [mss 1460,sackOK,TS val 2150135722 ecr 3790312328,nop,wscale 10], length 0
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

`mss 1460` both ways: 1500 minus 20 bytes of IP header and 20 of TCP header. The router can rewrite
that number as the handshake passes through it, so neither side ever sends a segment too big for the
narrowest link:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"What fits in one packet. On an Ethernet LAN with an MTU of 1500 bytes, 20 go to the IP header and 20 to the TCP header, leaving an MSS of 1460 bytes of data. On a DSL line with PPPoE, the MTU is 1492, and the same two headers leave an MSS of 1452.\"><defs><marker id=\"bg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Ethernet LAN, MTU 1500</text><rect x=\"20\" y=\"30\" width=\"58\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"49\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">IP 20</text><rect x=\"78\" y=\"30\" width=\"58\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"107\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">TCP 20</text><rect x=\"136\" y=\"30\" width=\"506.1333333333333\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"148\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">data: MSS 1460</text><text x=\"20\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">DSL with PPPoE, MTU 1492</text><rect x=\"20\" y=\"96\" width=\"58\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"49\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">IP 20</text><rect x=\"78\" y=\"96\" width=\"58\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"107\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">TCP 20</text><rect x=\"136\" y=\"96\" width=\"503.36\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"148\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">data: MSS 1452</text></svg>", "caption": "The MSS is the MTU minus the two headers. Clamping rewrites the MSS each side announces, so neither sends a segment the narrowest link cannot carry."}
```

```
ana@router:~$ sudo nft add table inet mangle
ana@router:~$ sudo nft add chain inet mangle forward '{ type filter hook forward priority mangle; }'
ana@router:~$ sudo nft add rule inet mangle forward tcp flags syn tcp option maxseg size set rt mtu
ana@router:~$ sudo nft list table inet mangle
table inet mangle {
        chain forward {
                type filter hook forward priority mangle; policy accept;
                tcp flags syn tcp option maxseg size set rt mtu
        }
}
ana@laptop:~$ curl -sS -m 5 -o /dev/null -w '%{http_code} %{size_download} bytes\n' https://www.example.com/prices.txt
200 186893 bytes
```

`set rt mtu` means: lower the MSS to fit the MTU of the route this packet takes. The price list now
arrives in full, all 186893 bytes, and the handshake as the web server received it shows why:

```
ana@www:~$ sudo tcpdump -n -c 1 -i eth0 "tcp[tcpflags] == tcp-syn"
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
13:16:22.132563 IP 203.0.113.2.48122 > 192.0.2.80.443: Flags [S], seq 2712839801, win 64240, options [mss 1452,sackOK,TS val 1201598779 ecr 0,nop,wscale 10], length 0
1 packet captured
1 packet received by filter
0 packets dropped by kernel
```

**`mss 1452`**, which is 1492 minus 40. Most home and office routers do this on their own for PPPoE
lines. When a fault looks like this one and they do not, this is the setting to look for, often called
*MSS clamping* or *TCP MSS adjust* in a router's menus.
