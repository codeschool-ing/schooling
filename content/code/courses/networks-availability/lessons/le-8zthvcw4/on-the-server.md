---
title: tcpdump on the server, one line at a time
version: 1
---

A server in a data centre has no screen, no Wireshark and nobody to install one, and it is usually
the machine closest to the problem. **What it does have, almost always, is `tcpdump`**, from the same
project as libpcap, the library behind lesson 11's capture filters, so it speaks the same BPF. It is
the tool for capturing on the host itself, the third place lesson 11 named.

The first attempt on `web1` fails:

```
ana@web1:~$ tcpdump -i eth0
tcpdump: eth0: You don't have permission to perform this capture on that device
(socket: Operation not permitted)
```

**Opening an interface to read every packet on it needs root**, or the capability a `wireshark` group
grants, and `web1` has no such group. So from here on capture goes through `sudo`, and the next
sections take care that only the capture runs with that privilege.

## Reading one line

The laptop fetched the home page, `curl -s http://192.0.2.21/` on `laptop`, while `tcpdump` on `web1`
printed the first four packets it saw on port 80, once as it comes and once with `-n`; start the capture
first, then fetch the page, twice:

```
ana@web1:~$ sudo tcpdump -i eth0 -c 4 tcp port 80
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
18:09:59.272963 IP 203.0.113.2.53572 > 192.0.2.21.http: Flags [S], seq 4253519600, win 64240, options [mss 1460,sackOK,TS val 2091423905 ecr 0,nop,wscale 10], length 0
18:09:59.272979 IP 192.0.2.21.http > 203.0.113.2.53572: Flags [S.], seq 1512749408, ack 4253519601, win 65160, options [mss 1460,sackOK,TS val 2178196906 ecr 2091423905,nop,wscale 10], length 0
18:09:59.273007 IP 203.0.113.2.53572 > 192.0.2.21.http: Flags [.], ack 1, win 63, options [nop,nop,TS val 2091423905 ecr 2178196906], length 0
18:09:59.273064 IP 203.0.113.2.53572 > 192.0.2.21.http: Flags [P.], seq 1:74, ack 1, win 63, options [nop,nop,TS val 2091423905 ecr 2178196906], length 73: HTTP: GET / HTTP/1.1
4 packets captured
10 packets received by filter
0 packets dropped by kernel
ana@web1:~$ sudo tcpdump -n -i eth0 -c 4 tcp port 80
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
18:10:01.354355 IP 203.0.113.2.53574 > 192.0.2.21.80: Flags [S], seq 3118618316, win 64240, options [mss 1460,sackOK,TS val 2627791292 ecr 0,nop,wscale 10], length 0
18:10:01.354371 IP 192.0.2.21.80 > 203.0.113.2.53574: Flags [S.], seq 2274837499, ack 3118618317, win 65160, options [mss 1460,sackOK,TS val 721148073 ecr 2627791292,nop,wscale 10], length 0
18:10:01.354397 IP 203.0.113.2.53574 > 192.0.2.21.80: Flags [.], ack 1, win 63, options [nop,nop,TS val 2627791292 ecr 721148073], length 0
18:10:01.354456 IP 203.0.113.2.53574 > 192.0.2.21.80: Flags [P.], seq 1:74, ack 1, win 63, options [nop,nop,TS val 2627791292 ecr 721148073], length 73: HTTP: GET / HTTP/1.1
4 packets captured
10 packets received by filter
0 packets dropped by kernel
```

**`-n` stops `tcpdump` turning numbers into names.** Without it the port printed as `http`, and on a
network with reverse DNS each address would be looked up too, a query per new address, sent while
the capture runs. With it, `80` is `80`. Use `-n` on a server always: a name is slower, it can be
wrong, and a port called `http` hides the question of whether it is really 80.

The source is `203.0.113.2`, not the laptop's `192.168.10.20`. That is `hq`'s public address: the
office router translated it, as lesson 11 of `networks-addressing` described, and `web1` never sees
a private address from the office at all. `4 packets captured` against `10 packets received by
filter` means ten had matched by the time `tcpdump` stopped, and it printed the four `-c 4` asked for.

Taking the first `-n` line apart:

| piece | what it says |
|---|---|
| `18:10:01.354355` | the time, to the microsecond, in the machine's own zone |
| `203.0.113.2.53574 > 192.0.2.21.80` | source address and port, then destination; the port is the last number after a dot |
| `Flags [S]` | the TCP flags: `S` SYN, `.` ACK, `P` push, `F` FIN, `R` reset |
| `seq 3118618316` | the sequence number the client chose |
| `win 64240` | the window, as the field carries it |
| `options [mss 1460,…,wscale 10]` | the TCP options, here the maximum segment size and the window scale |
| `length 0` | bytes of data in the segment; a SYN carries none |

**`[S]`, `[S.]`, `[.]`, `[P.]` is the connection opening and the first request**, the pattern to
recognise at a glance. After the SYN, `tcpdump` prints sequence numbers relative to the start, so the
request is `seq 1:74`, 73 bytes. And `win 63` on the third line is not a tiny window: the SYN said
`wscale 10`, so the real window is 63 × 1024 = 64512 bytes, which is the number `tshark` printed as
`Win=64512` in lesson 11. **`tcpdump` prints the field; the scale lives in an option two packets
earlier.**
