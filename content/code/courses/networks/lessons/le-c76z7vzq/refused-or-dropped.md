---
title: Yes, no, and nothing at all
version: 1
---

A TCP port can answer a connection in three ways, and a firewall decides which of the last two you
get. The web server is given a firewall with two rules, one that **drops** attempts on port 3306 and
one that **rejects** them on 5432, plus the UDP rule section 06 used:

```
ana@www:~$ sudo nft add table inet fw
ana@www:~$ sudo nft add chain inet fw input '{ type filter hook input priority 0; }'
ana@www:~$ sudo nft add rule inet fw input tcp dport 3306 drop
ana@www:~$ sudo nft add rule inet fw input tcp dport 5432 reject with tcp reset
ana@www:~$ sudo nft add rule inet fw input udp dport 9998 drop
```

Then three attempts from the laptop: 8080, where nothing listens; 5432, rejected; 3306, dropped.

```
ana@laptop:~$ nc -zv -w 3 192.0.2.80 8080
nc: connect to 192.0.2.80 port 8080 (tcp) failed: Connection refused
ana@laptop:~$ nc -zv -w 3 192.0.2.80 5432
nc: connect to 192.0.2.80 port 5432 (tcp) failed: Connection refused
ana@laptop:~$ time nc -zv -w 3 192.0.2.80 3306
nc: connect to 192.0.2.80 port 3306 (tcp) timed out: Operation now in progress

real    0m3.005s
user    0m0.002s
sys     0m0.000s
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Three ways a TCP port can answer. Nothing listening: the laptop sends SYN, the server answers RST, and nc reports connection refused at once. A firewall rule reject with tcp reset: SYN, then RST, refused at once, indistinguishable from the first. A firewall rule drop: the laptop sends SYN three times, nothing comes back, and nc reports timed out after its timeout.\"><defs><marker id=\"an-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what is on the port</text><text x=\"290\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the laptop sends</text><text x=\"420\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">www answers</text><text x=\"560\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nc gives up</text><rect x=\"14\" y=\"40\" width=\"692\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nothing listens: refused</text><text x=\"290\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SYN</text><text x=\"420\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">RST</text><text x=\"560\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">at once</text><rect x=\"14\" y=\"86\" width=\"692\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reject with tcp reset: refused</text><text x=\"290\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SYN</text><text x=\"420\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">RST</text><text x=\"560\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">at once</text><rect x=\"14\" y=\"132\" width=\"692\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">drop: timed out</text><text x=\"290\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SYN, SYN, SYN</text><text x=\"420\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nothing</text><text x=\"560\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">after the timeout</text></svg>", "caption": "A reset and a closed port look the same from outside. A drop is the only one of the three that makes the client wait, and it is the one a firewall usually chooses."}
```

Port 8080 and port 5432 give the same answer, `Connection refused`, at once. On the wire it is one
SYN out and one RST back:

```
ana@laptop:~$ sudo tcpdump -n -i eth0 -c 2 tcp port 8080
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
13:27:24.548279 IP 192.168.10.20.55428 > 192.0.2.80.8080: Flags [S], seq 2740136733, win 64240, options [mss 1460,sackOK,TS val 1967779466 ecr 0,nop,wscale 10], length 0
13:27:24.548594 IP 192.0.2.80.8080 > 192.168.10.20.55428: Flags [R.], seq 0, ack 2740136734, win 0, length 0
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

**From outside, a rejecting firewall is indistinguishable from a closed port.** Port 3306 is the
different one: nc waited the full three seconds it was given (`real 0m3.006s`), and the laptop's side
of the wire shows why:

```
ana@laptop:~$ sudo tcpdump -n -i eth0 -c 3 tcp port 3306
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
13:27:17.999289 IP 192.168.10.20.42742 > 192.0.2.80.3306: Flags [S], seq 3033148130, win 64240, options [mss 1460,sackOK,TS val 2247737711 ecr 0,nop,wscale 10], length 0
13:27:19.022502 IP 192.168.10.20.42742 > 192.0.2.80.3306: Flags [S], seq 3033148130, win 64240, options [mss 1460,sackOK,TS val 2247738735 ecr 0,nop,wscale 10], length 0
13:27:20.046492 IP 192.168.10.20.42742 > 192.0.2.80.3306: Flags [S], seq 3033148130, win 64240, options [mss 1460,sackOK,TS val 2247739759 ecr 0,nop,wscale 10], length 0
3 packets captured
3 packets received by filter
0 packets dropped by kernel
```

The same SYN, with the same sequence number, sent three times about a second apart, and not a single
packet back. The laptop's kernel keeps trying because a lost SYN is normal. A browser waits longer
than nc did, typically a minute or more, which is why a dropped port feels like a hung program.

The two firewall choices each have a reason:

- **Drop** tells a stranger nothing, not even that a machine is there, and makes a port scan slow.
  It is the usual choice on the internet side.
- **Reject** answers at once, so a legitimate program fails fast with a clear error instead of
  hanging. It is the kinder choice inside a network.

**For support, the timing is the clue.** `Connection refused` straight away means the path works and
the port is shut, and the question goes to whoever runs the service. A timeout means something between
you and the service is silently discarding the attempt, and the question goes to whoever runs the
firewall.
