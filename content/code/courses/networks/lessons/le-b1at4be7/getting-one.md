---
title: How a server gets a certificate
version: 1
---

It starts on the server, with a key that never leaves it. From the key comes a **certificate signing
request**, a CSR: the public key and the names, signed with the private key, which is what gets sent to
a certificate authority:

```
ana@server:~$ openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -subj "/CN=files.example.com" -keyout files.key -out files.csr 2>/dev/null; ls -l files.key files.csr
-rw-r--r-- 1 ana ana 367 Sep 25 14:03 files.csr
-rw------- 1 ana ana 241 Sep 25 14:03 files.key
ana@server:~$ openssl req -in files.csr -noout -subject -verify
Certificate request self-signature verify OK
subject=CN = files.example.com
ana@server:~$ head -1 files.key; head -1 files.csr
-----BEGIN PRIVATE KEY-----
-----BEGIN CERTIFICATE REQUEST-----
```

Two files. **`files.key` is `-rw-------`**, readable only by its owner, and it is the one to protect;
`files.csr` is safe to send anywhere. `-verify` checks that the request was signed by the key it
carries.

The authority then has to check that whoever sent the request controls the name. For most websites
today that is done by the **ACME** protocol, invented by Let's Encrypt, with no person involved:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"How an ACME client such as certbot on the web server gets a certificate from a certificate authority such as Let&#x27;s Encrypt. The client asks for a certificate for www.example.com. The CA answers: prove it, serve this token. The client places the token at /.well-known/acme-challenge/ on the site. The CA fetches it over HTTP from www.example.com, which only works if the name points at this server. The client sends a certificate signing request signed with the site&#x27;s key. The CA returns the certificate, valid for 90 days. Nothing here was run in the lab.\"><defs><marker id=\"ac-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"40\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">certbot on www</text><text x=\"680\" y=\"20\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the CA, Let&#x27;s Encrypt</text><path d=\"M40 32 L40 286\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M680 32 L680 286\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M42 64 L676 72\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ac-ah)\"></path><text x=\"360\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1  I want a certificate for www.example.com</text><path d=\"M678 104 L44 112\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ac-ah)\"></path><text x=\"360\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">2  prove it: serve this token</text><path d=\"M42 144 L676 152\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ac-ah)\"></path><text x=\"360\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">3  token placed at /.well-known/acme-challenge/</text><path d=\"M678 184 L44 192\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ac-ah)\"></path><text x=\"360\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">4  the CA fetches http://www.example.com/.well-known/…</text><path d=\"M42 224 L676 232\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ac-ah)\"></path><text x=\"360\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">5  a CSR, signed with the site&#x27;s key</text><path d=\"M678 264 L44 272\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ac-ah)\"></path><text x=\"360\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">6  the certificate, valid 90 days</text></svg>", "caption": "Proving control of the name, not identity, is what a certificate like this checks. Because nobody types anything, it can be done every two months without anybody noticing, which is the point."}
```

**None of that was run for this lesson**: the lab has no public certificate authority, and its own CA
signed the lab's certificates directly. The `http-01` check in the drawing proves the requester
controls the web server the name points at; a `dns-01` check proves it controls the name's DNS, by
publishing a `TXT` record at `_acme-challenge.www.example.com`, which is the one that works for
servers not reachable from the internet.

Automation is what makes short certificates bearable. Let's Encrypt issues for 90 days, like the
lab's, and a program such as `certbot` renews them about a month before they end. The CA/Browser Forum,
where authorities and browsers set the rules, voted in 2025 to shorten the maximum for every
certificate step by step, to 47 days by 2029. **A certificate renewed by hand every year is the one
that expires on a Sunday.**
