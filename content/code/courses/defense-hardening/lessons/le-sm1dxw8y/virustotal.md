---
title: VirusTotal, starting from the hash
version: 1
---

**VirusTotal runs a file past several dozen antivirus engines and other tools, and keeps the results
for everybody who looks the same file up later.** It was not reached for this course, because the lab
has no internet; everything in this section comes from VirusTotal's own documentation, and no output is
shown because none was produced.

## Search, do not upload

The search box on virustotal.com takes a hash as well as a file. Searching for the SHA-256 from the
last section asks "has anybody submitted this exact file before?" without sending the file. Two answers
are possible:

- **A report exists.** It shows how many engines flag the file, when it was first and last seen, the
  names it has been submitted under, and what the community has said about it. Nothing of yours was
  shared.
- **Nothing is found.** The file is new to VirusTotal. That is not a sign it is safe: a file written for
  one target, which is what a targeted attack sends, is new by definition. It is the point where the
  previous section's order decides whether this file may be uploaded at all.

The same lookup can be scripted through the public API, version 3, with a personal key. This is the
documented form; it was not run here:

```sh
curl -s -H "x-apikey: $VT_API_KEY" \
  https://www.virustotal.com/api/v3/files/1f40c2b362d01d064dcc53f20fc9b0a3e624469b810c9c5e7493e02d9be70cce
```

The free key has a small daily quota and its terms forbid commercial use, which is why firms that do
this every day pay for a licence.

## Reading the ratio

The number people quote is the **detection ratio**, so many engines out of so many. It is easy to read
wrongly in both directions:

| reading | why it misleads |
|---|---|
| "0 detections, so it is safe" | engines detect what they have seen; a new or targeted file starts at zero |
| "3 of 70, so it is probably fine" | a few engines may be the ones that recognise a new family first |
| "2 of 70 on our own installer, so it is malware" | heuristic engines flag packers and installers; lesson 7 called these false positives |
| "the ratio was 0 last week" | ratios rise as engines learn the file; a report is a snapshot with a date |

**The ratio is evidence, not a verdict.** What makes a report useful is the rest of it: the names
other people gave the file, when it first appeared, the domains it contacts, and whether the engines
that flag it agree on what it is.

## The privacy line, once more

VirusTotal's terms state that content submitted through the public service is shared with the
security community, including premium customers who can download the file. **A file that belongs to
the firm or carries a client's data is never uploaded there**, whatever the hurry. A paid private
scanning service, or the local analysis of lesson 12, is where such a file goes.
