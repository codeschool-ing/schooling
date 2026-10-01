---
title: A session cookie is a password that expires
version: 1
---

The cookie in this lesson's first capture, `session=7f3a9c2e`, is how the shop's application
recognises a signed-in customer on every request after the first. **Whoever presents it is that
customer** as far as the application can tell. Copying one from the wire and presenting it is
**session hijacking**: no password was needed, because the password was used once, at sign-in, and the
cookie replaced it.

That makes a session cookie a secret with the same weight as a password, and the defences follow
from treating it as one. Most are set by the application in the `Set-Cookie` header, and a defender
reviewing an application checks each:

| setting | what it prevents |
|---|---|
| `Secure` | the browser never sends the cookie over plain HTTP, so the first capture of this lesson could not happen |
| `HttpOnly` | scripts in the page cannot read it, so injected script cannot copy it |
| `SameSite=Lax` or `Strict` | other sites cannot make the browser send it with their requests |
| a short lifetime, renewed at sign-in | a copied cookie stops working soon, and a new session starts with a new value |
| invalidation at sign-out | the value dies with the session instead of lingering on the server |

**The first row only works with the rest of the site on HTTPS**, and lesson 13 shows what an attacker
on the path does with a site that answers on plain HTTP first and redirects afterwards: the redirect
itself travels in clear. That is why `Secure` pairs with HSTS, which tells the browser never to try
plain HTTP for the site at all.

## What the network can add

The network's contribution is the rest of this lesson: segments where a stranger cannot listen,
switches that refuse forged ARP, and a sensor that notices when something changes. None of those
protects a cookie sent in clear across a café's Wi-Fi. **Only the application, by never letting the
cookie travel unencrypted, protects it everywhere.**
