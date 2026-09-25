---
title: SPF: which servers may send
version: 1
---

**SPF**, the Sender Policy Framework, is a `TXT` record in which a domain lists the servers allowed to
send its mail:

```
ana@laptop:~$ dig +short TXT example.com
"v=spf1 mx -all"
ana@laptop:~$ dig +short TXT example.net
"v=spf1 mx -all"
```

`v=spf1 mx -all` reads left to right: `mx`, the servers named in the domain's MX records may send;
`-all`, everything else fails. Other terms list addresses (`ip4:198.51.100.0/24`) or pull in a
provider's list (`include:`), and `~all` asks for a "soft" fail, which receivers treat as suspicious
rather than as a refusal.

The receiving server checks the address the connection came from against the SPF record of **the
envelope sender's domain**, `MAIL FROM`. That is the header line `spf=pass smtp.mailfrom=example.com`
of section 05. Two limits, both important. SPF checks the envelope, not the `From:` a person reads. And
a message forwarded by another server arrives from that server's address and fails SPF, although nothing
is wrong with it.
