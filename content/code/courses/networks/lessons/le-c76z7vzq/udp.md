---
title: UDP: one packet, and no promises
version: 1
---

UDP sends a packet to a port and that is all. No handshake, no acknowledgement, no retransmission.
A DNS question from the laptop, seen at the resolver:

```
ana@resolver:~$ sudo tcpdump -n -i eth0 -c 2 udp port 53 and host 203.0.113.2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
13:27:08.492146 IP 203.0.113.2.56951 > 198.51.100.53.53: 59776+ [1au] A? www.example.com. (56)
13:27:08.492635 IP 198.51.100.53.53 > 203.0.113.2.56951: 59776 1/0/1 A 192.0.2.80 (60)
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

**Two packets, the whole exchange: a question and an answer.** `A? www.example.com.` asks for the
address; `A 192.0.2.80` is it, and `1/0/1` counts the records in the answer (lesson 4 reads the rest).
Over TCP the same question would have cost a handshake first, three packets before a single byte of
question. If the answer is lost, nobody in the kernel notices: the program itself, here `dig`, waits a
few seconds and asks again.

No handshake also means no clear answer when you test a port. `nc -u` sends a packet and reports what
it could tell:

```
ana@laptop:~$ nc -zuv -w 1 198.51.100.53 53
Connection to 198.51.100.53 53 port [udp/domain] succeeded!
```

```
ana@laptop:~$ nc -zuv -w 1 192.0.2.80 9999; echo "exit status $?"
exit status 1
```

```
ana@www:~$ sudo tcpdump -n -i eth0 -c 2 udp port 9999 or icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
13:27:11.567578 IP 203.0.113.2.33553 > 192.0.2.80.9999: UDP, length 1
13:27:11.567591 IP 192.0.2.80 > 203.0.113.2: ICMP 192.0.2.80 udp port 9999 unreachable, length 37
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

A closed UDP port is known only because the server's system sent back an ICMP *port unreachable*, and
nc noticed it and exited with status 1, silently. Now a port that a firewall drops, section 07:

```
ana@laptop:~$ nc -zuv -w 1 192.0.2.80 9998; echo "exit status $?"
Connection to 192.0.2.80 9998 port [udp/*] succeeded!
exit status 0
```

**`succeeded`, for a port nothing listens on.** The packet vanished, no ICMP came back, and to nc
silence looks exactly like a server that received the packet and chose not to reply. For UDP, "open"
from a port test means only "nothing said no". The real test is to ask the service a real question:
`dig` for DNS, as lesson 4 does.
