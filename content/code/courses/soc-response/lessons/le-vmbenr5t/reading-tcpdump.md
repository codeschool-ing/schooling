---
title: Reading it with tcpdump
version: 1
---

`tcpdump -r` reads a capture file back. `-nn` keeps addresses and ports as numbers, so tcpdump does not try to look
up names, which on an isolated lab would only make it slow and in a real incident might send a DNS query to the
other side:

```
ana@soc:~$ tcpdump -nn -r web.pcap 2>/dev/null | head -4
21:10:25.863410 IP 192.168.20.10.50542 > 203.0.113.200.8080: Flags [S], seq 1351909861, win 64240, options [mss 1460,sackOK,TS val 4155148826 ecr 0,nop,wscale 10], length 0
21:10:25.863522 IP 203.0.113.200.8080 > 192.168.20.10.50542: Flags [S.], seq 1005923498, ack 1351909862, win 65160, options [mss 1460,sackOK,TS val 1052539430 ecr 4155148826,nop,wscale 10], length 0
21:10:25.863537 IP 192.168.20.10.50542 > 203.0.113.200.8080: Flags [.], ack 1, win 63, options [nop,nop,TS val 4155148826 ecr 1052539430], length 0
21:10:25.863614 IP 192.168.20.10.50542 > 203.0.113.200.8080: Flags [P.], seq 1:96, ack 1, win 63, options [nop,nop,TS val 4155148826 ecr 1052539430], length 95: HTTP: GET /price-list.csv HTTP/1.1
ana@soc:~$ tcpdump -nn -r web.pcap 2>/dev/null | wc -l
20
```

Four lines are the start of every TCP conversation. Read the `Flags`:

1. `[S]`, **SYN**: `files`, from port 50542, asks `203.0.113.200` port 8080 to open a connection.
2. `[S.]`, **SYN-ACK**: the server agrees. The dot is an ACK.
3. `[.]`, **ACK**: `files` confirms. The connection is open: the **three-way handshake**.
4. `[P.]`, **PUSH**: the first data, `length 95`, and tcpdump recognises it: `HTTP: GET /price-list.csv`.

Twenty lines in all, one per packet. A line per packet is fine for twenty and useless for twenty thousand, which is
why the next tool exists. The source port and the sequence numbers in your capture are different: they are chosen
at random for every connection.
