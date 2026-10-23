---
title: urlscan, for a link instead of a file
version: 1
---

**urlscan.io opens a web address in a browser of its own and records everything that happened**: the
page as it rendered, every request it made, the domains and addresses those went to, the certificates,
and the scripts that ran. It was not reached for this course; this section comes from urlscan's
documentation, with no output shown.

The question it answers is the one a link raises: where does this actually lead, and what does the page
do, without anybody at the firm opening it. A phishing page imitating a bank, a link that redirects
three times before landing, a page that loads scripts from a domain lesson 14 would block: each shows up
in the report as something you can read.

## Search first, again

Like VirusTotal, urlscan keeps what it is given, and somebody else may already have scanned the same
address. The search page takes a domain, an address or a URL, and returns earlier scans with their
dates. **A scan from yesterday of the same link** answers most of what a new one would, and submits
nothing.

## Visibility

A new scan has a visibility, chosen when it is submitted:

| visibility | who can see the result |
|---|---|
| public | anybody, listed on the front page and in search |
| unlisted | anybody with the link, plus urlscan's paying security customers |
| private | only the account that submitted it |

**Public is the default for anonymous use**, and that is the setting that leaks. A link to a client's
document share, a password-reset link or a page with somebody's name in the address, scanned publicly,
is now readable by strangers, and scanning it may even consume a one-time token the client needed.
Links like that are not scanned at all; a link from a stranger may be, preferably unlisted or private.

## What to read in the report

- **The final address** after every redirect, and whether its domain matches what the link claimed.
- **The domains contacted**, which go to lesson 14's list if they are hostile.
- **The screenshot**, which shows what a person would have seen without anybody being that person.
- **The page's age and certificate**: a certificate issued yesterday for a domain registered yesterday
  is the shape of a phishing site, and the last section of this lesson is about the domain half.
