---
title: Taking a certificate back
version: 1
---

The key for `app.corp.example.com` was copied to a laptop that was then stolen. The certificate is
valid until 28 December, and anybody holding the key can present it. **Revocation** is the CA saying,
before the expiry date, that it no longer stands behind a certificate:

```
root@admin:~# cd ca; openssl ca -config ca.cnf -cert issuing.crt -keyfile issuing.key -revoke app.crt -crl_reason keyCompromise 2>&1 | tail -1
Database updated
```

The register is updated, but clients never read the CA's register. The CA publishes a **certificate
revocation list** (CRL), a list of revoked serials, signed by the CA and valid for a stated period:

```
root@admin:~# cd ca; openssl ca -config ca.cnf -cert issuing.crt -keyfile issuing.key -gencrl -crldays 7 -out issuing.crl 2>/dev/null; openssl crl -in issuing.crl -noout -text | grep -E "Last Update|Next Update|Serial Number|Revocation Date|Key Compromise"
        Last Update: Sep 28 20:47:40 2026 GMT
        Next Update: Oct  5 20:47:40 2026 GMT
    Serial Number: 1003
        Revocation Date: Sep 28 20:47:40 2026 GMT
                Key Compromise
```

Serial 1003, revoked, reason `Key Compromise`, and a `Next Update` seven days out: clients may cache
the list for that long, and the CA promises a fresh one by then. A verifier that checks the CRL refuses
the revoked certificate and still accepts the others:

```
root@admin:~# cd ca; cat issuing.crt root.crt > chain.pem; openssl verify -crl_check -CAfile chain.pem -CRLfile issuing.crl app.crt; openssl verify -crl_check -CAfile chain.pem -CRLfile issuing.crl www.example.com.crt
CN = app.corp.example.com
error 23 at 0 depth lookup: certificate revoked
error app.crt: verification failed
www.example.com.crt: OK
```

Error 23, `certificate revoked`, for `app`; `OK` for `www`. The register now marks the line `R`, with
the date and the reason:

```
root@admin:~# cd ca; tail -2 index.txt
V	261130000000Z		1002	unknown	/CN=www.example.com
R	261228000000Z	260928204740Z,keyCompromise	1003	unknown	/CN=app.corp.example.com
```

## Why revocation is the weak link

Everything above works when the verifier checks. **On the public web, many clients do not check at
all**, or check and carry on if the list cannot be fetched, which is exactly what somebody using a
stolen key would arrange. The alternatives each trade something:

| mechanism | how | its weakness |
|---|---|---|
| CRL | the client downloads the CA's list | lists grow large; clients skip them |
| OCSP | the client asks the CA about one certificate | a query per connection, and the CA learns what everyone visits |
| OCSP stapling | the server fetches the answer and sends it in the handshake | only helps if the client insists on it |
| short lifetimes | certificates valid for days or weeks, renewed automatically | needs automation everywhere |

The direction the web has taken is the last row: when a certificate lives for a few weeks, a stolen
key is useful for a few weeks, revocation or not. Inside a company the CA controls both ends, so it
can do what the public web cannot: **make every client check the CRL and refuse when it cannot**.
