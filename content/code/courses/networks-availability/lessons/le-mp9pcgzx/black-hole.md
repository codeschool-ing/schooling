---
title: The file that never arrives
version: 1
---

The worked case is the one lesson 1 promised: a PMTU black hole. The two offices are joined by a
WireGuard tunnel built as in lesson 4, `wg0` on `hq` and on `branch`: the key pairs, the files of `hq`
and `branch` from lesson 4's first section, and `sudo wg-quick up wg0` on both. The fault is three
commands on `hq`, given here; the rest of the section finds them the way it would have to without
knowing:

```sh
sudo nft add table ip hardening
sudo nft add chain ip hardening out '{ type filter hook output priority 0; }'
sudo nft add rule ip hardening out icmp type destination-unreachable drop
```
 The report from the branch is the
kind nobody can reproduce over the phone: **the file server's web page opens, and a download from it
never finishes.** Both halves are true:

```
ana@till:~$ curl -sS -m 5 -o /dev/null -w "%{http_code} %{size_download} bytes\n" http://192.168.10.10/
200 16 bytes
ana@till:~$ curl -sS -m 8 -o /dev/null -w "%{http_code} %{size_download} bytes\n" http://192.168.10.10/big.bin
curl: (28) Operation timed out after 8002 milliseconds with 0 bytes received
000 0 bytes
```

The page arrives, status 200 and 16 bytes. The download, `big.bin`, gets **0 bytes in 8002
milliseconds**, and curl gives up at the limit it was given. The name, the route, the tunnel and the web
server all work, or the small page would have failed too. **Whatever is wrong depends on size.**

A capture on `hq`'s office side, where the file server's packets pass on their way into the tunnel,
shows the conversation:

```
ana@hq:~$ sudo tcpdump -n -t -i eth0 -c 9 tcp port 80 and host 192.168.20.30
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
IP 192.168.20.30.41212 > 192.168.10.10.80: Flags [S], seq 3890829214, win 64240, options [mss 1460,sackOK,TS val 1270073489 ecr 0,nop,wscale 10], length 0
IP 192.168.10.10.80 > 192.168.20.30.41212: Flags [S.], seq 288962322, ack 3890829215, win 65160, options [mss 1460,sackOK,TS val 797129185 ecr 1270073489,nop,wscale 10], length 0
IP 192.168.20.30.41212 > 192.168.10.10.80: Flags [.], ack 1, win 63, options [nop,nop,TS val 1270073490 ecr 797129185], length 0
IP 192.168.20.30.41212 > 192.168.10.10.80: Flags [P.], seq 1:84, ack 1, win 63, options [nop,nop,TS val 1270073490 ecr 797129185], length 83: HTTP: GET /big.bin HTTP/1.1
IP 192.168.10.10.80 > 192.168.20.30.41212: Flags [.], ack 84, win 64, options [nop,nop,TS val 797129185 ecr 1270073490], length 0
IP 192.168.10.10.80 > 192.168.20.30.41212: Flags [.], seq 1:1449, ack 84, win 64, options [nop,nop,TS val 797129185 ecr 1270073490], length 1448: HTTP: HTTP/1.1 200 OK
IP 192.168.10.10.80 > 192.168.20.30.41212: Flags [.], seq 1449:2897, ack 84, win 64, options [nop,nop,TS val 797129185 ecr 1270073490], length 1448: HTTP
IP 192.168.10.10.80 > 192.168.20.30.41212: Flags [.], seq 2897:4345, ack 84, win 64, options [nop,nop,TS val 797129185 ecr 1270073490], length 1448: HTTP
IP 192.168.10.10.80 > 192.168.20.30.41212: Flags [.], seq 4345:5793, ack 84, win 64, options [nop,nop,TS val 797129185 ecr 1270073490], length 1448: HTTP
9 packets captured
17 packets received by filter
0 packets dropped by kernel
```

Read it in three parts. The handshake completes, `[S]`, `[S.]`, `[.]`, and both sides announce `mss
1460`, the largest segment each will accept, sized for an ordinary 1500-byte Ethernet. The request
crosses, 83 bytes of `GET /big.bin`, and `files` acknowledges it with `ack 84`. Then `files` starts
sending, and **every segment carries 1448 bytes**: 1460 less 12 bytes of TCP timestamp option, which
with 32 bytes of TCP header and 20 of IP makes a 1500-byte packet. The capture stopped at nine packets,
as `-c 9` told it to, and in those nine the till never acknowledges a byte of data.

A 1500-byte packet is about to enter a tunnel, so the hypothesis is size, and ping can test size
directly. From `files` towards the till, with Don't Fragment set:

```
ana@files:~$ ping -c 1 -M do -s 1392 192.168.20.30 | tail -n 2
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.563/0.563/0.563/0.000 ms
ana@files:~$ ping -c 1 -W 2 -M do -s 1400 192.168.20.30 | tail -n 2
1 packets transmitted, 0 received, 100% packet loss, time 0ms

ana@hq:~$ ip link show wg0 | head -n 1
2: wg0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1420 qdisc pfifo_fast state UNKNOWN mode DEFAULT group default qlen 500
```

`-s 1392` makes a 1420-byte packet, and it crosses. `-s 1400` makes 1428, and it is lost. The tunnel's
MTU is **1420**, the default `wg-quick` sets, which leaves room for WireGuard's own headers on a 1500-byte
link. So far that is ordinary: a packet too big for the next link, with Don't Fragment set, is dropped.
What is not ordinary is the silence. In lesson 1 the same experiment through the IP-in-IP tunnel printed
`Frag needed and DF set (mtu = 1480)`, and its statistics line said `+1 errors`. Here the line says `0
received` and nothing else. **The router dropped the packet, and its message saying why never
arrived.**

A message a router sends leaves through its own output path, so that is where to look:

```
ana@hq:~$ sudo nft list ruleset | grep -B 3 destination-unreachable
table ip hardening {
	chain out {
		type filter hook output priority filter; policy accept;
		icmp type destination-unreachable drop
```

A table called `hardening`, a chain on the router's `output` hook, and one rule: drop every ICMP
destination unreachable that `hq` itself sends. "Fragmentation needed" is one kind of destination
unreachable, so **the rule drops exactly the message path MTU discovery depends on**. `files` sends
1448-byte segments and `hq` drops each one at the entrance to `wg0`. The explanation is thrown away on the
way out, and `files` goes on trying a size that will never fit until the till's curl gives up.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 780 364\" role=\"img\" aria-label=\"A sequence between three machines: till at 192.168.20.30, hq whose tunnel wg0 has an MTU of 1420, and files at 192.168.10.10. The handshake crosses: SYN with mss 1460, SYN-ACK with mss 1460, then GET /big.bin. files sends a segment of 1448 bytes of data, a 1500-byte packet; it stops at hq, too big for wg0, and is dropped. hq&#x27;s ICMP message, fragmentation needed with mtu 1420, is dropped by the hardening rule on hq&#x27;s output before it reaches files. The next 1448-byte segment meets the same fate, and the till receives 0 bytes in 8002 ms.\"><defs><marker id=\"bh-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"14\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">till</text><text x=\"110.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.20.30</text><rect x=\"300\" y=\"14\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hq</text><text x=\"390.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">wg0 mtu 1420</text><rect x=\"600\" y=\"14\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"670.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">files</text><text x=\"670.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.10.10</text><path d=\"M110 54 L110 306\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M390 54 L390 306\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M670 54 L670 306\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M110 80 L664 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bh-ah)\"></path><text x=\"390.0\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">SYN, mss 1460</text><path d=\"M670 110 L116 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bh-ah)\"></path><text x=\"390.0\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">SYN-ACK, mss 1460</text><path d=\"M110 140 L664 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bh-ah)\"></path><text x=\"390.0\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GET /big.bin</text><path d=\"M670 180 L402 180\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#bh-ah)\"></path><text x=\"530\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1448 bytes of data: a 1500-byte packet</text><path d=\"M386.5 176.5 L393.5 183.5 M386.5 183.5 L393.5 176.5\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"378\" y=\"183\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">too big for wg0: dropped</text><path d=\"M398 230 L560 230\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#bh-ah)\"></path><text x=\"480\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">ICMP: fragmentation needed, mtu 1420</text><path d=\"M564.5 226.5 L571.5 233.5 M564.5 233.5 L571.5 226.5\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"480\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">dropped by the hardening rule on hq's output</text><path d=\"M670 280 L402 280\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#bh-ah)\"></path><text x=\"530\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the next 1448-byte segment, the same fate</text><path d=\"M386.5 276.5 L393.5 283.5 M386.5 283.5 L393.5 276.5\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><rect x=\"40\" y=\"318\" width=\"170\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"125\" y=\"335\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">0 bytes in 8002 ms</text></svg>", "caption": "The black hole. Small packets cross, the first full-size one is dropped at the tunnel, and the message that would tell files to send smaller ones is dropped by hq's own firewall."}
```

**The small page crossed because it fitted.** Sixteen bytes of body and a few headers make one small
packet, far under 1420. Anything that fits in a small packet works; anything that needs a full-size one
does not. That is the signature to remember: logins work, the first screen of a page works, an e-mail
without an attachment works, and a download, an upload or a large page hangs, with no error from
anybody.

Rules like `hardening` are written in good faith, to keep a router from telling strangers which
addresses and ports are closed. Lesson 23 comes back to that: how to write this case up so that the
record fixes the rule and not the person who wrote it.
