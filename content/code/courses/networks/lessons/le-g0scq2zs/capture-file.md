---
title: tcpdump to a file, for later
version: 1
---

tcpdump has appeared in almost every lesson, printing packets as they pass. With `-w` it writes them to
a file instead, the **pcap** format that Wireshark and every other packet tool can open:

```
ana@laptop:~$ sudo ip neigh flush dev eth0
ana@laptop:~$ sudo timeout 5 tcpdump -i eth0 -n -w /tmp/web.pcap host 192.0.2.80
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
22 packets captured
22 packets received by filter
0 packets dropped by kernel
ana@laptop:~$ ls -l /tmp/web.pcap
-rw-r--r-- 1 tcpdump tcpdump 5023 Sep 25 16:00 /tmp/web.pcap
ana@laptop:~$ tcpdump -n -r /tmp/web.pcap "tcp[tcpflags] & (tcp-syn|tcp-fin) != 0" 2>/dev/null
16:00:42.225540 IP 192.168.10.20.51554 > 192.0.2.80.443: Flags [S], seq 3902438229, win 64240, options [mss 1460,sackOK,TS val 779025817 ecr 0,nop,wscale 10], length 0
16:00:42.225963 IP 192.0.2.80.443 > 192.168.10.20.51554: Flags [S.], seq 923909534, ack 3902438230, win 65160, options [mss 1460,sackOK,TS val 3408522847 ecr 779025817,nop,wscale 10], length 0
16:00:42.258253 IP 192.0.2.80.443 > 192.168.10.20.51554: Flags [F.], seq 2379, ack 802, win 64, options [nop,nop,TS val 3408522879 ecr 779025850], length 0
16:00:42.258857 IP 192.168.10.20.51554 > 192.0.2.80.443: Flags [F.], seq 802, ack 2380, win 78, options [nop,nop,TS val 779025851 ecr 3408522879], length 0
```

22 packets, one page fetched over HTTPS, in `/tmp/web.pcap`. `-r` reads the file back, and the same
filters apply. `host 192.0.2.80` chose what was captured, and `tcp[tcpflags] & (tcp-syn|tcp-fin) != 0`
picks out only the packets that open and close a connection, the handshake and the goodbye of lesson 3.

**A capture file is how a problem travels.** It can be taken on the machine where the fault is, read
later somewhere else, and attached to a ticket for whoever knows the protocol. It can also contain
passwords and private data, everything the lessons on FTP and email showed in the clear, so it is
handled like any other sensitive file. The filters worth knowing by heart are few: `host`, `port`, `net`,
`and`, `or` and `not`.
