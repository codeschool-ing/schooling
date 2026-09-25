---
title: The source, and a copy of it
version: 1
---

There are two kinds of DNS server, and they answer differently. The same question to each:

```
ana@laptop:~$ dig @ns1.example.com www.example.com +norecurse +noall +comments +answer | grep -E "flags|IN"
;; flags: qr aa; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2
; EDNS: version: 0, flags:; udp: 1232
www.example.com.        300     IN      A       192.0.2.80
ana@laptop:~$ dig www.example.com +noall +comments +answer | grep -E "flags|IN"
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
; EDNS: version: 0, flags:; udp: 1232
www.example.com.        299     IN      A       192.0.2.80
```

**`aa`, *authoritative answer*, appears only in the first**: `ns1.example.com` holds the zone file and
is the source. The resolver's answer has `rd ra` and no `aa`: it is repeating something it was told.
And its TTL is **299, not 300**. The resolver is counting down.

```
ana@laptop:~$ dig +noall +answer www.example.com
www.example.com.        299     IN      A       192.0.2.80
ana@laptop:~$ dig +noall +answer www.example.com
www.example.com.        294     IN      A       192.0.2.80
```

Five seconds later, 294. **The TTL is how long anybody may keep the answer before asking again**, and
it was set by the owner of the domain in the zone file. When it reaches zero the resolver forgets the
record, and the next question walks to `ns1` again.

Caching is why DNS is fast: the laptop's `dig` answered in `0 msec` because the resolver already had
the answer. It is also why a change to DNS is never instant, which is the next section.

The laptop itself keeps a cache too on most systems: `systemd-resolved` on a desktop Linux, the DNS
Client service on Windows, `mDNSResponder` on a Mac. The lab's laptop has none, so every question here
went to the resolver.
