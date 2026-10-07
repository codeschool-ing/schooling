---
title: Evidence from the repository
version: 1
---

Every lesson of this course added a commit to `~/tm/portal-model`. An auditor asking "show me that
threat modelling happens here, and when" is asking for exactly that history:

```
(.venv) ana@vm:~/tm/portal-model$ git log --format="%h %ad %an %s" --date=short
fa6c2ba 2026-10-06 ana List what the insurer asked for, and check it
d3b266b 2026-10-05 ana Map the controls to ISO 27001 and the NIST CSF
7060908 2026-10-01 ana Record the first decisions
dfe7ca2 2026-09-29 ana Rank the controls by what they save
dfe011c 2026-09-24 ana Simulate the ranges, and compare with a matrix
16259cb 2026-09-22 ana Estimate the expected loss of the larger risks
2b965bc 2026-09-17 ana Write a requirement for each threat
72b7507 2026-09-14 ana Add the threats the abuse cases found
23e3e45 2026-09-10 ana Draw the console as it is: reachable from the internet
088ee69 2026-09-10 ana List the entry and exit points
f602de2 2026-09-08 ana Model one goal as an attack tree
4799e48 2026-09-03 ana List the threats found with STRIDE
839eba3 2026-09-03 ana Summarise what pytm finds
0cc253e 2026-09-01 ana Draw the portal as a data flow diagram
```

Fourteen commits in five weeks, each a step a person can name. That is good evidence of a
**process**: the model was built over time, in an order that makes sense, and not assembled the week
before the audit. A single commit dated 6 October holding every file would say the opposite, however
good the files were.

The history of one file answers a narrower question, such as when the list of threats last changed:

```
(.venv) ana@vm:~/tm/portal-model$ git log --format="%h %ad %s" --date=short -- threats.csv
72b7507 2026-09-14 Add the threats the abuse cases found
4799e48 2026-09-03 List the threats found with STRIDE
```

Two changes, the last on 14 September. An auditor reads that two ways: the threats were revisited
once after the first pass, which is good; and **nothing has been added since**, although the console
was redrawn and three documents arrived from outside. Lesson 15 is about that second reading.

### What it does not prove

Git is strong evidence of some things and weak evidence of others, and the difference matters.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l14-git\" aria-label=\"What a git history shows as evidence, and how strongly. The content of each file at each commit: strong, because every commit names its parent by hash. The order of the commits: strong once pushed to a remote others use. The date of a commit: weak, because the committer writes it. Who wrote it: weak, a name in the configuration, unless the commit is signed. That daniel approved RA-001: only what the file says.\"><rect x=\"20.0\" y=\"20.0\" width=\"300.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the content of each file at each commit</text><rect x=\"340.0\" y=\"20.0\" width=\"360.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"352.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">strong: every commit names its parent by hash</text><rect x=\"20.0\" y=\"66.0\" width=\"300.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the order of the commits</text><rect x=\"340.0\" y=\"66.0\" width=\"360.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"352.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">strong, once pushed to a remote others use</text><rect x=\"20.0\" y=\"112.0\" width=\"300.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the date of a commit</text><rect x=\"340.0\" y=\"112.0\" width=\"360.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"352.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">weak: the committer writes it</text><rect x=\"20.0\" y=\"158.0\" width=\"300.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">who wrote it</text><rect x=\"340.0\" y=\"158.0\" width=\"360.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"352.0\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">weak: a name in the config, unless signed</text><rect x=\"20.0\" y=\"204.0\" width=\"300.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">that daniel approved RA-001</text><rect x=\"340.0\" y=\"204.0\" width=\"360.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"352.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">only what the file says</text></svg>", "caption": "Git is excellent evidence of what changed and in what order, and weak evidence of when and by whom. A careful auditor knows which half they are reading."}
```

**The content and the order are strong.** Each commit names its parent by a hash of its content, so
changing an old file changes every hash after it. Once the history is pushed to a remote that other
people fetch from, rewriting it shows.

**The dates and the names are weak.** Both are written by whoever makes the commit. This course's own
lab sets every date on purpose, so its captures repeat, and nothing in the history above shows that.
An auditor treats a commit date as the committer's claim, made stronger by a hosted remote's own
record of when a push arrived, or by protected branches that only accept changes through review.

**An approval in a file is only what the file says.** RA-001 names its owner:

```
(.venv) ana@vm:~/tm/portal-model$ grep owner decisions/RA-001-crafted-pdf.md
owner: daniel
(.venv) ana@vm:~/tm/portal-model$ git log --format="%an <%ae>" -- decisions/RA-001-crafted-pdf.md
ana <ana@vereda.example>
```

daniel is the owner, and ana committed the file. Nothing in the repository shows that daniel read it.
That is not a fault in RA-001; it is a gap in how approvals are recorded, and there are ordinary
fixes. daniel can approve the change in the hosting platform's review, which records his account and
the time; or he can make the commit himself, signed with his own key. Either turns "the file says
daniel" into "daniel did it".

### The model checks itself

Some evidence is produced by running the model's own programs. `trace.py` from lesson 8 summarises
coverage:

```
(.venv) ana@vm:~/tm/portal-model$ python3 trace.py | tail -3
17 threats, 19 requirements
no requirement: T14
not verified:   R14 R17
```

This is evidence of a different kind: not that something happened, but that the model knows where
it is incomplete. T14 has no requirement because it was accepted, and RA-001 says so. R14 and R17
have no verification yet. **An auditor trusts a model that lists its own gaps** more than one that
has none, because a model with no gaps has usually not been looked at closely.
