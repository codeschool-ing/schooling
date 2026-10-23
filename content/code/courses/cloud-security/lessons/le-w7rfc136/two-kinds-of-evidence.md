---
title: The line, and the two kinds of evidence on either side of it
version: 1
---

**The `cloud` course drew the shared responsibility model as one line across a stack: below it the
provider does the work, above it you do. For a security engineer the line has a second meaning. It
also divides two kinds of evidence, and you will spend your working life collecting the one on your
side.** That course's lesson 1 is the drawing; this lesson is what you do with it.

The wrong picture is that the line divides *blame*: if something breaks below it, the provider pays,
and if it breaks above it, you do. A contract says something like that, and an incident report never
does. When patients' records leak, the people in them do not ask which row of a stack failed. The
clinic answers for them under the LGPD whoever ran the faulty layer, and its fines and its
reputation are its own. **The responsibility is split; the consequences are not.**

## Below the line, you read a report

Nothing below the line can be inspected by you. You will never be shown the hypervisor, walk the
building or read the access log of the provider's own engineers. What you get instead is a
**third-party attestation**: an auditor the provider hired examined those controls against a
published standard and wrote down what they found. Two sections on, this lesson says what one of those
reports contains and what it cannot tell you.

That is evidence of a weaker kind than a test, and it is the only kind available. It is also the same
for every customer: the provider runs one hypervisor for all of them, and one report covers it.

## Above the line, you ask the API

Everything above the line is a setting, and every setting can be read back. Whether a bucket is
encrypted, whether it may be made public, who holds a key that still works, which network ports are
open to the internet: each is one request away, and the answer is specific to **your** account, as of
**now**. That is evidence of the strong kind, and it is also a duty. Nobody else will ask those
questions about your account, because nobody else can.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l02-evidence\" aria-label=\"The shared responsibility line, with the evidence available on each side. Above the line, the customer's settings: who holds a working key, whether a bucket is encrypted or may be made public, which ports are open. The evidence for them is a request to the API, and the answer is about your account, as of now. Below the line, the provider's work: the hypervisor, the buildings, the physical network, its own staff's access. The evidence for it is an auditor's report, which is about every customer, over a period in the past.\"><defs><marker id=\"l02-evidence-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l02-evidence-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"30.0\" width=\"330.0\" height=\"125.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"46.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">yours: settings in your account</text><text x=\"56.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">who holds a key that still works</text><text x=\"56.0\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">is the bucket encrypted, can it go public</text><text x=\"56.0\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">which ports are open to the internet</text><path d=\"M18.0 172.0 L372.0 172.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"195.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the line</text><rect x=\"30.0\" y=\"200.0\" width=\"330.0\" height=\"110.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"46.0\" y=\"220.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">the provider's: its own work</text><text x=\"56.0\" y=\"248.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">hypervisor, buildings, physical network</text><text x=\"56.0\" y=\"270.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">its own engineers' access</text><text x=\"56.0\" y=\"292.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the same for every customer</text><path d=\"M364.0 92.0 L436.0 92.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-evidence-af-ah-phosphor)\"></path><rect x=\"440.0\" y=\"50.0\" width=\"250.0\" height=\"85.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"565.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">ask the API</text><text x=\"565.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">about your account</text><text x=\"565.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">as of now</text><path d=\"M364.0 255.0 L436.0 255.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-evidence-af-ah-paper-dim)\"></path><rect x=\"440.0\" y=\"212.0\" width=\"250.0\" height=\"85.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">read an auditor's report</text><text x=\"565.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">about every customer</text><text x=\"565.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">over a period in the past</text></svg>", "caption": "The line splits the evidence as well as the work. Only the evidence above it is about your account, and only you can collect it."}
```

## The rows that never move

Two rows sit above the line on every model, and they are the reason this course exists: **the data
and who can reach it**. A provider can encrypt your disks, patch its own servers and keep its
building locked, and the clinic's records will still be exactly as private as the clinic's own
settings allow. Lessons 6 to 11 are those two rows, one control at a time.
