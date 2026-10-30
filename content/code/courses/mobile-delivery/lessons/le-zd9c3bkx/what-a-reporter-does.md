---
title: What a crash reporter does
version: 1
---

**A crash on a phone leaves no trace the team can see.** The app vanishes and the person opens it
again, or does not. The operating system keeps its own crash logs, and both stores show some of
them, lesson 8's Android vitals and App Store Connect's crash counts, but with a delay of a day or
more and only from people who agreed to share diagnostics. A **crash reporter** is a library inside
the app that tells you itself, within minutes, with the context the system does not have.

## The shape every one of them has

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l12-sequence\" aria-label=\"Two launches of the app on a timeline. During the first launch, the reporter starts first, the app keeps breadcrumbs as it runs, then it crashes; the reporter writes the report to the phone's disk and the app vanishes. The person opens the app again. During the second launch, the reporter starts first again, finds the report on disk and sends it to the server, which answers that it accepted it, and the report is deleted from the disk.\"><defs><marker id=\"l12-sequence-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12-sequence-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l12-sequence-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"300\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">launch 1</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">launch 2</text><text x=\"40\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1  reporter starts</text><text x=\"40\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">2  breadcrumbs kept</text><text x=\"40\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">3  crash</text><text x=\"40\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">4  report written to disk</text><text x=\"40\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5  the app vanishes</text><text x=\"420\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1  reporter starts</text><text x=\"420\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">2  report sent</text><text x=\"420\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">3  accepted, deleted</text><path d=\"M320 100 L398 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l12-sequence-ah-paper-dim)\"></path><text x=\"359\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">opened again</text><rect x=\"150\" y=\"220\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"240.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the phone's disk</text><rect x=\"470\" y=\"220\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"550.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">crash server</text><path d=\"M170 180 L210 218\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-sequence-ah-amber)\"></path><path d=\"M330 230 L468 230\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-sequence-ah-phosphor)\"></path></svg>", "caption": "The report crosses the gap between two launches on disk. Nothing is sent at the moment of the crash, because a crashing process is the last place to trust with a network request."}
```

1. **It starts first**, before any other code of the app runs, so a crash during start-up is caught
   too.
2. **It keeps breadcrumbs**: a short list of what the app was doing, "opened Statistics", "tapped
   guitar", kept in memory and replaced as it goes.
3. **On a crash, it writes a report to disk, and nothing else.** A process that is crashing may have
   a corrupted heap, a dead network stack, seconds to live. Writing one file is the most it can be
   trusted to finish. A native crash on iOS or Android is caught by a signal handler, where even
   allocating memory is unsafe, so the reporters write a pre-allocated buffer.
4. **On the next launch, it sends what is on disk**, and deletes each report once the server has
   accepted it. A report that cannot be sent stays for the launch after that.

So **the report of a crash arrives when the person opens the app again**, which is why a crash on
start-up, the one that stops people opening it at all, is the one most likely never to arrive. The
better reporters try to send a start-up crash at once, synchronously, for that reason.

## What a report carries

The **error**: its type, its message and the stack, the list of functions that were running. The
**build**: version name and number, lesson 9, so the report can be matched to the code. The
**device**: model, operating system version, free memory, orientation. The **breadcrumbs**. And an
**identifier for the installation**, so a crash that happens to one person forty times is not
counted as forty people.

What it should not carry is anything that identifies the person, unless you decided it should and
declared it, lesson 5. The next section builds a reporter whose every field you can read.
