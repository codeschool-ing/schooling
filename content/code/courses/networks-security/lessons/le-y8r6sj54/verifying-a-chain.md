---
title: Verifying a chain, link by link
version: 1
---

A client checks a certificate by walking up from it to a root it trusts, checking at every step that
the signature is valid, the dates are current and the issuer was allowed to sign. The server helps by
sending its own certificate **and the intermediate**, and the client supplies the root from its store:

```
ana@laptop:~$ openssl s_client -connect www.example.com:443 -servername www.example.com </dev/null 2>/dev/null | grep -E "^ *[0-9] s:|^ *i:|^Verify return code"
 0 s:CN = www.example.com
   i:O = Example Corp, CN = Example Corp Issuing CA
 1 s:O = Example Corp, CN = Example Corp Issuing CA
   i:O = Example Corp, CN = Example Corp Root CA
Verify return code: 0 (ok)
```

Depth 0 is `www.example.com`, issued by the issuing CA; depth 1 is the issuing CA, issued by the root.
The root is not sent; `laptop` already has it. `Verify return code: 0 (ok)`.

`openssl verify` does the same walk by hand. Given only the root as trusted and the server's
certificate, it cannot find the link in the middle:

```
root@admin:~# cd ca; openssl verify -CAfile root.crt www.example.com.crt
CN = www.example.com
error 20 at 0 depth lookup: unable to get local issuer certificate
error www.example.com.crt: verification failed
```

Error 20, `unable to get local issuer certificate`: the certificate names an issuer that the verifier
does not have. With the intermediate supplied as **untrusted**, a certificate to be checked on its way
up rather than believed on its own, the walk completes:

```
root@admin:~# cd ca; openssl verify -CAfile root.crt -untrusted issuing.crt www.example.com.crt
www.example.com.crt: OK
```

That word matters. **Only roots are trusted; intermediates are verified.** A server that forgets to
send its intermediate produces exactly error 20 on the clients that have not seen that intermediate
before, which is `networks` lesson 6's missing-chain failure seen from the CA's side.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"How a client walks a chain. The server sends two certificates: its own, www.example.com, and the issuing CA&#x27;s. The client has the root in its trust store. It checks that the issuing CA signed www.example.com, then that the root signed the issuing CA, and stops at the root because it trusts it. Missing the issuing CA&#x27;s certificate, the walk breaks at the first step: error 20.\"><defs><marker id=\"cw-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"180\" width=\"220\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www.example.com</text><text x=\"30\" y=\"213\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">depth 0: sent by the server</text><rect x=\"20\" y=\"100\" width=\"220\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Example Corp Issuing CA</text><text x=\"30\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">depth 1: sent by the server</text><rect x=\"20\" y=\"20\" width=\"220\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Example Corp Root CA</text><text x=\"30\" y=\"53\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">in the trust store</text><path d=\"M130 180 L130 146\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#cw-ah-paper-dim)\"></path><path d=\"M130 100 L130 66\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#cw-ah-paper-dim)\"></path><text x=\"142\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">signed by?</text><text x=\"142\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">signed by?</text><text x=\"300\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">trusted: the walk stops here</text><text x=\"300\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">checked: signature, dates, CA:TRUE, pathlen:0</text><text x=\"300\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">checked: signature, dates, name, key usage</text><text x=\"300\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">without depth 1: error 20, unable to get local issuer certificate</text></svg>", "caption": "Sent by the server: the first two. Already on the client: the root. Only the root is trusted; the rest is checked."}
```
