---
title: What an SBOM is for
version: 1
---

A software bill of materials is usually introduced as a compliance document: a list a customer or a
regulator asks for, produced once, filed somewhere. Read that way it is paperwork, and teams that
treat it as paperwork make one before an audit and never open it again. **An SBOM earns its keep on a
specific morning: the one when an advisory lands and somebody asks "are we affected?"**

### The morning of the advisory

On 29 March 2024 the backdoor in xz 5.6.0 and 5.6.1 was made public, and lesson 12 told the story.
Every organisation that ran Linux had the same question that day: which of our images and machines
contain xz, in which version, and where are they running? There are two ways to answer it.

- **Without a record**, somebody pulls every image from every registry, scans or opens each one, and
  logs in to every machine, while the advisory is in the news and the list of images keeps growing.
  It takes days, and the answer is only as good as the list of places somebody remembered to look.
- **With a record made at build time**, the question is a query over files that already exist: one
  list per image, each naming every package and version inside it. It takes minutes, and it covers
  images that are no longer running anywhere, which matters when the question is "were we exposed
  last month?".

That second arrangement is the whole case for an SBOM. **The list has to exist before the question
does**, because on the morning of the advisory the build that made the image is long gone.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"sp-l13-life\" aria-label=\"The life of an SBOM. On the day of the build, the pipeline builds and pushes the image and writes its SBOM beside the run. Months later an advisory is published. Without the SBOM, somebody pulls and inspects every image and machine, which takes days. With it, a query over the stored files answers in minutes, including for images no longer running.\"><defs><marker id=\"sp-l13-life-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l13-life-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">build day</text><rect x=\"20\" y=\"35\" width=\"140\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">build and push</text><rect x=\"185\" y=\"35\" width=\"140\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">write the SBOM</text><rect x=\"20\" y=\"110\" width=\"305\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"172.5\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">kept beside the run</text><path d=\"M160 58 L183 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l13-life-ah-paper-dim)\"></path><path d=\"M255 81 L255 108\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l13-life-ah-phosphor)\"></path><line x1=\"352\" y1=\"15\" x2=\"352\" y2=\"225\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></line><text x=\"380\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">months later</text><rect x=\"380\" y=\"35\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">an advisory lands</text><rect x=\"555\" y=\"35\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">are we affected?</text><path d=\"M530 58 L553 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l13-life-ah-paper-dim)\"></path><rect x=\"380\" y=\"110\" width=\"325\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"542.5\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">without it</text><text x=\"542.5\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pull and open every image: days</text><rect x=\"380\" y=\"175\" width=\"325\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"542.5\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">with it</text><text x=\"542.5\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one query over the files: minutes</text><path d=\"M325 140 L340 140 L340 198 L378 198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l13-life-ah-phosphor)\"></path></svg>", "caption": "The list has to be written on the build day, because the question arrives long after the build is gone."}
```

### What is in one

An SBOM is a machine-readable list of the components of one piece of software, each with enough
identity to be matched against other data: a name, a version, a supplier, the licence, often a hash,
and a **package URL**. The `purl` names a package unambiguously across ecosystems:
`pkg:pypi/gunicorn@22.0.0` is gunicorn from PyPI, `pkg:deb/debian/libc6@2.41-12+deb13u4` is a
Debian package. Better SBOMs also record which component depends on which.

In 2021 the United States' NTIA published the "minimum elements" an SBOM should carry. They make a useful checklist for reading one: the supplier, the component's name and version, a unique
identifier such as the purl, the dependency relationships, the author of the SBOM, and a timestamp.
The European Union's Cyber Resilience Act also requires manufacturers of products with software to
draw one up. You will check syft's output against that list in the next sections.

### What it is not

- **It is not a vulnerability report.** An SBOM lists what is there; whether any of it is vulnerable
  is a question asked of the list, today, against today's advisories. That is why the same SBOM is
  worth scanning again next month, and the scanning section shows it.
- **It is not proof of anything.** A list anybody could have edited says what its author wrote.
  Lesson 14 signs it and attaches it to the image, which turns it into a statement the pipeline
  made.
- **It is not complete by definition.** It contains what the generator could find. The last section
  of this lesson names what syft cannot see in linkbox's image.

### linkbox's first question

Lesson 8 noticed that linkbox's image carries a package, `packaging`, that `requirements.txt` never
pinned, and lesson 12 promised the list would find it. That is the question this lesson answers with
an SBOM, and the answer shows something no scan of `requirements.txt` could: **the image contains
what the installer decided to install, which is more than what the project asked for.**
