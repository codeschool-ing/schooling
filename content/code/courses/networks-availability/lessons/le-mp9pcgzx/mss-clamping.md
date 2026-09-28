---
title: Clamping the segment size
version: 1
---

There are two ways to fix a black hole, and they repair different things. The first is to let the
message through: remove the rule, or narrow it so the "fragmentation needed" that path MTU discovery
needs can leave the router. That repairs the mechanism for every protocol. The second, and the one run
here, is **to make TCP never send a packet too big for the tunnel**, so the message is never needed.

TCP's maximum segment size travels in the SYN, and **each side sends segments no larger than what the
other announced**. A router can rewrite that option as the SYN passes through it, which is called MSS
clamping, and nearly every VPN router does it. On `hq` it is two rules in the forward hook, one for SYNs
going into the tunnel and one for SYNs coming out of it:

```
ana@hq:~$ sudo nft add table ip clamp && sudo nft add chain ip clamp syn "{ type filter hook forward priority mangle; }"
ana@hq:~$ sudo nft add rule ip clamp syn oifname wg0 tcp flags syn tcp option maxseg size set 1380 && sudo nft add rule ip clamp syn iifname wg0 tcp flags syn tcp option maxseg size set 1380
```

**1380 is the tunnel's MTU less 40 bytes**: 20 of IP header and 20 of TCP header, the two that sit in
front of every segment. A segment of 1380 bytes of data or fewer makes a packet of 1420 or fewer, and
that fits in `wg0`. Then the same download, with a capture of the SYNs on `hq`'s office side while it
ran:

```
ana@till:~$ curl -sS -m 30 -o /dev/null -w "%{http_code} %{size_download} bytes\n" http://192.168.10.10/big.bin
200 20000000 bytes
ana@hq:~$ sudo tcpdump -n -t -i eth0 -c 2 "tcp[tcpflags] & tcp-syn != 0"
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
IP 192.168.20.30.40598 > 192.168.10.10.80: Flags [S], seq 1928010537, win 64240, options [mss 1380,sackOK,TS val 2773923947 ecr 0,nop,wscale 10], length 0
IP 192.168.10.10.80 > 192.168.20.30.40598: Flags [S.], seq 1684711710, ack 1928010538, win 65160, options [mss 1460,sackOK,TS val 2944618766 ecr 2773923947,nop,wscale 10], length 0
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

**20000000 bytes, status 200**: the whole file, where eight seconds had delivered nothing. The capture
shows how. The till's SYN left the branch announcing 1460, as it did in the failing capture, and by the
time it reaches the office LAN it says **`mss 1380`**, because `hq` rewrote it as it came out of `wg0`.
`files` now sends segments sized for 1380, and they fit. The SYN-ACK on the second line still says 1460,
because this capture is on the office side and `files`'s reply has not reached the second rule yet; that
rule rewrites it on its way into the tunnel, where the capture did not look.

The fix was checked with **the same test that found the fault**, the download of `big.bin`, and not with
a ping or a small page, which worked all along and would have proved nothing.

Two limits keep the result honest. **Clamping only helps TCP**: the MSS is a TCP option, so anything
else that sends full-size packets with Don't Fragment set still meets the dropped message at the tunnel.
And **the rule that caused it is still on `hq`**, dropping every destination unreachable the router would
send, including the ones that tell a client a host or a port cannot be reached; those failures now arrive
as timeouts instead of errors.

So the complete fix is both: clamp, and let "fragmentation needed" out. The second half was not run in
this lab. Lesson 23 writes the whole case up as an incident record, with the symptom, each hypothesis,
the test that settled it and the fix, including the half still to do.
