---
title: Many connections, one address, told apart by port
version: 2
---

Rewriting the address alone would let one conversation per destination out at a time: with every
packet leaving from 203.0.113.2, two replies from the same server to the same port would be
indistinguishable. **PAT, port address translation, also rewrites the source port when it has to, so
that every connection is still unique from outside.** It is what r1's `masquerade` does and what
every home router does, and in everyday speech it is simply called NAT; Cisco calls it NAT overload.

Lesson 5 gave the rule PAT has to keep: a connection is four numbers, and no two connections may share
all four. To watch r1 keep it, three PCs connect at once to `192.0.2.80` port 80, and two of them
insist on the same source port: pc1 and pc2 both ask for 40000, pc3 for 51000, each with
`sleep 4 | timeout 6 nc -N -p 40000 192.0.2.80 80` and its own port, which holds the connection open
for a few seconds. r1's table, emptied just before with `conntrack -F`, then holds:

```
root@r1:~# conntrack -L -p tcp
conntrack v1.4.8 (conntrack-tools): 3 flow entries have been shown.
tcp      6 431998 ESTABLISHED src=10.20.10.23 dst=192.0.2.80 sport=51000 dport=80 src=192.0.2.80 dst=203.0.113.2 sport=80 dport=51000 [ASSURED] mark=0 use=1
tcp      6 431998 ESTABLISHED src=10.20.10.21 dst=192.0.2.80 sport=40000 dport=80 src=192.0.2.80 dst=203.0.113.2 sport=80 dport=46745 [ASSURED] mark=0 use=1
tcp      6 431998 ESTABLISHED src=10.20.10.22 dst=192.0.2.80 sport=40000 dport=80 src=192.0.2.80 dst=203.0.113.2 sport=80 dport=40000 [ASSURED] mark=0 use=1
```

Each line has two halves, as in lesson 5: the connection as the PC sent it, then the reply r1
expects. Written out:

| PC | sent from | leaves as | reply expected at |
|---|---|---|---|
| pc3 | 10.20.10.23:51000 | 203.0.113.2:51000 | 203.0.113.2:51000 |
| pc1 | 10.20.10.21:40000 | 203.0.113.2:46745 | 203.0.113.2:46745 |
| pc2 | 10.20.10.22:40000 | 203.0.113.2:40000 | 203.0.113.2:40000 |

pc3 and pc2 kept their ports: nothing else was using 51000 or 40000 towards that server, so only the
address had to change. pc1 asked for 40000 when pc2 already had it. Keeping it would have made the two
connections identical from outside — 203.0.113.2 port 40000 to 192.0.2.80 port 80, twice — so r1 gave
pc1 port **46745** instead, and translates it back on every reply. **A port is rewritten only when
keeping it would make two connections the same from outside.**

The other fields: `6` is TCP's protocol number; `431998` is the seconds left before an idle entry is
forgotten, because an established TCP connection is kept for five days, 432000 seconds, and two have
passed; `[ASSURED]` means traffic has been seen in both directions.

From outside, the effect is that the whole office is one address with many ports. On isp, the
provider's router, a capture watched for the packets that open TCP connections (SYN) while pc1, pc2
and pc3 each fetched the same page:

```
ana@pc1:~$ curl -s http://192.0.2.80/
served by web2
ana@pc2:~$ curl -s http://192.0.2.80/
served by web1
ana@pc3:~$ curl -s http://192.0.2.80/
served by web2
root@isp:~# timeout 8 tcpdump -n -i eth1 -c 3 "tcp[tcpflags] == tcp-syn"
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), snapshot length 262144 bytes
08:24:55.380912 IP 203.0.113.2.45602 > 192.0.2.80.80: Flags [S], seq 3108904710, win 64240, options [mss 1460,sackOK,TS val 3435536978 ecr 0,nop,wscale 7], length 0
08:24:56.561483 IP 203.0.113.2.50074 > 192.0.2.80.80: Flags [S], seq 1287844257, win 64240, options [mss 1460,sackOK,TS val 2920209295 ecr 0,nop,wscale 7], length 0
08:24:57.776959 IP 203.0.113.2.40738 > 192.0.2.80.80: Flags [S], seq 659442927, win 64240, options [mss 1460,sackOK,TS val 4149592587 ecr 0,nop,wscale 7], length 0
3 packets captured
3 packets received by filter
0 packets dropped by kernel
```

The three `curl` commands ran first and printed their pages — `served by web2` and `served by web1`
are lesson 1's load balancer taking turns — and isp's capture was printed when it ended. Three
connections, three source ports, `45602`, `50074` and `40738`, and one address, `203.0.113.2`. Nothing
in those lines says which PC was which; only r1's table knows.

How many connections fit behind one address? The port field is 16 bits, so tens of thousands to any
one destination address and port, and more in total, since a port in use towards one server can be
used again towards another: the four numbers still differ. On a busy router the limit that bites first
is the size of its table.
