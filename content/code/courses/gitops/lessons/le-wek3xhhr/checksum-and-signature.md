---
title: What a checksum proves, and what it does not
version: 1
---

**Every download in this course was checked against a checksum**, from `kind` in lesson 1 to `flux` in
lesson 4. Lesson 1 promised to ask what that proves. It proves that the file you received is the
file whose hash is in the checksum file. It does not prove who made either of them.

The checksum file came from the same place as the binary: the same release page, the same server.
Somebody who could replace the binary there could replace the checksum beside it, and `sha256sum
--check` would print `OK` for their file. **A checksum protects against a damaged download; it does
not protect against a dishonest source.**

A **signature** answers the second question. The publisher holds a private key that never leaves
them, and publishes the matching public key once, somewhere you can get it independently: their
documentation, a key server, a repository you already trust. Signing computes, with the private key,
a value over the artefact's digest that only the private key could have produced; verifying checks,
with the public key, that the value matches the digest you have. **A changed artefact fails, and so
does an artefact signed by anybody else.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"Signing and verifying. The publisher signs the artefact&#x27;s digest with a private key that never leaves them. The signature is stored beside the artefact in the registry. A verifier with the public key checks the signature against the digest it pulled, and refuses on a mismatch.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"270\" fill=\"var(--ink)\"/><rect x=\"20\" y=\"30\" width=\"170\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"105.0\" y=\"50.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">private key</text><text x=\"105.0\" y=\"68.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">kept by the publisher</text><rect x=\"20\" y=\"190\" width=\"170\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"105.0\" y=\"210.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">public key</text><text x=\"105.0\" y=\"228.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">published once</text><rect x=\"270\" y=\"110\" width=\"180\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"360.0\" y=\"135.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">registry</text><text x=\"360.0\" y=\"153.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">artefact + signature</text><rect x=\"530\" y=\"110\" width=\"170\" height=\"60\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"615.0\" y=\"135.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">verifier</text><text x=\"615.0\" y=\"153.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">the cluster's side</text><line x1=\"190\" y1=\"60\" x2=\"259.9\" y2=\"119.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"266,125 262.8,116.4 257.0,123.2\" fill=\"var(--paper-dim)\"/><text x=\"200\" y=\"105\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">signs the digest</text><line x1=\"450\" y1=\"140\" x2=\"518.0\" y2=\"140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"526,140 518.0,135.5 518.0,144.5\" fill=\"var(--paper-dim)\"/><text x=\"470\" y=\"130\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">pulls</text><line x1=\"190\" y1=\"215\" x2=\"518.1\" y2=\"161.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"/><polygon points=\"526,160 517.4,156.9 518.8,165.7\" fill=\"var(--paper-dim)\"/><text x=\"330\" y=\"232\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">checks with</text><text x=\"615\" y=\"200\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--amber)\">wrong key or</text><text x=\"615\" y=\"216\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--amber)\">changed bytes: refuse</text></svg>", "caption": "A signature ties an artefact's digest to a key. The verifier needs only the public key, and that is the one thing it must get from somewhere it already trusts."}
```

For GitOps the question is sharper than for a download, because nobody looks at what is deployed:
an agent pulls by reference and runs it. Lesson 7 made that reference a digest, so the bytes cannot
change under it. This lesson makes the cluster's side check **who produced those bytes**, and makes
an unsigned artefact a refusal rather than a deployment.
