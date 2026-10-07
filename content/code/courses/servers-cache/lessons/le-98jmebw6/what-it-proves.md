---
title: What a certificate proves
version: 1
---

The common belief is that HTTPS means "encrypted", and that the padlock says the site is safe. Both
are half of it. **TLS does two jobs: it encrypts the connection, and it proves that the server at the
other end is the one the name belongs to.** Encryption alone is cheap and nearly worthless: a
connection encrypted to an impostor is a private conversation with the wrong person. The certificate
is the half that rules the impostor out, and it says nothing at all about whether the site is honest.

A certificate is a small signed document. It contains:

- the **names** it is valid for, in the *Subject Alternative Name* extension: `ipelivros.example`,
  `www.ipelivros.example`. The older *Common Name* field is no longer what browsers check;
- a **public key**, whose private half stays on the server and never leaves it;
- the **dates** it is valid between;
- the **issuer**, and the issuer's signature over all of the above.

During the handshake the server sends its certificate and proves it holds the private key that
matches it. The client checks that the name it asked for is in the list, that today is between the
dates, and that the signature is genuine. Then it asks who the issuer is.

## The chain

The issuer is a **certificate authority**, a CA, and its certificate is signed by another, until the
chain reaches a **root**: a certificate that signs itself and that your operating system or browser
ships in a list of roots it trusts. Ubuntu keeps that list in `/etc/ssl/certs`. A root is never used
to sign a website's certificate directly; it signs an **intermediate**, kept online, and the
intermediate signs the sites, so that the root's key can stay offline where nobody can steal it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 230\" role=\"img\" aria-label=\"Three certificates in a column. The root signs itself and lives in the client&#x27;s trust store. The root signs the intermediate. The intermediate signs the site&#x27;s certificate for ipelivros.example. The server sends the site&#x27;s certificate and the intermediate; the client already holds the root.\"><defs><marker id=\"fch-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"14\" width=\"230\" height=\"52\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"155.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">root CA</text><text x=\"155.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">issuer = itself</text><rect x=\"40\" y=\"89\" width=\"230\" height=\"52\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"155.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">intermediate CA</text><text x=\"155.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">issuer = root</text><rect x=\"40\" y=\"164\" width=\"230\" height=\"52\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"155.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ipelivros.example</text><text x=\"155.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">issuer = intermediate</text><line x1=\"155\" y1=\"66\" x2=\"155\" y2=\"87\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fch-ah)\"></line><line x1=\"155\" y1=\"141\" x2=\"155\" y2=\"162\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fch-ah)\"></line><text x=\"165\" y=\"77\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">signs</text><text x=\"165\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">signs</text><rect x=\"400\" y=\"14\" width=\"270\" height=\"52\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"535.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">already on the client</text><text x=\"535.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/etc/ssl/certs</text><rect x=\"400\" y=\"110\" width=\"270\" height=\"90\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"535.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sent by the server</text><text x=\"535.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">fullchain.pem</text><text x=\"535.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">site + intermediate</text><line x1=\"272\" y1=\"40\" x2=\"398\" y2=\"40\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#fch-ah)\"></line><line x1=\"272\" y1=\"115\" x2=\"398\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#fch-ah)\"></line><line x1=\"272\" y1=\"190\" x2=\"398\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#fch-ah)\"></line></svg>", "caption": "A chain of signatures, ending at a root the client trusted before the connection began."}
```

The server sends its own certificate and the intermediates. It does not send the root, because a
root the client does not already hold would prove nothing: anybody can make a certificate that signs
itself. That is exactly what the next section does.

**What a CA such as Let's Encrypt checks before signing is that you control the name**, and nothing
else: not who you are, not whether the business is real, not whether the site is safe. That kind of
certificate is called *domain-validated*, and it is what nearly every site uses; the paid kinds that
also check an organisation's papers are not shown any differently by today's browsers. A phishing site at a look-alike
domain gets a perfectly valid certificate for that domain. The padlock means "you are talking to
whoever controls this name", which is a precise and useful promise, and a narrower one than most
people read into it.
