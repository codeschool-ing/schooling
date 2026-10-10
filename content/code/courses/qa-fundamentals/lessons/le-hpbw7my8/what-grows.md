---
title: What grows when a defect is found late
version: 1
---

**A late defect does not cost more because time passed. It costs more because of what happened during
that time.** Four things accumulate between the moment a mistake is made and the moment it is found, and
each one is a separate reason. Naming them is more useful than any multiplier, because you can look at
a particular defect and ask how much of each it has collected.

## 1. What has been built on top

Code is built on code. A wrong decision in how the shop stores a reservation is, on the day it is made,
one decision. Three months later it is the foundation of the seat map, the refunds screen, the nightly
report and the box office's printing, and fixing it means changing all of them and testing all of them
again. **The defect did not grow; its dependants did.**

This is why the defects that grow fastest are the ones in requirements and design. A wrong price in one
line of `tickets.py` has nothing built on top of it. A wrong idea about what a reservation is has
everything built on top of it.

## 2. Who has met it

Before release, a defect has met the team. After release, it meets customers, and each one who meets it
adds a cost that has nothing to do with the code:

- the customer who was wrongly charged, who has to be found and refunded;
- the customer who noticed, complained at the counter, and now trusts the shop a little less;
- Célia, who spends her evening explaining it;
- in some domains, a regulator, because charging a pensioner full price in Brazil is not only a defect,
  it is a breach of a statute.

**A defect before release is a technical problem. After release it is a commercial one**, and sometimes
a legal one. The code fix may be identical at both moments; everything around it is not.

## 3. Who remembers why

The day Rafael wrote `age > 60` he knew exactly why. Six months later, the line is one of thousands, he
may be working on something else, and whoever fixes it has to rediscover what the code was meant to do
before they can change it safely. **Context decays**, and rebuilding it is slow, expensive work that
appears in nobody's estimate.

This is also the cheapest of the four to reduce without finding defects any earlier: tests that
describe what the code is for, and requirements kept beside it, are context that does not decay.

## 4. How many steps the fix has to go through

A defect found while Rafael is still writing the code is fixed by Rafael, in his editor, in a minute. A
defect found in testing needs a report, a triage, a fix, a review, and a second round of testing. A
defect found in production needs all of that plus a release, which at some companies is scheduled weeks
ahead, and a check afterwards that the fix reached every customer.

Each step is somebody's time, and **each step is a queue**. Lesson 13 is about queues; the short version
is that a fix waiting in four queues takes longer than four times the work in it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 250\" role=\"img\" data-fig=\"l03-what-grows\" aria-label=\"A grid. Columns, left to right: found in the sentence, in review, in testing, after release. Rows: what is built on top, who has met it, how much context is lost, how many steps the fix needs. Built on top grows from nothing to one line, a feature and the whole shop. People who met it stay the team until after release, when customers and Célia join. Context lost goes from none to most. Steps to fix go from a reply to an edit, then report, fix and retest, then all that plus a release. Cells shade darker to the right.\"><text x=\"198.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">in the sentence</text><text x=\"334.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">in review</text><text x=\"470.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">in testing</text><text x=\"606.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">after release</text><text x=\"120.0\" y=\"59.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">built on top</text><rect x=\"132.0\" y=\"38.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"198.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">nothing</text><rect x=\"268.0\" y=\"38.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"334.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">one line</text><rect x=\"404.0\" y=\"38.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"470.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">a feature</text><rect x=\"540.0\" y=\"38.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"606.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">the shop</text><text x=\"120.0\" y=\"105.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">people who met it</text><rect x=\"132.0\" y=\"84.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"198.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">the team</text><rect x=\"268.0\" y=\"84.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"334.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">the team</text><rect x=\"404.0\" y=\"84.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"470.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">the team</text><rect x=\"540.0\" y=\"84.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"606.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">customers, Célia</text><text x=\"120.0\" y=\"151.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">context lost</text><rect x=\"132.0\" y=\"130.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"198.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">none</text><rect x=\"268.0\" y=\"130.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"334.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">none</text><rect x=\"404.0\" y=\"130.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"470.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">some</text><rect x=\"540.0\" y=\"130.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"606.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">most</text><text x=\"120.0\" y=\"197.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">steps to fix</text><rect x=\"132.0\" y=\"176.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"198.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">a reply</text><rect x=\"268.0\" y=\"176.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"334.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">an edit</text><rect x=\"404.0\" y=\"176.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"470.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">report, fix, retest</text><rect x=\"540.0\" y=\"176.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"606.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">all that, plus a release</text></svg>", "caption": "The four things that grow, for the sixty-year-old’s defect found at four moments. Every cell in the right-hand column is a cost the fix itself does not show."}
```

## Using the four

When you report a defect, the four are what to think about, and the report is stronger for them. Not
"this is a serious bug", but: *this is a price rule, so nothing is built on it and the fix is one line;
it has not shipped, so no customer has met it; Rafael wrote it last week and remembers it; it can go
out with Friday's release.* That is a cheap defect, and saying so is as useful to the team as saying when
one is expensive.

The same four make the case for prevention without a single invented ratio. A defect stopped in the
requirement has nothing built on it, has met nobody, needs nobody to remember anything, and goes
through no queue at all.
