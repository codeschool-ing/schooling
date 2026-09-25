---
title: The records a domain holds
version: 1
---

A domain is a list of **records**, and each has a type. `dig NAME TYPE` asks for one; `+noall
+answer` prints only the answer lines. Everything `example.com` holds, one type at a time:

```
ana@laptop:~$ dig +noall +answer example.com A
example.com.            3600    IN      A       192.0.2.80
ana@laptop:~$ dig +noall +answer www.example.com AAAA
www.example.com.        300     IN      AAAA    2001:db8:10::80
ana@laptop:~$ dig +noall +answer shop.example.com
shop.example.com.       3600    IN      CNAME   www.example.com.
www.example.com.        300     IN      A       192.0.2.80
ana@laptop:~$ dig +noall +answer example.com MX
example.com.            3600    IN      MX      10 mail.example.com.
ana@laptop:~$ dig +noall +answer example.com TXT
example.com.            3600    IN      TXT     "v=spf1 mx -all"
ana@laptop:~$ dig +noall +answer _dmarc.example.com TXT
_dmarc.example.com.     3600    IN      TXT     "v=DMARC1; p=reject; rua=mailto:dmarc@example.com"
ana@laptop:~$ dig +noall +answer example.com NS
example.com.            3600    IN      NS      ns1.example.com.
ana@laptop:~$ dig +noall +answer example.com SOA
example.com.            3600    IN      SOA     ns1.example.com. hostmaster.example.com. 2026092501 3600 900 1209600 300
ana@laptop:~$ dig +noall +answer -x 192.0.2.80
80.2.0.192.in-addr.arpa. 3600   IN      PTR     www.example.com.
```

| type | holds | used by |
|---|---|---|
| `A` | an IPv4 address | every connection to the name |
| `AAAA` | an IPv6 address | the same, over IPv6 |
| `CNAME` | another name: "this is an alias of that" | `shop` → `www` |
| `MX` | the mail server for the domain, with a priority | lesson 9 |
| `TXT` | free text, used for rules about the domain | SPF and DMARC, lesson 9 |
| `NS` | the servers that answer for the domain | the resolver, section 04 |
| `SOA` | the zone's serial number and timers | secondary servers, section 06 |
| `PTR` | the name for an address, the other way round | logs, mail servers |

Two things in the answers are worth a second look. **Asking for `shop.example.com` returned two
lines**: the `CNAME` that says it is an alias of `www`, and then the `A` of `www`. The resolver
followed the alias on its own. A `CNAME` cannot sit beside other records with the same name, which is
why the bare domain, `example.com`, has its own `A` instead of an alias.

The **reverse lookup**, `-x 192.0.2.80`, asked for a name under `in-addr.arpa`, with the address
written backwards: `80.2.0.192.in-addr.arpa`. Reverse zones belong to whoever owns the address block,
usually the provider, and mail servers check them (lesson 9).
