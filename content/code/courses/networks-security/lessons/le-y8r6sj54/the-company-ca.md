---
title: The company's own authority, field by field
version: 1
---

The lab has had a CA since lesson 2: a **root**, which signs an **issuing CA**, which signs the
servers. It lives on `admin` here. The three certificates, with the fields that decide what each may
do:

```
root@admin:~# cd ca; for c in root issuing www.example.com; do echo "== $c"; openssl x509 -in $c.crt -noout -subject -issuer -dates -ext basicConstraints,keyUsage,extendedKeyUsage,subjectAltName 2>/dev/null; done
== root
subject=O = Example Corp, CN = Example Corp Root CA
issuer=O = Example Corp, CN = Example Corp Root CA
notBefore=Sep  1 00:00:00 2026 GMT
notAfter=Sep  1 00:00:00 2036 GMT
X509v3 Basic Constraints: critical
    CA:TRUE
X509v3 Key Usage: critical
    Certificate Sign, CRL Sign
== issuing
subject=O = Example Corp, CN = Example Corp Issuing CA
issuer=O = Example Corp, CN = Example Corp Root CA
notBefore=Sep  1 00:00:00 2026 GMT
notAfter=Sep  1 00:00:00 2031 GMT
X509v3 Basic Constraints: critical
    CA:TRUE, pathlen:0
X509v3 Key Usage: critical
    Certificate Sign, CRL Sign
== www.example.com
subject=CN = www.example.com
issuer=O = Example Corp, CN = Example Corp Issuing CA
notBefore=Sep  1 00:00:00 2026 GMT
notAfter=Nov 30 00:00:00 2026 GMT
X509v3 Basic Constraints: critical
    CA:FALSE
X509v3 Key Usage: critical
    Digital Signature
X509v3 Extended Key Usage: 
    TLS Web Server Authentication
X509v3 Subject Alternative Name: 
    DNS:www.example.com, DNS:example.com
```

Read them as three different jobs:

| certificate | issuer | valid for | may sign certificates? |
|---|---|---|---|
| Example Corp Root CA | itself | 10 years | yes, `CA:TRUE` |
| Example Corp Issuing CA | the root | 5 years | yes, but `pathlen:0`: only end certificates, never another CA |
| www.example.com | the issuing CA | 90 days | no, `CA:FALSE`; `Digital Signature` and `TLS Web Server Authentication` only |

**The root signs itself**, subject and issuer the same. Nothing vouches for it; it is trusted because
somebody installed it in the trust store, the list of roots a machine believes. On `laptop`:

```
ana@laptop:~$ ls -l /etc/ssl/certs/ | grep -i example; openssl x509 -in /etc/ssl/certs/example-corp-root-ca.pem -noout -subject -fingerprint -sha256
lrwxrwxrwx 1 root root     24 Sep 28 17:47 89e5d190.0 -> example-corp-root-ca.pem
lrwxrwxrwx 1 root root     57 Sep 28 17:47 example-corp-root-ca.pem -> /usr/local/share/ca-certificates/example-corp-root-ca.crt
subject=O = Example Corp, CN = Example Corp Root CA
sha256 Fingerprint=13:89:5E:5B:39:9B:02:5D:08:40:35:7B:8D:2B:41:15:12:F7:CC:BA:A9:9B:CB:D9:10:46:20:32:B7:51:10:D8
```

The company's root sits beside the public ones, and its fingerprint is what an administrator reads
aloud, or publishes internally, so that people installing it can check they have the right file.

## Why two levels

The root's private key could sign the servers directly. It does not, because **the root is the one
key whose loss cannot be repaired**: every machine that trusts it would have to be reconfigured. So
the root signs an issuing CA once and then goes offline, in a real company on a machine never
connected to a network, kept in a safe and used a few times in ten years. The issuing CA does the
daily work, and if its key is ever lost, the root revokes it and signs a new one, and the machines'
trust stores do not change.

`pathlen:0` and `CA:FALSE` are the limits that make this safe: a server's certificate cannot be used
to sign another certificate, and the issuing CA cannot create a CA of its own.
