---
title: DNSSEC, signatures on DNS answers
version: 1
---

**DNSSEC adds signatures to DNS records, so that a resolver can check that an answer really came
from the zone's owner and was not changed on the way.** It encrypts nothing: anybody watching can
still see which names are looked up. What it prevents is a forged answer, such as a false address for
`portal.vereda.example` slipped into a resolver's cache, which would send patients to a server of
somebody else's choosing.

## Vereda's zone, before signing

```
ana@lab:~/lab$ cat data/dns/db.vereda.example
$TTL 3600
@       IN SOA ns1.vereda.example. hostmaster.vereda.example. 2026061501 7200 900 1209600 300
@       IN NS  ns1.vereda.example.
ns1     IN A   192.0.2.53
portal  IN A   192.0.2.10
```

And two Ed25519 key pairs, in BIND's file format, made by the lab:

```
ana@lab:~/lab$ ls data/dns
Kvereda.example.+015+34091.key
Kvereda.example.+015+34091.private
Kvereda.example.+015+42395.key
Kvereda.example.+015+42395.private
db.vereda.example
```

The two serve different roles. The **zone signing key** (ZSK, tag 34091) signs every record set. The
**key signing key** (KSK, tag 42395, flag 257) signs only the set of DNSKEY records itself. Keeping
them apart lets the ZSK be replaced often without involving anybody outside the zone, while the KSK,
which the parent zone vouches for, changes rarely.

## Signing

```
ana@lab:~/lab$ cd data/dns && dnssec-signzone -S -K . -s 20260601000000 -e 20360601000000 -o vereda.example -f signed.zone db.vereda.example 2>&1 | tail -5
- ED25519
Zone fully signed:
Algorithm: ED25519: KSKs: 1 active, 0 stand-by, 0 revoked
                    ZSKs: 1 active, 0 stand-by, 0 revoked
signed.zone
```

The signer added a signature to every record set and checked the result. The portal's address now
travels with its own signature, an **RRSIG** record:

```
ana@lab:~/lab$ grep -A6 '^portal' data/dns/signed.zone
portal.vereda.example.	3600	IN A	192.0.2.10
			3600	RRSIG	A 15 3 3600 (
					20360601000000 20260601000000 34091 vereda.example.
					1oiWiijt7oB8Eqb0nmjpvyDfVtMH/VA/g68N
					73h5Cv7FiR9jkkBAoXTe7aDjt0UK0fnEv+gG
					M4Croop/vLwSCw== )
			300	NSEC	vereda.example. A RRSIG NSEC
```

The RRSIG names the algorithm (15, Ed25519), its validity window (from 1 June 2026 to 1 June 2036, as
the lab chose), the key that signed it (34091) and the signature itself. The **NSEC** record that
follows proves what does *not* exist: after `portal` the next name is the zone apex again, so a
resolver can be given signed proof that `admin.vereda.example` has no record, instead of trusting an
unsigned "no such name".

## The chain to the root

A signature is only as good as the key that checks it, the question of lessons 8 and 9 once again.
DNSSEC answers it with the DNS hierarchy itself. The zone's parent, `.example` here and `.com.br` for
a real Brazilian domain, publishes a **DS** record, a hash of the child's KSK:

```
ana@lab:~/lab$ cat data/dns/dsset-vereda.example.
vereda.example.		IN DS 42395 15 2 3F59AE7706354EB0350F91F441DA8547ADC6C1DDDC7EC8F80B3A3ACF AD227806
```

The parent signs its DS record with its own keys, its parent does the same, and so on up to the root
zone, whose key every validating resolver is configured with. That is a chain of trust like a
certificate's, with the root zone's key as the single anchor.

## A forged answer

Change the portal's address in the signed zone, as an attacker poisoning a cache would, without the
private key to re-sign it:

```
ana@lab:~/lab$ cd data/dns && sed 's/192.0.2.10$/203.0.113.66/' signed.zone > forged.zone && dnssec-verify -o vereda.example forged.zone 2>&1 | head -1
No correct ED25519 signature for portal.vereda.example A
```

A validating resolver gives its client a failure instead of the forged address. **Validation happens
in the resolver**, so DNSSEC protects only users whose resolver checks it; the public resolvers of
Google, Cloudflare and Quad9 do, and many company and ISP resolvers do too. Registro.br supports
DNSSEC for `.br` domains, and signing a zone is one setting in most DNS providers today.
