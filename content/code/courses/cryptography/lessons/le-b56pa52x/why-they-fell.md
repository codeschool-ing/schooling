---
title: How MD5 and SHA-1 fell
version: 1
---

**MD5 and SHA-1 did not fall because somebody reversed them. They fell because researchers learnt
to produce collisions, two different inputs with the same digest, far faster than the birthday
bound allows.** That broke the one promise signatures depend on. Their preimage resistance is still
largely intact, which is why both survive in places where nobody needs collision resistance, and
why people keep defending them in places where somebody does.

## Why a collision breaks a signature

A signature, as lesson 3 used it, does not sign the document. Signing a 20 MB file with RSA
directly is impossible, so every signature scheme first hashes the document and signs the digest.
The signature is therefore a statement about the digest, and it is valid for **any** document with
that digest:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"A document goes through a hash function and becomes a short digest; the private key signs only the digest. A second, different document that has the same digest would be covered by the same signature, which is why a hash that allows collisions breaks signatures.\"><defs><marker id=\"sh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"sh-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">document A</text><text x=\"95\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the harmless one</text><rect x=\"20\" y=\"140\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"95\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">document B</text><text x=\"95\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a different one</text><polyline points=\"172,55 258,55\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#sh-ah-wire)\"></polyline><text x=\"215\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">hash</text><polyline points=\"172,165 258,80\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" marker-end=\"url(#sh-ah-amber)\"></polyline><text x=\"212\" y=\"108\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">same digest?</text><rect x=\"260\" y=\"30\" width=\"160\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"340\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">digest</text><text x=\"340\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">b40d…54fc</text><polyline points=\"422,55 508,55\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#sh-ah-phosphor)\"></polyline><text x=\"465\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">private key</text><rect x=\"510\" y=\"30\" width=\"190\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"605\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">signature</text><text x=\"605\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">valid for the digest</text><text x=\"360\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">If B shares A&#x27;s digest, the signature</text><text x=\"360\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">on A is also a valid signature on B.</text></svg>", "caption": "The key signs the digest, never the document itself."}
```

So if somebody can produce two documents with the same digest, one harmless and one not, a
signature obtained on the harmless one is also a valid signature on the other. Nothing about the
signature algorithm or the key needs to be weak. The hash was the weak link.

## The timeline

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A timeline from 1990 to 2030. MD5 published 1992, SHA-1 1995, SHA-2 2001. Then MD5 collisions 2004, SHA-1 weakened 2005, the rogue CA certificate built from MD5 collisions 2008, Flame 2012, SHA-3 2015, SHAttered and browsers dropping SHA-1 in 2017, Shambles 2020, and NIST&#x27;s deadline to remove SHA-1 at the end of 2030.\"><polyline points=\"40,125 690,125\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></polyline><polyline points=\"40.0,121 40.0,129\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></polyline><text x=\"40.0\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1990</text><polyline points=\"202.5,121 202.5,129\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></polyline><text x=\"202.5\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2000</text><polyline points=\"365.0,121 365.0,129\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></polyline><text x=\"365.0\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2010</text><polyline points=\"527.5,121 527.5,129\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></polyline><text x=\"527.5\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2020</text><polyline points=\"690.0,121 690.0,129\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></polyline><text x=\"690.0\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2030</text><polyline points=\"72.5,119 72.5,48\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></polyline><text x=\"72.5\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">MD5</text><polyline points=\"121.25,119 121.25,70\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></polyline><text x=\"121.25\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">SHA-1</text><polyline points=\"218.75,119 218.75,48\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></polyline><text x=\"218.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">SHA-2</text><polyline points=\"446.25,119 446.25,48\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></polyline><text x=\"446.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">SHA-3</text><text x=\"38.0\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">published</text><polyline points=\"267.5,131 267.5,157\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></polyline><text x=\"267.5\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">MD5 collisions</text><polyline points=\"332.5,131 332.5,182\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></polyline><text x=\"332.5\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">rogue CA</text><polyline points=\"397.5,131 397.5,157\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></polyline><text x=\"397.5\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">Flame</text><polyline points=\"478.75,131 478.75,182\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></polyline><text x=\"478.75\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">SHAttered</text><polyline points=\"527.5,131 527.5,157\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></polyline><text x=\"527.5\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">Shambles</text><polyline points=\"690.0,131 690.0,182\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></polyline><text x=\"694.0\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">SHA-1 removed</text><text x=\"283.75\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">SHA-1 weakened</text><polyline points=\"283.75,119 283.75,100\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></polyline><text x=\"38.0\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">broken, or retired</text></svg>", "caption": "Each warning came a decade before the attack that made it urgent."}
```

**MD5.** Designed in 1991 and published as RFC 1321 in 1992. Weaknesses in its internals were found
in 1996, and in 2004 Xiaoyun Wang and colleagues published real MD5 collisions. Within a few years a
collision on an ordinary computer took seconds. In 2008 a team of researchers used MD5 collisions
to obtain, from a real certificate authority that still signed with MD5, a certificate that could
act as a CA itself; they made it expire in the past so it could not be abused, and the CAs stopped
using MD5 within weeks. In 2012 the Flame espionage malware was found signed with a forged Microsoft
code-signing certificate built from an MD5 collision against a forgotten Microsoft licensing CA. By
then MD5 had been deprecated for a decade, and that was the problem: it had been deprecated, not
removed.

**SHA-1.** Published by NIST in 1995. In 2005 Wang's group showed collisions could be found in about
2⁶⁹ operations, well under the 2⁸⁰ of the birthday bound. NIST deprecated it in 2011. Browsers
stopped trusting SHA-1 certificates in early 2017, and weeks later Google and CWI Amsterdam
published **SHAttered**, two different PDF files with the same SHA-1 digest, at the cost of about
6,500 years of processor time and 110 years of GPU time. In 2020 **SHA-1 is a Shambles**
demonstrated the stronger kind of collision, in which the two inputs can start with different,
chosen content, for about 45,000 dollars of rented GPU time, and used it against PGP's web of trust.
NIST has announced that SHA-1 is to be removed entirely by the end of 2030.

## Two kinds of collision, and why the second is worse

The 2004 MD5 and 2017 SHA-1 results were **identical-prefix** collisions: both inputs start with the
same content and differ only in blocks the attacker computes. That is enough to break a format that
can hide those blocks, which is how two different-looking PDFs can share a digest.

A **chosen-prefix** collision lets the two inputs start with different content chosen by the
attacker, such as two certificates with different names. That is what the 2008 rogue CA and Flame
used for MD5, and what Shambles brought to SHA-1. Once a chosen-prefix collision is affordable,
anything signed over that hash, by anybody who might be fooled into signing the harmless half, is
suspect.

## What a defender takes from it

The lesson is not about the mathematics. It is about the gap between a hash being **shown weak** and
being **removed**:

- MD5's internal weaknesses were known **twelve years** before the rogue CA, and SHA-1's **twelve
  years** before SHAttered. Each time, the warning came long before the attack;
- systems that kept the weak hash "because nobody has broken it in practice" were the ones exposed
  when somebody did;
- the fix is inventory: know where each hash is used, and replace it while the attack is still
  theoretical. Git, which identifies every commit by SHA-1, added collision detection in 2017 and
  supports SHA-256 repositories, precisely so that its move does not have to happen in a hurry.

SHA-256 has no known weakness of this kind today. That is what MD5 had in 1995.
