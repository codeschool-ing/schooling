---
title: A second opinion from Trivy, and why two tools disagree
version: 1
---

Two composition analysers pointed at the same project rarely print the same thing, and the first
reaction is to decide which one is wrong. **Usually neither is: they collected different lists of
packages, or looked them up in different databases, or counted differently.** Knowing which of the
three explains a difference is what makes a second tool useful rather than confusing.

Trivy is the second tool here. It is a general scanner that lesson 8 points at images and lesson 11
compares with others; `trivy fs` scans a directory. The previous section already ran it on lesson
1's `requirements.txt` and kept the JSON. Its findings, one line each:

@@CAPTURE trivy@@

**Fifteen findings, the same fifteen CVEs pip-audit's twenty-nine rows came down to**, each with a
severity pip-audit does not print. On the question both tools were asked, they agree. The second
command is where they stop agreeing: Trivy did not scan `requirements-dev.txt` at all. Its summary
says `-`, not scanned, which is different from `0`, clean.

### Where the lists come from

The two tools disagree about pytest because they collect packages differently, and a file with one
line in it shows the difference most plainly:

@@CAPTURE one@@

pip-audit **resolved** the file: it asked pip what installing `flask==3.0.0` would install today,
and audited all seven packages, each transitive one at the newest version Flask 3.0.0 accepts.
Trivy **read** the file: one line, one package. Neither is wrong, and they answer two questions.

- **Trivy audits what the file says.** It is fast, needs no network to resolve anything, and
  reports only what is written down. It recognises files by name, which is why `requirements.txt`
  is read and `requirements-dev.txt` is not, and it cannot see a transitive package the file does
  not pin.
- **pip-audit audits what would be installed.** It sees every transitive package, but at the
  version the index offers today, so the same file can audit clean on Monday and dirty on
  Thursday, or the other way round, with no commit in between.

linkbox's requirements pin the transitive packages by hand, which is why the two agreed on the
service. A project that pins only its direct dependencies would get two very different answers,
and the cure is lesson 15's compiled lock file, where every package is written down with its
version and both tools read the same list.

@@FIGURE tools@@

### Where the advisories come from

pip-audit looked each package up on PyPI, which serves advisories from OSV. Trivy looks them up in
**its own database**, built from GitHub's advisories, the NVD, Linux distributions' feeds and
others, and downloaded to the machine. On this machine the database was downloaded once on the day
of the recording, so every Trivy number in the course comes from the same one. On yours it is at
most a day old, and the counts you see will not be these.

The two sources usually agree on whether a version is affected, as they did here, and often
disagree on everything around it: the severity, the fixed version when a fix arrived in two
branches, the day a new advisory appears. A flaw published this morning can be in one database by
lunch and the other by tomorrow.

### Two counts for one finding

| | pip-audit | Trivy |
|---|---|---|
| what it collects | the packages pip would install, resolved now | the lines of files it recognises by name |
| transitive packages not in the file | audited, at today's versions | not seen |
| `requirements-dev.txt` | audited, because it was named with `-r` | not scanned |
| advisories from | PyPI, which serves OSV | its own database, downloaded |
| one flaw published twice | two rows | one row |
| severity | not printed | printed, from a chosen source |

### What to do with two tools

Running both on every push buys little: two gates, two sets of exceptions and twice the noise for
mostly the same answer. **This pipeline gates on one**, pip-audit, because it audits what will
actually be installed and it reads both files. Trivy earns its place where it sees what pip-audit
cannot: the operating system's packages inside an image, which lesson 8 scans. A second tool is
worth running now and then on the same input, as this section did, because the differences are
where a blind spot shows: here, a file one tool never opened.
