---
title: Four words that are not synonyms
version: 1
---

Lessons 1 to 4 decided who may read the data and protected it on the way. This lesson changes the
data itself, so that less of it is dangerous in the first place. Four techniques do that, and the
words for them are used interchangeably in meetings and mean different things in law:

| technique | what it does | can the original be recovered? |
|---|---|---|
| **masking** | hides part of a value when it is shown: `***.874.168-**` | the value is intact underneath; whoever reads the table reads it |
| **tokenisation** | replaces a value with a stand-in, and keeps the mapping somewhere else | yes, by whoever controls the mapping |
| **pseudonymisation** | replaces who somebody is with a code, so records about the same person still join | yes, with information kept separately |
| **anonymisation** | changes the data until nobody in it can be singled out by reasonable means | no — that is the definition |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l5-spectrum\" aria-label=\"Four techniques placed along one line, from the original value on the left to data nobody can be found in on the right: masking, tokenisation, pseudonymisation, anonymisation. The first three are still personal data under the LGPD; only the fourth is not, and only while it holds.\"><defs><marker id=\"dg-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M30.0 70.0 L690.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><text x=\"30.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the original value</text><text x=\"690.0\" y=\"48.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nobody can be found</text><rect x=\"30.0\" y=\"92.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">masking</text><text x=\"110.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">***.874.168-**</text><rect x=\"195.0\" y=\"92.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"275.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tokenisation</text><text x=\"275.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tok_bbc2f3fe…</text><rect x=\"360.0\" y=\"92.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"440.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pseudonymisation</text><text x=\"440.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">vault:v1:5Vv5…</text><rect x=\"525.0\" y=\"92.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"605.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">anonymisation</text><text x=\"605.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">counts, k ≥ 5</text><rect x=\"30.0\" y=\"170.0\" width=\"490.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"275.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">personal data: every obligation applies</text><rect x=\"525.0\" y=\"170.0\" width=\"160.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"605.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">not personal data</text></svg>", "caption": "The law draws its line at the right-hand end, not in the middle."}
```

The difference that matters is the last column, because **the law treats the two ends
differently.** Brazil's LGPD says anonymised data is not personal data at all (art. 12), with
everything that follows: no legal basis needed, no data subject rights, no retention limit. Masked,
tokenised and pseudonymised data are still personal data, governed in full. A team that calls a
pseudonymised export "anonymous" has not changed what the law says about it — only what it tells
itself.

**Obfuscation** is the fifth word, and it is the weakest: making data harder to read without any
secret, the way base64 or a reversible shuffle does. It protects against nobody who looks; lesson
11 of the `cryptography` course is about why encoding is not encryption. This lesson mentions it
only to say it is not one of the four.

## What each technique is for

The question is never "which one is best" but **who needs what from the data**:

- support needs to recognise a customer on the phone, not to copy their documents — **masking**;
- developers need data with the shape of production, not the people in it — a **masked copy**;
- the website needs to find a customer by CPF without the database holding CPFs — a **token**;
- analysts need to count and join a customer's orders, not to know who it is — a **pseudonym**;
- a report for a regulator or the public needs numbers nobody can be found in — **anonymisation**,
  and a way to check it.

The sections that follow build each of these on Ipê's data, and the last measures how far from
anonymous "anonymous-looking" data can be.
