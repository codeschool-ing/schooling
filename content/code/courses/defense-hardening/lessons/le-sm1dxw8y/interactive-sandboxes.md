---
title: Sandboxes somebody else runs
version: 1
---

**An online sandbox runs a suspicious file in a disposable virtual machine and records what it did.**
Lesson 12 built a small version of this on your own machine: run a program where it can do no harm and
watch what it tries. Services such as any.run and Joe Sandbox do the same at scale, with Windows and
other operating systems, a full set of documents and browsers installed, and a report written for
analysts. Neither was reached for this course; this section comes from their documentation, and no
report is shown.

## What a report contains

| part of the report | what it answers |
|---|---|
| process tree | what started what: the document that launched a script that launched a download |
| network activity | the domains and addresses contacted, with the requests themselves |
| files written and changed | what was dropped on disk, and where it tried to persist across a reboot |
| indicators | hashes, domains and addresses to block or search for elsewhere |
| behaviour mapped to MITRE ATT&CK | the techniques observed, named in the vocabulary detection rules use |

The indicators are what a defender takes away: the domains go to lesson 14's resolver, the hashes to
lesson 7's signatures and lesson 8's hunting, the techniques to the detection rules.

## The two services

**any.run** is interactive: the analyst watches the virtual machine's screen in the browser and can
click through what the sample asks for, such as a document that says "enable editing". Its free plan
makes every analysis public.

**Joe Sandbox** runs samples automatically and writes long, detailed reports. Its free "Cloud Basic"
tier publishes reports; the paid tiers keep them private and add more systems.

## Their limits

A sandbox sees what a sample does in a few minutes, in one machine, on that day. Samples written to
avoid analysis check for the signs of a virtual machine, wait longer than the sandbox watches, or do
nothing unless they find the right language, domain or user, and then the report is clean because
nothing ran. **A clean sandbox report means the sample did nothing there**, which is weaker than "the
sample does nothing". The privacy rule of the first section applies with more force here than anywhere:
a document uploaded to a public sandbox is published together with a video of somebody opening it.
