---
title: Revocation: taking a certificate back before it expires
version: 1
---

**Revocation is the issuer declaring that a certificate must no longer be trusted, before its
`Not After` date: because its key leaked, because it was issued wrongly, or because the name changed
hands.** The mechanism exists and works in the lab. On the public web it has never worked well,
which is a large part of why certificate lifetimes are shrinking.

## Vereda revokes one

On 20 May, the private key of `files.vereda.example` was found in a public repository. Vereda's
issuing CA added the certificate's serial number to its **certificate revocation list** (CRL), a
file it signs and publishes:

```
ana@lab:~/lab$ openssl crl -in pki/issuing1.crl -noout -text | head -15
Certificate Revocation List (CRL):
        Version 2 (0x1)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = BR, O = Vereda Fisioterapia, CN = Vereda Issuing CA 1
        Last Update: Jun  1 00:00:00 2026 GMT
        Next Update: Jun 30 00:00:00 2026 GMT
        CRL extensions:
            X509v3 CRL Number: 
                7
Revoked Certificates:
    Serial Number: 3A03
        Revocation Date: May 20 00:00:00 2026 GMT
        CRL entry extensions:
            X509v3 CRL Reason Code: 
                Key Compromise
```

The list names the issuer, when it was made (`Last Update`), when the next one is due
(`Next Update`), and each revoked serial with its date and reason. `3A03` is the files server's
serial, the same number its certificate carries in the `Serial Number` field. The CRL is signed by
the issuing CA, so nobody else can add or remove entries.

## A check that has to be asked for

Checked the way the earlier sections did, the files server's certificate passes. Its chain, dates
and signature are all fine:

```
ana@lab:~/lab$ openssl verify -attime 1781535600 -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/files.pem
pki/files.pem: OK
```

Only when verification is told to consult the CRL does it fail:

```
ana@lab:~/lab$ openssl verify -attime 1781535600 -crl_check -CRLfile pki/issuing1.crl -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/files.pem
C = BR, O = Vereda Fisioterapia, CN = files.vereda.example
error 23 at 0 depth lookup: certificate revoked
error pki/files.pem: verification failed
```

That is the weakness of revocation in one pair of commands. **A client that does not look does not
know.** And the CRL itself expires: once `Next Update` has passed, the list can no longer be trusted
to be current, and a client that requires it refuses everything, here a certificate that was never
revoked:

```
ana@lab:~/lab$ openssl verify -attime $(date -d "2026-07-15 12:00 -03" +%s) -crl_check -CRLfile pki/issuing1.crl -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/portal.pem
C = BR, O = Vereda Fisioterapia, CN = portal.vereda.example
error 12 at 0 depth lookup: CRL has expired
error pki/portal.pem: verification failed
```

## Where the client looks, and why it often does not

Each certificate says where its issuer publishes the CRL:

```
ana@lab:~/lab$ openssl x509 -in pki/portal.pem -noout -ext crlDistributionPoints
X509v3 CRL Distribution Points: 
    Full Name:
      URI:http://pki.vereda.example/issuing1.crl
```

Three ways of checking have been tried on the public web, and each has a problem:

- **CRLs** can grow large, and fetching one for every connection is slow;
- **OCSP**, a service the client queries about one certificate, tells the CA which sites each user
  visits, and when the responder does not answer, browsers have always **continued anyway**
  (*soft-fail*), so an attacker who can block the query defeats it. *OCSP stapling*, where the server
  fetches the answer and sends it in the handshake, fixes the privacy and speed problems but needs
  every server to do it. Let's Encrypt, the largest CA, ended its OCSP service in 2025 and publishes
  CRLs instead;
- **browser-maintained lists**: Chrome's CRLSets and Firefox's CRLite compress the revocations that
  matter into a list the browser downloads, which is how revocation of public certificates mostly
  works now.

The conclusion the industry drew is the one lesson 8 ended on: **if revocation cannot be relied on,
make certificates expire quickly.** A 47-day certificate that leaks is a much smaller problem than a
398-day one whose revocation nobody checks.

For an **internal** CA the situation is better, because the clients are yours: you can require the
CRL check, publish the CRL somewhere every client reaches, and refresh it well before `Next Update`.
The capture of the expired CRL above is what happens on the day that refresh fails.
