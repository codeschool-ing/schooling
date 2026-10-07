---
title: What a key-management service does
version: 1
---

The idea fits in one sentence: **the key stays inside the service, and what leaves is the result
of using it.** An application that needs a CPF encrypted sends the CPF and the name of a key; the
service encrypts it and sends back ciphertext. To read it, an application with the right to
decrypt sends the ciphertext back and receives the CPF. Neither application ever holds the key.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l4-kms\" aria-label=\"The website sends a CPF and the name of a key to the key-management service and receives ciphertext, which it stores in the database. Support sends the ciphertext and receives the CPF. The key itself stays inside the service; no arrow carries it out. Every request is written to the audit log.\"><defs><marker id=\"dg-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"dg-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"dg-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20.0\" y=\"50.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the website</text><text x=\"95.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">policy: encrypt</text><rect x=\"20.0\" y=\"170.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">support</text><text x=\"95.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">policy: decrypt</text><rect x=\"285.0\" y=\"60.0\" width=\"150.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">key service</text><rect x=\"310.0\" y=\"102.0\" width=\"100.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ipe-cpf</text><text x=\"360.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the key never</text><text x=\"360.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">leaves</text><rect x=\"550.0\" y=\"50.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">database</text><text x=\"625.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vault:v2:…</text><rect x=\"550.0\" y=\"170.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">audit log</text><path d=\"M170.0 66.0 L283.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><text x=\"228.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">CPF</text><path d=\"M283.0 104.0 L170.0 86.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><text x=\"228.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ciphertext</text><path d=\"M95 50 L95 22 L625 22 L625 48\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#dg-ah-wire)\"></path><text x=\"360.0\" y=\"14.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">stores the ciphertext</text><path d=\"M170.0 186.0 L283.0 176.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><text x=\"228.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ciphertext</text><path d=\"M283.0 196.0 L170.0 206.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><text x=\"228.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">CPF</text><path d=\"M435.0 190.0 L548.0 195.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-phosphor)\"></path><text x=\"492.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every use</text></svg>", "caption": "The key stays in the service. What leaves is the result of using it, and every use is recorded."}
```

Five things follow from that arrangement, and each one is the answer to a stage of the last
section:

- **The key cannot be copied by the people using it**, because they never have it. A leaked
  application token can be revoked; a leaked key has to be assumed copied for ever.
- **Use is a permission.** Encrypting and decrypting are separate operations, so they are
  separate grants: the website may encrypt and never decrypt, support may decrypt and never
  encrypt, nobody but the key's administrator may read its configuration. Section 7 writes those
  policies.
- **Every use is recorded.** The service sees every request, so it can log who asked to decrypt
  what, and when — which is exactly the question an investigation asks after a leak. Section 8.
- **Keys change without the data moving.** A ciphertext says which version of the key made it,
  so a new version can encrypt from today while old versions still decrypt. Section 10.
- **A key can be destroyed**, deliberately, and everything encrypted only with it becomes
  unreadable everywhere at once, backups included. Section 13 uses that on purpose.

## What it does not do

**It does not decide who should be able to decrypt.** It enforces the policy somebody writes; a
policy giving every application decrypt is a key handed to everybody with extra latency.

**It does not protect data the application has already decrypted.** Support decrypts a CPF to
read it to a customer on the phone, and from that moment it is plaintext in support's screen.
The service narrows who can turn ciphertext into plaintext; lessons 1 and 2 still decide who
those people are.

**It becomes the thing everything depends on.** If the service is down, nothing can be encrypted
or decrypted. That is why the next sections spend time on how it starts, how it is sealed, and
who holds the means to unseal it.

## Where the keys finally live

Somewhere, the service itself has to protect its keys at rest. A cloud KMS keeps them in
**hardware security modules** — devices built so that a key generated inside them can be used but
never exported. OpenBao, running on an ordinary machine, encrypts its storage with a key that is
itself split between several people, and that is the first thing the lab does with it.
