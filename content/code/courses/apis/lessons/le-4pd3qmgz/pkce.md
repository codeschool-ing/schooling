---
title: "PKCE: proof that the code is yours"
version: 1
---

**The obvious defence for a code is the client's secret: only the real client can exchange it,
because only the real client knows the secret.** That holds for a program on a server. It fails
for a **public client**, which is any app whose code you can download: a phone app, or a
single-page app running in the browser. A secret shipped inside one of those is in every copy,
and anybody can read it out.

Public clients also have a weaker redirect. A phone app receives its code at an address like
`com.example.reader:/callback`, and on some systems a second app can register the same address
and receive the redirect instead. That is the case PKCE was written for, in RFC 7636 (2015): a
code taken on the way, by somebody who also knows everything the app ships with.

**PKCE (Proof Key for Code Exchange, said "pixy") binds the code to a secret made fresh for this
one sign-in.** Before step 1, the client makes a random string, the **code verifier**, and keeps
it. To `/authorize` it sends only the **code challenge**: the SHA-256 of the verifier, written in
base64url. At `/token` it sends the verifier itself, and the authorization server hashes it and
compares the result with the challenge it stored beside the code.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"PKCE in two moments. At /authorize the client sends only the code challenge, the SHA-256 of its verifier, through the browser, where anyone may read it; the authorization server stores it with the code. At /token the client sends the code and the verifier directly; the server hashes the verifier and compares. A copied code arrives without the verifier and is refused with invalid_grant.\"><defs><marker id=\"l09-pkce-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"120\" width=\"160\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">client</text><text x=\"100.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">keeps the verifier</text><rect x=\"285\" y=\"20\" width=\"150\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">browser</text><text x=\"360.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">anyone may read this</text><rect x=\"530\" y=\"120\" width=\"170\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">authorization server</text><text x=\"615.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">keeps the challenge</text><line x1=\"100\" y1=\"118\" x2=\"283\" y2=\"52\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l09-pkce-ah)\"></line><text x=\"128\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">code_challenge</text><text x=\"128\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">SHA-256 of the verifier</text><line x1=\"437\" y1=\"52\" x2=\"615\" y2=\"118\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l09-pkce-ah)\"></line><text x=\"560\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">1 · at /authorize</text><line x1=\"182\" y1=\"150\" x2=\"528\" y2=\"150\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l09-pkce-ah)\"></line><text x=\"355.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">code + code_verifier</text><text x=\"355\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">2 · at /token, directly</text><text x=\"615\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">S256(verifier) == challenge?</text><rect x=\"270\" y=\"222\" width=\"180\" height=\"54\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a copied code</text><text x=\"360.0\" y=\"257.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no verifier</text><line x1=\"452\" y1=\"249\" x2=\"560\" y2=\"214\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l09-pkce-ah)\"></line><text x=\"615\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">invalid_grant</text><text x=\"615\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">refused</text></svg>", "caption": "The challenge may be read on the way; the verifier is sent once, directly, after the code exists. A code without its verifier is refused."}
```

The challenge travels through the browser and may be seen, and seeing it does not help: a hash
cannot be run backwards to find the verifier. The verifier travels once, on the direct connection,
after the code exists. So whoever took the code holds half of a pair and cannot make the other
half.

`pkce.py` makes one pair:

```python
# shelf/pkce.py
"""A PKCE pair: the verifier the client keeps, the challenge it sends."""
import base64
import hashlib
import secrets

verifier = secrets.token_urlsafe(48)
digest = hashlib.sha256(verifier.encode()).digest()
challenge = base64.urlsafe_b64encode(digest).rstrip(b"=").decode()
print(verifier, challenge)
```

Forty-eight random bytes become a 64-character verifier, inside the 43 to 128 that RFC 7636
allows. The challenge is always 43 characters, because a SHA-256 is 32 bytes and base64url without
the `=` padding writes 32 bytes in 43. Run it from `~/shelf` and you get a new pair each time:

```
ana@api:~/shelf$ python3 pkce.py
-QV9LSW9UeeEE_J5SqR3XIlIimh0zFT6r9fGLi-k4-L9oWtaDbYs9KOV57w1gaUk zANQsEMelf8lNz_YtKNNBuE_aWQcX2F0fOBDwEvziS8
```

**The client has to remember the verifier between the two halves of the flow**, the way a web app
keeps it in the user's session. In your terminal a shell variable does that job. `read` puts the
two words of one run into two variables, and the flow in this lesson uses them:

```
ana@api:~/shelf$ read VERIFIER CHALLENGE < <(python3 pkce.py)
ana@api:~/shelf$ echo $VERIFIER; echo $CHALLENGE
h09V4DsivYL6BRH8zeQYCfK4EInvkd8ltjRhcPohPXCUu4r1sdZkGUMtF6L0XJ6M
TeUBmfOrwmD1rsnQgLpOo1FewMYh88qSkbE83VZ13ys
```

Nothing about the challenge is secret, and you can make it from the verifier with `openssl`,
which proves the transformation is just a hash and an encoding. The output matches the line
above it:

```
ana@api:~/shelf$ printf %s "$VERIFIER" | openssl dgst -sha256 -binary | basenc --base64url | tr -d =
TeUBmfOrwmD1rsnQgLpOo1FewMYh88qSkbE83VZ13ys
```

RFC 7636 also defines a method called `plain`, where the challenge is the verifier itself. It
exists for clients that cannot compute a SHA-256, and it gives up the property above, since the
browser then carries the verifier. `idp.py` accepts only `S256`.

**PKCE is no longer only for public clients.** RFC 9700, the OAuth security recommendations
published in 2025, asks every client to use it, and the OAuth 2.1 draft makes it required. With a
client secret as well, the code is protected twice: a stolen code needs the secret, and a code
slipped into somebody else's session fails the verifier. `idp.py` asks every client for it.
