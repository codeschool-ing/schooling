---
title: An exchange with whom? Authenticating the key exchange
version: 1
---

**Diffie-Hellman agrees a secret with whoever answered, and on its own it cannot tell who that
was.** An attacker sitting between Ana and the server can run one exchange with Ana and another
with the server, and relay everything between them. Each side ends up with a perfectly good shared
secret, shared with the attacker. This is the *man-in-the-middle* problem, and every protocol that
uses Diffie-Hellman has to answer it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A man in the middle. Ana runs a Diffie-Hellman exchange with the attacker, believing it is the server, and agrees secret one. The attacker runs a second exchange with the server and agrees secret two. Everything Ana sends is decrypted with secret one, read, and re-encrypted with secret two. A signature over the exchange, checked against the server&#x27;s certificate, is what Ana would need to notice.\"><defs><marker id=\"mitm-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"60\" width=\"140\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Ana</text><rect x=\"290\" y=\"60\" width=\"140\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">attacker</text><text x=\"360\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reads everything</text><rect x=\"560\" y=\"60\" width=\"140\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">server</text><polyline points=\"162,90 288,90\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#mitm-ah-amber)\"></polyline><polyline points=\"288,98 162,98\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#mitm-ah-amber)\"></polyline><text x=\"225\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">secret 1</text><polyline points=\"432,90 558,90\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#mitm-ah-amber)\"></polyline><polyline points=\"558,98 432,98\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#mitm-ah-amber)\"></polyline><text x=\"495\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">secret 2</text><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the fix: the server signs the exchange with its certificate key</text><text x=\"360\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">and the attacker cannot produce that signature</text></svg>", "caption": "Two honest exchanges, one dishonest party in the middle."}
```

## Why the exchange cannot see it

Look at what Ana receives in section 02: a number, 19, with nothing attached to say who chose it. An
attacker who replaces 19 with a value of their own is indistinguishable from Bruno. The mathematics
of the exchange is untouched; the attacker simply does two honest exchanges. Encryption on top of
that secret protects Ana's data from everybody except the one party she should have been protected
from.

## The fix: sign the exchange

The answer combines this lesson with lessons 3 and 8. The server has a **long-term key pair**, and
its public key is bound to its name by a certificate that a CA signed. During the exchange the
server **signs** its ephemeral public value, and in TLS 1.3 the whole conversation so far, with that
long-term key. Ana checks:

1. that the certificate chains to a CA she trusts and names the server she meant to reach (lessons
   8 and 9);
2. that the signature over the exchange verifies with the key in that certificate.

An attacker in the middle can still run an exchange with Ana, but cannot produce that signature,
because the private key never left the server. Ana's check fails and she stops. Each key does one
job: the **ephemeral** pair provides the secret and forward secrecy; the **long-term** pair provides
identity, and never encrypts anything.

## Where people switch it off

The authentication step is the one that gets disabled, usually to make an error go away:

- `curl -k`, `verify=False` in Python's `requests`, `InsecureSkipVerify: true` in Go and
  `NODE_TLS_REJECT_UNAUTHORIZED=0` all keep the encryption and remove the check of **who** is on the
  other end. What remains is an encrypted conversation with whoever answered;
- SSH asks the same question the first time it meets a server (*"The authenticity of host … can't
  be established"*), and typing `yes` without comparing the fingerprint is the same choice.

The fix for a certificate error is almost never to stop checking. It is to find out why the check
failed, and lesson 10 is a tour of the reasons.
