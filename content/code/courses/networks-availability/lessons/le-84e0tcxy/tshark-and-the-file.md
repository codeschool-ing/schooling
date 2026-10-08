---
title: Wireshark without a window
version: 1
---

**The machines of this course have no screen, so every capture in this lesson is taken with `tshark`.** That
changes less than it seems. `tshark` is Wireshark with a terminal in front of it: the same
dissectors decode each packet, the same two filter languages choose what to keep and what to show,
and a file saved by one opens in the other. Where this lesson types `-f "tcp port 80"`, the window
has a capture filter box; where it types `-Y "http.request"`, the window has the display filter bar
above the packet list. The words typed into them are identical.

The first thing to check is who is capturing:

```
ana@mon:~$ id -nG; tshark -D
ana wireshark
1. eth0
2. any
3. lo (Loopback)
4. bluetooth-monitor
5. nflog
6. nfqueue
7. dbus-system
8. dbus-session
9. ciscodump (Cisco remote capture)
10. dpauxmon (DisplayPort AUX channel monitor capture)
11. randpkt (Random packet generator)
12. sdjournal (systemd Journal Export)
13. sshdump (SSH remote capture)
14. udpdump (UDP Listener remote capture)
15. wifidump (Wi-Fi remote capture)
```

`ana` is in the `wireshark` group, and that is why no command in this lesson starts with `sudo`.
`netlab.sh` put you in it too; your list of groups is longer on a Multipass machine, and `wireshark` is
in it.
**Capturing needs a privilege, and decoding a packet does not.** So the Ubuntu package gives the
privilege to the small helper that opens the interface, and lets the members of one group run it. The
dissectors, the code that parses whatever a stranger chose to send, run as `ana`. Running all of
Wireshark as root, to avoid adding somebody to a group, puts all of that code within reach of the
packets it is reading.

`tshark -D` lists what can be captured on: `eth0`, the `any` pseudo-interface that listens on every
interface at once, and extras the package ships, from Bluetooth to remote capture over SSH. On `mon`
only `eth0` carries anything.

## Save first, look afterwards

The habit that pays is to **write the capture to a file and analyse the file**, rather than read a
screen scrolling past. `mon` captured for eight seconds while `files` did a morning's work in
miniature: a web page, two DNS lookups, a ping, an HTTPS request and a page that does not exist. Start
the capture below on `mon`, and within its eight seconds paste this on `files`:

```sh
curl -s http://192.0.2.21/ >/dev/null; dig +short www.example.com >/dev/null; dig +short nosuch.example.com >/dev/null; ping -c 2 192.0.2.22 >/dev/null; curl -s https://www.example.com/ --resolve www.example.com:443:192.0.2.21 >/dev/null; curl -s http://192.0.2.23/nothing-here >/dev/null
```

```
ana@mon:~$ tshark -n -q -i eth0 -f "not arp" -a duration:8 -w files.pcap
Capturing on 'eth0'
45 packets captured
ana@mon:~$ ls -l files.pcap
-rw------- 1 ana ana 8904 Sep 28 18:09 files.pcap
ana@mon:~$ tshark -r files.pcap | head -n 12
    1 0.000000000 192.168.10.10 → 192.0.2.21   TCP 74 59928 → 80 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=3641093702 TSecr=0 WS=1024
    2 0.000062359   192.0.2.21 → 192.168.10.10 TCP 74 80 → 59928 [SYN, ACK] Seq=0 Ack=1 Win=65160 Len=0 MSS=1460 SACK_PERM TSval=82424114 TSecr=3641093702 WS=1024
    3 0.000077303 192.168.10.10 → 192.0.2.21   TCP 66 59928 → 80 [ACK] Seq=1 Ack=1 Win=64512 Len=0 TSval=3641093702 TSecr=82424114
    4 0.000137514 192.168.10.10 → 192.0.2.21   HTTP 139 GET / HTTP/1.1 
    5 0.000150015   192.0.2.21 → 192.168.10.10 TCP 66 80 → 59928 [ACK] Seq=1 Ack=74 Win=65536 Len=0 TSval=82424114 TSecr=3641093702
    6 0.000308278   192.0.2.21 → 192.168.10.10 HTTP 309 HTTP/1.1 200 OK  (text/html)
    7 0.000337410 192.168.10.10 → 192.0.2.21   TCP 66 59928 → 80 [ACK] Seq=74 Ack=244 Win=64512 Len=0 TSval=3641093703 TSecr=82424115
    8 0.000454293 192.168.10.10 → 192.0.2.21   TCP 66 59928 → 80 [FIN, ACK] Seq=74 Ack=244 Win=64512 Len=0 TSval=3641093703 TSecr=82424115
    9 0.000520927   192.0.2.21 → 192.168.10.10 TCP 66 80 → 59928 [FIN, ACK] Seq=244 Ack=75 Win=65536 Len=0 TSval=82424115 TSecr=3641093703
   10 0.000534840 192.168.10.10 → 192.0.2.21   TCP 66 59928 → 80 [ACK] Seq=75 Ack=245 Win=64512 Len=0 TSval=3641093703 TSecr=82424115
   11 0.008987287 192.168.10.10 → 192.0.2.53   DNS 98 Standard query 0x9ce1 A www.example.com OPT
   12 0.009225585   192.0.2.53 → 192.168.10.10 DNS 130 Standard query response 0x9ce1 A www.example.com A 192.0.2.80 OPT
```

`-w files.pcap` writes each packet to the file instead of printing it, `-q` keeps the screen quiet
apart from the count, and `-a duration:8` stops after eight seconds. **45 packets in 8904 bytes**, and
the file was created with mode `-rw-------`, readable by `ana` and nobody else. A capture file holds
whatever crossed the wire, so that is the right default, and lesson 12 comes back to it.

Reading it back with `-r` prints one line per packet, in the columns the window shows. They are the frame number, the seconds since the first packet, source and destination, the protocol Wireshark decided
it was, the length on the wire, and a summary. **Every time in this lab is one computer talking to
itself**, so the whole page, frames 1 to 10, took under a millisecond. On a real network the gap
between frame 1 and frame 2 is the round trip to the server, and it is often the first number worth
reading.
