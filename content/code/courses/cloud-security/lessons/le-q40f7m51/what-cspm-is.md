---
title: Posture is the configuration, read again and again
version: 1
---

**A cloud account's security posture is the state of its configuration at this moment: which
buckets are public, which ports face the internet, which users sign in with one factor. Cloud
security posture management, CSPM, is a program that reads that state through the API, compares it
with a list of rules, and reports every place the two disagree. Then it reads it again tomorrow.**

The wrong picture is an audit: a consultant spends two weeks with the account, writes a report, and
the account is now known to be fine. It was fine on the day the report was written. Lesson 1 showed
how short a change is in the cloud — one request made a bucket public and printed nothing — so a
configuration checked in March says very little about October. **Posture is a reading, not a
certificate**, and the reading goes stale at the speed of the API.

## What it reads, and what it does not

Lesson 1 already made the point this lesson stands on: in the cloud, **inventory is a query**. Every
bucket, every security group and every user is one `describe` or `list` away. A CSPM tool is that
query run on a schedule, over every service and every region, with a rule beside each answer:

| it asks | the rule | lesson |
|---|---|---|
| does a bucket policy allow `"Principal": "*"`? | storage is not public unless somebody decided it | 9 |
| does a bucket have default encryption? | data at rest is encrypted | 11 |
| does a security group allow port 22 from `0.0.0.0/0`? | administration is not open to the world | 8 |
| does a user sign in without a second factor? | people use MFA | 6 |
| does an access key exist that is two years old? | keys rotate | 7 |

Almost every lesson of this course ends with a setting that should be one way and can drift the
other. **A CSPM tool is those lessons turned into rules that run without you.**

Three neighbours do different jobs, and confusing them is how a team ends up believing it is covered:

- **a vulnerability scanner** reads software: an old library, an unpatched kernel. Lesson 13 runs
  one over a function's dependencies. It says nothing about who may read a bucket;
- **threat detection** reads events: a key used from a new country, a burst of `ListBuckets` at three
  in the morning. AWS's GuardDuty, Microsoft Defender's threat alerts and Google's Event Threat
  Detection are this. They react to what somebody did, and lesson 15 is about the records they read;
- **CSPM** reads configuration. It finds the open door before anybody walks through it, and it
  cannot tell whether somebody already did.

## The rules come from somewhere

A rule list is opinion until somebody publishes it. The ones most tools start from are the **CIS
Benchmarks** for AWS, Azure and Google Cloud, from the same Center for Internet Security that
publishes one for each operating system, and each provider's own best-practice set. Neither knows the clinic. The public
website has to be a public bucket, and a rule that flags it every morning is a rule people learn to
ignore. The section after the scanner is about that: a finding is not a fix, and an exception needs
a reason and an end date.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l16-loop\" aria-label=\"The posture loop. The scanner reads the configuration through the API, compares each answer with its rules, and writes findings. Each finding goes to an owner, who either fixes it or accepts it with a reason and an end date. The next scan reads the configuration again. Drift, a hand change made after the scan, enters the configuration from outside the loop, and only the next reading sees it.\"><defs><marker id=\"l16-loop-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l16-loop-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l16-loop-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40.0\" y=\"110.0\" width=\"140.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"110.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">configuration</text><text x=\"110.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">what the API answers</text><rect x=\"220.0\" y=\"110.0\" width=\"140.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"290.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">rules</text><text x=\"290.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">CIS, provider, yours</text><rect x=\"400.0\" y=\"110.0\" width=\"140.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"470.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">findings</text><text x=\"470.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">rule, resource, detail</text><rect x=\"560.0\" y=\"50.0\" width=\"130.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"625.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">fix</text><text x=\"625.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">by the owner</text><rect x=\"560.0\" y=\"170.0\" width=\"130.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"625.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">accept</text><text x=\"625.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">reason and end date</text><path d=\"M182.0 140.0 L218.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-loop-af-ah-paper-dim)\"></path><text x=\"200.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">read</text><path d=\"M362.0 140.0 L398.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-loop-af-ah-paper-dim)\"></path><path d=\"M542.0 128.0 L558.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-loop-af-ah-paper-dim)\"></path><path d=\"M542.0 152.0 L558.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-loop-af-ah-paper-dim)\"></path><path d=\"M625 232 L625 270 L110 270 L110 172\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-loop-af-ah-phosphor)\"></path><path d=\"M690 80 L705 80 L705 270 L625 270\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"370.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the next scan reads it all again</text><path d=\"M110.0 34.0 L110.0 108.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l16-loop-af-ah-amber)\"></path><text x=\"124.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">drift: a hand change after the scan</text></svg>", "caption": "A finding is not the end of the loop: the fix, or the dated exception, is checked by the next reading, and so is every change made by hand in between."}
```

The next two sections build the loop on your own computer: an account with four faults in it, and a
program of fifty-six lines that finds them.
