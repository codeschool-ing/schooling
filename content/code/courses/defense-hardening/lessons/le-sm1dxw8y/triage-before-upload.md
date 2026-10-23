---
title: Before anything leaves the building
version: 1
---

**Sooner or later somebody forwards a file or a link and asks whether it is safe.** A client's
"invoice" with an odd extension, a link to a payment page that looks almost right, an attachment the
mail filter let through. The instinct is to drop it into the first online scanner that comes up in a
search. This lesson is about answering the question well, and the first part of answering it well is
the order you do things in, because **uploading a file to an online service is publishing it**.

## What an upload gives away

The online services this lesson describes keep what they are sent. VirusTotal's documentation says
plainly that files submitted through its public interface are shared with its premium customers and
security partners, who can download them. urlscan.io's public scans are visible to anybody who
searches. any.run's and Joe Sandbox's free tiers make their analyses public. All of that is useful
to the security community and dangerous to you if the file was one of Jatobá's: **a client's
spreadsheet full of CPF numbers, uploaded "to check it", is a data leak** of exactly the kind lesson 9
tried to prevent, and under the LGPD the firm answers for it.

The same goes for links. A URL can carry a token that logs somebody in, a reset code, or a client's
name in its path; submitting it publicly hands those to strangers, and scanning it may even use the
token.

## The order

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l19-triage\" aria-label=\"The order of triage. One: look locally, with file, a hash, strings and a YARA rule, which sends nothing anywhere. Two: search the hash on an online service, which reveals nothing about the content. If a report exists, read it and stop. If not, three: ask whether the file is the firm's or carries a client's data. If yes, analyse it privately, in your own sandbox or a paid private service. If no, it may be uploaded. Four, in every case: write down the hash, where you looked, what it said and when.\"><defs><marker id=\"l19-triage-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l19-triage-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"150.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1 look locally</text><text x=\"95.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">file, hash, strings, YARA</text><rect x=\"210.0\" y=\"30.0\" width=\"150.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"285.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2 search the hash</text><text x=\"285.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reveals nothing</text><path d=\"M170.0 55.0 L210.0 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l19-triage-dh-ah-paper-dim)\"></path><rect x=\"400.0\" y=\"30.0\" width=\"140.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"470.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">report found</text><text x=\"470.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">read it, stop</text><path d=\"M360.0 55.0 L400.0 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l19-triage-dh-ah-paper-dim)\"></path><rect x=\"210.0\" y=\"130.0\" width=\"150.0\" height=\"56.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"285.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3 the firm’s file?</text><text x=\"285.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">or a client’s data?</text><path d=\"M285.0 80.0 L285.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l19-triage-dh-ah-paper-dim)\"></path><text x=\"292.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nothing found</text><rect x=\"20.0\" y=\"140.0\" width=\"150.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">private analysis</text><text x=\"95.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lesson 12, or paid</text><path d=\"M210.0 160.0 L170.0 162.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l19-triage-dh-ah-amber)\"></path><text x=\"190.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">yes</text><rect x=\"400.0\" y=\"140.0\" width=\"140.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"470.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">may be uploaded</text><text x=\"470.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">public service</text><path d=\"M360.0 160.0 L400.0 162.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l19-triage-dh-ah-paper-dim)\"></path><text x=\"380.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no</text><rect x=\"160.0\" y=\"225.0\" width=\"400.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">4 write down: hash, where, what it said, when</text></svg>", "caption": "The upload is the last step and the optional one, never the first."}
```

1. **Look locally first.** What the file really is, and its hash, cost nothing and leave nothing
   behind. The next section does this on `desk`.
2. **Search by hash before submitting anything.** A hash reveals nothing about the content, and if
   the file is known, the answer is already there.
3. **Upload only what is not the firm's.** A file from outside that nobody at the firm wrote, and
   that carries no client's data, may go to a service; anything else goes to a private analysis, such
   as the sandbox of lesson 12 or a paid service with private submissions.
4. **Write down what you did**: the hash, where you looked, what it said, and when. The verdict of an
   online service changes as more engines learn a file, and "it was clean on Tuesday" is only useful
   with the date.

Start the lab for this lesson: one machine, the workstation where the file arrived.

```sh
sudo bash hostlab.sh up desk
```
