---
title: Writing the capture to a file
version: 1
---

Reading lines as they scroll past works for four packets. For anything else, **`tcpdump` writes a
pcap file, and the reading happens afterwards**, on the server or on somebody else's machine. The
laptop made four requests, three for the home page and one for a page that does not exist:

```
ana@web1:~$ sudo tcpdump -n -i eth0 -c 40 -Z ana -w web1.pcap tcp port 80
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
40 packets captured
40 packets received by filter
0 packets dropped by kernel
ana@web1:~$ ls -l web1.pcap
-rw-r--r-- 1 ana ana 4690 Sep 28 18:10 web1.pcap
```

`-w web1.pcap` writes the packets instead of printing them, and `-c 40` stops at forty. **`-Z ana` is
the flag that matters most**: `tcpdump` opens the interface as root, then gives up root and becomes
`ana` before it writes a byte. The file is hers, and the program that has been parsing whatever the
network sent it is no longer running as root.

The file was created `-rw-r--r--`, **readable by every account on the server**. `tshark` made its file
readable by its owner only; `tcpdump` here did not, and a capture holds whatever crossed the wire. On
a server other people log into, `chmod 600 web1.pcap` straight after, or a `umask 077` before, is part
of taking the capture.

`capinfos`, which comes with Wireshark, describes a file without opening its packets:

```
ana@web1:~$ capinfos web1.pcap
File name:           web1.pcap
File type:           Wireshark/tcpdump/... - pcap
File encapsulation:  Ethernet
File timestamp precision:  microseconds (6)
Packet size limit:   file hdr: 262144 bytes
Number of packets:   40
File size:           4690 bytes
Data size:           4026 bytes
Capture duration:    0.018971 seconds
First packet time:   2026-09-28 18:10:03.429832
Last packet time:    2026-09-28 18:10:03.448803
Data byte rate:      212 kBps
Data bit rate:       1697 kbps
Average packet size: 100.65 bytes
Average packet rate: 2108 packets/s
SHA256:              91afae27f69e71b0e5364189b07c2edee3d536762a4ed0cf92970339487ae63f
SHA1:                fe4e7f425596642253896c5a280b63c66bf04646
Strict time order:   True
Number of interfaces in file: 1
Interface #0 info:
                     Encapsulation = Ethernet (1 - ether)
                     Capture length = 262144
                     Time precision = microseconds (6)
                     Time ticks per second = 1000000
```

Forty packets, captured in 0.018971 seconds, between two timestamps written to the microsecond.
**`File size` is 664 bytes more than `Data size`**, and that is the pcap format itself. It puts a 24-byte header at the start of the file, and 16 bytes in front of every packet recording when it arrived and how long it was: 24 + 40 × 16 = 664. `Packet size limit: 262144` is the snap length, how much of each
packet was kept, and the section on snap length makes it smaller on purpose.

**The two hashes are for later.** Whoever receives this file can run `capinfos` on their copy and
compare `SHA256`; the same line means the same bytes, and nothing was lost or edited on the way.
