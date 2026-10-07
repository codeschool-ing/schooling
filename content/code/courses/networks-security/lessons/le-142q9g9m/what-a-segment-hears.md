---
title: What anybody on a segment can hear
version: 1
---

**Sniffing** is reading traffic that passes a network interface, including traffic addressed to
other machines. A defender does it all the time: an intrusion detection sensor (lesson 14) does
nothing else. Whoever else manages it on the same segment reads exactly what the sensor reads, so
the question worth asking is **what is there to read**.

In your lab this lesson starts from `sudo bash nslab.sh reset`, with the company's policy loaded on
`fw` by `nft -f baseline.nft`. The lab has a sensor plugged into the DMZ, with no address of its own:

```
root@sensor:~# ip -br addr show eth0
eth0@if70        UP             
```

`UP` and no address. It listens and never speaks, which is how a sensor should be connected. Now a
client on the internet asks the shop for a page over **plain HTTP**, carrying a session cookie, and
the sensor records the segment. Each recording in this lesson is started on `sensor`, as root, a
moment before the client acts, and stops itself after eight seconds; the filter at the end is the
traffic it keeps. This one is `http.pcap` with `tcp port 80`; later ones are `dns.pcap` with
`udp port 53` and `tls.pcap` with `tcp port 443`:

```sh
setsid timeout 8 tcpdump -i eth0 -s0 -w /root/http.pcap tcp port 80 </dev/null >/dev/null 2>&1 &
```

```
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" -b "session=7f3a9c2e" http://www.example.com/orders
404
root@sensor:~# tcpdump -r http.pcap -n -A 2>/dev/null | grep -aoE "GET /[^ ]* HTTP/1.1|Host: .*|User-Agent: .*|Cookie: .*" | uniq
GET /orders HTTP/1.1
Host: www.example.com
User-Agent: curl/8.5.0
Cookie: session=7f3a9c2e
```

The page is a `404`; that does not matter. **Everything the client sent is readable**: which page, on
which site, with which program, and the session cookie that proves who the client is to the
application. Anybody who can read the segment can copy that cookie, and this lesson's last section
says what that is worth to them.

DNS is plain text too:

```
ana@remote:~$ dig +short @192.0.2.53 www.example.com
192.0.2.80
root@sensor:~# tcpdump -r dns.pcap -n 2>/dev/null | cut -d" " -f2-
IP 203.0.113.50.60300 > 192.0.2.53.53: 45084+ [1au] A? www.example.com. (56)
IP 192.0.2.53.53 > 203.0.113.50.60300: 45084* 1/0/1 A 192.0.2.80 (60)
```

The question and the answer, in full: who asked, for which name, and what address came back. Now the
same request to the shop, over HTTPS, recorded the same way:

```
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" -b "session=7f3a9c2e" https://www.example.com/orders
404
root@sensor:~# tcpdump -r tls.pcap -n -A 2>/dev/null | grep -caE "GET /|Cookie: "
0
root@sensor:~# tcpdump -r tls.pcap -n 2>/dev/null | wc -l
17
```

Seventeen packets crossed the segment, and **none of them contains the request or the cookie** in any
form a reader of the segment can use. The names and the sizes still show, which is lesson 2's
metadata; what was said does not.

**The defence against sniffing is not preventing it, which nobody can promise on every segment. It is
making sure there is nothing worth reading.** Write down every protocol in the company that still
carries a password, a cookie or a document in clear. This lesson's next sections are about how an
attacker gets onto a segment they were not meant to hear.
