---
title: What a tunnel does not hide
version: 1
---

A tunnel joins two networks. It does not make the traffic private, and people who say "the VPN" about a
GRE tunnel sometimes believe it does. The ISP's router can read everything inside. Here is the till
fetching a page from the head office file server, `files`, as the ISP sees it, with `-A` to print each
packet's contents as text:

```
ana@isp:~$ sudo tcpdump -l -n -t -A -i eth0 -c 8 ip proto 47 | grep --line-buffered -E "GRE|GET|Host|served"
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
IP 198.51.100.2 > 203.0.113.2: GREv0, key=0x2a, length 68: IP 192.168.20.30.54502 > 192.168.10.10.80: Flags [S], seq 903736331, win 64240, options [mss 1460,sackOK,TS val 3994382340 ecr 0,nop,wscale 10], length 0
IP 203.0.113.2 > 198.51.100.2: GREv0, key=0x2a, length 68: IP 192.168.10.10.80 > 192.168.20.30.54502: Flags [S.], seq 2813130645, ack 903736332, win 65160, options [mss 1460,sackOK,TS val 134118023 ecr 3994382340,nop,wscale 10], length 0
IP 198.51.100.2 > 203.0.113.2: GREv0, key=0x2a, length 60: IP 192.168.20.30.54502 > 192.168.10.10.80: Flags [.], ack 1, win 63, options [nop,nop,TS val 3994382341 ecr 134118023], length 0
IP 198.51.100.2 > 203.0.113.2: GREv0, key=0x2a, length 136: IP 192.168.20.30.54502 > 192.168.10.10.80: Flags [P.], seq 1:77, ack 1, win 63, options [nop,nop,TS val 3994382341 ecr 134118023], length 76: HTTP: GET / HTTP/1.1
..p...z.GET / HTTP/1.1
Host: 192.168.10.10
IP 203.0.113.2 > 198.51.100.2: GREv0, key=0x2a, length 60: IP 192.168.10.10.80 > 192.168.20.30.54502: Flags [.], ack 77, win 64, options [nop,nop,TS val 134118023 ecr 3994382341], length 0
IP 203.0.113.2 > 198.51.100.2: GREv0, key=0x2a, length 305: IP 192.168.10.10.80 > 192.168.20.30.54502: Flags [P.], seq 1:246, ack 77, win 64, options [nop,nop,TS val 134118024 ecr 3994382341], length 245: HTTP: HTTP/1.1 200 OK
served by files
IP 198.51.100.2 > 203.0.113.2: GREv0, key=0x2a, length 60: IP 192.168.20.30.54502 > 192.168.10.10.80: Flags [.], ack 246, win 63, options [nop,nop,TS val 3994382342 ecr 134118024], length 0
IP 198.51.100.2 > 203.0.113.2: GREv0, key=0x2a, length 60: IP 192.168.20.30.54502 > 192.168.10.10.80: Flags [F.], seq 77, ack 246, win 63, options [nop,nop,TS val 3994382342 ecr 134118024], length 0
8 packets captured
10 packets received by filter
0 packets dropped by kernel
```

**The whole conversation is there**: the internal addresses, the TCP handshake, the request line `GET /`,
and the page that came back, `served by files`. The page says little here because the lab's server has
nothing to say. On a real network the same capture would show whatever the offices send each other in
clear text, a login form, a spreadsheet, a patient's record.

There are three questions a link between offices has to answer, and a plain tunnel answers only the
first:

| | a plain tunnel | what is needed |
|---|---|---|
| can the packet reach the other office? | **yes** | routing through the tunnel |
| can anybody on the path read it? | yes, all of it | encryption |
| did it really come from the other office, unchanged? | nobody checks | authentication and integrity |

`branch` would accept a GRE packet with the right outer addresses and the right key from anybody, and
the key is printed in every line above. **Encryption and authentication are what turn a tunnel into a
VPN.** They can be added in two ways: around the tunnel, which is IPsec in lesson 2, or built into the
tunnel from the start, which is TLS-based VPNs in lesson 3 and WireGuard in lesson 4.

Plain GRE still has a place. Inside an IPsec connection it carries what IPsec on its own will not, such
as a routing protocol's multicast, and inside a data centre it carries traffic between networks that
never leave a private link. **A tunnel that crosses a network you do not control gets encrypted.**
