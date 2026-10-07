---
title: Issuing a certificate for an internal service
version: 1
---

The application on `app` will get its own certificate, for the internal name `app.corp.example.com`,
so that lesson 20 can encrypt the proxy's connection to it. Issuance has two halves, and the key never
changes hands.

**The server makes its key and a request.** A certificate signing request (CSR) holds the public key
and the name, and is signed with the private key to prove the requester holds it:

```
root@admin:~# cd ca; openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -subj "/CN=app.corp.example.com" -keyout app.key -out app.csr 2>/dev/null; openssl req -in app.csr -noout -subject -verify
Certificate request self-signature verify OK
subject=CN = app.corp.example.com
```

`self-signature verify OK`: whoever made this request has the private key that matches the public key
inside it. In a real deployment this runs on `app`, and only the CSR travels to the CA.

**The CA decides what to sign.** It does not copy whatever the request asks for; it applies its own
profile. The extensions for this certificate, written down before signing: the `[server]` section of
`ca.cnf` and one more line with the name, made with
`{ sed -n "/^\[server\]/,/^\[/p" ca.cnf | sed "\$d"; echo "subjectAltName = DNS:app.corp.example.com"; } > app.ext`
inside `ca`:

```
root@admin:~# cd ca; cat app.ext
[server]
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature
extendedKeyUsage = serverAuth
authorityKeyIdentifier = keyid
subjectAltName = DNS:app.corp.example.com
```

A server certificate, not a CA, usable for signatures in TLS server authentication, for one name.
The CA signs with those extensions and fixed dates, three months from today:

```
root@admin:~# cd ca; openssl ca -batch -config ca.cnf -cert issuing.crt -keyfile issuing.key -extfile app.ext -extensions server -startdate 20260928000000Z -enddate 20261228000000Z -in app.csr -out app.crt -notext 2>&1 | grep -E "Signature ok|Data Base"
Signature ok
root@admin:~# cd ca; openssl x509 -in app.crt -noout -serial -subject -issuer -dates -ext subjectAltName
serial=1003
subject=CN = app.corp.example.com
issuer=O = Example Corp, CN = Example Corp Issuing CA
notBefore=Sep 28 00:00:00 2026 GMT
notAfter=Dec 28 00:00:00 2026 GMT
X509v3 Subject Alternative Name: 
    DNS:app.corp.example.com
```

Serial `1003`, the next number in the CA's sequence. **The CA keeps a register of everything it has
issued**, one line per certificate:

```
root@admin:~# cd ca; tail -2 index.txt
V	261130000000Z		1002	unknown	/CN=www.example.com
V	261228000000Z		1003	unknown	/CN=app.corp.example.com
```

`V` for valid, the expiry date, the serial and the subject. That register is what makes the next
section possible: a CA can only take back what it knows it issued.

## Checking the requester

Signing is mechanical; **deciding whether to sign is the CA's whole value**. A public CA checks
control of the name, typically by asking the requester to publish a random value in DNS or on the web
server, and issues automatically through the ACME protocol when the check passes. An internal CA
answers to the company's own process: a ticket, an owner for the service, a name inside the company's
domain. Whatever the check is, it is written down, because a CA that signs whatever it is sent has
given its signature away.
