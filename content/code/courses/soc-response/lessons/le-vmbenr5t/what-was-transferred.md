---
title: What was transferred
version: 1
---

Two steps take the capture from "a conversation happened" to "this is the file". The first puts the conversation
back together in order, as the two programs saw it (Wireshark: *Follow, TCP Stream*). Streams are numbered from 0:

```
ana@soc:~$ tshark -r web.pcap -q -z follow,tcp,ascii,0 | head -22

===================================================================
Follow: tcp,ascii
Filter: tcp.stream eq 0
Node 0: 192.168.20.10:50542
Node 1: 203.0.113.200:8080
95
GET /price-list.csv HTTP/1.1
Host: 203.0.113.200:8080
User-Agent: curl/8.5.0
Accept: */*


	188
HTTP/1.0 200 OK
Server: SimpleHTTP/0.6 Python/3.13.16
Date: Thu, 08 Oct 2026 00:10:25 GMT
Content-type: text/csv
Content-Length: 49524
Last-Modified: Thu, 08 Oct 2026 00:10:21 GMT
```

Node 0 is `files`, node 1 the server. The number before each block is how many bytes that side sent: 95 bytes of
request, the `GET` with curl's headers, and then the server's reply, starting with its headers. The reply's body,
the 49,524 bytes of the list, follows; `head` cut it off here.

The second step rebuilds the file itself from the packets (Wireshark: *File, Export Objects, HTTP*):

```
ana@soc:~$ tshark -r web.pcap -q --export-objects http,objects
ana@soc:~$ ls -l objects
total 52
-rw-r--r-- 1 ana ana 49524 Oct  7 21:10 price-list.csv
root@soc:~# sha256sum www/price-list.csv /home/ana/objects/price-list.csv
355da1417a322b56fa40dcfc8368a2cabdcb77452dc65630641fad01b457d4b1  www/price-list.csv
355da1417a322b56fa40dcfc8368a2cabdcb77452dc65630641fad01b457d4b1  /home/ana/objects/price-list.csv
```

`--export-objects http,objects` writes every file transferred over HTTP into the folder `objects`. One file, 49,524
bytes. And the hash, taken as root because the original is in root's folder, settles it: **the file rebuilt from
the packets is byte for byte the file on the server.** That is a finding of the strongest kind, the same shape as
lesson 16's image: anybody with the capture can rebuild the file and check the hash.

On Thursday's night, a capture on `fw` would have answered lesson 12's open question directly, file by file, if the
transfer had been plain HTTP. Whether it was is the next section's problem.
