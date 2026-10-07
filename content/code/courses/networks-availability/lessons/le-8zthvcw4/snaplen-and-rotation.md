---
title: Keeping less, and keeping it going
version: 1
---

A capture on a busy server grows fast, and two flags keep it in bounds: one takes less of each
packet, the other keeps only the last few megabytes.

## Snap length

**The snap length is how many bytes of each packet are kept.** By default `tcpdump` keeps 262144, the
whole of any packet this network carries. For a question about connections and flags the headers
are enough, and `-s 96` keeps the first 96 bytes. The laptop made the same four requests, with the same
line as in the previous section:

```
ana@web1:~$ sudo tcpdump -n -i eth0 -s 96 -c 40 -Z ana -w short.pcap tcp port 80
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 96 bytes
40 packets captured
40 packets received by filter
0 packets dropped by kernel
ana@web1:~$ tcpdump -n -r short.pcap -v "tcp[tcpflags] & tcp-push != 0" | head -n 4
reading from file short.pcap, link-type EN10MB (Ethernet), snapshot length 96
18:10:05.723959 IP (tos 0x0, ttl 62, id 9618, offset 0, flags [DF], proto TCP (6), length 125)
    203.0.113.2.58030 > 192.0.2.21.80: Flags [P.], seq 3489478198:3489478271, ack 1958766029, win 63, options [nop,nop,TS val 2032094061 ecr 4037869552], length 73: HTTP, length: 73
	GET / HTTP/1.1 [|http]
18:10:05.724103 IP (tos 0x0, ttl 64, id 37345, offset 0, flags [DF], proto TCP (6), length 295)
ana@web1:~$ ls -l web1.pcap short.pcap
-rw-r--r-- 1 ana ana 3608 Sep 28 18:10 short.pcap
-rw-r--r-- 1 ana ana 4690 Sep 28 18:10 web1.pcap
```

`[|http]` is `tcpdump` saying that the packet ended, in the file, in the middle of HTTP. The request
line survived and the rest did not. **96 bytes is 14 of Ethernet, 20 of IP and 32 of TCP with its
options, which leaves 30 of the request**, enough for `GET / HTTP/1.1` and not for the headers after
it. `-v` added the IP header's details: `ttl 62` on the laptop's packet, which left at 64 and crossed
two routers, `hq` and the ISP.

The file is 3608 bytes against 4690 for the same forty packets kept whole. The saving is small here
because most packets were acknowledgements with no data to cut; **on a capture of large transfers
the snap length removes most of the file**, and most of what a stranger could read in it. Keeping
headers only is also the simplest privacy measure there is.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 170\" role=\"img\" aria-label=\"The laptop&#x27;s request drawn as a bar of 139 bytes: 14 of Ethernet, 20 of IP, 32 of TCP and 73 of HTTP. A cut at 96 bytes, labelled -s 96, keeps the three headers whole and the first 30 bytes of the request; the last 43 bytes are never written, which tcpdump marks as [|http].\"><rect x=\"20\" y=\"50\" width=\"61.60000000000001\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"50.800000000000004\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Ethernet</text><text x=\"50.800000000000004\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">14</text><rect x=\"81.60000000000001\" y=\"50\" width=\"88.0\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"125.60000000000001\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">IP</text><text x=\"125.60000000000001\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><rect x=\"169.60000000000002\" y=\"50\" width=\"140.8\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"240.00000000000003\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">TCP</text><text x=\"240.00000000000003\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">32</text><rect x=\"310.40000000000003\" y=\"50\" width=\"132.0\" height=\"44\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"442.40000000000003\" y=\"50\" width=\"189.20000000000005\" height=\"44\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"376.40000000000003\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">HTTP</text><text x=\"376.40000000000003\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">73</text><path d=\"M442.40000000000003 28 L442.40000000000003 46\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M442.40000000000003 98 L442.40000000000003 116\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"442.40000000000003\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">-s 96</text><text x=\"231.20000000000002\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">kept in the file: 96 bytes</text><text x=\"537.0\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">never written: 43</text><text x=\"231.20000000000002\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">headers whole, 30 bytes of the request</text><text x=\"537.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the rest: [|http]</text></svg>", "caption": "The request from the snap length capture, to scale. With -s 96 a question about connections and flags is still answerable, and the contents of the request mostly are not."}
```

## A ring of files

A fault that happens once a night needs a capture that runs all night without filling the disk.
**`-C` starts a new file every so many million bytes, and `-W` keeps only that many files**,
overwriting the oldest. The laptop downloaded a 20 MB file with this running,
`curl -s -o /dev/null http://192.0.2.21/big.bin`, and when the download had finished the capture was
stopped with `Ctrl+C`:

```
ana@web1:~$ sudo tcpdump -n -i eth0 -C 1 -W 3 -Z ana -w ring.pcap tcp port 80
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
15316 packets captured
15316 packets received by filter
0 packets dropped by kernel
ana@web1:~$ ls -l ring.pcap*
-rw-r--r-- 1 ana ana  237648 Sep 28 18:10 ring.pcap0
-rw-r--r-- 1 ana ana 1001402 Sep 28 18:10 ring.pcap1
-rw-r--r-- 1 ana ana 1000412 Sep 28 18:10 ring.pcap2
```

15316 packets passed, and three files of about a megabyte are what is left. `ring.pcap0` is the
smallest because it was being written when the capture stopped: **it is the newest file, not the
oldest**. `tcpdump` wrote 0, 1 and 2, then went back to 0 and started overwriting it, so the oldest
packets still kept are at the start of `ring.pcap1`. The handshake and the `GET` that began the
download were in files that no longer exist.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 710 172\" role=\"img\" aria-label=\"Three files in a row, ring.pcap0 of 237648 bytes, ring.pcap1 of 1001402 bytes and ring.pcap2 of 1000412 bytes, with arrows from each to the next and a dashed arrow from ring.pcap2 back to ring.pcap0: when the third is full, tcpdump overwrites the first. ring.pcap0 was being written when the capture stopped, so it is the newest; the oldest packets still kept are in ring.pcap1.\"><defs><marker id=\"rg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"50\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"125.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ring.pcap0</text><text x=\"125.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">237648 bytes</text><rect x=\"270\" y=\"50\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"355.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ring.pcap1</text><text x=\"355.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1001402 bytes</text><rect x=\"500\" y=\"50\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ring.pcap2</text><text x=\"585.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1000412 bytes</text><path d=\"M210 75 L270 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-ah)\"></path><path d=\"M440 75 L500 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-ah)\"></path><path d=\"M585 100 C 585 160, 125 160, 125 104\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#rg-ah)\"></path><text x=\"355\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">full: back to ring.pcap0, overwriting it</text><text x=\"125\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">being written when stopped: newest</text><text x=\"355\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">oldest packets still kept</text><text x=\"585\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">full at a million bytes</text></svg>", "caption": "The ring from -C 1 -W 3, with the sizes ls printed. Numbering says the order the files were created in, and nothing about which holds the newest packets."}
```

That is the trade: a ring keeps the minutes before you stopped it, which is what you want when you
stop it the moment the fault shows. The next section asks what happens to the files after that.
