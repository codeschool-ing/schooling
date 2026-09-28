---
title: Following a stream, and counting
version: 1
---

A list of packets is the wrong shape for most questions. "What did the client ask and what did the
server answer" is a conversation, and Wireshark rebuilds it: **Follow TCP Stream** in the window's
menu, `-z follow` in `tshark`.

```
ana@mon:~$ tshark -r files.pcap -q -z follow,tcp,ascii,0

===================================================================
Follow: tcp,ascii
Filter: tcp.stream eq 0
Node 0: 192.168.10.10:59928
Node 1: 192.0.2.21:80
73
GET / HTTP/1.1
Host: 192.0.2.21
User-Agent: curl/8.5.0
Accept: */*


	243
HTTP/1.1 200 OK
Server: nginx
Date: Mon, 28 Sep 2026 21:09:39 GMT
Content-Type: text/html
Content-Length: 15
Last-Modified: Mon, 28 Sep 2026 21:09:30 GMT
Connection: keep-alive
ETag: "6abad78a-f"
Accept-Ranges: bytes

served by web1

===================================================================
```

Stream 0 is the first TCP connection in the file, frames 1 to 10. `tshark` put the bytes of both
directions back in order: 73 from `192.168.10.10:59928`, then the 243 of the answer, marked with a
tab in front of the count, ending in the page itself, `served by web1`. **That is everything plain
HTTP ever was on the wire**: headers and body in clear text, readable by anyone who can copy the packets. After the section on mirror ports, that means anyone who can change a switch's
configuration. The same command on the HTTPS connection was not run here; it would show records of
bytes that mean nothing without the session's keys.

For a file of thousands of packets the first question is usually who talked to whom, and how much,
before any single packet. Two statistics answer it:

```
ana@mon:~$ tshark -r files.pcap -q -z conv,ip
================================================================================
IPv4 Conversations
Filter:<No Filter>
                                               |       <-      | |       ->      | |     Total     |    Relative    |   Duration   |
                                               | Frames  Bytes | | Frames  Bytes | | Frames  Bytes |      Start     |              |
192.168.10.10        <-> 192.0.2.21                12 3265 bytes      15 1800 bytes      27 5065 bytes     0.000000000         1.0975
192.168.10.10        <-> 192.0.2.23                 4 566 bytes       6 489 bytes      10 1055 bytes     1.104894905         0.0008
192.168.10.10        <-> 192.0.2.53                 2 297 bytes       2 199 bytes       4 496 bytes     0.008987287         0.0196
192.168.10.10        <-> 192.0.2.22                 2 196 bytes       2 196 bytes       4 392 bytes     0.041952556         1.0204
================================================================================
ana@mon:~$ tshark -r files.pcap -q -z io,phs

===================================================================
Protocol Hierarchy Statistics
Filter: 

eth                                      frames:45 bytes:7008
  ip                                     frames:45 bytes:7008
    tcp                                  frames:37 bytes:6120
      http                               frames:4 bytes:959
        data-text-lines                  frames:2 bytes:669
      tls                                frames:8 bytes:3463
    udp                                  frames:4 bytes:496
      dns                                frames:4 bytes:496
    icmp                                 frames:4 bytes:392
===================================================================
```

The conversations table is one line per pair of addresses. `web1` comes first with 27 frames and
5065 bytes, because it served both the page and the HTTPS request. The arrows are read from the
first address: `files` sent 15 frames, 1800 bytes, and received 12 frames, 3265 bytes. **A client
that receives more than it sends is the usual shape of browsing**, and a machine that suddenly sends
far more than it receives is one of the first things an analyst looks at.

The protocol hierarchy says the same file another way. Of 45 frames, 37 were TCP, and only 4 of those
carried HTTP and 8 carried TLS; the rest were the packets that open, acknowledge and close
connections. **On a real network this is where the unexpected protocol shows up first**, a line that
should not be there at all, before anybody has thought to filter for it.
