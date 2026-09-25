---
title: nslookup, the one on every system
version: 1
---

`dig` is the better tool and it is not always there. **`nslookup` is on Windows, macOS and Linux
alike**, so it is the one to use on somebody else's computer:

```
ana@laptop:~$ nslookup www.example.com
Server:         198.51.100.53
Address:        198.51.100.53#53

Non-authoritative answer:
Name:   www.example.com
Address: 192.0.2.80
Name:   www.example.com
Address: 2001:db8:10::80

ana@laptop:~$ nslookup -type=mx example.net
Server:         198.51.100.53
Address:        198.51.100.53#53

Non-authoritative answer:
example.net     mail exchanger = 10 mail.example.net.

Authoritative answers can be found from:

ana@laptop:~$ nslookup 192.0.2.80
80.2.0.192.in-addr.arpa name = www.example.com.

Authoritative answers can be found from:
```

The first two lines are the server that answered, the equivalent of `dig`'s `SERVER:` line. `Non-authoritative
answer` means it came from a resolver rather than from the domain's own server, which is normal.
`www.example.com` has two addresses, IPv4 and IPv6, and nslookup asks for both unless told otherwise.
`-type=mx` asks for mail exchangers, as in lesson 9, and an address on its own is looked up backwards,
in the `in-addr.arpa` zone of lesson 4.

`nslookup www.example.com 198.51.100.53` asks a particular server, like `dig @`. What nslookup does not
show is the TTL and the flags, `aa` among them, so for anything past "what does this name resolve to",
`dig` is the tool.
