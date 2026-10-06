---
title: When a CA gets it wrong
version: 1
---

**Every one of the hundred or so trusted roots can sign a certificate for any name, so the system is
only as strong as the weakest CA on the list.** That is the design's known flaw. The response, built
over the last fifteen years, does not try to make every CA perfect. It makes every certificate
**public**, so that a wrong one is seen, and it makes the consequences for a CA that misbehaves
severe enough to matter.

## What has happened

- **DigiNotar, 2011.** A Dutch CA was breached and its keys were used to issue more than five hundred
  fraudulent certificates, including one for `*.google.com` that was used to intercept the Gmail
  traffic of users in Iran. It was noticed because Chrome had Google's own keys built in and refused
  the forged certificate. Every browser removed DigiNotar's roots within weeks, and the company went
  bankrupt the same month.
- **Symantec, 2017.** After a series of improperly issued certificates, including test certificates
  for domains nobody had asked about, Google and Mozilla decided to distrust Symantec's roots in
  stages. Symantec sold its CA business, and its certificates stopped working in browsers during 2018.
- **Smaller cases** (TURKTRUST in 2013, CNNIC in 2015, WoSign and StartCom in 2016) ended in
  restrictions or removal. The pattern is the same: a CA issues something it should not, the
  certificate is found, the trust store programmes act.

The DigiNotar case was found by luck, on one site whose owner had pinned its own keys. The
mechanisms below exist so that finding one no longer depends on luck.

## Certificate Transparency

**Certificate Transparency (CT)**, RFC 6962, requires that certificates be written to public,
append-only logs run by several independent organisations. A CA submits each certificate and gets
back a signed receipt, a *Signed Certificate Timestamp*, which it embeds in the certificate. Chrome
has required those receipts for every publicly trusted certificate since 2018, and Safari does the
same; a certificate missing from the logs is refused.

The consequence for a defender is direct: **every certificate any public CA ever issued for your
domain can be listed.** Search services such as crt.sh read the logs, and monitoring tools send an
alert when a certificate for your domain appears that your team did not request. A forged
certificate can still be issued, but it cannot be issued in secret.

## CAA: saying which CAs may issue

A domain can publish a **CAA** record in DNS, listing the only CAs allowed to issue for it. CAs have
been required to check it since 2017 and must refuse when they are not listed. For Vereda, which uses
one CA for its public sites, the record would read:

```
vereda.example.  3600  IN  CAA  0 issue "letsencrypt.org"
vereda.example.  3600  IN  CAA  0 iodef "mailto:security@vereda.example"
```

The second line asks a CA to report refused requests. CAA does not stop a compromised CA that ignores
it; it stops honest CAs from being tricked, which is the more common case.

## Short lifetimes

A certificate that leaks or was wrongly issued is dangerous until it expires, and revocation (lesson 9)
is unreliable. So the CA/Browser Forum has been shortening the maximum lifetime of public TLS
certificates: 398 days since 2020, **200 days from March 2026**, 100 days from March 2027 and 47 days
from March 2029. Vereda's portal certificate in the lab runs from 1 May to 17 November 2026, exactly
200 days. Lifetimes that short only work with **automated renewal**, ACME, and that is the intended
side effect: a team that renews by hand once a year forgets; a team whose servers renew themselves
every few weeks does not.
