---
title: A tampered answer, refused
version: 1
---

To see validation work, the answer has to be wrong. On `dns`, the signed zone is edited by hand: the
shop's address changed to `203.0.113.66`, **without signing again**. That is what a forged answer
looks like to the resolver: the right name, a wrong address, and a signature that was made for
something else.

```
root@dns:~# sed -i "s/^\(www\.example\.com\.[[:space:]]*300[[:space:]]*IN A[[:space:]]*\)192.0.2.80/\1203.0.113.66/" /etc/bind/db.example.com.signed; grep -n "IN A" /etc/bind/db.example.com.signed
47:dns.example.com.	300	IN A	192.0.2.53
59:www.example.com.	300	IN A	203.0.113.66
```

The server is restarted to serve the edited file, with
`kill $(cat /var/cache/bind/named.pid); sleep 1; named -u bind -c /etc/bind/named.conf` on `dns`; the
resolver's cached answer for the name is thrown away, and `laptop` asks again:

```
root@laptop:~# unbound-control flush www.example.com
ok
ana@laptop:~$ dig @127.0.0.1 www.example.com | grep -E "status|^www"
;; ->>HEADER<<- opcode: QUERY, status: SERVFAIL, id: 8727
root@laptop:~# grep "validation failure" /var/lib/unbound/unbound.log | cut -d" " -f3-
info: validation failure <www.example.com. A IN>: signature crypto failed from 192.0.2.53
```

**`SERVFAIL`, and no address at all.** The resolver fetched the answer, checked the signature, found
it did not match, and refused to hand anything to the client. Its log says exactly why: `signature
crypto failed`. A client of this resolver cannot be sent to `203.0.113.66`, because it is never told
the address.

The flag `+cd`, *checking disabled*, asks the resolver to skip validation, which shows what would
have happened without it:

```
ana@laptop:~$ dig +cd +short @127.0.0.1 www.example.com
203.0.113.66
```

The forged address, handed over as if it were true.

## Where DNSSEC helps, and where it stops

| DNSSEC | does | does not |
|---|---|---|
| on the answer | prove it came from the zone's owner, unchanged | hide the question or the answer from anybody on the path |
| on the zone | protect every name in it, once signed | protect a zone whose owner never signed it |
| on the client | give a verdict it can rely on, if the resolver validates | help a client whose resolver does not validate |

**`SERVFAIL` is also what a mistake looks like.** An expired signature or a key rolled over carelessly
takes a signed zone off the internet for every validating resolver, with the same error. Signing a
zone is a commitment to re-signing it on schedule, and the lab's signatures carry their own expiry
date, 31 December 2026, for exactly that reason.
