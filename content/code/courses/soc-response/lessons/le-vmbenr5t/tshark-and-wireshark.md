---
title: tshark, and Wireshark
version: 1
---

**Wireshark** is the graphical packet analyser almost every analyst uses: a list of packets, the selected one
decoded layer by layer, and its bytes. **It was not run for this lesson**, because the lab has no screen. Its
command-line half, **tshark**, uses the same decoders, called **dissectors**, and the same filters; lesson 1
installed it. Everything below can be done in Wireshark's menus, and the menu is named beside each command.

The first question about any capture is **who talked to whom**. tshark's statistics answer it without listing a
single packet (Wireshark: *Statistics, Conversations*):

```
ana@soc:~$ tshark -r web.pcap -q -z conv,tcp
================================================================================
TCP Conversations
Filter:<No Filter>
                                                           |       <-      | |       ->      | |     Total     |    Relative    |   Duration   |
                                                           | Frames  Bytes | | Frames  Bytes | | Frames  Bytes |      Start     |              |
192.168.20.10:50542        <-> 203.0.113.200:8080               9 50 kB          11 829 bytes      20 51 kB         0.000000000         0.0045
================================================================================
```

One TCP conversation, between `files` port 50542 and the server's 8080: 11 frames, 829 bytes in one direction,
and 9 frames, 50 kB in the other, in 4.5 milliseconds. Read the arrows on the column headings: the large direction
is towards `files`. **The direction of the bytes is the first thing to check** when the question is whether data
left: Thursday's 612 MB went from `files` outward, this download comes in.

Then the conversation's content, as HTTP. `-Y` takes a **display filter**, Wireshark's own language, which is
different from the capture filter: it does not decide what is kept, only what is shown, and it can name any field a
dissector knows. `-T fields` prints the chosen fields, one packet per line:

```
ana@soc:~$ tshark -r web.pcap -Y http -T fields -e frame.number -e ip.src -e ip.dst -e http.request.method -e http.request.uri -e http.response.code -e http.content_length
4	192.168.20.10	203.0.113.200	GET	/price-list.csv		
16	203.0.113.200	192.168.20.10			200	49524
```

Frame 4 is the request: `GET /price-list.csv`. Frame 16 is the answer: `200`, and a `Content-Length` of `49524`.
Display filters are worth learning by their field names: `http.request.method == "POST"`, `ip.addr ==
203.0.113.200`, `tcp.flags.syn == 1 and tcp.flags.ack == 0` for new connections only. Wireshark shows the field
name of anything you click, at the bottom of its window.
