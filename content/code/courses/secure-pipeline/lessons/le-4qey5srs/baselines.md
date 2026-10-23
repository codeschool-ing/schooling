---
title: Old findings, new findings and exceptions that expire
version: 1
---

linkbox is small, and its pipeline met every finding one at a time. A real service adopting a
scanner meets them all at once: three hundred findings on the first run, in code written over
five years by people who have left. Breaking the build on all of them stops the team on day one,
and the gate is switched off by day three. Warning on all of them buries the next real finding
under three hundred old ones. **The way out is to separate new findings from existing ones**, and
to treat the two differently.

### Baselines

A baseline is a record of the findings that existed when the scanner arrived. The gate then breaks
only on findings that are not in it, which is the "now, in the change" half of the rule made
mechanical: whoever pushes is answerable for what they added, not for the history. The scanners of
this course each have a form of it:

```
ana@vm:~/linkbox$ gitleaks git --help | grep baseline
  -b, --baseline-path string          path to baseline with issues that can be ignored
ana@vm:~/linkbox$ semgrep scan --help 2>/dev/null | grep -A2 "baseline-commit=VAL"
       --baseline-commit=VAL (absent SEMGREP_BASELINE_COMMIT env)
           Only show results that are not found in this commit hash. Aborts
           run if not currently in a git directory, there are unstaged
ana@vm:~/linkbox$ pip-audit --help | grep -A2 -- "--ignore-vuln ID  "
  --ignore-vuln ID      ignore a specific vulnerability by its vulnerability
                        ID; this option can be used multiple times (default:
                        [])
```

gitleaks reads a previous report and leaves out the findings in it. Semgrep compares against a
commit and reports only what is new since then. pip-audit has no baseline at all, only
`--ignore-vuln`, one advisory at a time and for ever, which is why this lesson wrote a gate.

**A baseline has no dates and no names.** Every line in it is a finding somebody decided not to
fix today, recorded in a file nobody is responsible for, with no day on which the decision is
looked at again. Left alone it never shrinks, and an old finding in it is as exploitable as a new
one. So a baseline is a starting point with a plan attached: a number of findings, an owner for
the number, and a budget for bringing it down, measured the way lesson 20 measures security debt.

### Exceptions, which a baseline is not

The exception file of this lesson is the other tool, for the single finding a team has decided to
live with for a while. Its lines carry what a baseline lacks: **a date, a reason and an owner**.
The owner is not a field in the file. It is whoever committed the line, and Git already records
that:

```
ana@vm:~/linkbox$ git blame -s ci/exceptions.txt | tail -n 3
9c388009 4) PYSEC-2026-1475 2026-11-20 templates need rework for 3.1.5; Ana, see issue 41
9c388009 5) PYSEC-2026-1472 2026-11-20 templates need rework for 3.1.5; Ana, see issue 41
9c388009 6) PYSEC-2026-1471 2026-11-20 templates need rework for 3.1.6; Ana, see issue 41
ana@vm:~/linkbox$ git log -1 --format="%an, %ad" --date=short -- ci/exceptions.txt
Ana Lima, 2026-10-23
```

`git blame` names the commit behind each line, and the commit names its author and day. The name in
the reason is a courtesy for the reader; the commit is the record nobody can forget to fill in.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"sp-l07-expiry\" aria-label=\"The life of one exception, written on 23 October to hold until 20 November. From 23 October to 13 November the finding passes; from 14 to 20 November, its last week, the gate warns; from 21 November the exception is ignored and the finding breaks the build again. Renewing it is a new commit with a new date and reason.\"><defs><marker id=\"sp-l07-expiry-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l07-expiry-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40\" y=\"70\" width=\"420\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">passes, as excepted</text><rect x=\"460\" y=\"70\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"530\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">warns</text><rect x=\"600\" y=\"70\" width=\"105\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"652\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">breaks again</text><path d=\"M30 130 L710 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l07-expiry-ah-paper-dim)\"></path><line x1=\"40\" y1=\"122\" x2=\"40\" y2=\"138\" stroke=\"var(--paper)\" stroke-width=\"2\"></line><text x=\"36\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">23 Oct</text><text x=\"36\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the line is committed</text><line x1=\"460\" y1=\"122\" x2=\"460\" y2=\"138\" stroke=\"var(--paper)\" stroke-width=\"2\"></line><text x=\"460\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">14 Nov</text><text x=\"460\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the last week begins</text><line x1=\"597\" y1=\"122\" x2=\"597\" y2=\"138\" stroke=\"var(--paper)\" stroke-width=\"2\"></line><text x=\"597\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">20 Nov</text><text x=\"597\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the last day</text><text x=\"652\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">21 Nov: the date has passed</text><path d=\"M652 70 L652 40 L60 40 L60 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l07-expiry-ah-phosphor)\"></path><text x=\"356\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">renewing it: a new commit, a new date, a new reason</text></svg>", "caption": "The exception announces its own end a week early, and after it the finding is back as if it had never been excepted."}
```

Four rules keep exceptions from turning into a baseline by another name:

1. The date is short, weeks rather than a year, because a decision ages as fast as the code around
   it. The one in the last section ran four weeks.
2. The gate warns in the last week, so the people who wrote it see the date coming in the normal
   course of their pushes.
3. An expired exception is ignored, and the finding breaks the build exactly as before. Renewing
   one is a new commit with a new date and a reason that says what changed, read by a reviewer.
4. A line without a reason is refused: the gate cannot split it into three fields, Python raises,
   and the build breaks.

### Where this leaves the pipeline

Every stage now answers in three statuses, the last line counts the warnings, and a stage that did
not run breaks the build. The composition gate knows the difference between a fix nobody applied,
an advisory nobody can fix, and a decision with a date on it. What the lesson cannot write into a
script is the reading: **a warning is only worth its place if somebody reads it**, and the number
of warnings a team actually reads is smaller than the number a scanner can produce. Lesson 8 puts
an image scanner in front of the same question, with findings in a base image that have no fixed
version at all.
