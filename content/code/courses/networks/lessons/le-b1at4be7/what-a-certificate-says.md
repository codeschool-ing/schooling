---
title: What a certificate says
version: 1
---

A certificate is a public key with a statement attached: "this key belongs to these names, until this
date", signed by somebody who checked. `openssl s_client` fetches the one `www.example.com` sends, and
`openssl x509` prints the fields that matter:

```
ana@laptop:~$ openssl s_client -connect www.example.com:443 -servername www.example.com </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates -ext subjectAltName,basicConstraints,extendedKeyUsage
subject=CN = www.example.com
issuer=O = Example Trust Services, CN = Example Issuing CA 1
notBefore=Sep 25 17:03:48 2026 GMT
notAfter=Dec 24 17:03:48 2026 GMT
X509v3 Subject Alternative Name: 
    DNS:www.example.com, DNS:example.com, DNS:shop.example.com
X509v3 Extended Key Usage: 
    TLS Web Server Authentication
X509v3 Basic Constraints: critical
    CA:FALSE
```

- **`subject`**: who the certificate is about, `CN = www.example.com`. The *common name* is the old
  place for the name, kept for people to read.
- **`issuer`**: who signed it, `Example Issuing CA 1`. Section 03 follows it.
- **`notBefore` and `notAfter`**: the validity, in GMT. This one runs for 90 days, from September to
  December.
- **`Subject Alternative Name`**: the names it is valid for, and **the field clients actually check**.
  One certificate here covers three names: `www.example.com`, `example.com` and `shop.example.com`.
  A name not on this list fails, whatever the subject says.
- `Extended Key Usage: TLS Web Server Authentication` limits it to identifying servers, and
  `CA:FALSE` says it may not sign other certificates.

The **private key** that matches the certificate never leaves the server. The certificate is public,
and is sent to everybody who connects; the key is what proves the server is its owner, in the
handshake's `CertificateVerify` of lesson 5. A leaked key means somebody else can be this server, and
the only fix is a new key and a new certificate.
