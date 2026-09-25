---
title: nslookup, and DNS on Windows and macOS
version: 1
---

`nslookup` is older than `dig` and is on every system, including Windows, which makes it the tool you
will be told to use on a support call. On the lab's laptop:

```
ana@laptop:~$ nslookup www.example.com
Server:         198.51.100.53
Address:        198.51.100.53#53

Non-authoritative answer:
Name:   www.example.com
Address: 192.0.2.81
Name:   www.example.com
Address: 2001:db8:10::80

ana@laptop:~$ nslookup -type=mx example.com
Server:         198.51.100.53
Address:        198.51.100.53#53

Non-authoritative answer:
example.com     mail exchanger = 10 mail.example.com.

Authoritative answers can be found from:
```

**`Non-authoritative answer`** is `nslookup`'s way of saying what section 05 said with the missing `aa`:
this came from a resolver's cache, not from the zone's own server. It printed both addresses, the
`A` and the `AAAA`. `-type=mx` asks for another record type, like `dig`'s second argument.

On Windows and macOS, the cache that matters most on a support call is the machine's own:

```sh
nslookup www.example.com                      # Windows and macOS, as above
ipconfig /displaydns                          # Windows: what this PC has cached
ipconfig /flushdns                            # Windows: forget it all
Resolve-DnsName www.example.com -Type MX      # Windows PowerShell: dig's closest cousin
Clear-DnsClientCache                          # Windows PowerShell: the same flush
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder   # macOS: flush
C:\Windows\System32\drivers\etc\hosts                # Windows: the hosts file
```

**None of these were run for this lesson.** `ipconfig /flushdns` on Windows, and the two commands
together on a Mac, empty the local cache after a change, which is the step people forget: flushing
the resolver does nothing for a PC that is still holding its own copy for the rest of the TTL.
`Resolve-DnsName` is the PowerShell tool closest to `dig`, and it shows the TTL and the section each
record came from.
