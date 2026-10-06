---
title: How a six-digit code is made
version: 1
---

The most common second factor is an authenticator app that shows six digits and changes them every
thirty seconds. It looks like magic, since the phone needs no connection to the server, and it is
a short piece of arithmetic standardised as **TOTP**, time-based one-time password, in RFC 6238.

When ana turns on MFA, the server generates a random **secret**, usually shown as a QR code, and her
app stores it. From then on both sides hold the same secret, and neither ever sends it again. To make
a code, each side takes the secret and the current time and computes the same thing:

```schooling-figure
{"svg": "<svg id=\"sf-totp\" viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"How a TOTP code is made, on the phone and on the server at once. Both hold the same secret. Both take the time, 13:00:00 UTC, divide it into 30-second steps to get the counter 59709720, compute an HMAC of the counter with the secret, and cut it to six digits: 593771. The server compares its result with what the person typed. Nothing but the six digits crosses the network.\"><defs><marker id=\"sf-totp-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sf-totp-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"sf-totp-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">phone (app)</text><rect x=\"20\" y=\"70\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">time ÷ 30 s</text><rect x=\"190\" y=\"70\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"250.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">59709720</text><rect x=\"340\" y=\"70\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"395.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">HMAC</text><rect x=\"340\" y=\"14\" width=\"110\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"395.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">secret</text><rect x=\"600\" y=\"70\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"650.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">593771</text><path d=\"M160 90 L190 90\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-totp-ah-wire)\"></path><path d=\"M310 90 L340 90\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-totp-ah-wire)\"></path><path d=\"M450 90 L600 90\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-totp-ah-wire)\"></path><path d=\"M395 50 L395 70\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#sf-totp-ah-amber)\"></path><text x=\"20\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">server</text><rect x=\"20\" y=\"170\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">time ÷ 30 s</text><rect x=\"190\" y=\"170\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"250.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">59709720</text><rect x=\"340\" y=\"170\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"395.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">HMAC</text><rect x=\"340\" y=\"226\" width=\"110\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"395.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">secret</text><rect x=\"600\" y=\"170\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"650.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">593771</text><path d=\"M160 190 L190 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-totp-ah-wire)\"></path><path d=\"M310 190 L340 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-totp-ah-wire)\"></path><path d=\"M450 190 L600 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-totp-ah-wire)\"></path><path d=\"M395 226 L395 210\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#sf-totp-ah-amber)\"></path><path d=\"M650 110 L650 170\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#sf-totp-ah-phosphor)\"></path><text x=\"640\" y=\"134.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the person types it</text><text x=\"640\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the server compares</text><text x=\"470\" y=\"248.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Same secret, same step → same digits.</text></svg>", "caption": "Two sides compute the same code apart. Only the code travels; the secret never does."}
```

1. Divide the time since 1 January 1970 by 30 seconds and drop the fraction. That number, the
   **counter**, is the same for everybody during the same thirty-second step.
2. Compute an HMAC of the counter with the secret: a keyed hash that nobody without the secret can
   reproduce (`cryptography` lesson 6).
3. Cut the result down to six decimal digits.

Here is `oathtool`, a program that does the same calculation as an authenticator app, asked to show
its working. The secret is a public one, the example secret from the RFC itself, so it protects
nothing and can be printed:

```
ana@laptop:~$ oathtool --totp -b -v --now '2026-10-06 13:00:00 UTC' GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ
Hex secret: 3132333435363738393031323334353637383930
Base32 secret: GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ
Digits: 6
Window size: 0
TOTP mode: SHA1
Step size (seconds): 30
Start time: 1970-01-01 00:00:00 UTC (0)
Current time: 2026-10-06 13:00:00 UTC (1791291600)
Counter: 0x38F1918 (59709720)

593771
```

Everything in the recipe is there: the secret in two spellings, six digits, SHA-1 as the hash, a step
of 30 seconds counted from 1970. At 13:00:00 UTC on 6 October 2026 the counter is `59709720`, and the
code is `593771`.

Because the code depends on the step and not on the exact second, it lasts the whole step:

```
ana@laptop:~$ oathtool --totp -b --now '2026-10-06 13:00:00 UTC' GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ
593771
ana@laptop:~$ oathtool --totp -b --now '2026-10-06 13:00:29 UTC' GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ
593771
ana@laptop:~$ oathtool --totp -b --now '2026-10-06 13:00:30 UTC' GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ
124813
```

At `13:00:00` and at `13:00:29` the code is the same; at `13:00:30` a new step begins and the code
becomes `124813`. A code captured by an attacker is useless thirty seconds later, which is the
**one-time** in the name.

A variant called **HOTP**, in RFC 4226, uses a counter that goes up by one on every use instead of the
clock. TOTP is HOTP with the time as the counter, and it is what almost every authenticator app uses.
