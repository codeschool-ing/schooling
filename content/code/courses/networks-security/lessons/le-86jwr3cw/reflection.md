---
title: Reflection and amplification, and not being part of one
version: 1
---

The largest volumetric attacks rarely come from the attacker's machines directly. They are
**reflected**: the attacker sends small UDP questions to servers across the internet with the
**victim's address** forged as the source, and every server sends its answer to the victim. When the
answer is much larger than the question, the attack is **amplified**.

The arithmetic is what makes it attractive. A service whose 60-byte question produces a 3,000-byte
answer has an amplification factor of 50: one megabit per second of questions becomes fifty of
answers aimed at somebody else. Protocols with a large answer to a small UDP question have been used
this way: DNS, NTP, memcached, SSDP among them.

Two things follow for a defender, and neither is about receiving the attack:

- **Do not run a service that answers strangers with more than they asked.** A DNS server open to the
  internet should answer for its own names and refuse everything else.
- **Do not let your network send packets with somebody else's source address**, which is what the
  forged questions are. Lesson 8 writes that filter.

The lab's name server in the DMZ is reachable from the internet, on purpose. Asked about its own
name, and about a name that is not its business:

```
ana@remote:~$ dig @192.0.2.53 www.example.com +qr | grep -E "status|QUERY SIZE|MSG SIZE"
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 14931
;; QUERY SIZE: 56
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 14931
;; MSG SIZE  rcvd: 60
ana@remote:~$ dig @192.0.2.53 example.org | grep -E "status|MSG SIZE"
;; ->>HEADER<<- opcode: QUERY, status: REFUSED, id: 5292
;; MSG SIZE  rcvd: 46
```

For `www.example.com` it answers, 60 bytes for a 56-byte question, a factor close to 1. For
`example.org` it says `REFUSED`, in 46 bytes: **it is not an open resolver**, and it cannot be used to
send the answers to anybody else's questions to a victim. The configuration that does this is
`no-resolv` in its `dnsmasq` configuration: it forwards nothing and knows only what it was told.

A resolver that *is* meant to answer recursive questions, the one the staff use, belongs where only
the staff can reach it: the matrix of lesson 4 puts the internet's DNS cell on the authoritative
server alone.
