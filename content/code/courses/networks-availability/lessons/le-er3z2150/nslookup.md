---
title: nslookup, and dig beside it
version: 1
---

nslookup asks a DNS server one question and prints the answer, under a header naming **the server that
answered**. Four questions from the laptop, the last one to the address lesson 21's broken
`resolv.conf` pointed at:

```
ana@laptop:~$ nslookup www.example.com
Server:		192.0.2.53
Address:	192.0.2.53#53

Name:	www.example.com
Address: 192.0.2.80

ana@laptop:~$ nslookup -type=ns example.com
Server:		192.0.2.53
Address:	192.0.2.53#53

example.com	nameserver = ns.example.com.

ana@laptop:~$ nslookup nosuch.example.com
Server:		192.0.2.53
Address:	192.0.2.53#53

** server can't find nosuch.example.com: NXDOMAIN

ana@laptop:~$ nslookup www.example.com 192.0.2.54
;; communications error to 192.0.2.54#53: timed out
;; communications error to 192.0.2.54#53: timed out
;; communications error to 192.0.2.54#53: timed out
;; no servers could be reached

```

Read the header first. `Server: 192.0.2.53` is `ns`, and `#53` is the port. The commonest DNS fault is
asking the wrong server, which is what lesson 21 found, and **the header says who was asked before the
answer says anything**. `-type=ns` asks for another kind of record, here the name servers for
`example.com`.

The last two answers are both failures, and they are opposites. **NXDOMAIN is an answer**: the server
was reached, looked, and says the name does not exist. That is a fact about DNS data, and the fix is a
record. Three timeouts and `no servers could be reached` are **no answer at all**: nothing replied from
`192.0.2.54`, so nothing is known about the name. That is a fact about the path to DNS or the setting
that chose the server. A user describes both the same way, "the site doesn't exist", which is why the
words on the screen matter more than the report.

nslookup is on every system, Windows included, and it is enough to ask what a name resolves to. **dig is
the tool for asking why**, because it prints the whole DNS message: the status, the flags, the sections
and the TTL of each record. None of the four questions above was put to dig here; lesson 21 used it,
and the two spell the same questions like this:

| the question | nslookup | dig |
|---|---|---|
| a name's address | `nslookup www.example.com` | `dig www.example.com`, or `+short` for the address alone |
| from a chosen server | `nslookup www.example.com 192.0.2.53` | `dig @192.0.2.53 www.example.com` |
| another record type | `nslookup -type=ns example.com` | `dig ns example.com` |
| did an answer come at all | `no servers could be reached` | no `status:` line, as in lesson 21 |
