---
title: Reading the file back
version: 1
---

`-r` reads a file instead of an interface, and **reading needs no privilege**: the file belongs to
`ana`, so no `sudo` in front.

```
ana@web1:~$ tcpdump -n -r web1.pcap | head -n 6
reading from file web1.pcap, link-type EN10MB (Ethernet), snapshot length 262144
18:10:03.429832 IP 203.0.113.2.57998 > 192.0.2.21.80: Flags [S], seq 781299498, win 64240, options [mss 1460,sackOK,TS val 1879519515 ecr 0,nop,wscale 10], length 0
18:10:03.429866 IP 192.0.2.21.80 > 203.0.113.2.57998: Flags [S.], seq 3577260322, ack 781299499, win 65160, options [mss 1460,sackOK,TS val 3771413204 ecr 1879519515,nop,wscale 10], length 0
18:10:03.429895 IP 203.0.113.2.57998 > 192.0.2.21.80: Flags [.], ack 1, win 63, options [nop,nop,TS val 1879519515 ecr 3771413204], length 0
18:10:03.429954 IP 203.0.113.2.57998 > 192.0.2.21.80: Flags [P.], seq 1:74, ack 1, win 63, options [nop,nop,TS val 1879519515 ecr 3771413204], length 73: HTTP: GET / HTTP/1.1
18:10:03.429957 IP 192.0.2.21.80 > 203.0.113.2.57998: Flags [.], ack 74, win 64, options [nop,nop,TS val 3771413204 ecr 1879519515], length 0
18:10:03.430184 IP 192.0.2.21.80 > 203.0.113.2.57998: Flags [P.], seq 1:244, ack 74, win 64, options [nop,nop,TS val 3771413204 ecr 1879519515], length 243: HTTP: HTTP/1.1 200 OK
```

The first connection, packet by packet: SYN, SYN-ACK, ACK, the request of 73 bytes, the server's
acknowledgement, and the start of the answer, 243 bytes that say `HTTP/1.1 200 OK`. The file keeps
the original times, so a capture taken at night is read in the morning with the night's clock.

A filter given with `-r` is BPF, like a capture filter, and it selects from the file. BPF can also
look at bits: `tcp[tcpflags]` is the byte of TCP flags, and `& tcp-syn != 0` keeps packets with the
SYN bit set.

```
ana@web1:~$ tcpdump -n -r web1.pcap "tcp[tcpflags] & tcp-syn != 0"
reading from file web1.pcap, link-type EN10MB (Ethernet), snapshot length 262144
18:10:03.429832 IP 203.0.113.2.57998 > 192.0.2.21.80: Flags [S], seq 781299498, win 64240, options [mss 1460,sackOK,TS val 1879519515 ecr 0,nop,wscale 10], length 0
18:10:03.429866 IP 192.0.2.21.80 > 203.0.113.2.57998: Flags [S.], seq 3577260322, ack 781299499, win 65160, options [mss 1460,sackOK,TS val 3771413204 ecr 1879519515,nop,wscale 10], length 0
18:10:03.436113 IP 203.0.113.2.58006 > 192.0.2.21.80: Flags [S], seq 819435649, win 64240, options [mss 1460,sackOK,TS val 1554105456 ecr 0,nop,wscale 10], length 0
18:10:03.436121 IP 192.0.2.21.80 > 203.0.113.2.58006: Flags [S.], seq 2611216251, ack 819435650, win 65160, options [mss 1460,sackOK,TS val 1942754168 ecr 1554105456,nop,wscale 10], length 0
18:10:03.442388 IP 203.0.113.2.58022 > 192.0.2.21.80: Flags [S], seq 2112191451, win 64240, options [mss 1460,sackOK,TS val 113813396 ecr 0,nop,wscale 10], length 0
18:10:03.442397 IP 192.0.2.21.80 > 203.0.113.2.58022: Flags [S.], seq 1868065903, ack 2112191452, win 65160, options [mss 1460,sackOK,TS val 2339123235 ecr 113813396,nop,wscale 10], length 0
18:10:03.448333 IP 203.0.113.2.58026 > 192.0.2.21.80: Flags [S], seq 111897154, win 64240, options [mss 1460,sackOK,TS val 2610192501 ecr 0,nop,wscale 10], length 0
18:10:03.448342 IP 192.0.2.21.80 > 203.0.113.2.58026: Flags [S.], seq 2309079825, ack 111897155, win 65160, options [mss 1460,sackOK,TS val 1982204633 ecr 2610192501,nop,wscale 10], length 0
```

**Eight lines, two per connection: four connections**, one per request, each a SYN and its SYN-ACK.
Counting SYNs is the quickest way to answer "how many times did the clients connect", and on a
server under attack or under a retry storm it is the number that jumps first.

`-A` prints each packet's bytes as ASCII, and with the push flag and a `grep` it becomes a list of
requests and answers:

```
ana@web1:~$ tcpdump -n -A -r web1.pcap "tcp[tcpflags] & tcp-push != 0" | grep -E "GET|HTTP/1.1 [0-9]"
reading from file web1.pcap, link-type EN10MB (Ethernet), snapshot length 262144
18:10:03.429954 IP 203.0.113.2.57998 > 192.0.2.21.80: Flags [P.], seq 781299499:781299572, ack 3577260323, win 63, options [nop,nop,TS val 1879519515 ecr 3771413204], length 73: HTTP: GET / HTTP/1.1
p.1...2.GET / HTTP/1.1
18:10:03.430184 IP 192.0.2.21.80 > 203.0.113.2.57998: Flags [P.], seq 1:244, ack 73, win 64, options [nop,nop,TS val 3771413204 ecr 1879519515], length 243: HTTP: HTTP/1.1 200 OK
..2.p.1.HTTP/1.1 200 OK
18:10:03.436191 IP 203.0.113.2.58006 > 192.0.2.21.80: Flags [P.], seq 819435650:819435723, ack 2611216252, win 63, options [nop,nop,TS val 1554105456 ecr 1942754168], length 73: HTTP: GET / HTTP/1.1
\..ps..xGET / HTTP/1.1
18:10:03.436302 IP 192.0.2.21.80 > 203.0.113.2.58006: Flags [P.], seq 1:244, ack 73, win 64, options [nop,nop,TS val 1942754168 ecr 1554105456], length 243: HTTP: HTTP/1.1 200 OK
s..x\..pHTTP/1.1 200 OK
18:10:03.442465 IP 203.0.113.2.58022 > 192.0.2.21.80: Flags [P.], seq 2112191452:2112191525, ack 1868065904, win 63, options [nop,nop,TS val 113813396 ecr 2339123235], length 73: HTTP: GET / HTTP/1.1
.....l0#GET / HTTP/1.1
18:10:03.442630 IP 192.0.2.21.80 > 203.0.113.2.58022: Flags [P.], seq 1:244, ack 73, win 64, options [nop,nop,TS val 2339123236 ecr 113813396], length 243: HTTP: HTTP/1.1 200 OK
.l0$....HTTP/1.1 200 OK
18:10:03.448411 IP 203.0.113.2.58026 > 192.0.2.21.80: Flags [P.], seq 111897155:111897235, ack 2309079826, win 63, options [nop,nop,TS val 2610192501 ecr 1982204633], length 80: HTTP: GET /missing HTTP/1.1
.GET /missing HTTP/1.1
18:10:03.448552 IP 192.0.2.21.80 > 203.0.113.2.58026: Flags [P.], seq 1:295, ack 80, win 64, options [nop,nop,TS val 1982204633 ecr 2610192501], length 294: HTTP: HTTP/1.1 404 Not Found
...`uHTTP/1.1 404 Not Found
```

Three `200 OK` and one `404 Not Found`, for `/missing`. The few characters before `GET` and `HTTP`
are bytes of the TCP header, printed as characters like everything else.

**Look at the sequence numbers**, because they changed. The first line says `seq
781299499:781299572`, raw numbers, where the full read above said `seq 1:74`; and the answer
acknowledges `73`, where it said `74`. `tcpdump` counts relative numbers from the first packet it
sees of each connection, and this filter hid the handshake, so it started counting from the
request. **The off-by-one comes from the filter, not from the network**, and it is the kind of thing
that sends somebody looking for a lost byte that was never lost. When the numbers matter, read them
with the handshake in view, or ask for raw numbers everywhere with `-S`, which was not run here.
