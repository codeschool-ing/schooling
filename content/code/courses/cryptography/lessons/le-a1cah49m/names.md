---
title: Names: which hosts a certificate covers
version: 1
---

**A client checks that the host name it connected to appears in the certificate's Subject
Alternative Name list, and nowhere else.** A perfectly valid certificate for one name is useless
for another, and that check is what stops a stolen or mis-issued certificate for `example.org`
being used to impersonate Vereda.

## The list, and the check

The portal's certificate lists one name:

```
ana@lab:~/lab$ openssl x509 -in pki/portal.pem -noout -ext subjectAltName
X509v3 Subject Alternative Name: 
    DNS:portal.vereda.example
```

Asked to check that name, verification passes:

```
ana@lab:~/lab$ openssl verify -attime 1781535600 -verify_hostname portal.vereda.example -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/portal.pem
pki/portal.pem: OK
```

Asked about `www.vereda.example`, which the certificate does not list, it fails, although the chain,
the dates and the signature are all fine:

```
ana@lab:~/lab$ openssl verify -attime 1781535600 -verify_hostname www.vereda.example -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/portal.pem
C = BR, O = Vereda Fisioterapia, CN = portal.vereda.example
error 62 at 0 depth lookup: hostname mismatch
error pki/portal.pem: verification failed
```

## The common name is not checked

The `Subject` line also says `CN = portal.vereda.example`, and for years clients compared the host
name against it. That fallback was a source of ambiguity, and browsers dropped it: Chrome stopped
reading the common name in 2017, and the CA/Browser Forum's rules require every name to be in the
SAN list. **A certificate whose name appears only in the CN fails in a modern browser.** It is still
a common mistake in certificates made by hand for internal services, which then work in an old
library and fail everywhere else.

## Wildcards

A SAN entry may start with `*.`, which matches **exactly one** label at that position:

| SAN entry | matches | does not match |
|---|---|---|
| `*.vereda.example` | `portal.vereda.example`, `agenda.vereda.example` | `vereda.example`, `a.b.vereda.example` |
| `vereda.example` | `vereda.example` | `www.vereda.example` |

A wildcard is convenient and widens what one stolen key exposes: every host under the domain shares
it. Teams that use one keep it to hosts with the same owner and the same security, and prefer one
certificate per service where automation makes that cheap.

## Who does the check

`openssl verify` only checked the name because it was asked to with `-verify_hostname`. Browsers and
most HTTP libraries check by default. The danger is lower-level code: a raw TLS socket, an old
library, or a configuration flag can check the chain and skip the name. **A certificate that
chains to a trusted root, checked without its name, proves only that somebody somewhere has a
certificate.** In Python, `ssl.create_default_context()` checks both; code that builds an
`SSLContext` by hand and sets `check_hostname = False` does not. Lesson 10 shows the same mismatch
from the client's side of a real handshake.
