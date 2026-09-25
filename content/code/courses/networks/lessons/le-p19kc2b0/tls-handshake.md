---
title: What TLS adds, and how it starts
version: 1
---

TLS gives a connection three things plain HTTP does not have:

- **Confidentiality**: nobody on the path can read it.
- **Integrity**: nobody on the path can change it without the change being detected.
- **Authentication**: the server proves it is the one the name says, with a certificate, lesson 6.

It starts with a handshake, after TCP's and before the first byte of HTTP. `curl -v` names every
message, and filtered to those lines:

```
ana@laptop:~$ curl -sv -o /dev/null https://www.example.com/ 2>&1 | grep -E '^\* (TLSv1.3|SSL connection|ALPN)'
* ALPN: curl offers h2,http/1.1
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384 / X25519 / id-ecPublicKey
* ALPN: server accepted h2
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" aria-label=\"The TLS 1.3 handshake between curl on the laptop and nginx on www. In the clear: ClientHello, carrying the name www.example.com, the protocols h2 and http/1.1, and a key share; ServerHello, carrying the server&#x27;s key share, after which both sides have the same secret. Encrypted from here on: EncryptedExtensions, h2 accepted; Certificate, CN www.example.com and the chain; CertificateVerify, proof the server holds the certificate&#x27;s key; the server&#x27;s Finished; the client&#x27;s Finished; and then the request, GET / HTTP/2, encrypted.\"><defs><marker id=\"t13-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"40\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">laptop, curl</text><text x=\"680\" y=\"20\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">www, nginx</text><path d=\"M40 32 L40 386\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M680 32 L680 386\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"360\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">readable by anyone on the path</text><path d=\"M42 72 L676 80\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t13-ah)\"></path><text x=\"200\" y=\"64\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ClientHello</text><text x=\"214\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">name www.example.com, h2 or http/1.1, a key share</text><path d=\"M678 110 L44 118\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t13-ah)\"></path><text x=\"200\" y=\"102\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ServerHello</text><text x=\"214\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its key share: both sides now have the same secret</text><path d=\"M40 134 L680 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"360\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">encrypted from here on</text><path d=\"M678 170 L44 178\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t13-ah)\"></path><text x=\"200\" y=\"162\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">EncryptedExtensions</text><text x=\"214\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">h2 accepted</text><path d=\"M678 208 L44 216\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t13-ah)\"></path><text x=\"200\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Certificate</text><text x=\"214\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CN = www.example.com, and the chain</text><path d=\"M678 246 L44 254\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t13-ah)\"></path><text x=\"200\" y=\"238\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CertificateVerify</text><text x=\"214\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">proof it holds the certificate&#x27;s key</text><path d=\"M678 284 L44 292\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t13-ah)\"></path><text x=\"200\" y=\"276\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Finished</text><text x=\"214\" y=\"276\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the server&#x27;s side is done</text><path d=\"M42 322 L676 330\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t13-ah)\"></path><text x=\"200\" y=\"314\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Finished</text><text x=\"214\" y=\"314\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the client&#x27;s side is done</text><path d=\"M42 360 L676 368\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t13-ah)\"></path><text x=\"200\" y=\"352\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET / HTTP/2</text><text x=\"214\" y=\"352\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the request, encrypted</text></svg>", "caption": "TLS 1.3 needs one round trip before the request can go. Only the first two messages are readable on the wire, and the name in the first one is the part an observer can always see."}
```

**TLS 1.3 needs one round trip.** The client's **Client hello** carries the name of the site (the
*SNI*, *server name indication*, so a server with many sites knows which certificate to send), the
protocols it can speak (`h2,http/1.1`, the *ALPN* list) and its half of a key exchange. The **Server
hello** carries the server's half, and from that moment both sides share a secret nobody on the path
saw. Everything after it is encrypted, the certificate included. `Change cipher spec` is a leftover
that TLS 1.3 sends only to get past old middleboxes, and the two `Newsession Ticket`s let the next
connection skip part of this. `openssl s_client` summarises the result:

```
ana@laptop:~$ openssl s_client -connect www.example.com:443 -servername www.example.com -brief </dev/null 2>&1
CONNECTION ESTABLISHED
Protocol version: TLSv1.3
Ciphersuite: TLS_AES_256_GCM_SHA384
Peer certificate: CN = www.example.com
Hash used: SHA256
Signature type: ECDSA
Verification: OK
Server Temp Key: X25519, 253 bits
DONE
```

**`Verification: OK`** is the line that matters here, and lesson 6 is about what it checked.
`X25519` is the key exchange, and `TLS_AES_256_GCM_SHA384` is the cipher everything else was encrypted
with.
